import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';

class App extends StatelessWidget {
  const App({required this.poetryRepository, super.key});

  final PoetryRepository poetryRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: poetryRepository,
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.appTitle)),
              body: Center(child: Text(context.l10n.appTitle)),
            );
          },
        ),
      ),
    );
  }
}
