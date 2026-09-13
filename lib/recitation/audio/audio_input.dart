import 'dart:typed_data';

import 'package:record/record.dart';

/// PCM16 microphone source for the transcription engine.
///
/// A thin seam over the `record` plugin so the session driver stays
/// unit-testable: production uses [RecordAudioInput], tests use fakes.
abstract class AudioInput {
  /// Checks (and requests) microphone permission.
  Future<bool> ensurePermission();

  /// Starts a 16 kHz mono PCM16 stream. Throws when permission is denied
  /// or the recorder fails to start.
  Future<Stream<Uint8List>> startPcm16();

  /// Stops the stream. Safe to call when idle.
  Future<void> stop();

  /// Releases recorder resources.
  void dispose();
}

/// [AudioInput] backed by the `record` plugin.
class RecordAudioInput implements AudioInput {
  /// Creates a recorder-backed input.
  RecordAudioInput({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> ensurePermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startPcm16() {
    return _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
  }

  @override
  Future<void> stop() => _recorder.stop();

  @override
  void dispose() => _recorder.dispose();
}
