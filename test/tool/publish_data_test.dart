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
  });
}
