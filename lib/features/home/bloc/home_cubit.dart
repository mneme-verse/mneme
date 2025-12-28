import 'package:bloc/bloc.dart';
import 'package:mneme/db/database.dart'; // For Author type implied
import 'package:mneme/repository/poetry_repository.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded(this.authors, {this.hasReachedMax = false});
  final List<Author> authors;
  final bool hasReachedMax;
}

class HomeError extends HomeState {
  HomeError(this.message);
  final String message;
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._poetryRepository) : super(HomeInitial());

  final PoetryRepository _poetryRepository;
  static const _limit = 20;

  Future<void> fetchAuthors({int offset = 0}) async {
    if (state is HomeLoading) return; // Prevent double load

    // If initial fetch
    if (offset == 0) {
      emit(HomeLoading());
    }

    try {
      final authors = await _poetryRepository.getAuthors(
        offset: offset,
        // ignore: avoid_redundant_argument_values -- Explicitly requested by reviewer for clarity
        limit: _limit,
      );

      if (offset == 0) {
        emit(HomeLoaded(authors, hasReachedMax: authors.length < _limit));
      } else {
        if (state is HomeLoaded) {
          final currentAuthors = (state as HomeLoaded).authors;
          emit(
            HomeLoaded(
              currentAuthors + authors,
              hasReachedMax: authors.length < _limit,
            ),
          );
        }
      }
    } on Exception catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
