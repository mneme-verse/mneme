import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.resources,
    required this.manifestClient,
    this.speechModel,
    this.onCompleted,
    super.key,
  });

  /// Installed resources shared with the rest of the app.
  final ResourceRepository resources;

  /// Client for the published corpus manifest.
  final CorpusManifestClient manifestClient;

  /// Speech model installed alongside the corpus; defaults to
  /// [defaultSpeechModel] inside the cubit.
  final LockedResource? speechModel;

  /// Invoked with the installed language when onboarding completes.
  final void Function(String language)? onCompleted;

  static Route<void> route({
    required ResourceRepository resources,
    required CorpusManifestClient manifestClient,
    LockedResource? speechModel,
    void Function(String language)? onCompleted,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => OnboardingPage(
        resources: resources,
        manifestClient: manifestClient,
        speechModel: speechModel,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(
        resources: resources,
        manifestClient: manifestClient,
        speechModel: speechModel,
      ),
      child: OnboardingView(onCompleted: onCompleted),
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({this.onCompleted, super.key});

  /// See [OnboardingPage.onCompleted].
  final void Function(String language)? onCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state.phase == OnboardingPhase.completed &&
            state.language != null) {
          onCompleted?.call(state.language!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (state.phase) {
                OnboardingPhase.languageSelection => _LanguageSelector(
                  languages: onboardingLanguages,
                  onSelect: context.read<OnboardingCubit>().selectLanguage,
                ),
                OnboardingPhase.installing => _InstallProgress(state: state),
                OnboardingPhase.failed => _InstallFailure(state: state),
                OnboardingPhase.completed => const CircularProgressIndicator(),
              },
            ),
          ),
        );
      },
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.languages, required this.onSelect});

  final List<String> languages;
  final Future<void> Function(String language) onSelect;

  static const _names = {'ru': 'Русский', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.selectLanguage,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),
        for (final language in languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 200,
              child: FilledButton(
                onPressed: () => onSelect(language).ignore(),
                child: Text(_names[language] ?? language),
              ),
            ),
          ),
      ],
    );
  }
}

class _InstallProgress extends StatelessWidget {
  const _InstallProgress({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = state.resource == OnboardingResource.speechModel
        ? l10n.installingModel
        : l10n.installingCorpus;
    final totalBytes = state.totalBytes > 0 ? state.totalBytes : 1;
    final progress = state.receivedBytes / totalBytes;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.installingResources,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 32),
        Text(label),
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          child: LinearProgressIndicator(value: progress.clamp(0, 1)),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.downloadProgress(
            (state.receivedBytes / (1024 * 1024)).round(),
            (state.totalBytes / (1024 * 1024)).round(),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: context.read<OnboardingCubit>().cancel,
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _InstallFailure extends StatelessWidget {
  const _InstallFailure({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.installationFailed,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text('${state.error ?? ''}'),
        const SizedBox(height: 24),
        SizedBox(
          width: 240,
          child: FilledButton(
            onPressed: () {
              final language = state.language;
              if (language != null) {
                // The cubit also throws for awaiting callers, but the UI
                // reads the failed state instead; the error is discarded
                // here so it never becomes an unhandled async exception.
                cubit.selectLanguage(language).ignore();
              }
            },
            child: Text(l10n.retry),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: cubit.resetToLanguageSelection,
          child: Text(l10n.chooseDifferentLanguage),
        ),
      ],
    );
  }
}
