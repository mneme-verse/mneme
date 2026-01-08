import 'package:mneme/app/app.dart';
import 'package:mneme/bootstrap.dart';

void main() {
  // Fire and forget - bootstrap handles app initialization
  // ignore: discarded_futures
  bootstrap(() => const App());
}
