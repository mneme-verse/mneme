import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/onboarding/view/onboarding_page.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  const App({required this.poetryRepository, super.key});

  final PoetryRepository poetryRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures -- fire and forget
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      // Show loading screen / splash while checking prefs
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return RepositoryProvider.value(
      value: widget.poetryRepository,
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _onboardingCompleted! ? const HomePage() : const OnboardingPage(),
      ),
    );
  }
}
