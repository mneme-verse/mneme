import 'package:mneme/app/app.dart';
import 'package:mneme/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
