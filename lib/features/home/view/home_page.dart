import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/home/bloc/home_cubit.dart';
import 'package:mneme/l10n/l10n.dart';
import 'package:mneme/repository/poetry_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        context.read<PoetryRepository>(),
        // ignore: discarded_futures -- fire and forget
      )..fetchAuthors(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.scrollController,
  });

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
            onPressed: () {
              // TODO(rominf): Implement SearchDelegate/SearchView
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO(rominf): Issue #5 - Navigate to Settings
            },
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
                  onTap: () {
                    // TODO(rominf): Navigate to AuthorDetailsPage
                  },
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
