import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// Raw Dart FFI bindings for the transcribe.cpp C API subset the app uses.
///
/// Only file-backed streaming transcription is bound: open a session on a
/// model file, begin a stream, feed 16 kHz mono float32 PCM, and read the
/// authoritative `full_text` snapshot. Everything else lives upstream in
/// `third_party/transcribe.cpp/include/transcribe.h`.
class TranscribeBindings {
  /// Loads `libtranscribe.so` from the candidate locations.
  TranscribeBindings() : this.fromLibrary(_openLibrary());

  /// Binds entry points from an already-opened library (tests).
  TranscribeBindings.fromLibrary(this._lib) {
    _version = _lib
        .lookupFunction<
          ffi.Pointer<Utf8> Function(),
          ffi.Pointer<Utf8> Function()
        >('transcribe_version');
    _statusString = _lib
        .lookupFunction<
          ffi.Pointer<Utf8> Function(ffi.Int32),
          ffi.Pointer<Utf8> Function(int)
        >('transcribe_status_string');
    _open = _lib
        .lookupFunction<
          ffi.Int32 Function(
            ffi.Pointer<Utf8>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Pointer<ffi.Void>>,
          ),
          int Function(
            ffi.Pointer<Utf8>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Pointer<ffi.Void>>,
          )
        >('transcribe_open');
    _sessionFree = _lib
        .lookupFunction<
          ffi.Void Function(ffi.Pointer<ffi.Void>),
          void Function(ffi.Pointer<ffi.Void>)
        >('transcribe_session_free');
    _streamBegin = _lib
        .lookupFunction<
          ffi.Int32 Function(
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
          ),
          int Function(
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Void>,
          )
        >('transcribe_stream_begin');
    _streamFeed = _lib
        .lookupFunction<
          ffi.Int32 Function(
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Float>,
            ffi.Int32,
            ffi.Pointer<ffi.Void>,
          ),
          int Function(
            ffi.Pointer<ffi.Void>,
            ffi.Pointer<ffi.Float>,
            int,
            ffi.Pointer<ffi.Void>,
          )
        >('transcribe_stream_feed');
    _streamFinalize = _lib
        .lookupFunction<
          ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>),
          int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
        >('transcribe_stream_finalize');
    _streamReset = _lib
        .lookupFunction<
          ffi.Void Function(ffi.Pointer<ffi.Void>),
          void Function(ffi.Pointer<ffi.Void>)
        >('transcribe_stream_reset');
    _streamRevision = _lib
        .lookupFunction<
          ffi.Int32 Function(ffi.Pointer<ffi.Void>),
          int Function(ffi.Pointer<ffi.Void>)
        >('transcribe_stream_revision');
    _streamGetText = _lib
        .lookupFunction<
          ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_StreamText>),
          int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_StreamText>)
        >('transcribe_stream_get_text');
  }

  /// Status code for success; every other code is a failure.
  static const int statusOk = 0;

  final ffi.DynamicLibrary _lib;
  late final ffi.Pointer<Utf8> Function() _version;
  late final ffi.Pointer<Utf8> Function(int) _statusString;
  late final int Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Pointer<ffi.Void>>,
  )
  _open;
  late final void Function(ffi.Pointer<ffi.Void>) _sessionFree;
  late final int Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
  )
  _streamBegin;
  late final int Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Float>,
    int,
    ffi.Pointer<ffi.Void>,
  )
  _streamFeed;
  late final int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)
  _streamFinalize;
  late final void Function(ffi.Pointer<ffi.Void>) _streamReset;
  late final int Function(ffi.Pointer<ffi.Void>) _streamRevision;
  late final int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_StreamText>)
  _streamGetText;

  /// Opens the platform library; throws [ArgumentError] when absent from
  /// every candidate location.
  static ffi.DynamicLibrary _openLibrary() {
    ArgumentError? last;
    for (final candidate in libraryCandidates()) {
      try {
        return ffi.DynamicLibrary.open(candidate);
        // A missing candidate reports as ArgumentError; try the next one
        // instead of failing on the first miss.
        // ignore: avoid_catching_errors
      } on ArgumentError catch (e) {
        last = e;
      }
    }
    throw last ?? ArgumentError('no library candidates');
  }

  /// Library locations in probe order: the platform path first, then the
  /// Flutter Linux bundle `lib` directory beside the executable.
  static List<String> libraryCandidates() {
    const base = 'libtranscribe.so';
    // Only Linux resolves a bundle directory; other platforms probe the
    // bare name. Unit tests run on Linux, so this branch is excluded.
    // coverage:ignore-start
    if (!Platform.isLinux) return [base];
    // coverage:ignore-end
    final bundleLib = p.join(p.dirname(Platform.resolvedExecutable), 'lib');
    return [base, p.join(bundleLib, base)];
  }

  /// Library version string, borrowed storage (do not free).
  String version() => _version().toDartString();

  /// Status description, borrowed storage (do not free).
  String statusString(int status) => _statusString(status).toDartString();

  /// Opens a session owning its model file; defaults for both params.
  /// Returns the status and the session slot (null session on failure).
  (int, ffi.Pointer<ffi.Void>) openSession(String modelPath) {
    final path = modelPath.toNativeUtf8();
    final outSession = calloc<ffi.Pointer<ffi.Void>>();
    try {
      final status = _open(path, ffi.nullptr, ffi.nullptr, outSession);
      return (status, outSession.value);
    } finally {
      calloc
        ..free(path)
        ..free(outSession);
    }
  }

  /// Frees a session (and its owned model). Null is a no-op upstream.
  void freeSession(ffi.Pointer<ffi.Void> session) => _sessionFree(session);

  /// Begins a streaming run with library defaults.
  int streamBegin(ffi.Pointer<ffi.Void> session) =>
      _streamBegin(session, ffi.nullptr, ffi.nullptr);

  /// Feeds 16 kHz mono float32 PCM into the active stream.
  int streamFeed(ffi.Pointer<ffi.Void> session, Float32List pcm) {
    final ptr = calloc<ffi.Float>(pcm.length);
    try {
      ptr.asTypedList(pcm.length).setAll(0, pcm);
      return _streamFeed(session, ptr, pcm.length, ffi.nullptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Ends input and flushes remaining text.
  int streamFinalize(ffi.Pointer<ffi.Void> session) =>
      _streamFinalize(session, ffi.nullptr);

  /// Abandons the stream and returns the session to idle.
  void streamReset(ffi.Pointer<ffi.Void> session) => _streamReset(session);

  /// Monotonic snapshot revision; re-read text when it advances.
  int streamRevision(ffi.Pointer<ffi.Void> session) => _streamRevision(session);

  /// Authoritative `full_text` snapshot; empty on failure.
  String streamText(ffi.Pointer<ffi.Void> session) {
    final text = calloc<_StreamText>();
    try {
      final status = _streamGetText(session, text);
      if (status != statusOk) return '';
      final ptr = text.ref.fullText;
      if (ptr == ffi.nullptr) return '';
      return ptr.toDartString();
    } finally {
      calloc.free(text);
    }
  }
}

/// Prefix of `transcribe_stream_text`: only the fields the app reads.
/// `struct_size` + `full_text` + `full_text_bytes` must match the C layout.
final class _StreamText extends ffi.Struct {
  @ffi.Uint64()
  external int structSize;

  external ffi.Pointer<Utf8> fullText;

  @ffi.Uint64()
  external int fullTextBytes;
}
