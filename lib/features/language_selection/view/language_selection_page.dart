import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mneme/features/language_selection/cubit/language_selection_cubit.dart';
import 'package:mneme/features/language_selection/models/language_model.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Fire and forget - showing dialog
              // ignore: discarded_futures
              _showLicenseDialog(
                context,
                context.read<LanguageSelectionCubit>().state.availableLanguages,
              );
            },
          ),
        ],
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

  Future<void> _showLicenseDialog(
    BuildContext context,
    List<LanguageModel> languages,
  ) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.licenseInfoTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                return ListTile(
                  title: Text(language.name),
                  subtitle: Text(language.license.text),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}
