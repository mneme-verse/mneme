import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/author/cubit/author_cubit.dart';
import 'package:mneme/features/reader/view/reader_page.dart';
import 'package:mneme/repository/poetry_repository.dart';

/// One author's poems. Tapping a poem opens the reader.
class AuthorPage extends StatelessWidget {
  const AuthorPage({required this.authorName, super.key});

  /// Display name of the author.
  final String authorName;

  /// Opens the poems of [authorName].
  static Route<void> route({required String authorName}) {
    return MaterialPageRoute<void>(
      builder: (_) => AuthorPage(authorName: authorName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthorCubit(context.read<PoetryRepository>())
        // ignore: discarded_futures -- fire and forget
        ..load(authorName),
      child: AuthorView(authorName: authorName),
    );
  }
}

/// Author body; separated for testability.
class AuthorView extends StatelessWidget {
  const AuthorView({required this.authorName, super.key});

  /// Display name of the author.
  final String authorName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(authorName)),
      body: BlocBuilder<AuthorCubit, AuthorState>(
        builder: (context, state) {
          return switch (state) {
            AuthorInitial() || AuthorLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            AuthorError(:final message) => Center(child: Text(message)),
            AuthorLoaded(:final poems) => ListView.builder(
              itemCount: poems.length,
              itemBuilder: (context, index) {
                final poem = poems[index];
                return ListTile(
                  title: Text(poem.title),
                  onTap: () => Navigator.of(
                    context,
                  ).push(ReaderPage.route(poemId: poem.id)),
                );
              },
            ),
          };
        },
      ),
    );
  }
}
