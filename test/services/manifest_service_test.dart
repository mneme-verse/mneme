import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/services/manifest_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ManifestService manifestService;

  setUp(() {
    mockDio = MockDio();
    manifestService = ManifestService(dio: mockDio);
  });

  group('ManifestService', () {
    test('fetchManifest returns data on 200', () async {
      final mockResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'url'),
        statusCode: 200,
        data: {'test': 'data'},
      );

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => mockResponse,
      );

      final result = await manifestService.fetchManifest();

      expect(result, equals({'test': 'data'}));
      verify(() => mockDio.get<dynamic>(any())).called(1);
    });

    test('fetchManifest parses JSON string on 200', () async {
      final mockResponse = Response<String>(
        requestOptions: RequestOptions(path: 'url'),
        statusCode: 200,
        data: '{"test": "data"}',
      );

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => mockResponse,
      );

      final result = await manifestService.fetchManifest();

      expect(result, equals({'test': 'data'}));
    });

    test('fetchManifest throws exception on unexpected type', () async {
      final mockResponse = Response<int>(
        requestOptions: RequestOptions(path: 'url'),
        statusCode: 200,
        data: 123,
      );

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => mockResponse,
      );

      expect(
        () => manifestService.fetchManifest(),
        throwsException,
      );
    });

    test('fetchManifest throws exception on non-200', () async {
      final mockResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'url'),
        statusCode: 404,
        statusMessage: 'Not Found',
      );

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => mockResponse,
      );

      expect(
        () => manifestService.fetchManifest(),
        throwsException,
      );
    });

    test('fetchManifest throws exception on error', () async {
      when(() => mockDio.get<dynamic>(any())).thenThrow(
        Exception('Network error'),
      );

      expect(
        () => manifestService.fetchManifest(),
        throwsException,
      );
    });
  });
}
