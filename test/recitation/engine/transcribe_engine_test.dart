import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/recitation/engine/transcribe_bindings.dart';
import 'package:mneme/recitation/engine/transcribe_engine.dart';
import 'package:mocktail/mocktail.dart';

class MockBindings extends Mock implements TranscribeBindings {}

void main() {
  late MockBindings bindings;

  setUp(() {
    bindings = MockBindings();
    registerFallbackValue(ffi.Pointer<ffi.Void>.fromAddress(0));
    registerFallbackValue(Float32List(0));
    registerFallbackValue((0, ffi.Pointer<ffi.Void>.fromAddress(0)));
    when(
      () => bindings.openSession(any()),
    ).thenReturn((0, ffi.Pointer<ffi.Void>.fromAddress(1)));
    when(() => bindings.streamBegin(any())).thenReturn(0);
    when(
      () => bindings.streamFeed(any(), any()),
    ).thenReturn(0);
    when(() => bindings.streamFinalize(any())).thenReturn(0);
    when(() => bindings.streamText(any())).thenReturn('hello world');
  });

  TranscribeEngine openEngine() =>
      TranscribeEngine('model.gguf', open: () => bindings);

  group('TranscribeEngine', () {
    test('missing library becomes unavailability, not a crash', () {
      expect(
        () => TranscribeEngine(
          'model.gguf',
          open: () => throw ArgumentError('libtranscribe.so: not found'),
        ),
        throwsA(isA<TranscribeEngineUnavailable>()),
      );
    });

    test('failed open throws with the model path', () {
      when(
        () => bindings.openSession(any()),
      ).thenReturn((3, ffi.nullptr));
      when(() => bindings.statusString(any())).thenReturn('not found');
      expect(
        openEngine,
        throwsA(
          isA<TranscribeEngineException>().having(
            (e) => e.message,
            'message',
            contains('model.gguf'),
          ),
        ),
      );
    });

    test('begin, feed and text drive a stream', () {
      final engine = openEngine()
        ..begin()
        ..feed(Float32List(160));
      expect(engine.text(), 'hello world');
      verify(() => bindings.streamBegin(any())).called(1);
      verify(() => bindings.streamFeed(any(), any())).called(1);
      engine.dispose();
    });

    test('empty feed never reaches native code', () {
      final engine = openEngine()
        ..begin()
        ..feed(Float32List(0));
      verifyNever(() => bindings.streamFeed(any(), any()));
      engine.dispose();
    });

    test('text is empty before begin', () {
      final engine = openEngine();
      expect(engine.text(), isEmpty);
      verifyNever(() => bindings.streamText(any()));
      engine.dispose();
    });

    test('finalize flushes and ends the stream', () {
      final engine = openEngine()..begin();
      expect(engine.finalize(), 'hello world');
      verify(() => bindings.streamFinalize(any())).called(1);
      expect(engine.text(), isEmpty);
      engine.dispose();
    });

    test('failed begin throws with status text', () {
      when(() => bindings.streamBegin(any())).thenReturn(8);
      when(() => bindings.statusString(any())).thenReturn('backend');
      final engine = openEngine();
      expect(
        engine.begin,
        throwsA(
          isA<TranscribeEngineException>().having(
            (e) => e.message,
            'message',
            contains('backend'),
          ),
        ),
      );
      engine.dispose();
    });

    test('use after dispose throws', () {
      final engine = openEngine()..dispose();
      expect(engine.begin, throwsA(isA<TranscribeEngineException>()));
      expect(engine.text, throwsA(isA<TranscribeEngineException>()));
    });

    test('dispose is idempotent', () {
      final engine = openEngine()..dispose();
      expect(engine.dispose, returnsNormally);
      verify(() => bindings.freeSession(any())).called(1);
    });
  });
}
