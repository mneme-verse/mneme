import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/onboarding/view/onboarding_page.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/resources/corpus_manifest.dart';
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
    super.key,
  });

  final AppDatabaseOpener databaseOpener;
  final ResourceRepository resources;
  final CorpusManifestClient manifestClient;

  /// Injectable preferences; defaults to [SharedPreferences.getInstance].
  final Future<SharedPreferences>? prefs;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _loading = 'loading';
  static const _onboarding = 'onboarding';

  String _mode = _loading;
  AppDatabase? _database;

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

    if (completed && language != null) {
      _openLanguage(language);
    } else {
      setState(() => _mode = _onboarding);
    }
  }

  void _openLanguage(String language) {
    setState(() {
      unawaited(_database?.close() ?? Future<void>.value());
      _database = widget.databaseOpener(language);
      _mode = 'home';
    });
  }

  void _onOnboardingCompleted(String language) {
    _openLanguage(language);
  }

  PoetryRepository get _poetryRepository => PoetryRepository(_database!);

  @override
  void dispose() {
    unawaited(_database?.close() ?? Future<void>.value());
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
          onCompleted: _onOnboardingCompleted,
        ),
        _ => RepositoryProvider.value(
          value: _poetryRepository,
          child: const HomePage(),
        ),
      },
    );
  }
}
