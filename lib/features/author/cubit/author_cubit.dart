import 'package:bloc/bloc.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/repository/poetry_repository.dart';

/// Author poems states: exactly one is visible at a time.
sealed class AuthorState {
  const AuthorState();
}

/// Nothing requested yet.
class AuthorInitial extends AuthorState {
  const AuthorInitial();
}

/// Poems are loading.
class AuthorLoading extends AuthorState {
  const AuthorLoading();
}

/// Poems ready to display.
class AuthorLoaded extends AuthorState {
  const AuthorLoaded(this.poems);

  /// The author's poems.
  final List<Poem> poems;
}

/// Loading failed.
class AuthorError extends AuthorState {
  const AuthorError(this.message);

  /// Human-readable failure.
  final String message;
}

/// Loads one author's poems.
class AuthorCubit extends Cubit<AuthorState> {
  /// Creates an author loader over the poetry repository.
  AuthorCubit(this._poetry) : super(const AuthorInitial());

  final PoetryRepository _poetry;

  /// Loads poems for [authorName].
  Future<void> load(String authorName) async {
    if (state is AuthorLoading) return;
    emit(const AuthorLoading());
    try {
      emit(AuthorLoaded(await _poetry.getPoemsByAuthor(authorName)));
    } on Object catch (e) {
      emit(AuthorError(e.toString()));
    }
  }
}
