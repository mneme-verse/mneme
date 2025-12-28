import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is null', () {
      expect(OnboardingCubit().state, null);
    });

    blocTest<OnboardingCubit, String?>(
      'emits language code and saves prefs when completeOnboarding is called',
      build: OnboardingCubit.new,
      act: (cubit) => cubit.completeOnboarding('en'),
      expect: () => ['en'],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selected_language'), 'en');
        expect(prefs.getBool('onboarding_completed'), true);
      },
    );
  });
}
