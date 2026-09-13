import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/repository/poetry_repository.dart';

/// Search states: exactly one is visible at a time.
sealed class SearchState {
  const SearchState();
}

/// No query entered yet.
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// A query is in flight.
class SearchLoading extends SearchState {
  const SearchLoading();
}

/// Results for the latest settled query.
class SearchLoaded extends SearchState {
  const SearchLoaded(this.poems);

  /// Matching poems, at most the requested limit.
  final List<Poem> poems;
}

/// The latest query failed.
class SearchError extends SearchState {
  const SearchError(this.message);

  /// Human-readable failure.
  final String message;
}

/// Debounced as-you-type poem search. Rapid keystrokes settle into one
/// repository query per pause; stale results never overwrite newer ones.
class SearchCubit extends Cubit<SearchState> {
  /// Creates a search over the poetry repository with a settle window.
  SearchCubit(
    this._poetry, {
    Duration debounce = const Duration(milliseconds: 300),
  }) : _debounce = debounce,
       super(const SearchInitial());

  final PoetryRepository _poetry;
  final Duration _debounce;
  Timer? _timer;
  int _request = 0;

  /// Restarts the settle window for [query]; empty queries reset to initial.
  void query(String query, List<String> activeLanguages) {
    _timer?.cancel();
    if (query.trim().isEmpty) {
      _request++;
      emit(const SearchInitial());
      return;
    }
    emit(const SearchLoading());
    final ticket = ++_request;
    _timer = Timer(_debounce, () async {
      try {
        final poems = await _poetry.searchPoems(query, activeLanguages);
        if (ticket == _request) emit(SearchLoaded(poems));
      } on Object catch (e) {
        if (ticket == _request) emit(SearchError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
