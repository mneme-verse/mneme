import 'package:bloc/bloc.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/database.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';

/// Reader states: exactly one is visible at a time.
sealed class ReaderState {
  const ReaderState();
}

/// Nothing requested yet.
class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

/// Poem is loading.
class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

/// Poem ready to display.
class ReaderLoaded extends ReaderState {
  const ReaderLoaded(this.poem);

  /// The displayed poem.
  final Poem poem;
}

/// The requested poem does not exist.
class ReaderMissing extends ReaderState {
  const ReaderMissing();
}

/// Loading failed for any other reason.
class ReaderError extends ReaderState {
  const ReaderError(this.message);

  /// Human-readable failure.
  final String message;
}

/// Loads one poem for distraction-free reading and, in review mode,
/// records an FSRS grade for it.
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(this._poetry, [this._study]) : super(const ReaderInitial());

  final PoetryRepository _poetry;
  final StudyRepository? _study;

  /// Loads the poem with [poemId].
  Future<void> load(int poemId) async {
    if (state is ReaderLoading) return;
    emit(const ReaderLoading());
    try {
      final poem = await _poetry.getPoemById(poemId);
      if (poem == null) {
        emit(const ReaderMissing());
      } else {
        emit(ReaderLoaded(poem));
      }
    } on Object catch (e) {
      emit(ReaderError(e.toString()));
    }
  }

  /// Records [rating] for the loaded poem. No-op without a study repository.
  Future<void> grade(fsrs.Rating rating) async {
    final current = state;
    final study = _study;
    if (current is! ReaderLoaded || study == null) return;
    await study.submitReview(
      poemKey: current.poem.poemKey,
      rating: rating,
    );
  }
}
