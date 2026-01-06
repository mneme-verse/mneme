import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:mneme/db/database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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
      expect(result['raw_authors'], ['Test Author']);
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
      expect(result['raw_authors'], ['[Anonymous]']);
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
      expect(result!['raw_authors'], ['A1', 'A2']);
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

      // Verify DB content
      final db = AppDatabase(NativeDatabase(dbFile));

      // Verify Poems
      final count = await db.poems.count().getSingle();
      expect(count, 1);

      final poem = await db.poems.select().getSingle();
      expect(poem.title, 'Test Poem');
      expect(poem.body, 'Line 1');
      expect(poem.authorNames, 'Author'); // Check denormalized name

      // Verify Authors
      final authors = await db.authors.select().get();
      expect(authors.length, 1);
      expect(authors.first.name, 'Author');
      expect(authors.first.poemCount, 1);

      // Verify PoemAuthors
      final poemAuthors = await db.poemAuthors.select().get();
      expect(poemAuthors.length, 1);
      expect(poemAuthors.first.poemId, poem.id);
      expect(poemAuthors.first.authorId, authors.first.id);

      await db.close();
    });

    test('builds database correctly handling multiple authors', () async {
      // Setup
      final builder = PoeTreeBuilder(dbOutputDir: tempDir.path);
      const lang = 'en';
      final langDir = Directory(path.join(tempDir.path, lang))..createSync();

      // Poem 1: Two authors
      File(path.join(langDir.path, 'poem1.json')).writeAsStringSync(
        jsonEncode({
          'id': 1,
          'title': 'Collaborative Poem',
          'author': [
            {'name': 'Author One'},
            {'name': 'Author Two'},
          ],
          'body': [
            {'text': 'Body'},
          ],
          'year_created': 2024,
        }),
      );

      // Poem 2: One of the authors from Poem 1
      File(path.join(langDir.path, 'poem2.json')).writeAsStringSync(
        jsonEncode({
          'id': 2,
          'title': 'Solo Poem',
          'author': {'name': 'Author One'},
          'body': [
            {'text': 'Body'},
          ],
          'year_created': 2025,
        }),
      );

      // Execute
      await builder.buildDatabase(tempDir, [lang], {});

      final db = AppDatabase(
        NativeDatabase(File(path.join(tempDir.path, 'en.db'))),
      );

      // Verify Authors
      final authors = await db.authors.select().get();
      expect(authors.length, 2);

      final authorOne = authors.firstWhere((a) => a.name == 'Author One');
      final authorTwo = authors.firstWhere((a) => a.name == 'Author Two');

      expect(authorOne.poemCount, 2);
      expect(authorTwo.poemCount, 1);

      // Verify Poems
      final poem1 =
          await (db.poems.select()
                ..where((t) => t.title.equals('Collaborative Poem')))
              .getSingle();
      expect(poem1.authorNames, 'Author One, Author Two');

      final poem2 =
          await (db.poems.select()..where((t) => t.title.equals('Solo Poem')))
              .getSingle();
      expect(poem2.authorNames, 'Author One');

      // Verify Junction Table
      final links1 =
          await (db.poemAuthors.select()
                ..where((t) => t.poemId.equals(poem1.id)))
              .get();
      expect(links1.length, 2);
      expect(
        links1.map((l) => l.authorId),
        containsAll([authorOne.id, authorTwo.id]),
      );

      final links2 =
          await (db.poemAuthors.select()
                ..where((t) => t.poemId.equals(poem2.id)))
              .get();
      expect(links2.length, 1);
      expect(links2.first.authorId, authorOne.id);

      await db.close();
    });

    test('generateManifest creates manifest with license', () async {
      final builder = PoeTreeBuilder(dbOutputDir: tempDir.path);
      // Create a dummy .db.zst file so generateManifest calculates hash/size and writes file
      File(path.join(tempDir.path, 'en.db.zst')).writeAsBytesSync([1, 2, 3]);

      await builder.generateManifest();

      final manifestFile = File(path.join(tempDir.path, 'manifest.json'));
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json.containsKey('license'), isFalse);
      // Check for language entry and name
      expect(json.containsKey('en'), isTrue);
      final enEntry = json['en'] as Map<String, dynamic>;
      expect(enEntry['name'], 'English');

      expect(enEntry.containsKey('license'), isTrue);
      final licenseParam = enEntry['license'] as Map<String, dynamic>;
      expect(
        licenseParam['text'],
        contains('CC BY-SA 4.0'),
      );
      expect(
        licenseParam['url'],
        'https://creativecommons.org/licenses/by-sa/4.0/',
      );
    });

    test('compressDatabases only compresses selected languages', () async {
      // Track which files were compressed
      final compressedFiles = <String>[];

      final builder = PoeTreeBuilder(
        dbOutputDir: tempDir.path,
        compressor: (filePath) async {
          compressedFiles.add(path.basename(filePath));
        },
      );

      // Create multiple .db files
      File(path.join(tempDir.path, 'en.db')).writeAsBytesSync([1, 2, 3, 4]);
      File(path.join(tempDir.path, 'ru.db')).writeAsBytesSync([5, 6, 7, 8]);
      File(path.join(tempDir.path, 'fr.db')).writeAsBytesSync([9, 10, 11, 12]);

      // Compress only English database
      await builder.compressDatabases(['en']);

      // Verify only en.db was compressed
      expect(compressedFiles, ['en.db']);
    });

    test('compressDatabases handles multiple selected languages', () async {
      // Track which files were compressed
      final compressedFiles = <String>[];

      final builder = PoeTreeBuilder(
        dbOutputDir: tempDir.path,
        compressor: (filePath) async {
          compressedFiles.add(path.basename(filePath));
        },
      );

      // Create multiple .db files
      File(path.join(tempDir.path, 'en.db')).writeAsBytesSync([1, 2, 3, 4]);
      File(path.join(tempDir.path, 'ru.db')).writeAsBytesSync([5, 6, 7, 8]);
      File(path.join(tempDir.path, 'fr.db')).writeAsBytesSync([9, 10, 11, 12]);

      // Compress English and Russian databases
      await builder.compressDatabases(['en', 'ru']);

      // Verify en.db and ru.db were compressed, but not fr.db
      expect(compressedFiles.length, 2);
      expect(compressedFiles, containsAll(['en.db', 'ru.db']));
      expect(compressedFiles, isNot(contains('fr.db')));
    });

    test('compressDatabases skips if .zst exists', () async {
      // Track which files were compressed
      final compressedFiles = <String>[];

      final builder = PoeTreeBuilder(
        dbOutputDir: tempDir.path,
        compressor: (filePath) async {
          compressedFiles.add(path.basename(filePath));
        },
      );

      // Create .db and .db.zst files
      File(path.join(tempDir.path, 'en.db')).writeAsBytesSync([1, 2, 3, 4]);
      File(
        path.join(tempDir.path, 'en.db.zst'),
      ).writeAsBytesSync([5, 6, 7, 8]);

      // Attempt compression
      await builder.compressDatabases(['en']);

      // Verify no compression happened
      expect(compressedFiles, isEmpty);

      // Verify .db file is unchanged
      final dbContent = File(
        path.join(tempDir.path, 'en.db'),
      ).readAsBytesSync();
      expect(dbContent, [1, 2, 3, 4]);
    });

    test('compressDatabases runs if .zst does not exist', () async {
      // Track which files were compressed
      final compressedFiles = <String>[];

      final builder = PoeTreeBuilder(
        dbOutputDir: tempDir.path,
        compressor: (filePath) async {
          compressedFiles.add(path.basename(filePath));
        },
      );

      // Create .db file only
      File(path.join(tempDir.path, 'en.db')).writeAsBytesSync([1, 2, 3, 4]);

      // Ensure .zst does not exist
      final zstFile = File(path.join(tempDir.path, 'en.db.zst'));
      if (zstFile.existsSync()) {
        zstFile.deleteSync();
      }

      // Attempt compression
      await builder.compressDatabases(['en']);

      // Verify compression happened
      expect(compressedFiles, ['en.db']);
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
