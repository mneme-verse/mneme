import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mneme/resources/corpus_manifest.dart';

void main() {
  const sha =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  Map<String, Object> entry({required String file}) => {
    'file': file,
    'sha256': sha,
    'size': 42,
    'version': corpusDataVersion,
    'schema_version': 2,
  };

  CorpusManifestClient clientFor(Map<String, Object> manifest) {
    return CorpusManifestClient(
      client: MockClient((request) async {
        return http.Response(jsonEncode(manifest), 200);
      }),
    );
  }

  test('release tag derives from the shared corpus version', () {
    expect(corpusReleaseTag, corpusReleaseTagFor(corpusDataVersion));
    expect(corpusReleaseTag, 'data-v$corpusDataVersion');
  });

  test('pack URL stays inside the manifest release directory', () async {
    final client = clientFor({'ru': entry(file: 'ru.db.gz')});
    final pack = await client.packFor('ru');

    expect(pack.file, 'ru.db.gz');
    final url = client.packUrl(pack);
    expect(
      url.toString(),
      '${corpusReleaseBase(corpusReleaseTag)}ru.db.gz',
    );
  });

  test('manifest-controlled file names cannot traverse directories', () async {
    for (final file in [
      '../../outside.db.gz',
      'sub/ru.db.gz',
      r'sub\ru.db.gz',
      '/abs.db.gz',
      // Well-formed but not the language-keyed pack the connection opens.
      'other.db.gz',
    ]) {
      await expectLater(
        clientFor({'ru': entry(file: file)}).packFor('ru'),
        throwsA(isA<CorpusManifestException>()),
        reason: 'file "$file" must be rejected',
      );
    }
  });

  test('malformed manifests fail with a typed exception', () async {
    final badManifests = <String, Object>{
      'not JSON': 'this is not json',
      'JSON array': '[1, 2]',
      'JSON number': '42',
      'missing entry': jsonEncode({'en': entry(file: 'en.db.gz')}),
      'bad schema': jsonEncode({
        'ru': {...entry(file: 'ru.db.gz'), 'schema_version': 1},
      }),
      'bad hash': jsonEncode({
        'ru': {...entry(file: 'ru.db.gz'), 'sha256': 'xyz'},
      }),
      'bad size': jsonEncode({
        'ru': {...entry(file: 'ru.db.gz'), 'size': 0},
      }),
    };
    for (final body in badManifests.values) {
      final client = CorpusManifestClient(
        client: MockClient((_) async => http.Response(body.toString(), 200)),
      );
      await expectLater(
        client.packFor('ru'),
        throwsA(isA<CorpusManifestException>()),
      );
    }
  });

  test('manifest exception describes the problem', () {
    expect(
      const CorpusManifestException('gone').toString(),
      contains('gone'),
    );
  });
}
