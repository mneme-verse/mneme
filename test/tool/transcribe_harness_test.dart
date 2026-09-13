import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

// Import the tool file relatively, matching test/tool/builder_test.dart.
import '../../tool/transcribe_harness.dart';

void main() {
  group('WAV fixture encoding', () {
    test('silence encodes as 16 kHz mono 16-bit with zeroed samples', () {
      final bytes = encodeWavMono16(silenceSamples(16000));
      final info = parseWavHeader(bytes);

      expect(info.sampleRate, harnessSampleRate);
      expect(info.channels, 1);
      expect(info.bitsPerSample, 16);
      expect(info.frames, 16000);
      expect(bytes.length, 44 + 16000 * 2);
      expect(bytes.sublist(44), everyElement(0));
    });

    test('sine starts near zero and reaches near full scale', () {
      final samples = sineSamples(16000, harnessSampleRate, harnessSineHz);

      expect(samples.first.abs(), lessThan(3000));
      final peak = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      expect(peak, greaterThan(32000));
    });

    test('noise is deterministic for one seed and differs across seeds', () {
      expect(noiseSamples(512), orderedEquals(noiseSamples(512)));
      expect(
        noiseSamples(512, seed: 1),
        isNot(orderedEquals(noiseSamples(512))),
      );
    });

    test('header parser rejects truncated and non-WAV bytes', () {
      expect(
        () => parseWavHeader(Uint8List.fromList(List.filled(10, 0))),
        throwsFormatException,
      );
      final garbage = Uint8List.fromList(List.filled(100, 0x41));
      expect(() => parseWavHeader(garbage), throwsFormatException);
    });

    test('header parser rejects a corrupted data size', () {
      final bytes = Uint8List.fromList(encodeWavMono16(silenceSamples(8)));
      ByteData.sublistView(bytes).setUint32(40, 9999, Endian.little);
      expect(() => parseWavHeader(bytes), throwsFormatException);
    });
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('transcribe_harness_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('write then verify passes with three pinned fixtures', () async {
      final entries = await writeFixtures(tempDir);

      expect(entries.map((e) => e['file']), containsAll(harnessFixtureNames));
      expect(await verifyFixtures(tempDir), isEmpty);
      expect(
        File('${tempDir.path}/$harnessManifestName').existsSync(),
        isTrue,
      );
    });

    test('tampered fixture bytes are reported', () async {
      await writeFixtures(tempDir);
      final victim = File('${tempDir.path}/silence_1s.wav');
      final bytes = await victim.readAsBytes();
      bytes[100] ^= 0xFF;
      await victim.writeAsBytes(bytes, flush: true);

      final problems = await verifyFixtures(tempDir);
      expect(problems, hasLength(1));
      expect(problems.single, contains('silence_1s.wav'));
    });

    test('missing manifest is reported', () async {
      expect(await verifyFixtures(tempDir), hasLength(1));
    });
  });

  group('revision pin', () {
    test('matches ignoring case and surrounding whitespace', () {
      expect(
        revisionMatches(
          '  585B98F7E66777D16F2DA734CEEDAA7398060FA7\n',
          '585b98f7e66777d16f2da734ceedaa7398060fa7',
        ),
        isTrue,
      );
    });

    test('rejects a different revision', () {
      expect(
        revisionMatches(
          'deadbeef',
          '585b98f7e66777d16f2da734ceedaa7398060fa7',
        ),
        isFalse,
      );
    });
  });

  test('sha256 uses lowercase hex', () {
    expect(
      sha256Hex([]),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });
}
