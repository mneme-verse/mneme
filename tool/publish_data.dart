// CLI tool uses print for output.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const dbOutputDir = 'assets/database';

/// Process runner typedef for dependency injection
typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      bool runInShell,
    });

void main(List<String> args) async {
  final parser = _buildArgParser();

  try {
    final results = parser.parse(args);

    if (results['help'] as bool) {
      _printHelp(parser);
      return;
    }

    final publisher = DataPublisher(
      dbOutputDir: dbOutputDir,
    );

    await publisher.publish();
  } on ArgParserException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printHelp(parser);
    exit(1);
  } on Object catch (e) {
    stderr.writeln('Unexpected error: $e');
    exit(1);
  }
}

class DataPublisher {
  DataPublisher({
    required this.dbOutputDir,
    ProcessRunner? processRunner,
    this.fs = const LocalFileSystem(),
  }) : _processRunner = processRunner ?? Process.run;

  final String dbOutputDir;
  final ProcessRunner _processRunner;
  final FileSystem fs; // Helper interface for FS operations

  Future<void> publish() async {
    // 1. Validate Artifacts
    print('🔍 Validating artifacts...');
    final dbDir = fs.directory(dbOutputDir);
    if (!dbDir.existsSync()) {
      throw Exception('Database directory $dbOutputDir not found.');
    }

    final zstFiles = dbDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db.zst'))
        .toList();

    if (zstFiles.isEmpty) {
      throw Exception('No .db.zst files found in $dbOutputDir.');
    }

    final manifestFile = fs.file(path.join(dbDir.path, 'manifest.json'));
    if (!manifestFile.existsSync()) {
      throw Exception(
        'manifest.json not found in $dbOutputDir. Run builder first.',
      );
    }

    // 2. Validate Manifest (License validation moved to builder tests)
    final manifestContent = await manifestFile.readAsString();
    final manifest = json.decode(manifestContent) as Map<String, dynamic>;

    print('✅ Artifacts valid (${zstFiles.length} files + manifest)');

    // 3. Prepare Release Info
    String? version;
    for (final key in manifest.keys) {
      if (key == 'license') continue;
      final entry = manifest[key] as Map<String, dynamic>;
      if (entry.containsKey('version')) {
        version = entry['version'] as String;
        break;
      }
    }

    if (version == null) {
      throw Exception('Could not determine version from manifest.');
    }

    final tagName = 'data-v$version';
    print('📦 Preparing release: $tagName');

    // 4. Create Release
    print('🚀 Creating GitHub release...');

    final checkResult = await _processRunner('gh', [
      'release',
      'view',
      tagName,
    ]);

    if (checkResult.exitCode == 0) {
      print('ℹ️  Release $tagName already exists. Uploading artifacts...');
    } else {
      final createResult = await _processRunner('gh', [
        'release',
        'create',
        tagName,
        '--title',
        'Data Release v$version',
        '--notes',
        'Data release generated from PoeTree corpus.',
      ]);

      if (createResult.exitCode != 0) {
        throw Exception('Error creating release: ${createResult.stderr}');
      }
      print('✅ Release created.');
    }

    // 5. Upload Assets
    print('📤 Uploading assets...');
    final assetPaths = [
      ...zstFiles.map((f) => f.path),
      manifestFile.path,
    ];

    final uploadResult = await _processRunner('gh', [
      'release',
      'upload',
      tagName,
      ...assetPaths,
      '--clobber',
    ]);

    if (uploadResult.exitCode != 0) {
      throw Exception('Error uploading assets: ${uploadResult.stderr}');
    }

    print(
      '🎉 Release complete: https://github.com/mneme-verse/mneme/releases/tag/'
      '$tagName',
    );
  }
}

/// Simple abstraction for FileSystem to improve testability
abstract class FileSystem {
  const FileSystem();
  Directory directory(String path);
  File file(String path);
}

class LocalFileSystem extends FileSystem {
  const LocalFileSystem();
  @override
  Directory directory(String path) => Directory(path);
  @override
  File file(String path) => File(path);
}

ArgParser _buildArgParser() {
  return ArgParser()..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show help message',
  );
}

void _printHelp(ArgParser parser) {
  print('''
Publish Data Script - Automates GitHub Release for Data Artifacts

USAGE:
    dart run tool/publish_data.dart [OPTIONS]

OPTIONS:
${parser.usage}
''');
}
