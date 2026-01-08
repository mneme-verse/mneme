import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/db/connection/flutter_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/language_selection/view/language_selection_page.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mneme/services/preferences_service.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    this.preferencesService,
    this.databaseInitializer,
    this.repositoryBuilder,
  });

  final PreferencesService? preferencesService;
  final DatabaseInitializer? databaseInitializer;
  final PoetryRepository Function(String language)? repositoryBuilder;

  @override
  State<App> createState() => _AppState();
}

enum _InitializationState {
  loading,
  languageSelected,
  noLanguageSelected,
}

class _AppState extends State<App> {
  _InitializationState _initializationState = _InitializationState.loading;
  late PoetryRepository _poetryRepository;
  late final PreferencesService _preferencesService;
  late final DatabaseInitializer _databaseInitializer;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _databaseInitializer = widget.databaseInitializer ?? DatabaseInitializer();
    // ignore: discarded_futures -- initApp is fire-and-forget
    _initApp();
  }

  @override
  void dispose() {
    if (_initializationState == _InitializationState.languageSelected) {
      unawaited(_poetryRepository.close());
    }
    super.dispose();
  }

  Future<void> _initApp() async {
    await _preferencesService.init();
    final selectedLanguage = _preferencesService.getSelectedLanguage();

    if (selectedLanguage != null) {
      await _initializeForLanguage(selectedLanguage);
    } else {
      if (mounted) {
        setState(() {
          _initializationState = _InitializationState.noLanguageSelected;
        });
      }
    }
  }

  Future<void> _initializeForLanguage(String language) async {
    if (!mounted) return;

    // Ensure loading state if called from language selection
    setState(() {
      _initializationState = _InitializationState.loading;
    });

    try {
      await _databaseInitializer.initializeDatabase(language: language);
      final repo = _createRepository(language);

      if (mounted) {
        setState(() {
          _poetryRepository = repo;
          _initializationState = _InitializationState.languageSelected;
        });
      }
    } on Object {
      // Handle error appropriately - maybe reset to no language selected
      if (mounted) {
        setState(() {
          _initializationState = _InitializationState.noLanguageSelected;
        });
      }
    }
  }

  PoetryRepository _createRepository(String language) {
    if (widget.repositoryBuilder != null) {
      return widget.repositoryBuilder!(language);
    }
    final db = AppDatabase(openConnection(name: language));
    return PoetryRepository(db);
  }

  Future<void> _handleSettingsPressed() async {
    if (!mounted) return;

    await _preferencesService.clearSelectedLanguage();
    await _poetryRepository.close();

    if (mounted) {
      setState(() {
        _initializationState = _InitializationState.noLanguageSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: switch (_initializationState) {
        _InitializationState.loading => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        _InitializationState.noLanguageSelected => LanguageSelectionPage(
          onSelectionComplete: () async {
            final language = _preferencesService.getSelectedLanguage();
            if (language != null) {
              await _initializeForLanguage(language);
            }
          },
        ),
        _InitializationState.languageSelected => RepositoryProvider.value(
          value: _poetryRepository,
          child: HomePage(
            onSettingsPressed: _handleSettingsPressed,
          ),
        ),
      },
      theme: _initializationState == _InitializationState.languageSelected
          ? ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              useMaterial3: true,
            )
          : null,
    );
  }
}
