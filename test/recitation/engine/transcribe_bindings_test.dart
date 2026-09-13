import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/recitation/engine/transcribe_bindings.dart';

/// Exercises the FFI bindings against a tiny compiled stub of the C API.
///
/// The stub validates signatures and struct layout through real foreign
/// calls. It needs a C toolchain; the group skips where none exists
/// (bare Dart SDK containers), while CI builders always qualify.
void main() {
  group('TranscribeBindings over a stub library', () {
    late TranscribeBindings bindings;
    late Directory workDir;

    setUpAll(() async {
      workDir = Directory.systemTemp.createTempSync('stub-transcribe-');
      addTearDown(() => workDir.deleteSync(recursive: true));
      final so = '${workDir.path}/libstub_transcribe.so';
      final compile = await Process.run('cc', [
        '-shared',
        '-fPIC',
        '-O1',
        '-o',
        so,
        'test/recitation/engine/stub_transcribe.c',
      ]);
      if (compile.exitCode != 0) {
        markTestSkipped('no C toolchain: ${compile.stderr}');
      }
      bindings = TranscribeBindings.fromLibrary(
        ffi.DynamicLibrary.open(so),
      );
    });

    test('reports the stub version and status strings', () {
      expect(bindings.version(), 'test-stub');
      expect(bindings.statusString(0), 'ok');
      expect(bindings.statusString(8), 'error');
    });

    test('missing model fails with file-not-found', () {
      final (status, session) = bindings.openSession('missing.gguf');
      expect(status, 3);
      expect(session, ffi.nullptr);
      bindings.freeSession(session);
    });

    test('a streaming round trip returns the stub transcript', () {
      final (status, session) = bindings.openSession('model.gguf');
      expect(status, TranscribeBindings.statusOk);
      expect(session, isNot(ffi.nullptr));
      addTearDown(() => bindings.freeSession(session));

      expect(bindings.streamBegin(session), TranscribeBindings.statusOk);
      final revision = bindings.streamRevision(session);
      expect(revision, greaterThan(0));

      final fed = bindings.streamFeed(session, Float32List(160));
      expect(fed, TranscribeBindings.statusOk);
      expect(bindings.streamRevision(session), greaterThan(revision));
      expect(bindings.streamText(session), 'stub transcript');

      expect(bindings.streamFinalize(session), TranscribeBindings.statusOk);
      expect(bindings.streamText(session), 'stub transcript');

      bindings.streamReset(session);
      expect(bindings.streamText(session), 'stub transcript');
    });

    test('default constructor surfaces a missing library', () {
      expect(TranscribeBindings.new, throwsArgumentError);
    });

    test('null session text is empty', () {
      expect(bindings.streamText(ffi.nullptr), isEmpty);
    });
  });
}
