// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/app/app.dart';

void main() {
  group('App', () {
    testWidgets('renders Mneme MVP text', (tester) async {
      await tester.pumpWidget(App());
      expect(find.text('Mneme MVP'), findsNWidgets(2)); // AppBar and Center
    });
  });
}
