import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';

/// Whether this is the tester build (the one with Test Mode). Tests override it.
final testBuildProvider = Provider<bool>((ref) => AppFlags.testBuild);

/// A temporary testing switch that opens every era and every level, so the
/// whole game can be played without grinding through the unlock order.
///
/// Persisted on the device so it survives a restart, and read by the era and
/// level screens. It changes only what is *shown as unlocked*: it does not
/// complete anything, award stars, or send anything to the server.
///
/// Only the tester build has it. In the student build [enabled] is false: the
/// switch always reads off, [set] does nothing, and a value an earlier tester
/// install left on the phone is never read.
class UnlockAllNotifier extends StateNotifier<bool> {
  final bool _enabled;

  UnlockAllNotifier({bool enabled = true})
      : _enabled = enabled,
        super(enabled && StorageService.getUnlockAll());

  Future<void> set(bool value) async {
    if (!_enabled) return;
    state = value;
    await StorageService.setUnlockAll(value);
  }
}

final unlockAllProvider = StateNotifierProvider<UnlockAllNotifier, bool>(
    (ref) => UnlockAllNotifier(enabled: ref.watch(testBuildProvider)));
