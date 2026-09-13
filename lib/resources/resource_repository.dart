import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mneme/resources/resource_installer.dart';
import 'package:mneme/resources/resource_locks.dart';

/// Lifecycle of one offline resource.
enum ResourcePhase {
  /// No install attempted yet.
  notInstalled,

  /// Bytes are being downloaded.
  downloading,

  /// Download finished; SHA-256 verification is running.
  verifying,

  /// Verified bytes are being moved into place.
  installing,

  /// The resource is installed with the expected hash.
  installed,

  /// The last install attempt failed or was canceled.
  failed,
}

/// State of one resource, exposed through [ResourceRepository.states].
class ResourceState {
  const ResourceState({
    required this.id,
    required this.phase,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  const ResourceState.notInstalled(this.id)
    : phase = ResourcePhase.notInstalled,
      receivedBytes = 0,
      totalBytes = 0,
      error = null;

  final String id;
  final ResourcePhase phase;
  final int receivedBytes;
  final int totalBytes;
  final Object? error;

  ResourceState copyWith({
    ResourcePhase? phase,
    int? receivedBytes,
    int? totalBytes,
    Object? error,
  }) {
    return ResourceState(
      id: id,
      phase: phase ?? this.phase,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error,
    );
  }
}

/// Tracks and installs offline resources: locked speech models and corpus
/// packs. All installs are cancellable; cancellation returns the resource
/// to [ResourcePhase.notInstalled] without leaving partial files behind.
class ResourceRepository {
  ResourceRepository({
    required Directory modelDir,
    required Directory corpusDir,
    http.Client? client,
  }) : _models = ResourceInstaller(
         client: client ?? http.Client(),
         destinationDir: modelDir,
       ),
       _corpora = ResourceInstaller(
         client: client ?? http.Client(),
         destinationDir: corpusDir,
       );

  final ResourceInstaller _models;
  final ResourceInstaller _corpora;

  // Synchronous delivery: progress states reach listeners in emission
  // order, so install markers never overtake the install they describe.
  final _statesController = StreamController<ResourceState>.broadcast(
    sync: true,
  );
  final _states = <String, ResourceState>{};
  final _cancelTokens = <String, InstallCancelToken>{};

  /// Broadcast stream of state changes.
  Stream<ResourceState> get states => _statesController.stream;

  /// Current state of [id]; unknown ids report [ResourcePhase.notInstalled].
  ResourceState stateOf(String id) =>
      _states[id] ?? ResourceState.notInstalled(id);

  /// True when the given locked speech model is installed.
  Future<bool> isSpeechModelInstalled(LockedResource model) {
    return _models.isInstalled(model.id, model.sha256);
  }

  /// True when a file with the model [id] exists. No hash check: install
  /// verified the bytes, and this is a cheap launch gate, not verification.
  bool isModelPresent(String id) => _models.exists(id);

  /// True when the language pack file exists. Same cheap-gate contract
  /// as [isModelPresent].
  bool isCorpusPackPresent(String id) => _corpora.exists(id);

  /// Starts installing [model] (no-op when already installed).
  ///
  /// Progress and errors surface through [states]; the returned future
  /// completes with the installed file or the failure exception.
  Future<File> installSpeechModel(LockedResource model) {
    return _install(model, _models);
  }

  /// Installs one corpus pack described by a manifest entry.
  ///
  /// [id] is the pack filename, e.g. `ru.db.zst`; [sha256] and [sizeBytes]
  /// come from the published manifest.json and are enforced exactly like
  /// speech models.
  Future<File> installCorpusPack(
    String id,
    String url,
    String sha256, {
    int? sizeBytes,
  }) {
    return _install(
      LockedResource(
        id: id,
        url: url,
        sha256: sha256,
        sizeBytes: sizeBytes ?? 0,
      ),
      _corpora,
    );
  }

  /// Cancels the in-flight install of [id], if any.
  void cancel(String id) => _cancelTokens[id]?.cancel();

  /// Installs started through [_install], keyed by resource id. Concurrent
  /// calls for the same id and bytes share one download instead of
  /// truncating each other's partial file or stealing each other's
  /// cancel token. A different descriptor waits out the current install
  /// and then installs its own bytes.
  final _ongoing = <String, _OngoingInstall>{};

  Future<File> _install(
    LockedResource resource,
    ResourceInstaller installer,
  ) async {
    while (true) {
      final ongoing = _ongoing[resource.id];
      if (ongoing == null) break;
      if (_sameBytes(ongoing.resource, resource)) {
        return ongoing.future;
      }
      try {
        await ongoing.future;
      } on Exception catch (_) {
        // The conflicting install failed; fall through and try ours.
      }
    }
    late final Future<File> future;
    future = _runInstall(resource, installer).whenComplete(() {
      final current = _ongoing[resource.id];
      if (current != null && identical(current.future, future)) {
        _ongoing.remove(resource.id);
      }
    });
    _ongoing[resource.id] = _OngoingInstall(
      resource: resource,
      future: future,
    );
    return future;
  }

  Future<File> _runInstall(
    LockedResource resource,
    ResourceInstaller installer,
  ) async {
    if (await installer.isInstalled(resource.id, resource.sha256)) {
      _emit(
        ResourceState(
          id: resource.id,
          phase: ResourcePhase.installed,
          totalBytes: resource.sizeBytes,
        ),
      );
      return installer.pathFor(resource.id);
    }

    final token = InstallCancelToken();
    _cancelTokens[resource.id] = token;
    _emit(
      ResourceState.notInstalled(resource.id).copyWith(
        phase: ResourcePhase.downloading,
        totalBytes: resource.sizeBytes,
      ),
    );

    try {
      final file = await installer.install(
        resource.id,
        Uri.parse(resource.url),
        resource.sha256,
        expectedSize: resource.sizeBytes > 0 ? resource.sizeBytes : null,
        cancelToken: token,
        onProgress: (progress) {
          _emit(
            ResourceState(
              id: resource.id,
              phase: ResourcePhase.downloading,
              receivedBytes: progress.receivedBytes,
              totalBytes: progress.totalBytes,
            ),
          );
        },
      );
      _emit(
        ResourceState(
          id: resource.id,
          phase: ResourcePhase.installed,
          totalBytes: resource.sizeBytes,
        ),
      );
      return file;
    } on InstallCanceledException {
      _emit(ResourceState.notInstalled(resource.id));
      rethrow;
    } catch (error) {
      _emit(
        ResourceState.notInstalled(resource.id).copyWith(
          phase: ResourcePhase.failed,
          error: error,
        ),
      );
      rethrow;
    } finally {
      _cancelTokens.remove(resource.id);
    }
  }

  void _emit(ResourceState state) {
    _states[state.id] = state;
    if (!_statesController.isClosed) {
      _statesController.add(state);
    }
  }

  /// Releases the state stream. Installs in flight are canceled.
  Future<void> dispose() async {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    await _statesController.close();
  }
}

/// An install started for one resource descriptor.
class _OngoingInstall {
  const _OngoingInstall({required this.resource, required this.future});

  final LockedResource resource;
  final Future<File> future;
}

/// True when both descriptors would install byte-identical content.
bool _sameBytes(LockedResource a, LockedResource b) =>
    a.url == b.url && a.sha256 == b.sha256 && a.sizeBytes == b.sizeBytes;
