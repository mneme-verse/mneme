import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/app/app.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  group('App', () {
    testWidgets('renders Onboarding Page initially', (tester) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final repo = MockPoetryRepository();

      await tester.pumpWidget(App(poetryRepository: repo));
      await tester.pumpAndSettle(); // Wait for async initState

      // Should show Onboarding title
      expect(find.text('Select Language'), findsOneWidget);
    });
  });
}
