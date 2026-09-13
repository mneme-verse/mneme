import 'dart:async';

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
  _OnboardingRun? _run;

  Future<SharedPreferences> _resolvePrefs() async =>
      _prefs ?? SharedPreferences.getInstance();

  /// Starts installing resources for [language].
  ///
  /// Failures surface as [OnboardingPhase.failed] with [OnboardingState.error];
  /// the error is also rethrown for awaiting callers. A completed install
  /// emits [OnboardingPhase.completed] and persists the language. A newer
  /// run, [cancel], or [close] supersedes this one: only the latest run
  /// may emit or clean up.
  Future<void> selectLanguage(String language) async {
    // A new run supersedes any previous one, including a manifest fetch
    // that has no resource token yet. The old installer keeps running in
    // the background, but its emissions and cleanup no longer apply.
    _run?.token.cancel();
    await _run?.subscription?.cancel();
    final run = _run = _OnboardingRun(InstallCancelToken());
    run.subscription = _resources.states.listen((update) {
      // Mirror byte progress into the installing state. Stale runs and
      // post-completion events are ignored by identity and phase.
      if (!identical(_run, run)) return;
      if (state.phase != OnboardingPhase.installing) return;
      emit(
        state.copyWith(
          resource: update.id == _speechModel.id
              ? OnboardingResource.speechModel
              : OnboardingResource.corpus,
          receivedBytes: update.receivedBytes,
          totalBytes: update.totalBytes,
        ),
      );
    });
    emit(
      const OnboardingState.languageSelection().copyWith(
        phase: OnboardingPhase.installing,
        language: language,
        resource: OnboardingResource.corpus,
      ),
    );

    try {
      final pack = await _manifestClient.packFor(language);
      if (run.token.isCanceled) throw InstallCanceledException(pack.file);
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
      if (run.token.isCanceled) throw InstallCanceledException(model.id);
      emit(
        state.copyWith(
          resource: OnboardingResource.speechModel,
          receivedBytes: 0,
          totalBytes: model.sizeBytes,
        ),
      );
      await _resources.installSpeechModel(model);
      // A cancel that lands after the last byte must still win: never
      // persist completion for a superseded run.
      if (run.token.isCanceled) throw InstallCanceledException(model.id);

      final prefs = await _resolvePrefs();
      await prefs.setString('selected_language', language);
      // Installed versions, checked on relaunch without network: a corpus
      // bump or model change sends the user back through onboarding.
      await prefs.setString('installed_corpus_version', pack.version);
      await prefs.setString('installed_model_id', model.id);
      await prefs.setString('installed_model_sha256', model.sha256);
      await prefs.setBool('onboarding_completed', true);

      emit(state.copyWith(phase: OnboardingPhase.completed));
    } on InstallCanceledException {
      if (identical(_run, run)) {
        emit(state.copyWith(phase: OnboardingPhase.failed));
      }
      rethrow;
    } catch (error) {
      if (identical(_run, run)) {
        emit(state.copyWith(phase: OnboardingPhase.failed, error: error));
      }
      rethrow;
    } finally {
      if (identical(_run, run)) {
        await run.subscription?.cancel();
        _run = null;
      }
    }
  }

  /// Cancels the in-flight install of the current language.
  void cancel() {
    _run?.token.cancel();
    final language = state.language;
    if (language == null) return;

    // Cancel both possible in-flight resources for this onboarding run.
    // Pack filenames are language-keyed by the manifest contract, and the
    // model is the injected one, not necessarily the default.
    _resources
      ..cancel('$language.db.gz')
      ..cancel(_speechModel.id);
  }

  /// Returns to language selection after a failure.
  void resetToLanguageSelection() {
    emit(const OnboardingState.languageSelection());
  }

  @override
  Future<void> close() async {
    _run?.token.cancel();
    await _run?.subscription?.cancel();
    return super.close();
  }
}

/// One onboarding attempt: emissions and cleanup apply only while this
/// run is still the cubit's latest.
class _OnboardingRun {
  _OnboardingRun(this.token);

  final InstallCancelToken token;
  // ignore: cancel_subscriptions -- canceled on replace, settle, and close.
  StreamSubscription<ResourceState>? subscription;
}
