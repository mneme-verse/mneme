import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mneme/constants.dart';
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
    // coverage:ignore-start
  }) : _manifestService = manifestService ?? ManifestService(),
       _databaseInitializer = databaseInitializer ?? DatabaseInitializer(),
       _preferencesService = preferencesService ?? PreferencesService(),
       // coverage:ignore-end
       super(const LanguageSelectionState());

  final ManifestService _manifestService;
  final DatabaseInitializer _databaseInitializer;
  final PreferencesService _preferencesService;

  /// Load available languages from manifest.
  Future<void> loadLanguages() async {
    emit(
      state.copyWith(
        status: LanguageSelectionStatus.loading,
        clearErrorMessage: true,
        clearSelectedLanguage: true,
      ),
    );

    await _preferencesService.init();

    Map<String, dynamic> manifest;
    try {
      manifest = await _manifestService.fetchManifest();
      // Ignore the unawaited lint here or just await it. Awaiting is simpler.
      await _preferencesService.setCachedManifest(jsonEncode(manifest));
    } on Exception catch (error) {
      final cachedManifestJson = _preferencesService.getCachedManifest();
      if (cachedManifestJson != null) {
        try {
          manifest = Map<String, dynamic>.from(
            jsonDecode(cachedManifestJson) as Map,
          );
        } on Object catch (_) {
          // If decoding the cached manifest fails, report the original error.
          emit(
            state.copyWith(
              status: LanguageSelectionStatus.error,
              errorMessage: error.toString(),
            ),
          );
          return;
        }
      } else {
        emit(
          state.copyWith(
            status: LanguageSelectionStatus.error,
            errorMessage: error.toString(),
          ),
        );
        return;
      }
    }

    try {
      // Filter out non-language / metadata entries and only parse valid
      // language maps. Parse each entry defensively so one bad record
      // does not prevent other languages from loading.
      final languages =
          manifest.entries
              .where((entry) {
                final value = entry.value;
                if (value is! Map<String, dynamic>) return false;
                const requiredKeys = ['file', 'size', 'hash'];
                return requiredKeys.every(value.containsKey);
              })
              .expand((entry) {
                try {
                  final code = entry.key;
                  final data = entry.value as Map<String, dynamic>;
                  final name = data['name'] as String? ?? code.toUpperCase();
                  return [LanguageModel.fromJson(code, data, name)];
                } on Object catch (_) {
                  return const <LanguageModel>[];
                }
              })
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      emit(
        state.copyWith(
          status: LanguageSelectionStatus.loaded,
          availableLanguages: languages,
        ),
      );
    } on Object catch (e) {
      // In case formatting or type casting fails
      emit(
        state.copyWith(
          status: LanguageSelectionStatus.error,
          errorMessage: e.toString(),
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
        clearErrorMessage: true,
      ),
    );

    try {
      final fileName = language.file ?? '${language.code}.db.zst';
      final downloadUrl = '$kDatabaseReleaseBaseUrl/$fileName';

      await _databaseInitializer.initializeDatabase(
        language: language.code,
        url: downloadUrl,
        expectedSize: language.size,
        expectedHash: language.hash,
        onProgress: (received, total) {
          if (total <= 0) {
            // Total size is unknown or invalid; skip emitting a determinate
            // progress value.
            return;
          }
          final progress = (received / total).clamp(0.0, 1.0);
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
