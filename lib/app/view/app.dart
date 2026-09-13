import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/db/connection/study_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/study_database.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/onboarding/view/onboarding_page.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the corpus database for [language]. The app owns the returned
/// database and closes it when the language changes.
typedef AppDatabaseOpener = AppDatabase Function(String language);

/// Root widget. Owns the open corpus database for the selected language and
/// the repositories derived from it.
///
/// Onboarding installs the corpus pack and speech model for the chosen
/// language; only after a successful install does the app open that
/// language's database.
class App extends StatefulWidget {
  const App({
    required this.databaseOpener,
    required this.resources,
    required this.manifestClient,
    this.prefs,
    this.speechModel,
    super.key,
  });

  final AppDatabaseOpener databaseOpener;
  final ResourceRepository resources;
  final CorpusManifestClient manifestClient;

  /// Injectable preferences; defaults to [SharedPreferences.getInstance].
  final Future<SharedPreferences>? prefs;

  /// Speech model installed during onboarding; defaults to the standard
  /// locked model. Flavors and tests can select another locked model
  /// without changing the install flow.
  final LockedResource? speechModel;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _loading = 'loading';
  static const _onboarding = 'onboarding';

  String _mode = _loading;
  AppDatabase? _database;
  StudyDatabase? _studyDatabase;
  late String _language;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreState());
  }

  Future<SharedPreferences> _resolvePrefs() async =>
      widget.prefs ?? SharedPreferences.getInstance();

  Future<void> _restoreState() async {
    final prefs = await _resolvePrefs();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    final language = prefs.getString('selected_language');
    if (!mounted) return;

    // Preferences alone do not prove the resources survived, and versions
    // move on: a removed pack/model or a corpus bump/model change sends
    // the user back through onboarding, which reinstalls. Install verified
    // the hashes; presence plus matching versions is a sufficient offline
    // launch gate.
    final model =
        widget.speechModel ??
        lockedSpeechModels.firstWhere((m) => m.id == defaultSpeechModelId);
    final intact =
        completed &&
        language != null &&
        widget.resources.isModelPresent(model.id) &&
        widget.resources.isCorpusPackPresent('$language.db.gz') &&
        prefs.getString('installed_corpus_version') == corpusDataVersion &&
        prefs.getString('installed_model_id') == model.id &&
        prefs.getString('installed_model_sha256') == model.sha256;
    if (!intact) {
      await prefs.setBool('onboarding_completed', false);
      if (!mounted) return;
      setState(() => _mode = _onboarding);
      return;
    }
    _openLanguage(language);
  }

  void _openLanguage(String language) {
    setState(() {
      unawaited(_database?.close() ?? Future<void>.value());
      _database = widget.databaseOpener(language);
      _studyDatabase ??= StudyDatabase(openStudyConnection());
      _language = language;
      _mode = 'home';
    });
  }

  void _onOnboardingCompleted(String language) {
    _openLanguage(language);
  }

  PoetryRepository get _poetryRepository => PoetryRepository(_database!);
  StudyRepository get _studyRepository => StudyRepository(_studyDatabase!);

  @override
  void dispose() {
    unawaited(_database?.close() ?? Future<void>.value());
    unawaited(_studyDatabase?.close() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: switch (_mode) {
        _loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        _onboarding => OnboardingPage(
          resources: widget.resources,
          manifestClient: widget.manifestClient,
          speechModel: widget.speechModel,
          onCompleted: _onOnboardingCompleted,
        ),
        _ => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: _poetryRepository),
            RepositoryProvider.value(value: _studyRepository),
          ],
          child: HomePage(language: _language),
        ),
      },
    );
  }
}
