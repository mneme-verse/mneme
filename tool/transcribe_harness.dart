// CLI tool uses print for output and simple error handling
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Sample rate the transcribe.cpp C API consumes: 16 kHz mono float PCM.
///
/// Fixtures are stored as 16-bit PCM WAV so any WAV reader (including the
/// example CLI's `wav.h`) loads them without resampling. The harness never
/// claims recognition accuracy from these files: synthetic tones carry no
/// speech, so they only prove plumbing (build, fixture validity, CLI runs
/// without crashing). Accuracy evidence requires consented human recordings
/// with deliberate word errors; see `docs/offline-recitation-discovery.md`.
const harnessSampleRate = 16000;

/// One second of audio per fixture keeps the harness fast and deterministic.
const harnessFixtureSeconds = 1;

/// Sine frequency for the tone fixture.
const harnessSineHz = 440.0;
/// Filenames generated under the fixtures directory.
const harnessFixtureNames = [
  'silence_1s.wav',
  'sine440_1s.wav',
  'noise_1s.wav',
];
/// Manifest filename written alongside the fixtures.
const harnessManifestName = 'manifest.json';

/// Parsed header of a 16-bit PCM WAV fixture.
class WavInfo {
  const WavInfo({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.frames,
  });

  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int frames;
}

/// Returns 16-bit silence samples: [frames] zeros.
List<int> silenceSamples(int frames) => List<int>.filled(frames, 0);

/// Returns [frames] of a full-scale 440 Hz sine wave at [sampleRate].
List<int> sineSamples(int frames, int sampleRate, double frequencyHz) {
  return List<int>.generate(frames, (i) {
    final phase = 2 * math.pi * frequencyHz * i / sampleRate;
    return (32767 * math.sin(phase)).round().clamp(-32768, 32767);
  });
}

/// Returns [frames] of deterministic white noise from a 32-bit LCG.
///
/// Fixed seed means every harness run produces byte-identical fixtures, so
/// the manifest hashes are stable across machines.
List<int> noiseSamples(int frames, {int seed = 0x12345678}) {
  var state = seed;
  return List<int>.generate(frames, (_) {
    state = (1103515245 * state + 12345) & 0x7fffffff;
    return (state % 65536) - 32768;
  });
}

/// Encodes [samples] as a 16-bit PCM mono WAV at [sampleRate].
Uint8List encodeWavMono16(List<int> samples, {int sampleRate = 16000}) {
  final dataBytes = samples.length * 2;
  final buffer = Uint8List(44 + dataBytes);
  final view = ByteData.sublistView(buffer);
  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      buffer[offset + i] = text.codeUnitAt(i);
    }
  }

  writeAscii(0, 'RIFF');
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  writeAscii(36, 'data');
  view
    ..setUint32(4, 36 + dataBytes, Endian.little)
    ..setUint32(16, 16, Endian.little) // fmt chunk size
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little) // byte rate
    ..setUint16(32, 2, Endian.little) // block align
    ..setUint16(34, 16, Endian.little) // bits per sample
    ..setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    view.setInt16(44 + i * 2, samples[i].clamp(-32768, 32767), Endian.little);
  }
  return buffer;
}

/// Parses a 16-bit PCM mono WAV header. Throws [FormatException] when the
/// bytes are not a supported fixture.
WavInfo parseWavHeader(Uint8List bytes) {
  if (bytes.length < 44) {
    throw const FormatException('too short for a WAV header');
  }
  String ascii(int offset, int length) =>
      String.fromCharCodes(bytes.sublist(offset, offset + length));
  final view = ByteData.sublistView(bytes);
  if (ascii(0, 4) != 'RIFF' ||
      ascii(8, 4) != 'WAVE' ||
      ascii(12, 4) != 'fmt ' ||
      ascii(36, 4) != 'data') {
    throw const FormatException('not a PCM WAV file');
  }
  if (view.getUint16(20, Endian.little) != 1) {
    throw const FormatException('only PCM WAV fixtures are supported');
  }
  if (view.getUint16(34, Endian.little) != 16) {
    throw const FormatException('only 16-bit WAV fixtures are supported');
  }
  final dataBytes = view.getUint32(40, Endian.little);
  if (bytes.length != 44 + dataBytes) {
    throw const FormatException('WAV data chunk size mismatch');
  }
  return WavInfo(
    sampleRate: view.getUint32(24, Endian.little),
    channels: view.getUint16(22, Endian.little),
    bitsPerSample: view.getUint16(34, Endian.little),
    frames: dataBytes ~/ 2,
  );
}

/// Lowercase hex SHA-256 of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Writes the three synthetic fixtures plus a SHA-256 manifest into [dir].
///
/// Returns the manifest entries. The manifest lets later steps (and humans)
/// confirm the fixtures on disk are the bytes this harness generated.
Future<List<Map<String, Object>>> writeFixtures(Directory dir) async {
  await dir.create(recursive: true);
  const frames = harnessSampleRate * harnessFixtureSeconds;
  final waveforms = <String, List<int>>{
    'silence_1s.wav': silenceSamples(frames),
    'sine440_1s.wav': sineSamples(frames, harnessSampleRate, harnessSineHz),
    'noise_1s.wav': noiseSamples(frames),
  };
  final entries = <Map<String, Object>>[];
  for (final entry in waveforms.entries) {
    final bytes = encodeWavMono16(entry.value);
    final file = File(path.join(dir.path, entry.key));
    await file.writeAsBytes(bytes, flush: true);
    // Read back through the parser so a corrupt write fails fast here,
    // not pages later inside a C++ test log.
    final info = parseWavHeader(await file.readAsBytes());
    entries.add({
      'file': entry.key,
      'sha256': sha256Hex(bytes),
      'sample_rate': info.sampleRate,
      'channels': info.channels,
      'bits_per_sample': info.bitsPerSample,
      'frames': info.frames,
    });
  }
  final manifest = File(path.join(dir.path, harnessManifestName));
  await manifest.writeAsString(
    '${jsonEncode({'fixtures': entries})}\n',
    flush: true,
  );
  return entries;
}

/// Verifies every file listed in the manifest inside [dir].
///
/// Returns the list of problems; empty means all fixtures verified.
Future<List<String>> verifyFixtures(Directory dir) async {
  final problems = <String>[];
  final manifest = File(path.join(dir.path, harnessManifestName));
  if (!manifest.existsSync()) {
    return ['missing $harnessManifestName in ${dir.path}'];
  }
  final decoded = jsonDecode(await manifest.readAsString());
  final entries = (decoded as Map)['fixtures'] as List;
  for (final raw in entries) {
    final entry = raw as Map;
    final name = entry['file'] as String;
    final file = File(path.join(dir.path, name));
    if (!file.existsSync()) {
      problems.add('missing fixture $name');
      continue;
    }
    final bytes = await file.readAsBytes();
    final actual = sha256Hex(bytes);
    if (actual != entry['sha256']) {
      problems.add('hash mismatch for $name');
      continue;
    }
    try {
      final info = parseWavHeader(bytes);
      if (info.sampleRate != harnessSampleRate || info.channels != 1) {
        problems.add('$name is not 16 kHz mono');
      }
    } on FormatException catch (e) {
      problems.add('$name is not a valid WAV fixture: $e');
    }
  }
  return problems;
}

/// Compares a `git rev-parse HEAD` value against the locked engine revision.
bool revisionMatches(String actual, String locked) =>
    actual.trim().toLowerCase() == locked.trim().toLowerCase();

/// Reads the locked transcribe.cpp revision from `docs/model-lock.json`.
Future<String> readLockedRevision() async {
  final file = File('docs/model-lock.json');
  final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return (decoded['engine'] as Map<String, dynamic>)['revision'] as String;
}

ArgParser _buildArgParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message.',
    )
    ..addOption(
      'fixtures-dir',
      defaultsTo: path.join('build', 'transcribe-fixtures'),
      help: 'Directory for synthetic WAV fixtures and manifest.',
    )
    ..addOption(
      'build-dir',
      defaultsTo: path.join('build', 'transcribe-desktop'),
      help: 'CMake build directory for transcribe.cpp.',
    )
    ..addFlag(
      'skip-build',
      negatable: false,
      help: 'Only generate fixtures and verify the manifest.',
    )
    ..addFlag(
      'skip-tests',
      negatable: false,
      help: 'Build transcribe.cpp but do not run ctest.',
    )
    ..addOption(
      'model',
      help: 'Optional GGUF model for a negative plumbing run of '
          'transcribe-cli over the silence fixture. Expects exit 0; '
          'the transcript is not asserted.',
    );
}

void _printHelp(ArgParser parser) {
  print('Desktop transcribe.cpp harness (fixtures, build, smoke tests)');
  print('');
  print('Usage: dart run tool/transcribe_harness.dart [options]');
  print('');
  print(parser.usage);
  print('');
  print('Without --model, inference is reported as SKIP: no accuracy claim '
      'is made from synthetic fixtures.');
}

Future<int> _run(String executable, List<String> args) async {
  print('+ ${[executable, ...args].join(' ')}');
  final process = await Process.start(
    executable,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

/// Desktop harness entry point. See `_printHelp` for the contract.
Future<void> main(List<String> args) async {
  final parser = _buildArgParser();
  ArgResults results;
  try {
    results = parser.parse(args);
  } on ArgParserException catch (e) {
    print(e.message);
    _printHelp(parser);
    exitCode = 64;
    return;
  }
  if (results['help'] as bool) {
    _printHelp(parser);
    return;
  }

  // 1. Pin check: the vendored engine must be the locked revision.
  final locked = await readLockedRevision();
  final revResult = await Process.run(
    'git',
    ['-C', 'third_party/transcribe.cpp', 'rev-parse', 'HEAD'],
  );
  if (revResult.exitCode != 0) {
    print('FAIL: cannot read transcribe.cpp revision: ${revResult.stderr}');
    print('Clone the engine, then check out the locked revision:');
    print('  git clone https://github.com/handy-computer/transcribe.cpp '
        'third_party/transcribe.cpp');
    print('  git -C third_party/transcribe.cpp checkout $locked');
    exitCode = 1;
    return;
  }
  final actual = (revResult.stdout as String).trim();
  if (!revisionMatches(actual, locked)) {
    print('FAIL: transcribe.cpp at $actual, locked at $locked.');
    print('Update docs/model-lock.json and lib/resources/resource_locks.dart '
        'together; never point the harness at a moving ref.');
    exitCode = 1;
    return;
  }
  print('Engine revision pinned: $actual');

  // 2. Synthetic fixtures plus manifest.
  final fixturesDir = Directory(results['fixtures-dir'] as String);
  final entries = await writeFixtures(fixturesDir);
  final written = entries.map((entry) => entry['file']).toSet();
  if (!written.containsAll(harnessFixtureNames)) {
    print('FAIL: harness wrote $written, expected $harnessFixtureNames.');
    exitCode = 1;
    return;
  }
  for (final entry in entries) {
    print('fixture ${entry['file']} sha256=${entry['sha256']}');
  }
  final problems = await verifyFixtures(fixturesDir);
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      print('FAIL: $problem');
    }
    exitCode = 1;
    return;
  }
  print('Fixtures verified against manifest.');

  if (results['skip-build'] as bool) {
    print('SKIP: cmake build (--skip-build).');
    print('SKIP: model inference (no --model given or build skipped).');
    return;
  }

  // 3. Configure and build the engine with model-free tests only.
  final buildDir = results['build-dir'] as String;
  var code = await _run('cmake', [
    '-S',
    'third_party/transcribe.cpp',
    '-B',
    buildDir,
    '-G',
    'Ninja',
    // Interpolated so the -D prefix does not glue onto the variable name
    // for spell-checking; cmake receives identical arguments.
    '${'-D'}CMAKE_BUILD_TYPE=Release',
    '${'-D'}TRANSCRIBE_BUILD_REAL_MODEL_TESTS=OFF',
  ]);
  if (code != 0) {
    exitCode = code;
    return;
  }
  final threads = Platform.numberOfProcessors.toString();
  code = await _run('cmake', ['--build', buildDir, '-j', threads]);
  if (code != 0) {
    exitCode = code;
    return;
  }
  // 4. Model-free unit and smoke tests (fixtures, parsers, ABI guards).
  if (results['skip-tests'] as bool) {
    print('SKIP: ctest (--skip-tests).');
  } else {
    code = await _run('ctest', [
      '--test-dir',
      buildDir,
      '--output-on-failure',
    ]);
    if (code != 0) {
      exitCode = code;
      return;
    }
  }

  // 5. Optional negative plumbing run: silence through the real CLI.
  final model = results['model'] as String?;
  if (model == null) {
    print('SKIP: model inference (no --model given). Synthetic fixtures '
        'prove plumbing only; accuracy needs human recordings.');
    return;
  }
  const cliNames = ['transcribe-cli', 'transcribe-cli.exe'];
  var cli = '';
  for (final name in cliNames) {
    final candidate = path.join(buildDir, 'bin', name);
    if (File(candidate).existsSync()) cli = candidate;
  }
  if (cli.isEmpty) {
    print('FAIL: expected CLI binary missing under $buildDir/bin.');
    exitCode = 1;
    return;
  }
  final silence = path.join(fixturesDir.path, 'silence_1s.wav');
  code = await _run(cli, ['--model', model, silence]);
  if (code != 0) {
    print('FAIL: transcribe-cli exit code $code on silence fixture.');
    exitCode = code;
    return;
  }
  print('Plumbing run passed (exit 0). Transcript content is not asserted: '
      'silence is a crash check, not an accuracy fixture.');
}
