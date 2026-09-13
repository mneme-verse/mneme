import 'package:bloc/bloc.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_installer.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phases of first-run resource installation.
enum OnboardingPhase {
  /// The user is choosing a corpus language.
  languageSelection,

  /// Resources are being downloaded and verified.
  installing,

  /// All resources are installed and the language is persisted.
  completed,

  /// The last install attempt failed or was canceled.
  failed,
}

/// Which resource is currently being installed.
enum OnboardingResource { corpus, speechModel }

/// Typed onboarding state. Byte progress refers to the resource named by
/// [resource].
class OnboardingState {
  const OnboardingState({
    required this.phase,
    this.language,
    this.resource,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  const OnboardingState.languageSelection()
    : phase = OnboardingPhase.languageSelection,
      language = null,
      resource = null,
      receivedBytes = 0,
      totalBytes = 0,
      error = null;

  final OnboardingPhase phase;
  final String? language;
  final OnboardingResource? resource;
  final int receivedBytes;
  final int totalBytes;
  final Object? error;

  OnboardingState copyWith({
    OnboardingPhase? phase,
    String? language,
    OnboardingResource? resource,
    int? receivedBytes,
    int? totalBytes,
    Object? error,
  }) {
    return OnboardingState(
      phase: phase ?? this.phase,
      language: language ?? this.language,
      resource: resource,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error,
    );
  }
}

/// Languages offered during onboarding, Russian first.
const onboardingLanguages = ['ru', 'en'];

/// The locked speech model installed by default.
LockedResource defaultSpeechModel() => lockedSpeechModels.firstWhere(
  (model) => model.id == defaultSpeechModelId,
);

/// Installs the corpus pack and the default speech model for the chosen
/// language, then persists the selection.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required ResourceRepository resources,
    required CorpusManifestClient manifestClient,
    LockedResource? speechModel,
    SharedPreferences? prefs,
  }) : _resources = resources,
       _manifestClient = manifestClient,
       _speechModel = speechModel ?? defaultSpeechModel(),
       _prefs = prefs,
       super(const OnboardingState.languageSelection());

  final ResourceRepository _resources;
  final CorpusManifestClient _manifestClient;
  final LockedResource _speechModel;
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _resolvePrefs() async =>
      _prefs ?? SharedPreferences.getInstance();

  /// Starts installing resources for [language].
  ///
  /// Failures surface as [OnboardingPhase.failed] with [OnboardingState.error];
  /// the error is also rethrown for awaiting callers. A completed install
  /// emits [OnboardingPhase.completed] and persists the language.
  Future<void> selectLanguage(String language) async {
    emit(
      const OnboardingState.languageSelection().copyWith(
        phase: OnboardingPhase.installing,
        language: language,
        resource: OnboardingResource.corpus,
      ),
    );

    try {
      final pack = await _manifestClient.packFor(language);
      emit(
        state.copyWith(
          resource: OnboardingResource.corpus,
          totalBytes: pack.sizeBytes,
        ),
      );
      await _resources.installCorpusPack(
        pack.file,
        _manifestClient.packUrl(pack).toString(),
        pack.sha256,
        sizeBytes: pack.sizeBytes,
      );

      final model = _speechModel;
      emit(
        state.copyWith(
          resource: OnboardingResource.speechModel,
          receivedBytes: 0,
          totalBytes: model.sizeBytes,
        ),
      );
      await _resources.installSpeechModel(model);

      final prefs = await _resolvePrefs();
      await prefs.setString('selected_language', language);
      await prefs.setBool('onboarding_completed', true);

      emit(state.copyWith(phase: OnboardingPhase.completed));
    } on InstallCanceledException {
      emit(state.copyWith(phase: OnboardingPhase.failed));
      rethrow;
    } catch (error) {
      emit(state.copyWith(phase: OnboardingPhase.failed, error: error));
      rethrow;
    }
  }

  /// Cancels the in-flight install of the current language.
  void cancel() {
    final language = state.language;
    if (language == null) return;

    // Cancel both possible in-flight resources for this onboarding run.
    _resources
      ..cancel('$language.db.zst')
      ..cancel(defaultSpeechModelId);
  }

  /// Returns to language selection after a failure.
  void resetToLanguageSelection() {
    emit(const OnboardingState.languageSelection());
  }
}
