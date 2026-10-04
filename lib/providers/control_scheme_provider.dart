import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/control_scheme.dart';
import '../services/storage_service.dart';

/// The student's chosen movement controls (Settings > Kontrol), saved on this
/// device. The level reads it when it starts and again when the student comes
/// back from Settings, so a change made from the pause menu applies on resume.
class ControlSchemeNotifier extends StateNotifier<ControlScheme> {
  ControlSchemeNotifier() : super(StorageService.getControlScheme());

  Future<void> set(ControlScheme scheme) async {
    state = scheme;
    await StorageService.setControlScheme(scheme);
  }
}

final controlSchemeProvider =
    StateNotifierProvider<ControlSchemeNotifier, ControlScheme>(
        (ref) => ControlSchemeNotifier());
