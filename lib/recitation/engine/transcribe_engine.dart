import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:mneme/recitation/engine/transcribe_bindings.dart';

/// Failure to use the native transcription engine.
class TranscribeEngineException implements Exception {
  /// Creates a failure with a human-readable [message].
  const TranscribeEngineException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'TranscribeEngineException($message)';
}

/// The native library is absent (not bundled for this platform).
class TranscribeEngineUnavailable extends TranscribeEngineException {
  /// Creates an unavailability notice.
  const TranscribeEngineUnavailable(super.message);
}

/// One streaming transcription session over a model file.
///
/// Sessions are single-threaded and cheap to describe but hold native
/// memory: always [dispose] them. All fallible native calls throw
/// [TranscribeEngineException] with the upstream status text; a missing
/// library throws [TranscribeEngineUnavailable] instead of crashing.
class TranscribeEngine {
  /// Opens [modelPath] and starts a session. [open] injects the bindings
  /// constructor (tests pass fakes without native code).
  TranscribeEngine(
    String modelPath, {
    TranscribeBindings Function()? open,
  }) : _open = open ?? TranscribeBindings.new {
    try {
      _bindings = _open();
      // A missing native library reports as ArgumentError; catch it here
      // so it becomes unavailability instead of a crash.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      throw TranscribeEngineUnavailable('${e.message}');
    }
    final (status, session) = _bindings.openSession(modelPath);
    if (status != TranscribeBindings.statusOk || session == ffi.nullptr) {
      final detail = _describe(status);
      _bindings.freeSession(session);
      throw TranscribeEngineException(
        'cannot open model "$modelPath": $detail',
      );
    }
    _session = session;
  }

  final TranscribeBindings Function() _open;
  late final TranscribeBindings _bindings;
  late final ffi.Pointer<ffi.Void> _session;
  var _active = false;
  var _disposed = false;

  /// Library version, for diagnostics.
  String get version => _bindings.version();

  /// Begins a streaming run with library defaults.
  void begin() {
    _requireLive();
    final status = _bindings.streamBegin(_session);
    if (status != TranscribeBindings.statusOk) {
      throw TranscribeEngineException(
        'cannot begin stream: ${_describe(status)}',
      );
    }
    _active = true;
  }

  /// Feeds 16 kHz mono float32 PCM. Empty input is a no-op.
  void feed(Float32List pcm) {
    _requireLive();
    if (!_active || pcm.isEmpty) return;
    final status = _bindings.streamFeed(_session, pcm);
    if (status != TranscribeBindings.statusOk) {
      throw TranscribeEngineException(
        'cannot feed stream: ${_describe(status)}',
      );
    }
  }

  /// Current authoritative transcript snapshot.
  String text() {
    _requireLive();
    if (!_active) return '';
    return _bindings.streamText(_session);
  }

  /// Ends input, flushes remaining text, and returns the final transcript.
  String finalize() {
    _requireLive();
    if (!_active) return '';
    final status = _bindings.streamFinalize(_session);
    _active = false;
    if (status != TranscribeBindings.statusOk) {
      throw TranscribeEngineException(
        'cannot finalize stream: ${_describe(status)}',
      );
    }
    return _bindings.streamText(_session);
  }

  /// Frees the session and its owned model. Idempotent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _active = false;
    _bindings.freeSession(_session);
  }

  void _requireLive() {
    if (_disposed) {
      throw const TranscribeEngineException('engine is disposed');
    }
  }

  String _describe(int status) {
    try {
      return _bindings.statusString(status);
    } on Object {
      return 'status $status';
    }
  }
}
