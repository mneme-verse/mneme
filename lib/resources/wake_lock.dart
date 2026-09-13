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
class WakelockPlusDevice implements DeviceWakeLock {
  /// Creates the plugin-backed lock.
  const WakelockPlusDevice();

  @override
  Future<void> acquire() => WakelockPlus.enable();

  @override
  Future<void> release() => WakelockPlus.disable();
}
