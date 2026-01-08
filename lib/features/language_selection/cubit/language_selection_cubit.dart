import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mneme/features/language_selection/models/language_model.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mneme/services/manifest_service.dart';
import 'package:mneme/services/preferences_service.dart';

part 'language_selection_state.dart';

/// Cubit for managing language selection state.
class LanguageSelectionCubit extends Cubit<LanguageSelectionState> {
  LanguageSelectionCubit({
    ManifestService? manifestService,
    DatabaseInitializer? databaseInitializer,
    PreferencesService? preferencesService,
  }) : _manifestService = manifestService ?? ManifestService(),
       _databaseInitializer = databaseInitializer ?? DatabaseInitializer(),
       _preferencesService = preferencesService ?? PreferencesService(),
       super(const LanguageSelectionState());

  final ManifestService _manifestService;
  final DatabaseInitializer _databaseInitializer;
  final PreferencesService _preferencesService;

  /// Load available languages from manifest.
  Future<void> loadLanguages() async {
    emit(state.copyWith(status: LanguageSelectionStatus.loading));

    try {
      final manifest = await _manifestService.fetchManifest();

      final languages = manifest.entries.map((
        entry,
      ) {
        final code = entry.key;
        final data = entry.value as Map<String, dynamic>;
        // Name is now in the manifest data
        final name = data['name'] as String? ?? code.toUpperCase();
        return LanguageModel.fromJson(code, data, name);
      }).toList()..sort((a, b) => a.name.compareTo(b.name));

      emit(
        state.copyWith(
          status: LanguageSelectionStatus.loaded,
          availableLanguages: languages,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: LanguageSelectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Select and download a language.
  Future<void> selectLanguage(LanguageModel language) async {
    emit(
      state.copyWith(
        status: LanguageSelectionStatus.downloading,
        selectedLanguage: language,
      ),
    );

    try {
      await _databaseInitializer.initializeDatabase(
        language: language.code,
        onProgress: (received, total) {
          final progress = received / total;
          emit(
            state.copyWith(
              status: LanguageSelectionStatus.downloading,
              downloadProgress: progress,
            ),
          );
        },
      );

      await _preferencesService.setSelectedLanguage(language.code);

      emit(state.copyWith(status: LanguageSelectionStatus.success));
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: LanguageSelectionStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
