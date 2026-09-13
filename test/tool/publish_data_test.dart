import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the tool file relatively
import '../../tool/publish_data.dart';
import 'publish_data_test.mocks.dart';

// Create a mock for FileSystem since Mockito can't mock abstract classes nicely
// without build_runner, and we want to keep it simple.
// Or we can just use the memory filesystem or real temp file system.
// Actually, let's use the real filesystem in temp dir for FS tests,
// and Mockito for FileSystem interface if we want pure unit tests.
// Let's use GenerateMocks for FS and ProcessResult.

@GenerateMocks([FileSystem, Directory, File])
void main() {
  late MockFileSystem mockFs;
  late MockDirectory mockDbDir;
  late MockFile mockManifestFile;
  late MockFile mockZstFile;
  late List<String> commandLog;

  // Custom ProcessRunner for testing
  Future<ProcessResult> mockProcessRunner(
    String executable,
    List<String> args, {
    bool runInShell = false,
  }) async {
    commandLog.add('$executable ${args.join(" ")}');

    // Simulate `gh release view` failing (release doesn't exist)
    if (args.contains('view') && args.contains('data-v1.0+1')) {
      return ProcessResult(0, 1, '', 'Release not found');
    }

    return ProcessResult(0, 0, '', '');
  }

  setUp(() {
    mockFs = MockFileSystem();
    mockDbDir = MockDirectory();
    mockManifestFile = MockFile();
    mockZstFile = MockFile();
    commandLog = [];

    // Setup default happy path
    when(mockFs.directory(any)).thenReturn(mockDbDir);
    when(mockDbDir.existsSync()).thenReturn(true);
    when(mockDbDir.path).thenReturn('assets/database');

    // List returns one ZST file
    when(mockDbDir.listSync()).thenReturn([mockZstFile]);
    when(mockZstFile.path).thenReturn('assets/database/en.db.zst');
    when(mockZstFile.readAsBytes()).thenAnswer((_) async => Uint8List(0));

    // Manifest file
    // Use precise path match or any
    when(
      mockFs.file('assets/database/manifest.json'),
    ).thenReturn(mockManifestFile);
    when(mockManifestFile.existsSync()).thenReturn(true);
    when(mockManifestFile.path).thenReturn('assets/database/manifest.json');
    when(mockManifestFile.readAsString()).thenAnswer(
      (_) async => jsonEncode({
        'license': {'text': 'dummy'},
        'en': {
          'version': '1.0+1',
          'file': 'en.db.zst',
        },
      }),
    );
  });

  group('DataPublisher', () {
    test('throws if db directory missing', () async {
      when(mockDbDir.existsSync()).thenReturn(false);
      final publisher = DataPublisher(
        dbOutputDir: 'missing',
        processRunner: mockProcessRunner,
        fs: mockFs,
      );

      expect(publisher.publish(), throwsException);
    });

    test('throws if no zst files found', () async {
      when(mockDbDir.listSync()).thenReturn([]);
      final publisher = DataPublisher(
        dbOutputDir: 'empty',
        processRunner: mockProcessRunner,
        fs: mockFs,
      );

      expect(
        publisher.publish(),
        throwsA(predicate((e) => e.toString().contains('No .db.zst files'))),
      );
    });

    test('throws if manifest missing', () async {
      when(mockManifestFile.existsSync()).thenReturn(false);
      final publisher = DataPublisher(
        dbOutputDir: 'dir',
        processRunner: mockProcessRunner,
        fs: mockFs,
      );

      expect(
        publisher.publish(),
        throwsA(
          predicate((e) => e.toString().contains('manifest.json not found')),
        ),
      );
    });

    test('throws if the local manifest is not an object', () async {
      when(mockManifestFile.readAsString()).thenAnswer((_) async => '[]');
      final publisher = DataPublisher(
        dbOutputDir: 'assets/database',
        processRunner: mockProcessRunner,
        fs: mockFs,
      );

      expect(
        publisher.publish(),
        throwsA(
          predicate((e) => e.toString().contains('not a JSON object')),
        ),
      );
    });

    test('successfully releases new version', () async {
      final publisher = DataPublisher(
        dbOutputDir: 'assets/database',
        processRunner: mockProcessRunner,
        fs: mockFs,
      );

      await publisher.publish();

      // Check command log
      // 1. Check if release exists
      expect(commandLog[0], 'gh release view data-v1.0+1');

      // 2. Create release
      expect(commandLog[1], contains('gh release create data-v1.0+1'));
      expect(commandLog[1], contains('--title Data Release v1.0+1'));

      // 3. Upload assets
      expect(commandLog[2], contains('gh release upload data-v1.0+1'));
      expect(commandLog[2], contains('assets/database/en.db.zst'));
      expect(commandLog[2], contains('assets/database/manifest.json'));
    });

    test('merges with the published manifest on existing releases', () async {
      Future<ProcessResult> existingRunner(
        String executable,
        List<String> args, {
        bool runInShell = false,
      }) async {
        commandLog.add('$executable ${args.join(" ")}');
        if (args.contains('view')) {
          return ProcessResult(0, 0, '', '');
        }
        if (args.contains('download')) {
          final dir = args[args.indexOf('--dir') + 1];
          File('$dir/manifest.json').writeAsStringSync(
            jsonEncode({
              'license': {'text': 'dummy'},
              'en': {'version': '1.0+1', 'file': 'en.db.zst'},
            }),
          );
          return ProcessResult(0, 0, '', '');
        }
        return ProcessResult(0, 0, '', '');
      }

      final publisher = DataPublisher(
        dbOutputDir: 'assets/database',
        processRunner: existingRunner,
        fs: mockFs,
      );

      await publisher.publish();

      final upload = commandLog.firstWhere((entry) => entry.contains('upload'));
      // The merged manifest lives outside the local database dir.
      expect(upload, contains('mneme-publish'));
      expect(upload, isNot(contains('assets/database/manifest.json')));
      expect(upload, contains('assets/database/en.db.zst'));
    });

    test('aborts instead of clobbering on merge failure', () async {
      final publisher = DataPublisher(
        dbOutputDir: 'assets/database',
        processRunner: (executable, args, {runInShell = false}) {
          commandLog.add('$executable ${args.join(" ")}');
          if (args.contains('--json')) {
            // The release already publishes a manifest...
            return Future.value(
              ProcessResult(0, 0, 'manifest.json\nen.db.zst', ''),
            );
          }
          // ...but its download fails transiently.
          return Future.value(
            ProcessResult(0, args.contains('view') ? 0 : 1, '', 'gone'),
          );
        },
        fs: mockFs,
      );
      await expectLater(publisher.publish(), throwsException);
      expect(
        commandLog.any((entry) => entry.contains('upload')),
        isFalse,
        reason: 'no upload may run when the merge cannot be read',
      );
    });

    test('mergeManifests keeps other languages and lets local win', () {
      final merged = mergeManifests(
        {
          'license': {'text': 'dummy'},
          'en': {'version': '1.0+1'},
          'ru': {'version': 'stale'},
        },
        {
          'ru': {'version': '1.0+2'},
        },
      );

      expect(merged['license'], {'text': 'dummy'});
      expect(merged['en'], {'version': '1.0+1'});
      expect(merged['ru'], {'version': '1.0+2'});
    });
  });
}
