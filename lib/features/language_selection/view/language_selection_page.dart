import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mneme/features/language_selection/cubit/language_selection_cubit.dart';
import 'package:mneme/l10n/l10n.dart';

/// Page for selecting the application language.
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({
    this.onSelectionComplete,
    super.key,
  });

  final VoidCallback? onSelectionComplete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Fire and forget - loading starts immediately
      // ignore: discarded_futures
      create: (_) => LanguageSelectionCubit()..loadLanguages(),
      child: LanguageSelectionView(
        onSelectionComplete: onSelectionComplete,
      ),
    );
  }
}

/// Main view for language selection.
class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView({
    this.onSelectionComplete,
    super.key,
  });

  final VoidCallback? onSelectionComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSelectionTitle),
      ),
      body: BlocConsumer<LanguageSelectionCubit, LanguageSelectionState>(
        listener: (context, state) {
          if (state.status == LanguageSelectionStatus.success) {
            onSelectionComplete?.call();
          }
        },
        builder: (context, state) {
          if (state.status == LanguageSelectionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LanguageSelectionStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.errorOccurred(state.errorMessage ?? 'Unknown')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Fire and forget - retry action
                      // ignore: discarded_futures
                      context.read<LanguageSelectionCubit>().loadLanguages();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state.status == LanguageSelectionStatus.downloading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.downloadingLanguage(
                      state.selectedLanguage?.name ?? '',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.availableLanguages.length,
            itemBuilder: (context, index) {
              final language = state.availableLanguages[index];
              return ListTile(
                title: Text(language.name),
                subtitle: Text(
                  '${language.license.text} (${l10n.tapForLicense})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Fire and forget - selection triggers download
                  // ignore: discarded_futures
                  context.read<LanguageSelectionCubit>().selectLanguage(
                    language,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
