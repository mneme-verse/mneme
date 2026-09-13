import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mneme/resources/resource_installer.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';

void main() {
  late HttpServer server;
  StreamSubscription<HttpRequest>? subscription;
  late Directory tempDir;
  late ResourceRepository repository;

  final payload = Uint8List.fromList(
    List<int>.generate(256 * 1024, (i) => i % 251),
  );

  String shaOf(List<int> bytes) => sha256.convert(bytes).toString();

  void serve({
    required List<int> bytes,
    int delayMs = 0,
    int status = 200,
  }) {
    subscription = server.listen((request) async {
      if (delayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
      request.response.statusCode = status;
      request.response.add(bytes);
      await request.response.close();
    });
  }

  String serverUrl(String path) => 'http://127.0.0.1:${server.port}/$path';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mneme-resources-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = ResourceRepository(
      modelDir: Directory('${tempDir.path}/models'),
      corpusDir: Directory('${tempDir.path}/corpora'),
    );
  });

  tearDown(() async {
    await repository.dispose();
    await subscription?.cancel();
    subscription = null;
    await server.close(force: true);
    await tempDir.delete(recursive: true);
  });

  test('install succeeds and atomically renames the verified file', () async {
    serve(bytes: payload);
    final installed = await repository.installCorpusPack(
      'fixture.bin',
      serverUrl('fixture.bin'),
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
  });

  test('mismatched sha256 fails and leaves no destination file', () async {
    serve(bytes: payload);
    final wrong = Uint8List.fromList(payload);
    wrong[0] = (wrong[0] + 1) % 256;

    await expectLater(
      repository.installCorpusPack(
        'bad.bin',
        serverUrl('bad.bin'),
        shaOf(wrong),
      ),
      throwsA(isA<Exception>()),
    );

    final state = repository.stateOf('bad.bin');
    expect(state.phase, ResourcePhase.failed);
    expect(state.error, isNotNull);
    final dir = Directory('${tempDir.path}/corpora');
    expect(
      dir.listSync(),
      isEmpty,
      reason: 'failed installs must clean up partial files',
    );
  });

  test(
    'cancellation removes the partial download and reports notInstalled',
    () async {
      serve(bytes: payload, delayMs: 5000);

      final future = repository.installCorpusPack(
        'slow.bin',
        serverUrl('slow.bin'),
        shaOf(payload),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      repository.cancel('slow.bin');

      await expectLater(future, throwsA(isA<Exception>()));
      expect(
        repository.stateOf('slow.bin').phase,
        ResourcePhase.notInstalled,
      );
      expect(
        Directory('${tempDir.path}/corpora').listSync(),
        isEmpty,
      );
    },
  );

  test('non-200 responses fail without creating files', () async {
    serve(bytes: [], status: 404);

    await expectLater(
      repository.installCorpusPack(
        'missing.bin',
        serverUrl('missing.bin'),
        shaOf(payload),
      ),
      throwsA(isA<Exception>()),
    );
    expect(repository.stateOf('missing.bin').phase, ResourcePhase.failed);
  });

  test(
    'already-installed resource short-circuits without redownload',
    () async {
      serve(bytes: payload);
      final first = await repository.installCorpusPack(
        'once.bin',
        serverUrl('once.bin'),
        shaOf(payload),
      );

      final url = serverUrl('once.bin');

      // Any further download attempt now fails at the socket level.
      await subscription?.cancel();
      await server.close(force: true);

      final second = await repository.installCorpusPack(
        'once.bin',
        url,
        shaOf(payload),
      );
      expect(second.path, first.path);
      expect(first.readAsBytesSync(), payload);
    },
  );

  test('states stream exposes download progress', () async {
    final received = <ResourceState>[];
    final sub = repository.states.listen(received.add);

    serve(bytes: payload);
    await repository.installCorpusPack(
      'progress.bin',
      serverUrl('progress.bin'),
      shaOf(payload),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received.first.phase, ResourcePhase.downloading);
    expect(
      received.any((s) => s.phase == ResourcePhase.installed),
      isTrue,
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
    serve(bytes: payload);
    for (final id in ['../evil.bin', r'..\evil.bin', '', '.', '..']) {
      await expectLater(
        repository.installCorpusPack(id, serverUrl('x'), shaOf(payload)),
        throwsArgumentError,
        reason: 'id "$id" must be rejected before any download',
      );
    }
    expect(
      File('${tempDir.path}/evil.bin').existsSync(),
      isFalse,
      reason: 'rejected ids must not create files outside the corpus dir',
    );
  });

  test('reinstall replaces the file and removes the backup', () async {
    serve(bytes: payload);
    final first = await repository.installCorpusPack(
      'fixture.bin',
      serverUrl('fixture.bin'),
      shaOf(payload),
    );
    final replacement = Uint8List.fromList(
      List<int>.generate(1024, (i) => 255 - (i % 251)),
    );
    // The shared server is single-subscription, so the replacement bytes
    // come from a second local server.
    final replacementServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    try {
      replacementServer.listen((request) async {
        request.response.add(replacement);
        await request.response.close();
      });
      final second = await repository.installCorpusPack(
        'fixture.bin',
        'http://127.0.0.1:${replacementServer.port}/fixture.bin',
        shaOf(replacement),
      );
      expect(second.path, first.path);
      expect(second.readAsBytesSync(), replacement);
      expect(File('${second.path}.bak').existsSync(), isFalse);
      expect(File('${second.path}.part').existsSync(), isFalse);
    } finally {
      await replacementServer.close(force: true);
    }
  });
  test('exceptions describe the failed resource', () {
    expect(
      const InstallCanceledException('ru.db.zst').toString(),
      contains('ru.db.zst'),
    );
    expect(
      const HashMismatchException('ru.db.zst', 'abc').toString(),
      contains('ru.db.zst'),
    );
  });

  test('size mismatch fails without installing', () async {
    serve(bytes: payload);
    await expectLater(
      repository.installCorpusPack(
        'fixture.bin',
        serverUrl('fixture.bin'),
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
    serve(bytes: payload);
    await repository.installCorpusPack(
      'fixture.bin',
      serverUrl('fixture.bin'),
      shaOf(payload),
    );
    expect(backup.existsSync(), isFalse);
  });

  test('uninstall removes destination and leftovers', () async {
    final dir = Directory('${tempDir.path}/solo')..createSync();
    final installer = ResourceInstaller(
      client: http.Client(),
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
    );
    serve(bytes: payload, delayMs: 500);
    final pending = local.installCorpusPack(
      'slow.bin',
      serverUrl('slow.bin'),
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
    serve(bytes: payload);
    final model = LockedResource(
      id: 'fake-model.gguf',
      url: serverUrl('fake-model.gguf'),
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
    var requests = 0;
    final counting = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => counting.close(force: true));
    counting.listen((request) async {
      requests++;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      request.response.add(payload);
      await request.response.close();
    });
    final url = 'http://127.0.0.1:${counting.port}/shared.bin';
    final files = await Future.wait([
      repository.installCorpusPack('shared.bin', url, shaOf(payload)),
      repository.installCorpusPack('shared.bin', url, shaOf(payload)),
    ]);

    expect(files[0].path, files[1].path);
    expect(requests, 1);
  });

  test('cancel from the final progress callback still wins', () async {
    serve(bytes: payload);
    final dir = Directory('${tempDir.path}/late')..createSync();
    final installer = ResourceInstaller(
      client: http.Client(),
      destinationDir: dir,
    );
    final token = InstallCancelToken();
    await expectLater(
      installer.install(
        'late.bin',
        Uri.parse(serverUrl('late.bin')),
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
}
