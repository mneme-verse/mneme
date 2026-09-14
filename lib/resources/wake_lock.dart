import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the device awake during long installs.
///
/// Screen lock and Doze stall multi-hundred-megabyte downloads; the
/// onboarding cubit holds the lock for the whole install and releases
/// it when the run settles. The interface keeps widget-adjacent code
/// unit-testable: production uses [WakelockPlusDevice], tests use fakes.
abstract class DeviceWakeLock {
  /// Prevents sleep until [release]. Idempotent.
  Future<void> acquire();

  /// Allows sleep again. Idempotent.
  Future<void> release();
}

/// [DeviceWakeLock] backed by the wakelock_plus plugin.
///
/// Unit tests cover the lock protocol through fakes; this wrapper only
/// forwards to platform channels, which need a device. The ignore markers
/// match the existing convention for platform-bound code.
// coverage:ignore-start
class WakelockPlusDevice implements DeviceWakeLock {
  /// Creates the plugin-backed lock.
  const WakelockPlusDevice();

  @override
  Future<void> acquire() => WakelockPlus.enable();

  @override
  Future<void> release() => WakelockPlus.disable();
}
// coverage:ignore-end
