import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:mneme/l10n/l10n.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const OnboardingPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Hardcoded languages for now, should come from manifest later (Issue #8)
    final languages = {'en': 'English', 'ru': 'Русский'};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)), // "Mneme" or similar
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.selectLanguage,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              ...languages.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: 200,
                    child: FilledButton(
                      onPressed: () async {
                        await context
                            .read<OnboardingCubit>()
                            .completeOnboarding(entry.key);

                        if (context.mounted) {
                          await Navigator.of(
                            context,
                          ).pushReplacement(HomePage.route());
                        }
                      },
                      child: Text(entry.value),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
