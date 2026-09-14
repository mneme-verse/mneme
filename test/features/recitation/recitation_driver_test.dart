import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/recitation/recitation_driver.dart';
import 'package:mneme/recitation/audio/audio_input.dart';
import 'package:mneme/recitation/engine/transcribe_bindings.dart';
import 'package:mneme/recitation/engine/transcribe_engine.dart';
import 'package:mocktail/mocktail.dart';

class MockBindings extends Mock implements TranscribeBindings {}

/// Scripted microphone: the test pushes PCM chunks by hand.
class FakeAudioInput implements AudioInput {
  /// Chunk stream under test control.
  final StreamController<Uint8List> controller = StreamController<Uint8List>();

  /// Permission answer.
  bool permission = true;

  /// Overrides stop, null for the default counting behavior.
  Future<void> Function()? stopHook;

  /// Stop call count.
  int stops = 0;

  /// Whether dispose ran.
  bool disposed = false;

  /// Pushes one PCM16 chunk into the take.
  void pushChunk(Uint8List chunk) => controller.add(chunk);

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<Stream<Uint8List>> startPcm16() async => controller.stream;

  @override
  Future<void> stop() async {
    stops++;
    await stopHook?.call();
  }

  @override
  void dispose() {
    disposed = true;
    unawaited(controller.close());
  }
}

void main() {
  late MockBindings bindings;
  late FakeAudioInput audio;
  late List<String> transcripts;

  setUp(() {
    bindings = MockBindings();
    audio = FakeAudioInput();
    transcripts = [];
    registerFallbackValue(ffi.Pointer<ffi.Void>.fromAddress(0));
    registerFallbackValue(Float32List(0));
    registerFallbackValue((0, ffi.Pointer<ffi.Void>.fromAddress(0)));
    when(
      () => bindings.openSession(any()),
    ).thenReturn((0, ffi.Pointer<ffi.Void>.fromAddress(1)));
    when(() => bindings.streamBegin(any())).thenReturn(0);
    when(() => bindings.streamFeed(any(), any())).thenReturn(0);
    when(() => bindings.streamFinalize(any())).thenReturn(0);
    when(() => bindings.streamText(any())).thenReturn('heard words');
  });

  RecitationDriver openDriver() => RecitationDriver(
    modelPath: 'model.gguf',
    onTranscript: transcripts.add,
    audio: audio,
    openEngine: (path) => TranscribeEngine(path, open: () => bindings),
  );

  /// Little-endian PCM16 bytes for [samples].
  Uint8List pcm16(List<int> samples) {
    final bytes = Uint8List(samples.length * 2);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(i * 2, samples[i], Endian.little);
    }
    return bytes;
  }

  group('RecitationDriver', () {
    test('chunks flow from microphone to transcript', () async {
      final driver = openDriver();
      await driver.start();
      expect(driver.isListening, isTrue);
      audio.pushChunk(pcm16([0, 32767, -32768, 1000]));
      await Future<void>.delayed(Duration.zero);
      expect(transcripts, ['heard words']);
      verify(() => bindings.streamFeed(any(), any())).called(1);
      await driver.stop();
      expect(driver.isListening, isFalse);
      expect(transcripts.last, 'heard words');
      verify(() => bindings.streamFinalize(any())).called(1);
      await driver.dispose();
      expect(audio.disposed, isTrue);
    });

    test('denied permission aborts before opening the engine', () async {
      audio.permission = false;
      final driver = openDriver();
      await expectLater(
        driver.start(),
        throwsA(isA<RecitationPermissionDenied>()),
      );
      expect(driver.isListening, isFalse);
      verifyNever(() => bindings.streamBegin(any()));
      await driver.dispose();
    });

    test('denial renders as a typed exception', () {
      expect(
        const RecitationPermissionDenied().toString(),
        'RecitationPermissionDenied()',
      );
    });

    test('default callback drops transcripts silently', () async {
      final quiet = RecitationDriver(
        modelPath: 'model.gguf',
        audio: audio,
        openEngine: (path) => TranscribeEngine(path, open: () => bindings),
      );
      addTearDown(quiet.dispose);
      await quiet.start();
      audio.pushChunk(pcm16([1, 2, 3, 4]));
      await Future<void>.delayed(Duration.zero);
      await quiet.stop();
    });

    test('stream errors end the chunk flow without transcripts', () async {
      final driver = openDriver();
      await driver.start();
      audio.controller.addError(Exception('mic lost'));
      await Future<void>.delayed(Duration.zero);
      expect(transcripts, isEmpty);
      await driver.stop();
    });

    test('feed failure tears the take down and reports once', () async {
      final errors = <Object>[];
      final driver = RecitationDriver(
        modelPath: 'model.gguf',
        onTranscript: transcripts.add,
        onError: errors.add,
        audio: audio,
        openEngine: (path) => TranscribeEngine(path, open: () => bindings),
      );
      addTearDown(driver.dispose);
      when(
        () => bindings.streamFeed(any(), any()),
      ).thenThrow(const TranscribeEngineException('overrun fault'));
      await driver.start();
      audio
        ..pushChunk(pcm16([1, 2, 3, 4]))
        ..pushChunk(pcm16([5, 6, 7, 8]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // The take is over: one report, no transcripts, session released,
      // recorder stopped, and no finalize on the broken engine.
      expect(driver.isListening, isFalse);
      expect(errors.single, isA<TranscribeEngineException>());
      expect(transcripts, isEmpty);
      expect(audio.stops, 1);
      verifyNever(() => bindings.streamFinalize(any()));
      verify(() => bindings.freeSession(any())).called(1);
    });

    test('microphone failure tears the take down and reports', () async {
      final errors = <Object>[];
      final driver = RecitationDriver(
        modelPath: 'model.gguf',
        onTranscript: transcripts.add,
        onError: errors.add,
        audio: audio,
        openEngine: (path) => TranscribeEngine(path, open: () => bindings),
      );
      addTearDown(driver.dispose);
      await driver.start();
      audio.controller.addError(Exception('mic lost'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(driver.isListening, isFalse);
      expect(errors.single, isA<Exception>());
      expect(transcripts, isEmpty);
      expect(audio.stops, 1);
      verifyNever(() => bindings.streamFinalize(any()));
      verify(() => bindings.freeSession(any())).called(1);
    });

    test('failing recorder stop still releases the session', () async {
      audio.stopHook = () => throw StateError('stop stuck');
      final driver = openDriver();
      addTearDown(driver.dispose);
      await driver.start();
      await expectLater(driver.stop(), throwsStateError);
      expect(driver.isListening, isFalse);
      // The final transcript still delivers before the session frees.
      expect(transcripts, ['heard words']);
      verify(() => bindings.streamFinalize(any())).called(1);
      verify(() => bindings.freeSession(any())).called(1);
    });

    test('stop while idle is a no-op', () async {
      final driver = openDriver();
      await driver.stop();
      verifyNever(() => bindings.streamFinalize(any()));
      await driver.dispose();
    });

    test('failed begin releases the engine', () async {
      when(() => bindings.streamBegin(any())).thenReturn(8);
      when(() => bindings.statusString(any())).thenReturn('backend');
      final driver = openDriver();
      await expectLater(
        driver.start(),
        throwsA(isA<TranscribeEngineException>()),
      );
      verify(() => bindings.freeSession(any())).called(1);
      await driver.dispose();
    });
  });
}
