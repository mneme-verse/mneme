import 'dart:io';

import 'package:dio/dio.dart';
import 'package:es_compression/zstd.dart' as es;

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

class MockEsZstdCodec extends Mock implements es.ZstdCodec {}

class MockZstdDecoder extends Mock implements es.ZstdDecoder {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late MockZstandard mockZstandard;
  late MockEsZstdCodec mockEsZstd;
  late DatabaseDownloader downloader;
  late Directory tempDir;
  late FakeDio fakeDio;

  setUpAll(() {
    registerFallbackValue('fallback');
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const Stream<List<int>>.empty());
  });

  setUp(() {
    mockZstandard = MockZstandard();
    mockEsZstd = MockEsZstdCodec();
    final mockDecoder = MockZstdDecoder();
    when(() => mockEsZstd.decoder).thenReturn(mockDecoder);
    when(() => mockDecoder.bind(any())).thenAnswer(
      (invocation) => (invocation.positionalArguments[0] as Stream<List<int>>)
          .map((_) => [4, 5, 6]),
    );
    tempDir = Directory.systemTemp.createTempSync();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
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
      downloader = DatabaseDownloader(
        dio: FakeDio(),
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
      );
      File(p.join(tempDir.path, 'en.db')).createSync();
      expect(await downloader.isDatabaseAvailable('en'), isTrue);
    });

    test('isDatabaseAvailable returns false if file does not exist', () async {
      downloader = DatabaseDownloader(
        dio: FakeDio(),
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
      );
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
      downloader = DatabaseDownloader(
        dio: fakeDio,
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
      );

      // On Linux (test env), we use es_compression
      when(
        () => mockEsZstd.decode(any()),
      ).thenReturn(decompressedData);

      // We still mock native zstandard just in case, but it shouldn't be called
      when(
        () => mockZstandard.decompress(any()),
      ).thenAnswer((_) async => decompressedData);

      await downloader.downloadDatabase(
        lang: 'en',
        url: 'http://example.com/en.db.zst',
        expectedSize: 3,
      );

      expect(File(dbPath).existsSync(), isTrue);
      expect(File(dbPath).readAsBytesSync(), equals(decompressedData));
      expect(File(zstPath).existsSync(), isFalse); // Should be deleted
    });

    test('downloadDatabase decompresses correctly on non-Linux', () async {
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
      downloader = DatabaseDownloader(
        dio: fakeDio,
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
        isLinux: false,
      );

      when(
        () => mockZstandard.decompress(any()),
      ).thenAnswer((_) async => decompressedData);

      await downloader.downloadDatabase(
        lang: 'en',
        url: 'http://example.com/en.db.zst',
        expectedSize: 3,
      );

      expect(File(dbPath).existsSync(), isTrue);
      expect(File(dbPath).readAsBytesSync(), equals(decompressedData));
      expect(File(zstPath).existsSync(), isFalse); // Should be deleted
    });

    test(
      'downloadDatabase throws if decompressedBytes is null on non-Linux',
      () async {
        final zstPath = p.join(tempDir.path, 'en.db.zst');
        final dbPath = p.join(tempDir.path, 'en.db');
        final compressedData = [1, 2, 3];

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            final path = savePath as String;
            File(path).writeAsBytesSync(compressedData);
          },
        );
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
          isLinux: false,
        );

        when(
          () => mockZstandard.decompress(any()),
        ).thenAnswer((_) async => null);

        expect(
          () => downloader.downloadDatabase(
            lang: 'en',
            url: 'http://example.com/en.db.zst',
            expectedSize: 3,
          ),
          throwsException,
        );

        expect(File(dbPath).existsSync(), isFalse);
        expect(File(zstPath).existsSync(), isFalse);
      },
    );

    test('downloadDatabase cleans up if download fails', () async {
      final zstPath = p.join(tempDir.path, 'en.db.zst');

      fakeDio = FakeDio(
        onDownload: (url, savePath) {
          final path = savePath as String;
          File(path).writeAsBytesSync([1]);
          throw Exception('Network error');
        },
      );
      downloader = DatabaseDownloader(
        dio: fakeDio,
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
      );

      expect(
        () => downloader.downloadDatabase(
          lang: 'en',
          url: 'url',
          expectedSize: 1,
        ),
        throwsException,
      );

      expect(File(zstPath).existsSync(), isFalse);
    });

    test(
      'downloadDatabase cleans up and throws on size mismatch',
      () async {
        final zstPath = p.join(tempDir.path, 'en.db.zst');
        final compressedData = [1, 2, 3];

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            final path = savePath as String;
            File(path).writeAsBytesSync(compressedData);
          },
        );
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
        );

        try {
          await downloader.downloadDatabase(
            lang: 'en',
            url: 'http://example.com/en.db.zst',
            expectedSize: 999, // does not match actual 3 bytes
          );
          fail('Should have thrown');
        } on Exception catch (e) {
          expect(e.toString(), contains('size mismatch'));
        }

        // .zst file should be cleaned up
        expect(File(zstPath).existsSync(), isFalse);
      },
    );

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
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
        );

        final mockDecoder = MockZstdDecoder();
        when(
          () => mockEsZstd.decoder,
        ).thenReturn(mockDecoder);

        when(() => mockDecoder.bind(any())).thenAnswer(
          (_) => Stream.error(const FormatException('Invalid data')),
        );

        // Also mock for non-Linux just in case
        when(
          () => mockZstandard.decompress(any()),
        ).thenAnswer((_) async => null);

        // Expect an exception. The type message differs based on path,
        // but we just check it throws.
        expect(
          () => downloader.downloadDatabase(
            lang: 'en',
            url: 'url',
            expectedSize: 3,
          ),
          throwsException,
        );

        // Ensure cleanup checks happen
        expect(File(zstPath).existsSync(), isFalse);
        expect(File(dbPath).existsSync(), isFalse);
      },
    );

    test('downloadDatabase cleans up if decompression throws', () async {
      final zstPath = p.join(tempDir.path, 'en.db.zst');
      final dbPath = p.join(tempDir.path, 'en.db');

      fakeDio = FakeDio(
        onDownload: (url, savePath) {
          final path = savePath as String;
          File(path).writeAsBytesSync([1, 2, 3]);
        },
      );
      downloader = DatabaseDownloader(
        dio: fakeDio,
        zstandard: mockZstandard,
        esZstd: mockEsZstd,
      );

      final mockDecoder = MockZstdDecoder();
      when(() => mockEsZstd.decoder).thenReturn(mockDecoder);
      when(() => mockDecoder.bind(any())).thenAnswer(
        (_) => Stream.error(Exception('Fail')),
      );

      when(() => mockZstandard.decompress(any())).thenThrow(Exception('Fail'));

      expect(
        () => downloader.downloadDatabase(
          lang: 'en',
          url: 'url',
          expectedSize: 3,
        ),
        throwsException,
      );

      expect(File(zstPath).existsSync(), isFalse);
      expect(File(dbPath).existsSync(), isFalse);
    });

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
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
        );

        final mockDecoder = MockZstdDecoder();
        when(() => mockEsZstd.decoder).thenReturn(mockDecoder);
        when(() => mockDecoder.bind(any())).thenAnswer(
          (_) => Stream.error(Exception('Corrupt data')),
        );

        when(
          () => mockZstandard.decompress(any()),
        ).thenThrow(Exception('Corrupt data'));

        try {
          await downloader.downloadDatabase(
            lang: 'en',
            url: 'url',
            expectedSize: 1,
          );
          fail('Should have thrown');
        } on Exception catch (e) {
          expect(e, isException);
        }

        expect(File(dbPath).existsSync(), isFalse);
      },
    );

    test(
      'downloadDatabase succeeds if hash matches (SHA-256 of compressed)',
      () async {
        final dbPath = p.join(tempDir.path, 'en.db');
        final compressedData = Uint8List.fromList([1, 2, 3]);
        final decompressedData = Uint8List.fromList([4, 5, 6]);
        // SHA-256 of [1, 2, 3] is
        // 039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81
        const expectedHash =
            '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81';

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            File(savePath as String).writeAsBytesSync(compressedData);
          },
        );
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
        );

        when(() => mockEsZstd.decode(any())).thenReturn(decompressedData);

        await downloader.downloadDatabase(
          lang: 'en',
          url: 'url',
          expectedSize: 3,
          expectedHash: expectedHash,
        );

        expect(File(dbPath).existsSync(), isTrue);
        expect(File(dbPath).readAsBytesSync(), equals(decompressedData));
      },
    );

    test(
      'downloadDatabase fails and cleans up if compressed hash mismatches',
      () async {
        final dbPath = p.join(tempDir.path, 'en.db');
        final zstPath = p.join(tempDir.path, 'en.db.zst');
        final compressedData = Uint8List.fromList([1]);
        const wrongHash = 'wrong-hash';

        fakeDio = FakeDio(
          onDownload: (url, savePath) {
            File(savePath as String).writeAsBytesSync(compressedData);
          },
        );
        downloader = DatabaseDownloader(
          dio: fakeDio,
          zstandard: mockZstandard,
          esZstd: mockEsZstd,
        );

        try {
          await downloader.downloadDatabase(
            lang: 'en',
            url: 'url',
            expectedSize: 1,
            expectedHash: wrongHash,
          );
          fail('Should have thrown');
        } on DatabaseDownloadException catch (e) {
          expect(e.toString(), contains('Hash mismatch'));
        }

        expect(File(dbPath).existsSync(), isFalse);
        expect(File(zstPath).existsSync(), isFalse);
      },
    );

    test('isDatabaseAvailable throws ArgumentError for invalid lang', () async {
      downloader = DatabaseDownloader();
      expect(
        () => downloader.isDatabaseAvailable('../en'),
        throwsArgumentError,
      );
    });

    test('downloadDatabase throws ArgumentError for invalid lang', () async {
      downloader = DatabaseDownloader();
      expect(
        () => downloader.downloadDatabase(
          lang: '../en',
          url: 'url',
          expectedSize: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
