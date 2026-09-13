import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/app/app.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/resources/corpus_manifest.dart';
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
      final harness = _AppHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(harness.openedLanguages, ['en']);
      expect(find.text('Select Language'), findsNothing);
    });
  });
}

/// Builds the [App] with in-memory databases and no network access.
class _AppHarness {
  final openedLanguages = <String>[];

  Widget build() {
    return App(
      databaseOpener: (language) {
        final db = AppDatabase(NativeDatabase.memory());
        openedLanguages.add(language);
        return db;
      },
      resources: ResourceRepository(
        modelDir: Directory.systemTemp.createTempSync('app-models'),
        corpusDir: Directory.systemTemp.createTempSync('app-corpora'),
      ),
      manifestClient: CorpusManifestClient(
        manifestUrl: Uri.parse('https://example.test/manifest.json'),
      ),
      prefs: SharedPreferences.getInstance(),
    );
  }
}
