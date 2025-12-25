import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/app/app.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  group('App', () {
    testWidgets('renders Mneme MVP text', (tester) async {
      final repo = MockPoetryRepository();
      await tester.pumpWidget(App(poetryRepository: repo));
      expect(find.text('Mneme MVP'), findsNWidgets(2)); // AppBar and Center
    });
  });
}
