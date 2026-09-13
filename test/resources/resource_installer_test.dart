import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/resources/resource_repository.dart';

void main() {
  late HttpServer server;
  late StreamSubscription<HttpRequest> subscription;
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
    await subscription.cancel();
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
      await subscription.cancel();
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
}
