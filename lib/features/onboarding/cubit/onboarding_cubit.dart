import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingCubit extends Cubit<String?> {
  OnboardingCubit() : super(null);

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  /// Save selected language and mark onboarding as complete.
  /// This is a stub for now that just mocks the "download"
  /// by saving preference.
  Future<void> completeOnboarding(String languageCode) async {
    final prefs = await _prefs;
    // In real app, we would trigger download here.
    // Issue #8 covers the actual download.
    // For now, we assume success.

    await prefs.setString('selected_language', languageCode);
    await prefs.setBool('onboarding_completed', true);
    emit(languageCode);
  }
}
