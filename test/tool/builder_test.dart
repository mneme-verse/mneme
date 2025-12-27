import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mneme/db/database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;

// Import the builder tool file.
// Note: Since it's in tool/, we import it via relative path.
import '../../tool/builder.dart';
import 'builder_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late Directory tempDir;

  setUp(() {
    mockClient = MockClient();
    tempDir = Directory.systemTemp.createTempSync('poetree_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('extractPoemData', () {
    test('extracts valid poem correctly', () {
      final json = {
        'title': 'Test Poem',
        'author': {'name': 'Test Author'},
        'body': [
          {'text': 'Line 1'},
          {'text': 'Line 2'},
        ],
        'year_created': 2024,
      };

      final result = extractPoemData(json, 'en');

      expect(result, isNotNull);
      expect(result!['title'], 'Test Poem');
      expect(result['author'], '["Test Author"]');
      expect(result['body'], 'Line 1\nLine 2');
      expect(result['year'], '2024');
    });

    test('accepts anonymous poems', () {
      final json = {
        'title': 'Anon Poem',
        'author': {'name': '[Anonymous]'},
        'body': [
          {'text': 'Body'},
        ],
      };

      final result = extractPoemData(json, 'en');

      expect(result, isNotNull);
      expect(result!['title'], 'Anon Poem');
      expect(result['author'], '["[Anonymous]"]');
    });

    test('handles list of authors', () {
      final json = {
        'title': 'Collab',
        'author': [
          {'name': 'A1'},
          {'name': 'A2'},
        ],
        'body': [
          {'text': 'Body'},
        ],
      };

      final result = extractPoemData(json, 'en');

      expect(result, isNotNull);
      expect(result!['author'], '["A1","A2"]');
    });

    test('handles missing optional fields', () {
      final json = {
        'title': 'Simple',
        'author': {'name': 'A'},
        'body': [
          {'text': 'B'},
        ],
      };

      final result = extractPoemData(json, 'en');

      expect(result, isNotNull);
      expect(result!['year'], isNull);
      expect(result['alt_titles'], isNull);
    });

    test('skips poems without title', () {
      final json = {
        'author': {'name': 'A'},
        'body': [
          {'text': 'B'},
        ],
      };

      final result = extractPoemData(json, 'en');
      expect(result, isNull);
    });
  });

  group('PoeTreeBuilder', () {
    test('downloadOrExtractCorpus downloads zip if not exists', () async {
      // Setup
      final builder = TestPoeTreeBuilder(
        client: mockClient,
        dbOutputDir: tempDir.path,
      );
      const lang = 'en';
      const zipUrl = 'https://zenodo.org/records/17414036/files/en.zip';

      when(
        mockClient.get(Uri.parse(zipUrl)),
      ).thenAnswer((_) async => http.Response('zip-content', 200));

      // Execute
      await builder.downloadAndExtractCorpus(
        lang,
        'https://zenodo.org/records/17414036/files',
        tempDir,
      );

      // Verify
      verify(mockClient.get(Uri.parse(zipUrl))).called(1);
      expect(builder.extractedZips, hasLength(1));
      expect(builder.extractedZips.first, contains('en.zip'));

      // Verify zip file was written
      final zipFile = File(path.join(tempDir.path, 'en.zip'));
      expect(zipFile.existsSync(), isTrue);
      expect(zipFile.readAsStringSync(), 'zip-content');
    });

    test('downloadOrExtractCorpus skips download if zip exists', () async {
      // Setup
      final builder = TestPoeTreeBuilder(
        client: mockClient,
        dbOutputDir: tempDir.path,
      );
      const lang = 'en';
      File(
        path.join(tempDir.path, 'en.zip'),
      ).writeAsStringSync('existing-content');

      // Execute
      await builder.downloadAndExtractCorpus(
        lang,
        'https://zenodo.org/records/17414036/files',
        tempDir,
      );

      // Verify
      verifyNever(mockClient.get(any));
      expect(builder.extractedZips, hasLength(1));
    });

    test('builds database from json files', () async {
      // Setup
      final builder = PoeTreeBuilder(dbOutputDir: tempDir.path);
      const lang = 'en';
      final langDir = Directory(path.join(tempDir.path, lang))..createSync();

      // Create a mock poem JSON
      File(path.join(langDir.path, 'poem1.json')).writeAsStringSync(
        jsonEncode({
          'id': 1,
          'title': 'Test Poem',
          'author': {'name': 'Author'},
          'body': [
            {'text': 'Line 1'},
          ],
          'year_created': 2024,
          'duplicate': false,
        }),
      );

      // Execute
      await builder.buildDatabase(tempDir, [lang], {});

      // Verify
      final dbFile = File(path.join(tempDir.path, 'en.db'));
      expect(dbFile.existsSync(), isTrue);

      // Verify DB content (basic check)
      final db = AppDatabase(NativeDatabase(dbFile));
      final count = await db.poems.count().getSingle();
      expect(count, 1);

      final poem = await db.poems.select().getSingle();
      expect(poem.title, 'Test Poem');
      expect(poem.body, 'Line 1');

      await db.close();
    });
  });
}

class TestPoeTreeBuilder extends PoeTreeBuilder {
  factory TestPoeTreeBuilder({http.Client? client, String? dbOutputDir}) {
    final extractedZips = <String>[];
    return TestPoeTreeBuilder._(
      extractedZips: extractedZips,
      zipExtractor: (zipPath, destPath) async {
        extractedZips.add(zipPath);
      },
      client: client,
      dbOutputDir: dbOutputDir ?? 'assets/database',
    );
  }

  TestPoeTreeBuilder._({
    required this.extractedZips,
    required super.zipExtractor,
    super.client,
    super.dbOutputDir,
  });

  final List<String> extractedZips;
}
