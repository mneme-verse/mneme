import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/resources/resource_locks.dart';

void main() {
  test('dart locks mirror docs/model-lock.json', () {
    final lock =
        json.decode(File('docs/model-lock.json').readAsStringSync())
            as Map<String, dynamic>;
    final models = (lock['models'] as List).cast<Map<String, dynamic>>();

    final lockedById = {
      for (final model in models) model['id'] as String: model,
    };

    expect(
      lockedSpeechModels.length,
      models.length,
      reason: 'every locked model appears in Dart constants',
    );
    for (final dart in lockedSpeechModels) {
      final json = lockedById[dart.id];
      expect(json, isNotNull, reason: '${dart.id} missing from lock file');
      expect(dart.url, json!['url']);
      expect(dart.sha256, json['sha256']);
      expect(dart.sizeBytes, json['size_bytes']);
    }

    final defaultJson = lockedById[defaultSpeechModelId];
    expect(defaultJson, isNotNull);
    expect(defaultJson!['role'], 'streaming-baseline');

    expect(
      speechModelLicenseFiles.keys.toSet(),
      lockedById.keys.toSet(),
      reason: 'every locked model carries a license notice',
    );
    for (final license in speechModelLicenseFiles.values) {
      final textFile = 'docs/licenses/$license.txt';
      expect(
        File(textFile).existsSync(),
        isTrue,
        reason: '$textFile must ship with the repo',
      );
    }
  });

  test('lock file references license texts that exist', () {
    final lock =
        json.decode(File('docs/model-lock.json').readAsStringSync())
            as Map<String, dynamic>;
    final models = (lock['models'] as List).cast<Map<String, dynamic>>();
    for (final model in models) {
      final license = model['license'] as Map<String, dynamic>;
      expect(File(license['text_file'] as String).existsSync(), isTrue);
    }
  });
}
