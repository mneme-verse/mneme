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
    final client = clientFor({'ru': entry(file: 'ru.db.zst')});
    final pack = await client.packFor('ru');

    expect(pack.file, 'ru.db.zst');
    final url = client.packUrl(pack);
    expect(
      url.toString(),
      '${corpusReleaseBase(corpusReleaseTag)}ru.db.zst',
    );
  });

  test('manifest-controlled file names cannot traverse directories', () async {
    for (final file in [
      '../../outside.db.zst',
      'sub/ru.db.zst',
      r'sub\ru.db.zst',
      '/abs.db.zst',
    ]) {
      await expectLater(
        clientFor({'ru': entry(file: file)}).packFor('ru'),
        throwsA(isA<CorpusManifestException>()),
        reason: 'file "$file" must be rejected',
      );
    }
  });
}
