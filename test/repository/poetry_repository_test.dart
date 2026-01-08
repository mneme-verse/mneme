import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('PoetryRepository', () {
    late MockAppDatabase mockDb;
    late PoetryRepository repository;

    setUp(() {
      mockDb = MockAppDatabase();
      repository = PoetryRepository(mockDb);
    });

    test('close calls db.close()', () async {
      when(() => mockDb.close()).thenAnswer((_) async {});

      await repository.close();

      verify(() => mockDb.close()).called(1);
    });
  });
}
