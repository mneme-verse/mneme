import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/author/view/author_page.dart';
import 'package:mneme/features/home/bloc/home_cubit.dart';
import 'package:mneme/features/recitation/view/recitation_page.dart';
import 'package:mneme/features/search/view/search_page.dart';
import 'package:mneme/features/study/view/study_page.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.language, super.key});

  /// Active corpus language, constraining search.
  final String language;

  static Route<void> route({required String language}) {
    return MaterialPageRoute<void>(
      builder: (_) => HomePage(language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        context.read<PoetryRepository>(),
        // ignore: discarded_futures -- fire and forget
      )..fetchAuthors(),
      child: HomeView(language: language),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({
    required this.language,
    super.key,
    this.scrollController,
  });

  /// Active corpus language, constraining search.
  final String language;

  /// Optional scroll controller for testing purposes.
  final ScrollController? scrollController;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll) {
      final cubit = context.read<HomeCubit>();
      final state = cubit.state;
      if (state is HomeLoaded && !state.hasReachedMax) {
        // ignore: discarded_futures -- fire and forget
        cubit.fetchAuthors(offset: state.authors.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.authors),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              SearchPage.route(activeLanguages: [widget.language]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () => Navigator.of(context).push(StudyPage.route()),
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => Navigator.of(context).push(RecitationPage.route()),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is HomeLoaded) {
            if (state.authors.isEmpty) {
              return Center(child: Text(context.l10n.noAuthorsFound));
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: state.hasReachedMax
                  ? state.authors.length
                  : state.authors.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.authors.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final author = state.authors[index];
                return ListTile(
                  title: Text(author.name),
                  subtitle: Text(context.l10n.poemsCount(author.poemCount)),
                  onTap: () => Navigator.of(context).push(
                    AuthorPage.route(authorName: author.name),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
