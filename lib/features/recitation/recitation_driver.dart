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
  RecitationDriver({
    required this.modelPath,
    void Function(String text)? onTranscript,
    AudioInput? audio,
    TranscribeEngine Function(String modelPath)? openEngine,
  }) : onTranscript = onTranscript ?? _ignore,
       _audio = audio ?? RecordAudioInput(),
       _openEngine = openEngine ?? TranscribeEngine.new;

  /// Receives interim and final transcripts.
  void Function(String text) onTranscript;

  /// Model file fed to the native session.
  final String modelPath;

  final AudioInput _audio;
  final TranscribeEngine Function(String) _openEngine;
  TranscribeEngine? _engine;
  StreamSubscription<Uint8List>? _subscription;
  var _listening = false;

  /// Drops transcripts when no owner is wired.
  static void _ignore(String _) {}

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
          engine.feed(_toFloat32(chunk));
          onTranscript(engine.text());
        },
        onError: (_) {},
      );
    } catch (_) {
      engine.dispose();
      rethrow;
    }
  }

  /// Stops the take, delivers the final transcript, and frees the
  /// session. Safe to call when idle.
  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    await _subscription?.cancel();
    _subscription = null;
    await _audio.stop();
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    try {
      onTranscript(engine.finalize());
    } finally {
      engine.dispose();
    }
  }

  /// Releases the recorder and any live session.
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
