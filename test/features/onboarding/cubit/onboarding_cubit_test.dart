import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_installer.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:mneme/resources/wake_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWakeLock implements DeviceWakeLock {
  /// Acquire call count.
  int acquires = 0;

  /// Release call count.
  int releases = 0;

  @override
  Future<void> acquire() async {
    acquires++;
  }

  @override
  Future<void> release() async {
    releases++;
  }
}

void main() {
  late Uri manifestUrl;
  late Uint8List corpusBytes;
  late Uint8List modelBytes;
  late LockedResource fakeSpeechModel;
  late String corpusSha256;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    manifestUrl = Uri.parse('https://example.test/data-v1/manifest.json');
    corpusBytes = Uint8List.fromList(List<int>.generate(4096, (i) => i % 7));
    modelBytes = Uint8List.fromList(List<int>.generate(2048, (i) => i % 13));
    corpusSha256 = sha256.convert(corpusBytes).toString();
    fakeSpeechModel = LockedResource(
      id: 'tiny-model.gguf',
      url: 'https://example.test/models/tiny-model.gguf',
      sha256: sha256.convert(modelBytes).toString(),
      sizeBytes: modelBytes.length,
    );
  });

  http.Client fakeClient({int manifestStatus = 200}) {
    return MockClient((request) async {
      if (request.url.toString() == manifestUrl.toString()) {
        if (manifestStatus != 200) {
          return http.Response('gone', manifestStatus);
        }
        return http.Response.bytes(
          utf8.encode(
            json.encode({
              'ru': {
                'file': 'ru.db.gz',
                'name': 'Русский',
                'size': corpusBytes.length,
                'sha256': corpusSha256,
                'version': '1.0+2',
                'schema_version': 2,
              },
            }),
          ),
          200,
        );
      }
      final segment = request.url.pathSegments.last;
      if (segment == 'ru.db.gz') {
        return http.Response.bytes(corpusBytes, 200);
      }
      if (request.url.toString() ==
          'https://example.test/models/'
              'tiny-model.gguf') {
        return http.Response.bytes(modelBytes, 200);
      }
      return http.Response('not found', 404);
    });
  }

  // Tests default to a fake lock: unit tests run without a platform
  // binding, and the production lock is best-effort anyway.
  OnboardingCubit buildCubit(http.Client client, {DeviceWakeLock? wakeLock}) {
    return OnboardingCubit(
      resources: ResourceRepository(
        modelDir: _tempDir('models'),
        corpusDir: _tempDir('corpora'),
        client: client,
      ),
      manifestClient: CorpusManifestClient(
        client: client,
        manifestUrl: manifestUrl,
      ),
      speechModel: fakeSpeechModel,
      wakeLock: wakeLock ?? FakeWakeLock(),
    );
  }

  group('WakeLock', () {
    test('a successful install acquires once and releases once', () async {
      final wakeLock = FakeWakeLock();
      final cubit = buildCubit(fakeClient(), wakeLock: wakeLock);
      addTearDown(cubit.close);
      await cubit.selectLanguage('ru');
      expect(wakeLock.acquires, 1);
      expect(wakeLock.releases, 1);
    });

    test('a failed install still releases the lock', () async {
      final wakeLock = FakeWakeLock();
      final cubit = buildCubit(
        fakeClient(manifestStatus: 500),
        wakeLock: wakeLock,
      );
      addTearDown(cubit.close);
      await expectLater(
        cubit.selectLanguage('ru'),
        throwsA(isA<Exception>()),
      );
      expect(wakeLock.acquires, 1);
      expect(wakeLock.releases, 1);
    });
  });

  group('OnboardingCubit', () {
    test('initial state is language selection', () {
      expect(
        buildCubit(fakeClient()).state.phase,
        OnboardingPhase.languageSelection,
      );
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'installs corpus pack and speech model, then persists the language',
      build: () => buildCubit(fakeClient()),
      act: (cubit) => cubit.selectLanguage('ru'),
      expect: () => [
        isA<OnboardingState>()
            .having((s) => s.phase, 'phase', OnboardingPhase.installing)
            .having((s) => s.resource, 'resource', OnboardingResource.corpus),
        isA<OnboardingState>()
            .having((s) => s.resource, 'resource', OnboardingResource.corpus)
            .having((s) => s.totalBytes, 'totalBytes', corpusBytes.length),
        // Mirrored repository progress: download start, full bytes,
        // then the installed marker for the corpus pack.
        isA<OnboardingState>()
            .having((s) => s.resource, 'resource', OnboardingResource.corpus)
            .having((s) => s.receivedBytes, 'receivedBytes', 0),
        isA<OnboardingState>()
            .having((s) => s.resource, 'resource', OnboardingResource.corpus)
            .having(
              (s) => s.receivedBytes,
              'receivedBytes',
              corpusBytes.length,
            ),
        isA<OnboardingState>().having(
          (s) => s.resource,
          'resource',
          OnboardingResource.corpus,
        ),
        // Same mirrored progress for the speech model.
        isA<OnboardingState>().having(
          (s) => s.resource,
          'resource',
          OnboardingResource.speechModel,
        ),
        isA<OnboardingState>()
            .having(
              (s) => s.resource,
              'resource',
              OnboardingResource.speechModel,
            )
            .having((s) => s.receivedBytes, 'receivedBytes', 0),
        isA<OnboardingState>()
            .having(
              (s) => s.resource,
              'resource',
              OnboardingResource.speechModel,
            )
            .having((s) => s.receivedBytes, 'receivedBytes', modelBytes.length),
        isA<OnboardingState>().having(
          (s) => s.resource,
          'resource',
          OnboardingResource.speechModel,
        ),
        isA<OnboardingState>().having(
          (s) => s.phase,
          'phase',
          OnboardingPhase.completed,
        ),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_language'), 'ru');
        expect(prefs.getBool('onboarding_completed'), true);
        expect(prefs.getString('installed_corpus_version'), '1.0+2');
        expect(
          prefs.getString('installed_model_id'),
          fakeSpeechModel.id,
        );
        expect(
          prefs.getString('installed_model_sha256'),
          fakeSpeechModel.sha256,
        );
      },
    );
    blocTest<OnboardingCubit, OnboardingState>(
      'manifest fetch failure emits failed state with the error',
      build: () => buildCubit(fakeClient(manifestStatus: 500)),
      act: (cubit) => cubit.selectLanguage('ru'),
      errors: () => [isA<CorpusManifestException>()],
      expect: () => [
        isA<OnboardingState>().having(
          (s) => s.phase,
          'phase',
          OnboardingPhase.installing,
        ),
        isA<OnboardingState>()
            .having((s) => s.phase, 'phase', OnboardingPhase.failed)
            .having((s) => s.error, 'error', isA<CorpusManifestException>()),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_language'), isNull);
        expect(prefs.getBool('onboarding_completed'), isNull);
      },
    );

    test('resetToLanguageSelection returns to the initial phase', () async {
      final cubit = buildCubit(fakeClient(manifestStatus: 500));
      await cubit.selectLanguage('ru').catchError((_) {});
      cubit.resetToLanguageSelection();
      expect(cubit.state.phase, OnboardingPhase.languageSelection);
      expect(cubit.state.error, isNull);
    });

    test('cancel during install emits failed state', () async {
      final half = corpusBytes.length ~/ 2;
      final resume = Completer<void>();
      final manifestBody = utf8.encode(
        json.encode({
          'ru': {
            'file': 'ru.db.gz',
            'name': 'Русский',
            'size': corpusBytes.length,
            'sha256': corpusSha256,
            'version': '1.0+2',
            'schema_version': 2,
          },
        }),
      );
      final client = _ScriptedClient((request) async {
        if (request.url.path == '/manifest.json') {
          return http.StreamedResponse(
            Stream.value(manifestBody),
            200,
            contentLength: manifestBody.length,
          );
        }
        // Two chunks with a gate between them: the test cancels while the
        // first half sits in the partial file, so the failure cannot race
        // the download.
        return http.StreamedResponse(
          (() async* {
            yield corpusBytes.sublist(0, half);
            await resume.future;
            yield corpusBytes.sublist(half);
          })(),
          200,
          contentLength: corpusBytes.length,
        );
      });
      final corpusDir = _tempDir('corpora');
      final cubit = OnboardingCubit(
        resources: ResourceRepository(
          modelDir: _tempDir('models'),
          corpusDir: corpusDir,
          client: client,
        ),
        manifestClient: CorpusManifestClient(
          client: client,
          manifestUrl: Uri.parse('https://example.test/manifest.json'),
        ),
        speechModel: fakeSpeechModel,
        wakeLock: FakeWakeLock(),
      );
      final pending = cubit.selectLanguage('ru');
      addTearDown(() async {
        if (!resume.isCompleted) resume.complete();
        await pending.catchError((_) {});
        if (!cubit.isClosed) await cubit.close();
      });
      final part = File('${corpusDir.path}/ru.db.gz.part');
      for (var i = 0; i < 500; i++) {
        if (part.existsSync() && part.lengthSync() >= half) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      cubit.cancel();
      resume.complete();
      await expectLater(
        pending,
        throwsA(isA<InstallCanceledException>()),
      );
      expect(cubit.state.phase, OnboardingPhase.failed);
    });

    test('a newer run supersedes the manifest fetch', () async {
      final requested = Completer<void>();
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      final manifestBody = utf8.encode(
        json.encode({
          'ru': {
            'file': 'ru.db.gz',
            'name': 'Русский',
            'size': corpusBytes.length,
            'sha256': corpusSha256,
            'version': '1.0+2',
            'schema_version': 2,
          },
        }),
      );
      final client = MockClient((request) async {
        if (request.url.toString() == manifestUrl.toString()) {
          if (!requested.isCompleted) requested.complete();
          await gate.future;
          return http.Response.bytes(manifestBody, 200);
        }
        if (request.url.toString() == fakeSpeechModel.url) {
          return http.Response.bytes(modelBytes, 200);
        }
        return http.Response.bytes(corpusBytes, 200);
      });
      final cubit = buildCubit(client);
      addTearDown(cubit.close);
      final first = cubit.selectLanguage('ru');
      await requested.future;
      // The second run cancels the first while it still awaits the
      // manifest; the first must fail without touching the new run.
      final second = cubit.selectLanguage('ru');
      gate.complete();
      await expectLater(
        first,
        throwsA(isA<InstallCanceledException>()),
      );
      await second;
      expect(cubit.state.phase, OnboardingPhase.completed);
    });
  });
}

Directory _tempDir(String prefix) {
  final dir = Directory.systemTemp.createTempSync('mneme-onboarding-$prefix');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

/// Scripts HTTP responses without sockets; see the installer tests for why
/// real loopback servers are avoided here.
class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}
