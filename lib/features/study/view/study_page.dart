import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/reader/view/reader_page.dart';
import 'package:mneme/features/study/cubit/study_cubit.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';

/// FSRS due queue. Tapping a row opens the reader in review mode; a
/// recorded grade pops back here and refreshes the queue.
class StudyPage extends StatelessWidget {
  const StudyPage({super.key});

  /// Opens the study queue.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const StudyPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudyCubit(
        context.read<StudyRepository>(),
        context.read<PoetryRepository>(),
        // ignore: discarded_futures -- fire and forget
      )..load(),
      child: const StudyView(),
    );
  }
}

/// Study body; separated for testability.
class StudyView extends StatelessWidget {
  const StudyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.review)),
      body: BlocBuilder<StudyCubit, StudyState>(
        builder: (context, state) {
          return switch (state) {
            StudyInitial() || StudyLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            StudyError(:final message) => Center(child: Text(message)),
            StudyLoaded(:final due) => _DueBody(due: due),
          };
        },
      ),
    );
  }
}

/// Due queue body; a method (not a ternary arm) so both branches
/// attribute coverage lines independently.
class _DueBody extends StatelessWidget {
  const _DueBody({required this.due});

  /// Due reviews, earliest first.
  final List<DueReview> due;

  @override
  Widget build(BuildContext context) {
    if (due.isEmpty) {
      return Center(child: Text(context.l10n.nothingDue));
    }
    return ListView.builder(
      itemCount: due.length,
      itemBuilder: (context, index) {
        final item = due[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Text(item.authorNames),
          onTap: () => _openReview(context, item.poemId),
        );
      },
    );
  }

  /// Opens the review reader; a recorded grade pops back and refreshes.
  Future<void> _openReview(BuildContext context, int poemId) async {
    final graded = await Navigator.of(context).push(
      ReaderPage.route(poemId: poemId, reviewMode: true),
    );
    if (graded == true && context.mounted) {
      unawaited(context.read<StudyCubit>().load());
    }
  }
}
