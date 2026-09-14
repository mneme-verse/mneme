import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_cmake/native_toolchain_cmake.dart';

/// Builds the transcribe.cpp shared library for host desktop targets.
///
/// Android APKs carry the NDK-built library in `jniLibs` (release
/// workflow); this hook only serves host builds so `flutter run` on
/// Linux always finds `libtranscribe.so` beside the app bundle without
/// manual copying. Outputs land under the hook output directory, never
/// in the pinned submodule worktree.
void main(List<String> args) async {
  await build(args, (input, output) async {
    final logger = Logger('mneme')
      ..onRecord.listen((record) => stderr.writeln(record.message));
    final builder = CMakeBuilder.create(
      name: 'transcribe',
      sourceDir: input.packageRoot.resolve('third_party/transcribe.cpp/'),
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
    final added = await output.findAndAddCodeAssets(
      input,
      names: {
        'transcribe':
            'package:mneme/recitation/engine/transcribe_bindings.dart',
      },
      logger: logger,
    );
    logger.info('Bundled native assets: $added');
  });
}
