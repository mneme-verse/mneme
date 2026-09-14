import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_cmake/native_toolchain_cmake.dart';
import 'package:path/path.dart' as p;

/// Builds the transcribe.cpp shared library for host desktop targets.
///
/// Android APKs carry NDK-built libraries in `jniLibs` (release
/// workflow); this hook only serves host builds so `flutter run` on
/// Linux finds the engine beside the app bundle without manual copying.
///
/// Upstream version-links its libraries (`libtranscribe.so` is a dev
/// symlink; the loader wants `libggml.so.0` and friends by DT_NEEDED
/// name), so the hook stages dereferenced copies under their runtime
/// names and registers every staged file: the top library plus each
/// DT_NEEDED sibling found in the build tree. Outputs land under the
/// hook output directory, never in the pinned submodule worktree.
void main(List<String> args) async {
  await build(args, (input, output) async {
    // Release APKs carry NDK-built libraries in jniLibs (the release
    // workflow sets MNEME_SKIP_NATIVE_HOOK); the host compile would
    // only waste release minutes.
    if (Platform.environment['MNEME_SKIP_NATIVE_HOOK'] == '1') return;
    final logger = Logger('mneme')
      ..onRecord.listen((record) => stderr.writeln(record.message));
    if (input.config.code.targetOS != OS.linux) return;
    // CI test checkouts and submodule-less trees skip: unit tests mock
    // the engine, and release APKs carry NDK-built libraries in
    // jniLibs. Run `git submodule update --init` for desktop takes.
    final sourceDir = input.packageRoot.resolve(
      'third_party/transcribe.cpp/',
    );
    final cmakeLists = sourceDir.resolve('CMakeLists.txt');
    if (!File.fromUri(cmakeLists).existsSync()) {
      logger.warning(
        'Skipping native engine build: submodule not checked out.',
      );
      return;
    }
    output.dependencies.addAll([
      cmakeLists,
      sourceDir.resolve('include/transcribe.h'),
    ]);
    final builder = CMakeBuilder.create(
      name: 'transcribe',
      sourceDir: sourceDir,
      defines: const {
        'CMAKE_BUILD_TYPE': 'Release',
        'TRANSCRIBE_BUILD_SHARED': 'ON',
        'TRANSCRIBE_BUILD_TESTS': 'OFF',
        'TRANSCRIBE_BUILD_EXAMPLES': 'OFF',
        'TRANSCRIBE_BUILD_TOOLS': 'OFF',
      },
      logger: logger,
    );
    await builder.run(input: input, output: output, logger: logger);
    final staged = _stageRuntimeLibraries(input.outputDirectory, logger);
    final top = staged['libtranscribe.so'];
    if (top == null) {
      throw StateError(
        'Native engine build produced no libtranscribe.so; refusing to '
        'bundle an app without its speech engine.',
      );
    }
    for (final entry in staged.entries) {
      final name = entry.key == 'libtranscribe.so'
          ? 'package:mneme/recitation/engine/transcribe_bindings.dart'
          : 'package:mneme/recitation/engine/native/${entry.key}';
      output.assets.code.add(
        CodeAsset(
          package: input.packageName,
          name: name,
          linkMode: DynamicLoadingBundled(),
          file: Uri.file(entry.value),
        ),
      );
    }
    logger.info('Bundled native libraries: ${staged.keys.toList()}');
  });
}

/// Copies the runtime library closure into `<outDir>/staged/`, keyed by
/// runtime file name.
///
/// Returns a map from the name the loader requests to the staged
/// absolute path: `libtranscribe.so` (dereferenced top library, the
/// name `DynamicLibrary.open` probes) plus one entry per DT_NEEDED
/// name resolvable in the build tree (the versioned ggml names).
/// System libraries are skipped: only names found under [outDir] land
/// in the bundle.
Map<String, String> _stageRuntimeLibraries(Uri outDir, Logger logger) {
  final stageDir = Directory.fromUri(outDir.resolve('staged/'))
    ..createSync(recursive: true);
  // The staged directory lives under the scanned output directory:
  // exclude it so reruns never index previously staged libraries.
  final entities = Directory.fromUri(outDir).listSync(
    recursive: true,
    followLinks: false,
  );
  final byName = <String, FileSystemEntity>{};
  final stagePath = p.normalize(stageDir.path);
  for (final entity in entities) {
    // p.isWithin is separator-safe; the trailing-separator form is not.
    if (entity.path == stagePath || p.isWithin(stagePath, entity.path)) {
      continue;
    }
    byName[entity.path.split(Platform.pathSeparator).last] = entity;
  }

  String stageBytes(String runtimeName, List<int> bytes) {
    final path = '${stageDir.path}${Platform.pathSeparator}$runtimeName';
    File(path).writeAsBytesSync(bytes, flush: true);
    return path;
  }

  List<int> readBytes(FileSystemEntity entity) {
    if (entity is Link) {
      final target = entity.targetSync();
      final absolute = p.isAbsolute(target)
          ? target
          : p.join(p.dirname(entity.path), target);
      return File(absolute).readAsBytesSync();
    }
    return (entity as File).readAsBytesSync();
  }

  final staged = <String, String>{};
  // Top library first: the bare dev-symlink name resolves to the
  // versioned bytes the loader actually maps.
  final topLink = byName['libtranscribe.so'];
  if (topLink == null) return staged;
  staged['libtranscribe.so'] = stageBytes(
    'libtranscribe.so',
    readBytes(topLink),
  );
  // Siblings join transitively: every staged library's own DT_NEEDED
  // names join the queue, so multi-level chains all land in the bundle.
  final queue = _neededLibraries('${stageDir.path}/libtranscribe.so');
  while (queue.isNotEmpty) {
    final needed = queue.removeLast();
    if (staged.containsKey(needed)) continue;
    final entity = byName[needed];
    if (entity == null) {
      logger.warning('Skipping system library $needed.');
      continue;
    }
    final path = stageBytes(needed, readBytes(entity));
    staged[needed] = path;
    queue.addAll(_neededLibraries(path));
  }
  return staged;
}

/// DT_NEEDED base names of [library] via readelf.
List<String> _neededLibraries(String library) {
  final result = Process.runSync('readelf', ['-d', library]);
  if (result.exitCode != 0) {
    throw StateError(
      'Cannot read DT_NEEDED of $library: ${result.stderr}',
    );
  }
  final needed = <String>[];
  final pattern = RegExp(r'\(NEEDED\)[^[]*\[([^\]]+)\]');
  for (final line in (result.stdout as String).split('\n')) {
    final match = pattern.firstMatch(line);
    if (match != null) needed.add(match.group(1)!);
  }
  return needed;
}
