import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/features/reader/cubit/reader_cubit.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';

/// Distraction-free poem page. In review mode a grade row records an FSRS
/// rating and closes the page.
class ReaderPage extends StatelessWidget {
  const ReaderPage({required this.poemId, this.reviewMode = false, super.key});

  /// Database id of the poem to display.
  final int poemId;

  /// Whether to show FSRS grade buttons.
  final bool reviewMode;

  /// Opens the reader for [poemId].
  static Route<bool> route({required int poemId, bool reviewMode = false}) {
    return MaterialPageRoute<bool>(
      builder: (_) => ReaderPage(poemId: poemId, reviewMode: reviewMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReaderCubit(
        context.read<PoetryRepository>(),
        reviewMode ? context.read<StudyRepository>() : null,
        // ignore: discarded_futures -- fire and forget
      )..load(poemId),
      child: ReaderView(reviewMode: reviewMode),
    );
  }
}

/// Reader body; separated for testability.
class ReaderView extends StatelessWidget {
  const ReaderView({required this.reviewMode, super.key});

  /// Whether to show FSRS grade buttons.
  final bool reviewMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          return switch (state) {
            ReaderInitial() || ReaderLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ReaderMissing() => Center(
              child: Text(context.l10n.poemNotFound),
            ),
            ReaderError(:final message) => Center(
              child: Text(message),
            ),
            ReaderLoaded(:final poem) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  poem.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  poem.authorNames,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  poem.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                  ),
                ),
                if (reviewMode) ...[
                  const SizedBox(height: 32),
                  _GradeRow(onGrade: _grade(context)),
                ],
              ],
            ),
          };
        },
      ),
    );
  }

  /// Grades the loaded poem and closes the page with `true`.
  void Function(fsrs.Rating) _grade(BuildContext context) {
    return (rating) {
      // ignore: discarded_futures -- the page closes regardless
      context.read<ReaderCubit>().grade(rating).whenComplete(() {
        if (context.mounted) Navigator.of(context).pop(true);
      });
    };
  }
}

/// Four FSRS grade buttons in one row.
class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.onGrade});

  /// Called with the tapped rating.
  final void Function(fsrs.Rating) onGrade;

  @override
  Widget build(BuildContext context) {
    final grades = [
      (fsrs.Rating.again, context.l10n.gradeAgain),
      (fsrs.Rating.hard, context.l10n.gradeHard),
      (fsrs.Rating.good, context.l10n.gradeGood),
      (fsrs.Rating.easy, context.l10n.gradeEasy),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (rating, label) in grades)
          ElevatedButton(
            onPressed: () => onGrade(rating),
            child: Text(label),
          ),
      ],
    );
  }
}
