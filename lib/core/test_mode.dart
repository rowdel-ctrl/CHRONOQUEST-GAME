import 'package:flutter/foundation.dart' show visibleForTesting;

import '../services/storage_service.dart';
import 'constants.dart';

/// Whether Test Mode is on: the tester build, with the switch in Settings turned on.
/// The student build never has it. While it is on, the lesson card does not make the tester
/// wait for its reading time, and every era, level and hero is open and hearts are free
/// (see `unlock_all_provider.dart`). The game's own clocks (a teacher's question timer, the
/// boss's answer clock, the golden portal's 5 seconds) keep running: testers play those.
///
/// Read from storage so game code that has no provider can ask.
class TestMode {
  TestMode._();

  /// Lets a test turn it on or off without a tester build. Null reads the real switch.
  @visibleForTesting
  static bool? debugOverride;

  static bool get on {
    final forced = debugOverride;
    if (forced != null) return forced;
    if (!AppFlags.testBuild) return false;
    try {
      return StorageService.getUnlockAll();
    } catch (_) {
      return false; // storage not ready
    }
  }
}
