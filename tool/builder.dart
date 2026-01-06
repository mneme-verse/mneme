// CLI tool uses print for output and simple error handling
// ignore_for_file: avoid_print, avoid_catches_without_on_clauses
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:es_compression/zstd.dart';
import 'package:http/http.dart' as http;
import 'package:mneme/db/database.dart';
import 'package:path/path.dart' as path;

const _availableCorpora = ['cs', 'de', 'en', 'hu', 'no', 'pt', 'ru', 'sl'];
const _filesPerHarvestIsolate = 500;
const _dbInsertBatchSize = 2500;

const _languageNames = {
  'cs': 'Čeština',
  'de': 'Deutsch',
  'en': 'English',
  'hu': 'Magyar',
  'no': 'Norsk',
  'pt': 'Português',
  'ru': 'Русский',
  'sl': 'Slovenščina',
};

/// PoeTree corpus ETL script that downloads and converts PoeTree JSON files
/// to SQLite database.
void main(List<String> args) async {
  final parser = _buildArgParser();

  try {
    final results = parser.parse(args);

    // Handle --help flag
    if (results['help'] as bool) {
      _printHelp(parser);
      return;
    }

    final cleanBefore = (results['clean-before'] as List<String>).toSet();
    final cleanAfter = (results['clean-after'] as List<String>).toSet();

    // Parse languages
    var selectedLanguages = _availableCorpora;

    if (results.wasParsed('languages')) {
      selectedLanguages = results['languages'] as List<String>;
    }

    print('🌳 PoeTree ETL Script');
    print('=' * 60);
    if (selectedLanguages.length < _availableCorpora.length) {
      print('📋 Selected languages: ${selectedLanguages.join(", ")}');
    }

    final builder = PoeTreeBuilder();

    // Clean specified targets before starting
    if (cleanBefore.isNotEmpty) {
      await builder.cleanFiles(cleanBefore, selectedLanguages);
    }

    final tempDir = Directory('.poetree');

    // Smart download: automatically detects and skips existing files
    await builder.downloadCorpora(tempDir, selectedLanguages);

    print('\n🗄️  Building databases...');
    await builder.buildDatabase(tempDir, selectedLanguages, cleanBefore);

    print('\n🗜️  Compressing databases...');
    await builder.compressDatabases(selectedLanguages);

    print('\n📜 Generating manifest...');
    await builder.generateManifest();

    print('\n✅ Complete! Databases generated in ${builder.dbOutputDir}/');

    // Clean up files after processing if requested
    if (cleanAfter.isNotEmpty) {
      await builder.cleanFilesAfter(cleanAfter, tempDir);
    } else if (tempDir.existsSync()) {
      print(
        '\nℹ️  Kept files in .poetree/ (use --clean-after=poetree to remove)',
      );
    }
  } on ArgParserException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    _printHelp(parser);
    exit(1);
  }
}

/// Build argument parser
ArgParser _buildArgParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    )
    ..addMultiOption(
      'clean-before',
      allowed: ['poetree', 'db', 'zst'],
      help:
          'Clean specific files BEFORE processing.\n'
          'poetree: Remove .poetree/ directory (ZIP + JSON)\n'
          'db: Remove uncompressed .db files\n'
          'zst: Remove compressed .db.zst files',
    )
    ..addMultiOption(
      'clean-after',
      allowed: ['poetree', 'db'],
      help:
          'Clean specific files AFTER processing.\n'
          'poetree: Remove .poetree/ directory (save space)\n'
          'db: Remove uncompressed .db files (keep only .zst)',
    )
    ..addMultiOption(
      'languages',
      abbr: 'l',
      allowed: _availableCorpora,
      help: 'Download only specified languages',
      defaultsTo: _availableCorpora,
    );
}

/// Print help information
void _printHelp(ArgParser parser) {
  print('''
🌳 PoeTree ETL Script - Build SQLite database from PoeTree corpus

USAGE:
    dart run tool/builder.dart [OPTIONS]

OPTIONS:
${parser.usage}

EXAMPLES:
    # Download all corpora and build database (keeps all files by default)
    dart run tool/builder.dart

    # Download only English and Russian
    dart run tool/builder.dart --languages=en,ru

    # Clean everything and rebuild from scratch
    dart run tool/builder.dart --clean-before=poetree,db,zst

    # Clean only databases before rebuilding
    dart run tool/builder.dart --clean-before=db,zst

    # Rebuild DBs using existing ZIP/JSON files (auto-detected)
    dart run tool/builder.dart --clean-before=db,zst

    # Clean up .poetree/ directory after building (save disk space)
    dart run tool/builder.dart --clean-after=poetree

    # Build and keep only compressed DBs (remove .db files after compression)
    dart run tool/builder.dart --clean-after=db

NOTE:
    Files are kept by default to avoid re-downloads and DB rebuilds.
    Downloads ~1.6 GB of ZIP files. Extracted content uses ~21 GB (~23 GB total).
    Use --clean-before to remove files before processing starts.
    Use --clean-after to remove files after processing completes (save space).
''');
}

class PoeTreeBuilder {
  PoeTreeBuilder({
    http.Client? client,
    this.dbOutputDir = 'assets/database',
    Future<void> Function(String, String)? zipExtractor,
    Future<void> Function(String)? compressor,
  }) : client = client ?? http.Client(),
       zipExtractor = zipExtractor ?? extractFileToDisk,
       compressor = compressor ?? _defaultCompressor;

  final http.Client client;
  final String dbOutputDir;
  final Future<void> Function(String, String) zipExtractor;
  final Future<void> Function(String) compressor;

  static Future<void> _defaultCompressor(String path) {
    return Isolate.run(() => compressFile(path));
  }

  /// Clean existing database and temp files based on specified targets
  Future<void> cleanFiles(
    Set<String> cleanTargets,
    List<String> selectedLanguages,
  ) async {
    print('\n🧹 Cleaning files...');

    final dbDir = Directory(dbOutputDir);

    // Clean database files (both .db and .db.zst)
    if (cleanTargets.contains('db') || cleanTargets.contains('zst')) {
      if (dbDir.existsSync()) {
        final entities = dbDir.listSync();
        for (final entity in entities) {
          final filename = path.basename(entity.path);

          // Check if it's a database file for a selected language
          var lang = '';
          var shouldDelete = false;

          // Handle .db.zst files
          if (cleanTargets.contains('zst') && filename.endsWith('.db.zst')) {
            lang = filename.substring(0, filename.length - 7); // Remove .db.zst
            shouldDelete = selectedLanguages.contains(lang);
          }
          // Handle .db files (not .db.zst)
          else if (cleanTargets.contains('db') && filename.endsWith('.db')) {
            lang = filename.substring(0, filename.length - 3);
            shouldDelete = selectedLanguages.contains(lang);
          }

          if (shouldDelete) {
            entity.deleteSync();
            print('  ✓ Deleted $filename');
          }
        }
      }
    }

    // Clean poetree directory (ZIP + JSON files)
    if (cleanTargets.contains('poetree')) {
      final tempDir = Directory('.poetree');
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        print('  ✓ Deleted .poetree directory');
      }
    }
  }

  /// Clean files after processing completes
  Future<void> cleanFilesAfter(
    Set<String> cleanTargets,
    Directory tempDir,
  ) async {
    print('\n🧹 Cleaning up files after processing...');

    // Clean poetree directory (ZIP + JSON files)
    if (cleanTargets.contains('poetree') && tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
      print('  ✓ Deleted .poetree directory');
    }

    // Clean uncompressed DB files (keep only .zst)
    if (cleanTargets.contains('db')) {
      final dbDir = Directory(dbOutputDir);
      if (dbDir.existsSync()) {
        final dbFiles = dbDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db'))
            .toList();

        for (final file in dbFiles) {
          file.deleteSync();
          print('  ✓ Deleted ${path.basename(file.path)} (kept .zst)');
        }
      }
    }
  }

  /// Download CC-BY-SA 4.0 licensed corpora from Zenodo
  Future<void> downloadCorpora(
    Directory tempDir,
    List<String> languages,
  ) async {
    print('\n📥 Downloading corpora from Zenodo...');

    // Use selected languages
    final corpora = languages;
    const zenodoBaseUrl = 'https://zenodo.org/records/17414036/files';

    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }

    print('     ℹ️  Downloading ${corpora.length} corpora in parallel...');

    await Future.wait<void>(
      corpora.map(
        (lang) => downloadAndExtractCorpus(
          lang,
          zenodoBaseUrl,
          tempDir,
        ),
      ),
    );
  }

  /// Download and extract a single corpus
  Future<void> downloadAndExtractCorpus(
    String lang,
    String zenodoBaseUrl,
    Directory tempDir,
  ) async {
    final langDir = Directory(path.join(tempDir.path, lang));
    final zipFile = File(path.join(tempDir.path, '$lang.zip'));

    // Check if already extracted with JSON files
    if (langDir.existsSync()) {
      final hasJsonFiles = langDir
          .listSync(recursive: true)
          .whereType<File>()
          .any((f) => f.path.endsWith('.json'));

      if (hasJsonFiles) {
        print('  ✓ Using existing $lang corpus');
        return;
      }
    }

    // Check if ZIP exists but not extracted
    if (zipFile.existsSync()) {
      print('  📦 Extracting existing $lang.zip...');
      try {
        await zipExtractor(zipFile.path, tempDir.path);
        print('     ✓ [$lang] Extracted');
        return;
      } catch (e) {
        print('     ❌ Extraction failed: $e');
        // Fall through to re-download
        zipFile.deleteSync();
      }
    }

    // Download and extract
    final zipUrl = '$zenodoBaseUrl/$lang.zip';
    print('  ⬇️  Downloading $lang.zip...');

    try {
      final response = await client.get(Uri.parse(zipUrl));
      if (response.statusCode == 200) {
        await zipFile.writeAsBytes(response.bodyBytes);
        final sizeMB = response.bodyBytes.length / 1024 / 1024;
        print(
          '     ✓ [$lang] Downloaded ${sizeMB.toStringAsFixed(1)} MB',
        );

        // Extract zip file
        print('     📦 [$lang] Extracting...');
        await zipExtractor(zipFile.path, tempDir.path);
        print('     ✓ [$lang] Extracted');

        // Keep zip file for future use
      } else {
        print('     ❌ [$lang] Failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('     ❌ [$lang] Error: $e');
    }
  }

  /// Build SQLite database from PoeTree JSON files
  Future<void> buildDatabase(
    Directory tempDir,
    List<String> selectedLanguages,
    Set<String> cleanTargets,
  ) async {
    // Ensure the temp directory exists
    if (!tempDir.existsSync()) {
      throw Exception(
        'The .poetree/ directory does not exist. '
        'Please verify that the corpus files were downloaded correctly.',
      );
    }

    // Ensure output directory exists
    final dbDir = Directory(dbOutputDir);
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    var totalPoems = 0;
    var skippedPoems = 0;
    var processedFiles = 0;

    // Process each language directory
    final langDirs = tempDir.listSync().whereType<Directory>().where(
      (d) =>
          !path.basename(d.path).startsWith('.') &&
          selectedLanguages.contains(path.basename(d.path)),
    );

    for (final langDir in langDirs) {
      final langCode = path.basename(langDir.path);
      print('\n  📖 Processing $langCode corpus...');

      final dbPath = path.join(dbDir.path, '$langCode.db');
      final dbFile = File(dbPath);

      // Check if database already exists and we're not cleaning
      if (dbFile.existsSync() && !cleanTargets.contains('db')) {
        print('  ⏭️  Skipping $langCode (database already exists)');
        continue;
      }

      // Delete existing database for this language if cleaning
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }

      print('  Opening database at $dbPath...');
      final db = AppDatabase(NativeDatabase(dbFile));

      // Optimization: Drop FTS triggers to speed up insertion
      await _dropFtsTriggers(db);

      // Find all JSON files recursively
      final jsonFiles = langDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      // Phase 1: Harvest duplicate titles
      print('     🔍 Harvesting duplicates...');
      final harvestResult = await harvestDuplicates(jsonFiles);
      final altTitlesMap = harvestResult.altTitles;
      print('     ✓ Found alternates for ${altTitlesMap.length} poems');
      print(
        '     ✓ Identified ${harvestResult.duplicatePaths.length} duplicates '
        'to skip',
      );

      processedFiles += jsonFiles.length;

      // Filter out duplicates from processing list
      final uniqueJsonFiles = jsonFiles
          .where((f) => !harvestResult.duplicatePaths.contains(f.path))
          .toList();

      // Author Registry state
      final authorNameToId = <String, int>{};
      final authorIdToCount = <int, int>{};
      var nextAuthorId = 1;
      var nextPoemId = 1;

      // Batch queues
      final poemsBatch = <Map<String, dynamic>>[];
      final poemAuthorsBatch = <Map<String, dynamic>>[];
      // We don't batch authors incrementally because we update counts.
      // We insert them all at the end.

      // Phase 2: Process files and build database
      // Chunk files into batches for efficient bulk insert
      var langPoems = 0; // Initialize counter for this language
      final batches = <List<File>>[];
      for (var i = 0; i < uniqueJsonFiles.length; i += _dbInsertBatchSize) {
        batches.add(
          uniqueJsonFiles.skip(i).take(_dbInsertBatchSize).toList(),
        );
      }

      print(
        '     ℹ️  Processing ${batches.length} batches using '
        '${Platform.numberOfProcessors} workers',
      );

      // Worker queue: Spawns N workers, each processes batches from the shared
      // list
      final workers = List.generate(Platform.numberOfProcessors, (_) async {
        while (batches.isNotEmpty) {
          final batch = batches.removeLast();

          // Prepare data for Isolate
          final filePaths = batch.map((f) => f.path).toList();

          // Run CPU-intensive parsing in a separate isolate
          final poemsData = await runBatchInIsolate(
            filePaths,
            langCode,
            altTitlesMap,
          );

          if (poemsData.isNotEmpty) {
            // Process the batch result on main thread to assign IDs
            // and manage relations.
            for (final p in poemsData) {
              final poemId = nextPoemId++;
              p['id'] = poemId; // Assign manual ID

              final rawAuthors = p['raw_authors'] as List<String>;
              // Denormalize author names for FTS (comma separated)
              p['author_names'] = rawAuthors.join(', ');

              // We remove 'raw_authors' before insert to avoid SQL error?
              // Only if we pass the map directly. batchInsertPoems extracts
              // specific fields, so it's fine to keep extra fields in the map.

              for (final authorName in rawAuthors) {
                var authorId = authorNameToId[authorName];
                if (authorId == null) {
                  authorId = nextAuthorId++;
                  authorNameToId[authorName] = authorId;
                  authorIdToCount[authorId] = 0;
                }

                authorIdToCount[authorId] = authorIdToCount[authorId]! + 1;

                poemAuthorsBatch.add({
                  'poem_id': poemId,
                  'author_id': authorId,
                });
              }

              poemsBatch.add(p);
            }

            // Flush batches if they get too big
            if (poemsBatch.length >= _dbInsertBatchSize) {
              await db.batchInsertPoems(poemsBatch);
              await db.batchInsertPoemAuthors(poemAuthorsBatch);

              langPoems += poemsBatch.length;
              totalPoems += poemsBatch.length;
              print('     ... $totalPoems poems processed');

              poemsBatch.clear();
              poemAuthorsBatch.clear();
            }
          }

          skippedPoems += batch.length - poemsData.length;
        }
      });

      await Future.wait(workers);

      // Flush remaining items
      if (poemsBatch.isNotEmpty) {
        await db.batchInsertPoems(poemsBatch);
        await db.batchInsertPoemAuthors(poemAuthorsBatch);
        langPoems += poemsBatch.length;
        totalPoems += poemsBatch.length;
      }

      print('\n  👥 Inserting ${authorNameToId.length} authors...');
      // Prepare authors for batch insert
      final authorsList = authorNameToId.entries.map((entry) {
        return {
          'id': entry.value,
          'name': entry.key,
          'poem_count': authorIdToCount[entry.value] ?? 0,
        };
      }).toList();

      // Insert authors in batches
      for (var i = 0; i < authorsList.length; i += _dbInsertBatchSize) {
        final end = (i + _dbInsertBatchSize < authorsList.length)
            ? i + _dbInsertBatchSize
            : authorsList.length;
        await db.batchInsertAuthors(authorsList.sublist(i, end));
      }

      // Rebuild FTS
      print('\n  🏗️  Building FTS index...');
      await db.customStatement(
        'INSERT INTO poems_fts (rowid, title, author, body, alt_titles) '
        'SELECT id, title, author_names, body, alt_titles FROM poems',
      );

      // Restore triggers
      print('  🔄 Restoring FTS triggers...');
      await db.createFtsTriggers();

      print('  🧹 Vacuuming database...');
      await db.customStatement('VACUUM;');

      // Insert Metadata
      print('  📝 Inserting metadata...');
      await db
          .into(db.metadata)
          .insert(
            MetadataCompanion.insert(
              key: 'license',
              value: 'CC BY-SA 4.0 / PoeTree',
            ),
          );

      await db.close();
      print('     ✓ $langPoems poems from $langCode');
    }

    print('\n  📊 Summary:');
    print('     • Total poems: $totalPoems');
    print('     • Skipped: $skippedPoems');
    print('     • Files processed: $processedFiles');
  }

  /// Compress all generated .db files to .zst using Isolates
  Future<void> compressDatabases(List<String> selectedLanguages) async {
    final dbDir = Directory(dbOutputDir);
    if (!dbDir.existsSync()) return;

    final dbFiles = dbDir.listSync().whereType<File>().where(
      (f) {
        if (!f.path.endsWith('.db')) return false;

        // Extract language code from filename (e.g., "en.db" -> "en")
        final filename = path.basename(f.path);
        final lang = filename.substring(0, filename.length - 3);

        if (!selectedLanguages.contains(lang)) return false;

        // Check if .zst file already exists
        final zstFile = File(path.setExtension(f.path, '.db.zst'));
        if (zstFile.existsSync()) {
          print('     ⏭️  Skipping $lang compression (already compressed)');
          return false;
        }

        return true;
      },
    ).toList();

    if (dbFiles.isEmpty) {
      print('No databases found to compress.');
      return;
    }

    print('     ℹ️  Compressing ${dbFiles.length} databases in parallel...');

    // Note: We don't delete during compression
    // Deletion happens in _cleanFilesAfter if --clean-after=db is specified
    await Future.wait(
      dbFiles.map((file) => compressor(file.path)),
    );
  }

  /// Generate manifest.json for all .db.zst files
  Future<void> generateManifest() async {
    final dbDir = Directory(dbOutputDir);
    if (!dbDir.existsSync()) return;

    final zstFiles = dbDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db.zst'))
        .toList();

    final manifest = <String, Map<String, dynamic>>{};

    // PoeTree attribution text
    const licenseText =
        'This dataset is derived from the PoeTree corpus (CC BY-SA 4.0). '
        'See README for full attribution.';

    const licenseObj = {
      'text': licenseText,
      'url': 'https://creativecommons.org/licenses/by-sa/4.0/',
    };

    // Using a fixed version for now as requested
    const poetreeVersion = '1.0';
    const internalVersion = 1;
    const versionObj = '$poetreeVersion+$internalVersion';

    for (final file in zstFiles) {
      final filename = path.basename(file.path);
      // Lang code is filename minus ".db.zst"
      final lang = filename.replaceAll('.db.zst', '');

      final bytes = await file.readAsBytes();
      final size = bytes.length;
      final hash = md5.convert(bytes).toString();

      manifest[lang] = {
        'file': filename,
        'name': _languageNames[lang] ?? lang,
        'size': size,
        'hash': hash,
        'version': versionObj,
        'license': licenseObj,
      };
    }

    final manifestFile = File(path.join(dbDir.path, 'manifest.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await manifestFile.writeAsString(encoder.convert(manifest));

    print('     ✓ Manifest generated with ${manifest.length} entries');
  }

  /// Drop FTS triggers to speed up insertion
  Future<void> _dropFtsTriggers(AppDatabase db) async {
    print('  ⚡ Disabling FTS triggers for bulk insert...');
    await db.customStatement('DROP TRIGGER IF EXISTS poems_ai');
    await db.customStatement('DROP TRIGGER IF EXISTS poems_ad');
    await db.customStatement('DROP TRIGGER IF EXISTS poems_au');
  }
}

/// Extract and map PoeTree JSON to Map structure for JSON insert
/// Extract and map PoeTree JSON to Map structure for JSON insert
Map<String, dynamic>? extractPoemData(
  Map<String, dynamic> data,
  String langCode, [
  List<String>? altTitles,
]) {
  try {
    // Extract title (may be null)
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      return null; // Skip poems without titles
    }

    // Extract author name(s)
    final authorData = data['author'];
    List<String> authors;

    if (authorData is List) {
      // Multiple authors
      authors = authorData
          .cast<Map<String, dynamic>>()
          .map((a) => a['name'] as String?)
          .where((n) => n != null && n.isNotEmpty)
          .cast<String>()
          .toList();
      if (authors.isEmpty) return null;
    } else if (authorData is Map<String, dynamic>) {
      final authorName = authorData['name'] as String? ?? '';
      if (authorName.isEmpty) return null;
      authors = [authorName];
    } else {
      return null;
    }

    // Encode authors and alternative titles as JSON
    final altTitlesJson = altTitles != null && altTitles.isNotEmpty
        ? json.encode(altTitles)
        : null;

    // Extract body - concatenate line texts, stripping annotations
    final bodyData = data['body'] as List<dynamic>?;
    if (bodyData == null || bodyData.isEmpty) {
      return null;
    }

    final lines = bodyData
        .cast<Map<String, dynamic>>()
        .map((line) => line['text'] as String?)
        .where((text) => text != null && text.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    final body = lines.join('\n');

    // Extract year - prefer year_created, fallback to source.year_published
    // Store as JSON list for ranges, string for single years
    String? year;
    final yearCreated = data['year_created'];
    if (yearCreated != null) {
      if (yearCreated is int) {
        year = yearCreated.toString();
      } else if (yearCreated is List && yearCreated.isNotEmpty) {
        // Time span like [1800, 1802] - store as JSON list
        year = json.encode(yearCreated);
      }
    }

    // Fallback to publication year
    if (year == null) {
      final source = data['source'] as Map<String, dynamic>?;
      final yearPub = source?['year_published'];
      if (yearPub is int) {
        year = yearPub.toString();
      }
    }

    return {
      'title': title,
      'raw_authors': authors, // Pass raw list for main thread processing
      'body': body,
      'year': year,
      'alt_titles': altTitlesJson,
    };
  } catch (e) {
    // Skip malformed poems
    return null;
  }
}

class DuplicateHarvestResult {
  DuplicateHarvestResult(this.altTitles, this.duplicatePaths);

  final Map<String, List<String>> altTitles;
  final Set<String> duplicatePaths;
}

/// Harvest alternative titles from duplicate poems
Future<DuplicateHarvestResult> harvestDuplicates(List<File> files) async {
  final filePaths = files.map((f) => f.path).toList();
  final cpuCount = Platform.numberOfProcessors;
  // Use fewer isolates for small batches to avoid overhead
  final isolateCount = (filePaths.length / _filesPerHarvestIsolate)
      .ceil()
      .clamp(1, cpuCount);

  if (filePaths.isEmpty) {
    return DuplicateHarvestResult({}, {});
  }

  print('     ℹ️  Spawning $isolateCount isolates for harvesting...');

  final chunkSize = (filePaths.length / isolateCount).ceil();
  final futures = <Future<DuplicateHarvestResult>>[];

  for (var i = 0; i < isolateCount; i++) {
    final start = i * chunkSize;
    if (start >= filePaths.length) break;
    final end = (start + chunkSize < filePaths.length)
        ? start + chunkSize
        : filePaths.length;

    final chunk = filePaths.sublist(start, end);

    futures.add(Isolate.run(() => harvestChunk(chunk)));
  }

  final results = await Future.wait(futures);

  // Merge results
  final mergedAltTitles = <String, List<String>>{};
  final mergedDuplicatePaths = <String>{};

  for (final result in results) {
    mergedDuplicatePaths.addAll(result.duplicatePaths);

    result.altTitles.forEach((key, values) {
      if (!mergedAltTitles.containsKey(key)) {
        mergedAltTitles[key] = [];
      }
      mergedAltTitles[key]!.addAll(values);
    });
  }

  return DuplicateHarvestResult(mergedAltTitles, mergedDuplicatePaths);
}

/// Isolate entry point for processing a chunk of files
Future<DuplicateHarvestResult> harvestChunk(List<String> filePaths) async {
  final altTitles = <String, List<String>>{};
  final duplicatePaths = <String>{};

  for (final filePath in filePaths) {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      final duplicateOf = data['duplicate'];
      final title = data['title'] as String?;

      if (duplicateOf != null && duplicateOf != false) {
        duplicatePaths.add(filePath);
        if (title != null) {
          final dupId = duplicateOf.toString();
          if (!altTitles.containsKey(dupId)) {
            altTitles[dupId] = [];
          }
          altTitles[dupId]!.add(title);
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  return DuplicateHarvestResult(altTitles, duplicatePaths);
}

/// Process a batch of files in an isolate
Future<List<Map<String, dynamic>>> processBatch(
  List<String> filePaths,
  String langCode,
  Map<String, List<String>> altTitlesMap,
) async {
  final currentBatch = <Map<String, dynamic>>[];

  for (final filePath in filePaths) {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Note: We already filtered known duplicates, but we keep this check
      // just in case data inconsistencies or if we want to be safe.
      if (data['duplicate'] != null && data['duplicate'] != false) {
        continue;
      }

      // Get alternative titles if any
      final id = data['id'].toString();
      final altTitles = altTitlesMap[id];

      final poem = extractPoemData(data, langCode, altTitles);
      if (poem != null) {
        currentBatch.add(poem);
      }
    } catch (e) {
      continue;
    }
  }
  return currentBatch;
}

Future<List<Map<String, dynamic>>> runBatchInIsolate(
  List<String> filePaths,
  String langCode,
  Map<String, List<String>> altTitlesMap,
) {
  return Isolate.run(
    () => processBatch(filePaths, langCode, altTitlesMap),
  );
}

/// Compress a single file using Zstandard
Future<void> compressFile(String filePath) async {
  final input = File(filePath);
  final output = File('$filePath.zst');

  final bytes = await input.readAsBytes();
  // Use ZstdCodec for compression with max level
  final codec = ZstdCodec(level: 22);
  final compressed = codec.encode(bytes);
  await output.writeAsBytes(compressed);
}
