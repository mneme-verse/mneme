import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/services/database_downloader.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:zstandard/zstandard.dart';

class FakeDio extends Fake implements Dio {
  FakeDio({this.onDownload});

  final void Function(String urlPath, dynamic savePath)? onDownload;

  @override
  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
    FileAccessMode fileAccessMode = FileAccessMode.write,
  }) async {
    onDownload?.call(urlPath, savePath);
    return Response(
      requestOptions: RequestOptions(path: urlPath),
      statusCode: 200,
    );
  }
}

class MockZstandard extends Mock implements Zstandard {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late MockZstandard mockZstandard;
  late DatabaseDownloader downloader;
  late Directory tempDir;
  late FakeDio fakeDio;

  setUpAll(() {
    registerFallbackValue('fallback');
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockZstandard = MockZstandard();
    tempDir = Directory.systemTemp.createTempSync();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DatabaseDownloader', () {
    test('isDatabaseAvailable returns true if file exists', () async {
      downloader = DatabaseDownloader(dio: FakeDio(), zstandard: mockZstandard);
      File(p.join(tempDir.path, 'en.db')).createSync();
      expect(await downloader.isDatabaseAvailable('en'), isTrue);
    });

    test('isDatabaseAvailable returns false if file does not exist', () async {
      downloader = DatabaseDownloader(dio: FakeDio(), zstandard: mockZstandard);
      expect(await downloader.isDatabaseAvailable('en'), isFalse);
    });

    test('downloadDatabase downloads and decompresses successfully', () async {
      final zstPath = p.join(tempDir.path, 'en.db.zst');
      final dbPath = p.join(tempDir.path, 'en.db');
      final compressedData = [1, 2, 3];
      final decompressedData = Uint8List.fromList([4, 5, 6]);

      fakeDio = FakeDio(
        onDownload: (url, savePath) {
          final path = savePath as String;
          File(path).writeAsBytesSync(compressedData);
        },
      );
      downloader = DatabaseDownloader(dio: fakeDio, zstandard: mockZstandard);

      when(
        () => mockZstandard.decompress(any()),
      ).thenAnswer((_) async => decompressedData);

      await downloader.downloadDatabase(
        lang: 'en',
        url: 'http://example.com/en.db.zst',
        expectedSize: 100,
      );

      expect(File(dbPath).existsSync(), isTrue);
      expect(File(dbPath).readAsBytesSync(), equals(decompressedData));
      expect(File(zstPath).existsSync(), isFalse); // Should be deleted
    });

    test('downloadDatabase cleans up if download fails', () async {
      final zstPath = p.join(tempDir.path, 'en.db.zst');

      fakeDio = FakeDio(
        onDownload: (url, savePath) {
          final path = savePath as String;
          File(path).writeAsBytesSync([1]);
          throw Exception('Network error');
        },
      );
      downloader = DatabaseDownloader(dio: fakeDio, zstandard: mockZstandard);

      expect(
        () => downloader.downloadDatabase(
          lang: 'en',
          url: 'url',
          expectedSize: 100,
        ),
        throwsException,
      );

      expect(File(zstPath).existsSync(), isFalse);
    });

    test(
      'downloadDatabase cleans up and throws if decompression returns null',
      () async {
        final zstPath = p.join(tempDir.path, 'en.db.zst');
        final dbPath = p.join(tempDir.path, 'en.db');

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            final path = savePath as String;
            File(path).writeAsBytesSync([1, 2, 3]);
          },
        );
        downloader = DatabaseDownloader(dio: fakeDio, zstandard: mockZstandard);

        when(
          () => mockZstandard.decompress(any()),
        ).thenAnswer((_) async => null);

        expect(
          () => downloader.downloadDatabase(
            lang: 'en',
            url: 'url',
            expectedSize: 100,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Decompression failed: Result is null'),
            ),
          ),
        );

        // Ensure cleanup checks happen
        expect(File(zstPath).existsSync(), isFalse);
        expect(File(dbPath).existsSync(), isFalse);
      },
    );

    test(
      'downloadDatabase cleans up db file if decompression throws',
      () async {
        final dbPath = p.join(tempDir.path, 'en.db');
        // Create db file beforehand to Verify cleanup
        File(dbPath).writeAsBytesSync([99]);

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            final path = savePath as String;
            File(path).writeAsBytesSync([1]);
          },
        );
        downloader = DatabaseDownloader(dio: fakeDio, zstandard: mockZstandard);

        when(
          () => mockZstandard.decompress(any()),
        ).thenThrow(Exception('Corrupt data'));

        try {
          await downloader.downloadDatabase(
            lang: 'en',
            url: 'url',
            expectedSize: 100,
          );
          fail('Should have thrown');
        } on Exception catch (e) {
          expect(e, isException);
        }

        expect(File(dbPath).existsSync(), isFalse);
      },
    );
  });
}
