import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/features/recitation/recitation_driver.dart';
import 'package:mneme/features/recitation/view/recitation_page.dart';
import 'package:mneme/l10n/gen/app_localizations.dart';
import 'package:mneme/recitation/audio/audio_input.dart';
import 'package:mneme/recitation/engine/transcribe_bindings.dart';
import 'package:mneme/recitation/engine/transcribe_engine.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBindings extends Mock implements TranscribeBindings {}

/// Scripted microphone for page takes.
class FakeAudioInput implements AudioInput {
  final StreamController<Uint8List> controller = StreamController<Uint8List>();

  /// Permission answer.
  bool permission = true;

  /// Overrides start, null for the default stream behavior.
  Future<Stream<Uint8List>> Function()? startHook;

  /// Overrides stop, null for success.
  Future<void> Function()? stopHook;

  /// Pushes one PCM16 chunk into the take.
  void pushChunk(Uint8List chunk) => controller.add(chunk);

  /// Fails the take's stream with [error].
  void pushError(Object error) => controller.addError(error);

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<Stream<Uint8List>> startPcm16() async =>
      startHook != null ? startHook!() : controller.stream;

  @override
  Future<void> stop() async {
    await stopHook?.call();
  }

  @override
  void dispose() {
    unawaited(controller.close());
  }
}

void main() {
  late MockBindings bindings;
  late FakeAudioInput audio;
  late PoetryRepository poetry;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDatabase(db, language: 'en');
    await db.customStatement(
      'INSERT INTO poem_passages '
      '(poem_id, start_token, end_token, search_text) '
      "VALUES (1, 0, 12, 'once upon midnight dreary while')",
    );
    await db.customStatement(
      'INSERT INTO passages_fts (rowid, search_text) '
      'SELECT id, search_text FROM poem_passages',
    );
    poetry = PoetryRepository(db);

    bindings = MockBindings();
    audio = FakeAudioInput();
    addTearDown(audio.dispose);
    registerFallbackValue(Float32List(0));
    registerFallbackValue((0, ffi.Pointer<ffi.Void>.fromAddress(0)));
    registerFallbackValue(ffi.Pointer<ffi.Void>.fromAddress(0));
    when(
      () => bindings.openSession(any()),
    ).thenReturn((0, ffi.Pointer<ffi.Void>.fromAddress(1)));
    when(() => bindings.streamBegin(any())).thenReturn(0);
    when(() => bindings.streamFeed(any(), any())).thenReturn(0);
    when(() => bindings.streamFinalize(any())).thenReturn(0);
    when(
      () => bindings.streamText(any()),
    ).thenReturn('Once upon a midnight dreary');
  });

  RecitationDriver openDriver() => RecitationDriver(
    modelPath: 'model.gguf',
    onTranscript: (_) {},
    audio: audio,
    openEngine: (path) => TranscribeEngine(path, open: () => bindings),
  );

  Future<void> pumpPage(WidgetTester tester, RecitationDriver driver) {
    return tester.pumpWidget(
      RepositoryProvider.value(
        value: poetry,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecitationPage(driver: driver),
        ),
      ),
    );
  }

  /// Little-endian PCM16 bytes for [samples].
  Uint8List pcm16(int samples) {
    final bytes = Uint8List(samples * 2);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < samples; i++) {
      data.setInt16(i * 2, 1000, Endian.little);
    }
    return bytes;
  }

  group('RecitationPage', () {
    testWidgets('idle page offers the microphone', (tester) async {
      await pumpPage(tester, openDriver());
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Recite'), findsWidgets);
    });

    testWidgets('denied permission renders instead of crashing', (
      tester,
    ) async {
      audio.permission = false;
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      expect(find.text('Microphone permission denied'), findsOneWidget);
    });

    testWidgets('engine failure renders instead of crashing', (
      tester,
    ) async {
      when(
        () => bindings.openSession(any()),
      ).thenReturn((8, ffi.nullptr));
      when(() => bindings.statusString(any())).thenReturn('backend');
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      expect(find.textContaining('backend'), findsOneWidget);
    });

    testWidgets('partial transcript leaves pending words', (tester) async {
      final semantics = tester.ensureSemantics();
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      when(
        () => bindings.streamText(any()),
      ).thenReturn('Once upon a midnight');
      audio.pushChunk(pcm16(1600));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tally-pending')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a wrong word renders the wrong tally', (tester) async {
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      when(
        () => bindings.streamText(any()),
      ).thenReturn('Once upon a banana');
      audio.pushChunk(pcm16(1600));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tally-wrong')), findsOneWidget);
    });

    testWidgets('a take locates the poem and reports feedback', (
      tester,
    ) async {
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      expect(find.text('Listening…'), findsOneWidget);

      audio.pushChunk(pcm16(1600));
      await tester.pumpAndSettle();
      expect(find.textContaining('midnight dreary'), findsOneWidget);
      expect(find.textContaining('The Raven'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop));
      // The stop chain drains on real event-loop turns (subscription
      // cancel, recorder stop) that settle does not await.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('unexpected start failure renders and recovers', (
      tester,
    ) async {
      audio.startHook = () => throw StateError('mic gone');
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      // A platform fault renders like the known cases, and the page is
      // idle enough to retry.
      expect(find.textContaining('mic gone'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      audio.startHook = null;
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      expect(find.text('Listening…'), findsOneWidget);
    });

    testWidgets('mid-take engine failure surfaces and ends the take', (
      tester,
    ) async {
      when(
        () => bindings.streamFeed(any(), any()),
      ).thenThrow(const TranscribeEngineException('overrun fault'));
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      audio.pushChunk(pcm16(1600));
      // The teardown chain (subscription cancel, recorder stop) drains
      // on real event-loop turns that settle does not await.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('overrun fault'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(driver.isListening, isFalse);
    });

    testWidgets('microphone stream error surfaces', (tester) async {
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      expect(find.text('Listening…'), findsOneWidget);
      audio.pushError(StateError('mic died'));
      // Same real-turn drain as above: the error teardown cancels the
      // subscription before reporting.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('mic died'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('stop failure renders and keeps the attempt', (
      tester,
    ) async {
      audio.stopHook = () => throw StateError('stop stuck');
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      audio.pushChunk(pcm16(1600));
      await tester.pumpAndSettle();
      expect(find.textContaining('midnight dreary'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.stop));
      // The failing stop still drains subscription cancel first.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('stop stuck'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      // The attempt stays visible even though stopping failed.
      expect(find.textContaining('midnight dreary'), findsOneWidget);
    });

    testWidgets('silent engine keeps listening without crashing', (
      tester,
    ) async {
      when(() => bindings.streamText(any())).thenReturn('');
      final driver = openDriver();
      addTearDown(driver.dispose);
      await pumpPage(tester, driver);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      audio.pushChunk(pcm16(1600));
      await tester.pumpAndSettle();
      // No speech recognized is not an error: the take stays open and
      // no failure renders.
      expect(find.text('Listening…'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      await tester.tap(find.byIcon(Icons.stop));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}
