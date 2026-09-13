/// Locked offline resource definitions.
///
/// `docs/model-lock.json` is the canonical record; the constants below
/// mirror it so the app can reference resources without asset loading.
/// `test/resources/resource_locks_test.dart` fails when the two drift
/// apart.
library;

/// An immutably pinned downloadable resource.
class LockedResource {
  const LockedResource({
    required this.id,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
  });

  /// Stable identifier, e.g. `nemotron-3.5-asr-streaming-0.6b-q8_0`.
  final String id;

  /// Revision-pinned download URL. Never a moving `main` reference.
  final String url;

  /// Expected SHA-256 of the downloaded bytes.
  final String sha256;

  /// Expected size in bytes, used for progress and pre-install checks.
  final int sizeBytes;
}

/// Speech models locked in `docs/model-lock.json`.
const List<LockedResource> lockedSpeechModels = [
  LockedResource(
    id: 'gigaam-v3-e2e-rnnt-q8_0',
    url:
        'https://huggingface.co/handy-computer/gigaam-v3-e2e-rnnt-gguf/'
        'resolve/f719d70812344f4d0fb8c11c0887b190501a7465/'
        'gigaam-v3-e2e-rnnt-Q8_0.gguf',
    sha256: '78d63b47723b7f8d78c6113a6ef983b5a86e2a86f6c273e1f5cb6967b1c4467a',
    sizeBytes: 273724832,
  ),
  LockedResource(
    id: 'nemotron-3.5-asr-streaming-0.6b-q8_0',
    url:
        'https://huggingface.co/handy-computer/'
        'nemotron-3.5-asr-streaming-0.6b-gguf/'
        'resolve/0221a878b3f4c3efd14e976702058fe998d41573/'
        'nemotron-3.5-asr-streaming-0.6b-Q8_0.gguf',
    sha256: 'b94545b313b3223fda7b2857a52681da813935c2127643d1e9ff0c23d988089c',
    sizeBytes: 751094240,
  ),
];

/// The multilingual streaming model installed by default. GigaAM remains
/// a locked comparison candidate but is not the default install because it
/// is Russian-only without native streaming.
const String defaultSpeechModelId = 'nemotron-3.5-asr-streaming-0.6b-q8_0';

/// Speech model license notices that must ship with each download.
const Map<String, String> speechModelLicenseFiles = {
  'gigaam-v3-e2e-rnnt-q8_0': 'MIT',
  'nemotron-3.5-asr-streaming-0.6b-q8_0': 'OpenMDW-1.1',
};
