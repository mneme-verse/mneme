import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:mneme/app/view/app.dart';
import 'package:mneme/db/connection/flutter_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
  }
}

/// Wires the concrete runtime dependencies and boots the [App].
///
/// The app opens the corpus database for the language stored in
/// preferences; onboarding installs resources before any language is
/// opened.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  final supportDir = await getApplicationSupportDirectory();
  final databaseOpener = _corpusDatabaseOpener(supportDir);
  final resources = ResourceRepository(
    modelDir: Directory(p.join(supportDir.path, 'models')),
    corpusDir: Directory(p.join(supportDir.path, 'corpora')),
  );
  final manifestClient = CorpusManifestClient();

  runApp(
    App(
      databaseOpener: databaseOpener,
      resources: resources,
      manifestClient: manifestClient,
    ),
  );
}

AppDatabaseOpener _corpusDatabaseOpener(Directory supportDir) {
  return (String language) {
    return AppDatabase(
      openCorpusConnection(
        name: language,
        supportDir: supportDir,
      ),
    );
  };
}
