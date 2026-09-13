import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mneme/resources/resource_installer.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';

/// Scripts HTTP responses without sockets: loopback servers behave
/// differently across test runners, so download behavior is verified
/// against controlled chunk streams instead.
class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

http.StreamedResponse _bytesResponse(
  List<int> bytes, {
  int status = 200,
  int? contentLength,
}) {
  return http.StreamedResponse(
    Stream.value(bytes),
    status,
    contentLength: contentLength ?? bytes.length,
  );
}

void main() {
  late Directory tempDir;
  late ResourceRepository repository;
  late int requests;
  late Future<http.StreamedResponse> Function(http.BaseRequest) handler;

  final payload = Uint8List.fromList(
    List<int>.generate(256 * 1024, (i) => i % 251),
  );

  String shaOf(List<int> bytes) => sha256.convert(bytes).toString();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mneme-resources-');
    requests = 0;
    handler = (request) async {
      requests++;
      return _bytesResponse(payload);
    };
    repository = ResourceRepository(
      modelDir: Directory('${tempDir.path}/models'),
      corpusDir: Directory('${tempDir.path}/corpora'),
      client: _ScriptedClient((request) => handler(request)),
    );
  });

  tearDown(() async {
    await repository.dispose();
    await tempDir.delete(recursive: true);
  });

  String packUrl(String path) => 'https://example.test/$path';

  test('install succeeds and atomically renames the verified file', () async {
    final installed = await repository.installCorpusPack(
      'fixture.bin',
      packUrl('fixture.bin'),
      shaOf(payload),
    );

    expect(installed.existsSync(), isTrue);
    expect(installed.readAsBytesSync(), payload);
    expect(
      File('${installed.path}.part').existsSync(),
      isFalse,
      reason: 'no partial file may survive a successful install',
    );
    expect(repository.stateOf('fixture.bin').phase, ResourcePhase.installed);
    expect(requests, 1);
  });

  test('mismatched sha256 fails and leaves no destination file', () async {
    await expectLater(
      repository.installCorpusPack(
        'fixture.bin',
        packUrl('fixture.bin'),
        '0' * 64,
      ),
      throwsA(isA<HashMismatchException>()),
    );
    expect(
      File('${tempDir.path}/corpora/fixture.bin').existsSync(),
      isFalse,
    );
  });

  group('range resume', () {
    late Directory dir;
    late ResourceInstaller installer;

    setUp(() {
      dir = Directory('${tempDir.path}/resume')..createSync();
      installer = ResourceInstaller(
        client: _ScriptedClient((request) => handler(request)),
        destinationDir: dir,
      );
    });

    /// Serves [payload] with Range support: 206 slices, 416 past the end,
    /// 200 full bodies when the test ignores the header.
    Future<http.StreamedResponse> rangeHandler(
      http.BaseRequest request, {
      bool honorRange = true,
    }) async {
      requests++;
      final range = request.headers['Range'];
      if (honorRange && range != null) {
        final start = int.parse(range.split('=')[1].split('-')[0]);
        if (start > payload.length) {
          return http.StreamedResponse(const Stream.empty(), 416);
        }
        return http.StreamedResponse(
          Stream.value(payload.sublist(start)),
          206,
          contentLength: payload.length - start,
        );
      }
      return _bytesResponse(payload);
    }

    test('interrupted download resumes from the surviving part', () async {
      handler = rangeHandler;
      final half = payload.length ~/ 2;
      File(
        '${dir.path}/resume.bin.part',
      ).writeAsBytesSync(payload.sublist(0, half));

      final installed = await installer.install(
        'resume.bin',
        Uri.parse(packUrl('resume.bin')),
        shaOf(payload),
      );

      expect(installed.readAsBytesSync(), payload);
      expect(requests, 1);
    });

    test('a server ignoring Range restarts the transfer', () async {
      handler = (request) => rangeHandler(request, honorRange: false);
      File('${dir.path}/clean.bin.part').writeAsBytesSync([1, 2, 3]);

      final installed = await installer.install(
        'clean.bin',
        Uri.parse(packUrl('clean.bin')),
        shaOf(payload),
      );

      expect(installed.readAsBytesSync(), payload);
      expect(requests, 2);
    });

    test('a stale oversized part restarts after 416', () async {
      handler = rangeHandler;
      File('${dir.path}/stale.bin.part').writeAsBytesSync([
        ...payload,
        9,
        9,
      ]);

      final installed = await installer.install(
        'stale.bin',
        Uri.parse(packUrl('stale.bin')),
        shaOf(payload),
      );

      expect(installed.readAsBytesSync(), payload);
      expect(requests, 2);
    });
  });
  test(
    'cancellation keeps the partial download for resume',
    () async {
      final gate = Completer<void>();
      handler = (request) async {
        requests++;
        return http.StreamedResponse(
          (() async* {
            yield payload.sublist(0, 1024);
            await gate.future;
            yield payload.sublist(1024);
          })(),
          200,
          contentLength: payload.length,
        );
      };
      final pending = repository.installCorpusPack(
        'slow.bin',
        packUrl('slow.bin'),
        shaOf(payload),
      );
      while (repository.stateOf('slow.bin').phase !=
          ResourcePhase.downloading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      repository.cancel('slow.bin');
      gate.complete();

      await expectLater(
        pending,
        throwsA(isA<InstallCanceledException>()),
      );
      expect(repository.stateOf('slow.bin').phase, ResourcePhase.notInstalled);
      expect(
        File('${tempDir.path}/corpora/slow.bin').existsSync(),
        isFalse,
      );
      expect(
        File('${tempDir.path}/corpora/slow.bin.part').existsSync(),
        isTrue,
        reason: 'a canceled transfer resumes instead of restarting',
      );
    },
  );

  test('non-200 responses fail without creating files', () async {
    handler = (request) async {
      requests++;
      return _bytesResponse([], status: 404, contentLength: 0);
    };
    await expectLater(
      repository.installCorpusPack(
        'missing.bin',
        packUrl('missing.bin'),
        shaOf(payload),
      ),
      throwsA(isA<Exception>()),
    );
    expect(repository.stateOf('missing.bin').phase, ResourcePhase.failed);
  });

  test(
    'already-installed resource short-circuits without redownload',
    () async {
      final first = await repository.installCorpusPack(
        'once.bin',
        packUrl('once.bin'),
        shaOf(payload),
      );
      expect(requests, 1);

      final second = await repository.installCorpusPack(
        'once.bin',
        packUrl('once.bin'),
        shaOf(payload),
      );
      expect(second.path, first.path);
      expect(first.readAsBytesSync(), payload);
      expect(requests, 1, reason: 'no second download may start');
    },
  );

  test('states stream exposes download progress', () async {
    final received = <ResourceState>[];
    final sub = repository.states.listen(received.add);
    addTearDown(sub.cancel);

    await repository.installCorpusPack(
      'progress.bin',
      packUrl('progress.bin'),
      shaOf(payload),
    );

    final downloading = received
        .where((s) => s.phase == ResourcePhase.downloading)
        .toList();
    expect(
      downloading.last.receivedBytes,
      payload.length,
      reason: 'final download update must cover all bytes',
    );
  });

  test('manifest-controlled ids cannot escape the destination', () async {
    for (final id in ['../evil.bin', r'..\evil.bin', '', '.', '..']) {
      await expectLater(
        repository.installCorpusPack(id, packUrl('x'), shaOf(payload)),
        throwsArgumentError,
        reason: 'id "$id" must be rejected before any download',
      );
    }
    expect(requests, 0, reason: 'rejected ids must never hit the network');
    expect(
      File('${tempDir.path}/evil.bin').existsSync(),
      isFalse,
      reason: 'rejected ids must not create files outside the corpus dir',
    );
  });

  test('reinstall replaces the file and removes the backup', () async {
    final first = await repository.installCorpusPack(
      'fixture.bin',
      packUrl('fixture.bin'),
      shaOf(payload),
    );
    final replacement = Uint8List.fromList(
      List<int>.generate(1024, (i) => 255 - (i % 251)),
    );
    handler = (request) async {
      requests++;
      return _bytesResponse(replacement);
    };
    final second = await repository.installCorpusPack(
      'fixture.bin',
      packUrl('fixture.bin'),
      shaOf(replacement),
    );

    expect(second.path, first.path);
    expect(second.readAsBytesSync(), replacement);
    expect(File('${second.path}.bak').existsSync(), isFalse);
    expect(File('${second.path}.part').existsSync(), isFalse);
  });

  test('exceptions describe the failed resource', () {
    expect(
      const InstallCanceledException('ru.db.gz').toString(),
      contains('ru.db.gz'),
    );
    expect(
      const HashMismatchException('ru.db.gz', 'abc').toString(),
      contains('ru.db.gz'),
    );
  });

  test('size mismatch fails without installing', () async {
    await expectLater(
      repository.installCorpusPack(
        'fixture.bin',
        packUrl('fixture.bin'),
        shaOf(payload),
        sizeBytes: payload.length + 1,
      ),
      throwsA(isA<HashMismatchException>()),
    );
    expect(
      File('${tempDir.path}/corpora/fixture.bin').existsSync(),
      isFalse,
    );
  });

  test('stale backup files are removed on install', () async {
    final backup = File('${tempDir.path}/corpora/fixture.bin.bak')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    await repository.installCorpusPack(
      'fixture.bin',
      packUrl('fixture.bin'),
      shaOf(payload),
    );
    expect(backup.existsSync(), isFalse);
  });

  test('uninstall removes destination and leftovers', () async {
    final dir = Directory('${tempDir.path}/solo')..createSync();
    final installer = ResourceInstaller(
      client: _ScriptedClient((request) async => _bytesResponse([])),
      destinationDir: dir,
    );
    addTearDown(() => installer.uninstall('x.bin'));
    final destination = File('${dir.path}/x.bin')..writeAsStringSync('old');
    File('${dir.path}/x.bin.part').writeAsStringSync('partial');
    File('${dir.path}/x.bin.bak').writeAsStringSync('backup');

    await installer.uninstall('x.bin');

    expect(destination.existsSync(), isFalse);
    expect(File('${dir.path}/x.bin.part').existsSync(), isFalse);
    expect(File('${dir.path}/x.bin.bak').existsSync(), isFalse);
    await installer.uninstall('x.bin');
  });

  test('dispose cancels in-flight installs', () async {
    final local = ResourceRepository(
      modelDir: Directory('${tempDir.path}/models2')..createSync(),
      corpusDir: Directory('${tempDir.path}/corpora2')..createSync(),
      client: _ScriptedClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return _bytesResponse(payload);
      }),
    );
    final pending = local.installCorpusPack(
      'slow.bin',
      packUrl('slow.bin'),
      shaOf(payload),
    );
    for (var i = 0; i < 100; i++) {
      if (local.stateOf('slow.bin').phase == ResourcePhase.downloading) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await local.dispose();
    await expectLater(
      pending,
      throwsA(isA<InstallCanceledException>()),
    );
  });

  test('speech model install state is reported', () async {
    final model = LockedResource(
      id: 'fake-model.gguf',
      url: packUrl('fake-model.gguf'),
      sha256: shaOf(payload),
      sizeBytes: payload.length,
    );
    expect(await repository.isSpeechModelInstalled(model), isFalse);
    await repository.installSpeechModel(model);
    expect(await repository.isSpeechModelInstalled(model), isTrue);
    expect(
      const ResourceState(
        id: 'x',
        phase: ResourcePhase.downloading,
      ).copyWith(receivedBytes: 3).phase,
      ResourcePhase.downloading,
    );
  });

  test('concurrent installs of one resource share a download', () async {
    handler = (request) async {
      requests++;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _bytesResponse(payload);
    };
    const url = 'https://example.test/shared.bin';
    final files = await Future.wait([
      repository.installCorpusPack('shared.bin', url, shaOf(payload)),
      repository.installCorpusPack('shared.bin', url, shaOf(payload)),
    ]);

    expect(files[0].path, files[1].path);
    expect(requests, 1);
  });

  test('conflicting bytes wait out the in-flight install', () async {
    final other = Uint8List.fromList(
      List<int>.generate(128, (i) => 255 - (i % 251)),
    );
    handler = (request) async {
      requests++;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final url = request.url.toString();
      return _bytesResponse(url.contains('v2') ? other : payload);
    };
    const id = 'contended.bin';
    final first = repository.installCorpusPack(
      id,
      packUrl('contended.bin'),
      shaOf(payload),
      sizeBytes: payload.length,
    );
    final second = repository.installCorpusPack(
      id,
      packUrl('contended.bin?v2'),
      shaOf(other),
      sizeBytes: other.length,
    );
    await Future.wait([first, second]);

    // Both downloads ran exactly once; the second install replaced the
    // first one's bytes (both handles address the same destination).
    expect(requests, 2);
    expect(File('${tempDir.path}/corpora/$id').readAsBytesSync(), other);
  });

  test('failed conflicts do not block a retry with other bytes', () async {
    const id = 'flaky.bin';
    final first = repository.installCorpusPack(
      id,
      packUrl('flaky.bin'),
      '0' * 64,
      sizeBytes: payload.length,
    );
    final second = repository.installCorpusPack(
      id,
      packUrl('flaky.bin'),
      shaOf(payload),
      sizeBytes: payload.length,
    );
    await expectLater(first, throwsA(isA<HashMismatchException>()));
    final installed = await second;
    expect(installed.readAsBytesSync(), payload);
    expect(requests, 2);
  });

  test('cancel from the final progress callback still wins', () async {
    final dir = Directory('${tempDir.path}/late')..createSync();
    final installer = ResourceInstaller(
      client: _ScriptedClient((request) async => _bytesResponse(payload)),
      destinationDir: dir,
    );
    final token = InstallCancelToken();
    await expectLater(
      installer.install(
        'late.bin',
        Uri.parse(packUrl('late.bin')),
        shaOf(payload),
        cancelToken: token,
        onProgress: (progress) {
          if (progress.receivedBytes >= payload.length) {
            token.cancel();
          }
        },
      ),
      throwsA(isA<InstallCanceledException>()),
    );
    expect(File('${dir.path}/late.bin').existsSync(), isFalse);
  });

  test('modelFile resolves the install path without I/O', () {
    final file = repository.modelFile('nemotron-test.gguf');
    expect(
      file.path,
      '${tempDir.path}${Platform.pathSeparator}models'
      '${Platform.pathSeparator}nemotron-test.gguf',
    );
    expect(file.existsSync(), isFalse);
  });
}
