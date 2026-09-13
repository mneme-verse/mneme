import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mneme/app/app.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App', () {
    testWidgets('renders onboarding when nothing is installed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final harness = _AppHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(
        harness.openedLanguages,
        isEmpty,
        reason: 'no database may open before onboarding completes',
      );
    });

    testWidgets('opens the stored language database on relaunch', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'selected_language': 'en',
      });
      final harness = _AppHarness()..installGateFiles(language: 'en');

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(harness.openedLanguages, ['en']);
      expect(find.text('Select Language'), findsNothing);
    });

    testWidgets('returns to onboarding when resources are missing', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'selected_language': 'en',
      });
      final harness = _AppHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(
        harness.openedLanguages,
        isEmpty,
        reason: 'missing resources must not open a database',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isFalse);
    });

    testWidgets('installs resources and opens the database on completion', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final packBytes = Uint8List.fromList(
        List<int>.generate(512, (i) => i % 251),
      );
      final modelBytes = Uint8List.fromList(
        List<int>.generate(256, (i) => 255 - (i % 251)),
      );
      final model = LockedResource(
        id: 'fake-model.gguf',
        url: 'https://example.test/fake-model.gguf',
        sha256: sha256.convert(modelBytes).toString(),
        sizeBytes: modelBytes.length,
      );
      final client = MockClient((request) async {
        final url = request.url.toString();
        if (url == 'https://example.test/manifest.json') {
          return http.Response(
            jsonEncode({
              'en': {
                'file': 'en.db.zst',
                'sha256': sha256.convert(packBytes).toString(),
                'size': packBytes.length,
                'version': '1.0+2',
                'schema_version': 2,
              },
            }),
            200,
          );
        }
        if (url == 'https://example.test/en.db.zst') {
          return http.Response.bytes(packBytes, 200);
        }
        if (url == model.url) {
          return http.Response.bytes(modelBytes, 200);
        }
        return http.Response('not found', 404);
      });
      final harness = _AppHarness();

      await tester.pumpWidget(
        harness.build(speechModel: model, client: client),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      // Installs use real filesystem I/O, which needs real time between
      // frames inside widget tests.
      for (var i = 0; i < 30 && harness.openedLanguages.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(harness.openedLanguages, ['en']);
      expect(find.text('Select Language'), findsNothing);
    });
  });
}

/// Builds the [App] with in-memory databases and no network access.
class _AppHarness {
  final openedLanguages = <String>[];
  late final Directory modelDir = Directory.systemTemp.createTempSync(
    'app-models',
  );
  late final Directory corpusDir = Directory.systemTemp.createTempSync(
    'app-corpora',
  );

  Widget build({
    LockedResource? speechModel,
    http.Client? client,
    String manifestUrl = 'https://example.test/manifest.json',
  }) {
    return App(
      databaseOpener: (language) {
        final db = AppDatabase(NativeDatabase.memory());
        openedLanguages.add(language);
        return db;
      },
      resources: ResourceRepository(
        modelDir: modelDir,
        corpusDir: corpusDir,
        client: client,
      ),
      manifestClient: CorpusManifestClient(
        client: client,
        manifestUrl: Uri.parse(manifestUrl),
      ),
      speechModel: speechModel,
      prefs: SharedPreferences.getInstance(),
    );
  }

  /// Writes placeholder gate files so relaunch treats resources as present.
  /// Installs still download: placeholders never match a real hash.
  void installGateFiles({required String language, String? modelId}) {
    File(
      '${modelDir.path}/${modelId ?? defaultSpeechModelId}',
    ).writeAsStringSync('gate');
    File('${corpusDir.path}/$language.db.zst').writeAsStringSync('gate');
  }
}
