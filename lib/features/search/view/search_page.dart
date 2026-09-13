import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/reader/view/reader_page.dart';
import 'package:mneme/features/search/cubit/search_cubit.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';

/// As-you-type poem search. Tapping a result opens the reader.
class SearchPage extends StatelessWidget {
  const SearchPage({required this.activeLanguages, super.key});

  /// Language codes constraining the search.
  final List<String> activeLanguages;

  /// Opens search over [activeLanguages].
  static Route<void> route({required List<String> activeLanguages}) {
    return MaterialPageRoute<void>(
      builder: (_) => SearchPage(activeLanguages: activeLanguages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit(context.read<PoetryRepository>()),
      child: SearchView(activeLanguages: activeLanguages),
    );
  }
}

/// Search body; separated for testability.
class SearchView extends StatefulWidget {
  const SearchView({required this.activeLanguages, super.key});

  /// Language codes constraining the search.
  final List<String> activeLanguages;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: context.l10n.searchHint),
              onChanged: (value) => context.read<SearchCubit>().query(
                value,
                widget.activeLanguages,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                return switch (state) {
                  SearchInitial() => const SizedBox.shrink(),
                  SearchLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  SearchError(:final message) => Center(child: Text(message)),
                  SearchLoaded(:final poems) => ListView.builder(
                    itemCount: poems.length,
                    itemBuilder: (context, index) {
                      final poem = poems[index];
                      return ListTile(
                        title: Text(poem.title),
                        subtitle: Text(poem.authorNames),
                        onTap: () => Navigator.of(context).push(
                          ReaderPage.route(poemId: poem.id),
                        ),
                      );
                    },
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
