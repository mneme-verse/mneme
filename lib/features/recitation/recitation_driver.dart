import 'dart:async';

import 'dart:typed_data';

import 'package:mneme/recitation/audio/audio_input.dart';
import 'package:mneme/recitation/engine/transcribe_engine.dart';

/// Microphone permission was denied.
class RecitationPermissionDenied implements Exception {
  /// Creates a denial notice.
  const RecitationPermissionDenied();

  @override
  String toString() => 'RecitationPermissionDenied()';
}

/// Drives one recitation take: microphone permission, PCM16 capture,
/// native streaming transcription, and transcript delivery.
///
/// The driver owns the engine session and the recorder subscription;
/// callers forward [onTranscript] text into the scoring cubit and call
/// [stop] for the final transcript. [dispose] always releases native
/// memory, even mid-take.
class RecitationDriver {
  /// Creates a driver for [modelPath]. [openEngine] and [audio] inject
  /// fakes so takes run in unit tests without a microphone or library.
  /// [onTranscript] receives interim and final transcripts; it is
  /// settable so owners can rewire delivery after construction.
  /// [onError] reports a take torn down by a mid-take engine or
  /// microphone failure; without it the take would stall silently.
  RecitationDriver({
    required this.modelPath,
    void Function(String text)? onTranscript,
    void Function(Object error)? onError,
    AudioInput? audio,
    TranscribeEngine Function(String modelPath)? openEngine,
  }) : onTranscript = onTranscript ?? _ignore,
       onError = onError ?? _ignoreError,
       _audio = audio ?? RecordAudioInput(),
       _openEngine = openEngine ?? TranscribeEngine.new;

  /// Receives interim and final transcripts.
  void Function(String text) onTranscript;

  /// Reports a torn-down take. Settable like [onTranscript].
  void Function(Object error) onError;

  /// Model file fed to the native session.
  final String modelPath;

  final AudioInput _audio;
  final TranscribeEngine Function(String) _openEngine;
  TranscribeEngine? _engine;
  StreamSubscription<Uint8List>? _subscription;
  var _listening = false;

  /// Drops transcripts when no owner is wired.
  static void _ignore(String _) {}

  /// Drops errors when no owner is wired.
  static void _ignoreError(Object _) {}

  /// Whether a take is in progress.
  bool get isListening => _listening;

  /// Starts a take: opens the engine session, begins the stream, and
  /// subscribes to microphone PCM. Throws [RecitationPermissionDenied]
  /// or [TranscribeEngineException].
  Future<void> start() async {
    if (_listening) return;
    if (!await _audio.ensurePermission()) {
      throw const RecitationPermissionDenied();
    }
    final engine = _openEngine(modelPath);
    try {
      engine.begin();
      final stream = await _audio.startPcm16();
      _engine = engine;
      _listening = true;
      _subscription = stream.listen(
        (chunk) {
          try {
            engine.feed(_toFloat32(chunk));
            onTranscript(engine.text());
          } catch (error) {
            // A broken engine must surface, not stall the take: tear it
            // down and report. Never rethrow into the stream (unhandled),
            // and the guard in [_fail] keeps the report singular.
            unawaited(_fail(error));
          }
        },
        onError: (Object error) {
          // A dying microphone stalls the take the same way: surface it.
          unawaited(_fail(error));
        },
      );
    } catch (_) {
      engine.dispose();
      rethrow;
    }
  }

  /// Tears a broken take down and reports the failure through [onError].
  ///
  /// Releases the subscription, recorder, and session (skipping the final
  /// transcript: the engine is broken, so finalizing would only throw
  /// again), then reports. Singular: concurrent chunk errors collapse
  /// into the first report via [_listening].
  Future<void> _fail(Object error) async {
    if (!_listening) return;
    _listening = false;
    try {
      await _subscription?.cancel();
    } catch (_) {}
    _subscription = null;
    try {
      await _audio.stop();
    } catch (_) {}
    final engine = _engine;
    _engine = null;
    try {
      engine?.dispose();
    } catch (_) {}
    onError(error);
  }

  /// Stops the take, delivers the final transcript, and frees the
  /// session. Safe to call when idle. A failing recorder stop still
  /// releases the session: teardown runs to completion either way.
  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    try {
      await _subscription?.cancel();
      _subscription = null;
      await _audio.stop();
    } finally {
      _releaseEngine();
    }
  }

  /// Delivers the final transcript and frees the session, if any.
  void _releaseEngine() {
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    try {
      onTranscript(engine.finalize());
    } finally {
      engine.dispose();
    }
  }

  Future<void> dispose() async {
    _listening = false;
    await _subscription?.cancel();
    _subscription = null;
    _audio.dispose();
    _engine?.dispose();
    _engine = null;
  }

  /// Converts little-endian PCM16 bytes to normalized float32 samples.
  static Float32List _toFloat32(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final out = Float32List(bytes.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768;
    }
    return out;
  }
}
