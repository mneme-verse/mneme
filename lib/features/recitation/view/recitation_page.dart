import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/recitation/cubit/recitation_cubit.dart';
import 'package:mneme/features/recitation/recitation_driver.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/recitation/engine/transcribe_engine.dart';
import 'package:mneme/recitation/matcher.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/resources/resource_locks.dart';
import 'package:mneme/resources/resource_repository.dart';

/// Live recitation page: microphone capture, offline streaming
/// transcription, and word feedback against the corpus.
///
class RecitationPage extends StatefulWidget {
  /// Creates live recitation. [driver] injects a session driver;
  /// production builds one from the installed speech model on first
  /// build.
  const RecitationPage({this.driver, super.key});

  /// Prebuilt session driver, null when the page must build its own.
  final RecitationDriver? driver;

  /// Opens live recitation.
  static Route<void> route({RecitationDriver? driver}) {
    return MaterialPageRoute<void>(
      builder: (_) => RecitationPage(driver: driver),
    );
  }

  @override
  State<RecitationPage> createState() => _RecitationPageState();
}

class _RecitationPageState extends State<RecitationPage> {
  late final RecitationCubit _cubit;
  late final RecitationDriver _driver;
  String? _error;

  @override
  void initState() {
    super.initState();
    // context.read is safe in initState (no subscription); owners are
    // fixed for the page lifetime, so no didChangeDependencies tracking.
    _cubit = RecitationCubit(
      poetryRepository: context.read<PoetryRepository>(),
    );
    _driver =
        widget.driver ??
        RecitationDriver(
          modelPath: context
              .read<ResourceRepository>()
              .modelFile(defaultSpeechModelId)
              .path,
        );
    _driver.onTranscript = (text) {
      unawaited(_cubit.onTranscript(text));
    };
  }

  @override
  void dispose() {
    unawaited(_driver.dispose());
    unawaited(_cubit.close());
    super.dispose();
  }

  /// Starts a take; engine or permission failures render instead of
  /// crashing.
  Future<void> _start() async {
    setState(() => _error = null);
    _cubit.start();
    try {
      await _driver.start();
    } on RecitationPermissionDenied {
      _cubit.stop();
      setState(() => _error = 'Microphone permission denied');
      return;
    } on TranscribeEngineException catch (e) {
      _cubit.stop();
      setState(() => _error = e.message);
      return;
    }
    if (mounted) setState(() {});
  }

  /// Stops the take, keeping the last attempt visible.
  Future<void> _stop() async {
    await _driver.stop();
    _cubit.stop();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _RecitationView(
        error: _error,
        isListening: _driver.isListening,
        onStart: _start,
        onStop: _stop,
      ),
    );
  }
}

/// Recitation body; separated for testability.
class _RecitationView extends StatelessWidget {
  const _RecitationView({
    required this.error,
    required this.isListening,
    required this.onStart,
    required this.onStop,
  });

  /// Engine or permission failure, null while healthy.
  final String? error;

  /// Whether a take is in progress.
  final bool isListening;

  /// Starts a take.
  final Future<void> Function() onStart;

  /// Stops the take.
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recite)),
      body: BlocBuilder<RecitationCubit, RecitationState>(
        builder: (context, state) {
          final error = this.error ?? state.error?.toString();
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Center(
                child: isListening
                    ? FloatingActionButton(
                        onPressed: onStop,
                        child: const Icon(Icons.stop),
                      )
                    : FloatingActionButton(
                        onPressed: onStart,
                        child: const Icon(Icons.mic),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  isListening ? context.l10n.listening : context.l10n.recite,
                ),
              ),
              const SizedBox(height: 24),
              if (state.located != null)
                Text(
                  '${state.located!.poemTitle} · '
                  '${(state.score * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (state.hypothesis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(state.hypothesis),
              ],
              const SizedBox(height: 16),
              _FeedbackSummary(feedback: state.feedback),
            ],
          );
        },
      ),
    );
  }
}

/// Correct/wrong/pending tallies over the located window.
class _FeedbackSummary extends StatelessWidget {
  const _FeedbackSummary({required this.feedback});

  /// Per-word feedback in poem-token order.
  final List<WordFeedback> feedback;

  @override
  Widget build(BuildContext context) {
    if (feedback.isEmpty) return const SizedBox.shrink();
    var correct = 0;
    var wrong = 0;
    var pending = 0;
    for (final word in feedback) {
      switch (word.verdict) {
        case WordVerdict.correct:
          correct++;
        case WordVerdict.wrong:
          wrong++;
        case WordVerdict.pending:
          pending++;
      }
    }
    return Wrap(
      spacing: 8,
      children: [
        _Tally(
          count: correct,
          color: Colors.green,
          semantics: 'correct',
        ),
        _Tally(count: wrong, color: Colors.red, semantics: 'wrong'),
        _Tally(
          count: pending,
          color: Colors.grey,
          semantics: 'pending',
        ),
      ],
    );
  }
}

/// One colored tally chip.
class _Tally extends StatelessWidget {
  const _Tally({
    required this.count,
    required this.color,
    required this.semantics,
  });

  /// Words with this verdict.
  final int count;

  /// Chip color.
  final Color color;

  /// Accessibility label.
  final String semantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: Chip(
        key: ValueKey('tally-$semantics'),
        avatar: CircleAvatar(backgroundColor: color),
        label: Text('$count'),
      ),
    );
  }
}
