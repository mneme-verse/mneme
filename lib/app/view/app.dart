import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/db/connection/flutter_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/language_selection/cubit/language_selection_cubit.dart';
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
    this.languageSelectionCubit,
  });

  final PreferencesService? preferencesService;
  final DatabaseInitializer? databaseInitializer;
  final PoetryRepository Function(String language)? repositoryBuilder;
  final LanguageSelectionCubit? languageSelectionCubit;

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
      final isAvailable = await _databaseInitializer.isDatabaseAvailable(
        language,
      );
      if (!mounted) return;
      if (!isAvailable) {
        // Database is missing — fall back to language selection
        await _preferencesService.clearSelectedLanguage();
        if (mounted) {
          setState(() {
            _initializationState = _InitializationState.noLanguageSelected;
          });
        }
        return;
      }

      final repo = _createRepository(language);

      if (mounted) {
        setState(() {
          _poetryRepository = repo;
          _initializationState = _InitializationState.languageSelected;
        });
      }
    } on Object {
      // Handle error appropriately - reset to no language selected
      await _preferencesService.clearSelectedLanguage();
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
    // coverage:ignore-start
    final db = AppDatabase(openConnection(name: language));
    return PoetryRepository(db);
    // coverage:ignore-end
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
          cubit: widget.languageSelectionCubit,
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
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            )
          : null,
    );
  }
}
