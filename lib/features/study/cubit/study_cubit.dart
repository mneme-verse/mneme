import 'package:bloc/bloc.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';

/// One due review row.
typedef DueReview = ({int poemId, String title, String authorNames});

/// Study queue states: exactly one is visible at a time.
sealed class StudyState {
  const StudyState();
}

/// Nothing requested yet.
class StudyInitial extends StudyState {
  const StudyInitial();
}

/// Due queue is loading.
class StudyLoading extends StudyState {
  const StudyLoading();
}

/// Due queue ready; empty when nothing is due.
class StudyLoaded extends StudyState {
  const StudyLoaded(this.due);

  /// Due reviews, earliest first.
  final List<DueReview> due;
}

/// The queue failed to load.
class StudyError extends StudyState {
  const StudyError(this.message);

  /// Human-readable failure.
  final String message;
}

/// Loads the FSRS due queue with poem titles for display.
class StudyCubit extends Cubit<StudyState> {
  /// Creates a study queue over the study and poetry repositories.
  StudyCubit(this._study, this._poetry) : super(const StudyInitial());

  final StudyRepository _study;
  final PoetryRepository _poetry;

  /// Reloads the due queue.
  Future<void> load() async {
    if (state is StudyLoading) return;
    emit(const StudyLoading());
    try {
      final keys = await _study.duePoemKeys();
      final due = <DueReview>[];
      for (final key in keys) {
        final poem = await _poetry.getPoemByKey(key);
        if (poem != null) {
          due.add(
            (poemId: poem.id, title: poem.title, authorNames: poem.authorNames),
          );
        }
      }
      emit(StudyLoaded(due));
    } on Object catch (e) {
      emit(StudyError(e.toString()));
    }
  }
}
