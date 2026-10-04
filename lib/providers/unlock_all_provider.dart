import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// A temporary testing switch that opens every era and every level, so the
/// whole game can be played without grinding through the unlock order.
///
/// Persisted on the device so it survives a restart, and read by the era and
/// level screens. It changes only what is *shown as unlocked*: it does not
/// complete anything, award stars, or send anything to the server.
class UnlockAllNotifier extends StateNotifier<bool> {
  UnlockAllNotifier() : super(StorageService.getUnlockAll());

  Future<void> set(bool value) async {
    state = value;
    await StorageService.setUnlockAll(value);
  }
}

final unlockAllProvider =
    StateNotifierProvider<UnlockAllNotifier, bool>((ref) => UnlockAllNotifier());
