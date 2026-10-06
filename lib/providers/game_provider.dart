import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hearts_state.dart';
import '../models/student.dart';
import '../services/storage_service.dart';

class GameState {
  final String selectedCharacterId;
  final String currentEraId;
  final int currentLevel;
  final PowerUps powerUps;
  final int coins;
  final HeartsState hearts;

  GameState({
    this.selectedCharacterId = 'rizal',
    this.currentEraId = 'pre-colonial',
    this.currentLevel = 1,
    PowerUps? powerUps,
    this.coins = 0,
    HeartsState? hearts,
  })  : powerUps = powerUps ?? PowerUps(),
        hearts = hearts ?? HeartsState.initial();

  GameState copyWith({
    String? selectedCharacterId,
    String? currentEraId,
    int? currentLevel,
    PowerUps? powerUps,
    int? coins,
    HeartsState? hearts,
  }) {
    return GameState(
      selectedCharacterId:
          selectedCharacterId ?? this.selectedCharacterId,
      currentEraId: currentEraId ?? this.currentEraId,
      currentLevel: currentLevel ?? this.currentLevel,
      powerUps: powerUps ?? this.powerUps,
      coins: coins ?? this.coins,
      hearts: hearts ?? this.hearts,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState()) {
    _loadCharacter();
    _loadHearts();
  }

  void _loadCharacter() {
    final char = StorageService.getCharacter();
    state = state.copyWith(selectedCharacterId: char);
  }

  void _loadHearts() {
    final hearts = StorageService.getHeartsState().regenerated(DateTime.now());
    StorageService.saveHeartsState(hearts);
    state = state.copyWith(hearts: hearts);
  }

  /// Re-applies pending regen so anything watching [GameState.hearts] (e.g.
  /// a level-select countdown) reflects real elapsed time, not just the
  /// value from when the provider was created.
  void refreshHearts() {
    if (_inLevel) return; // the clock is stopped during a level
    final hearts = state.hearts.regenerated(DateTime.now());
    if (hearts.count != state.hearts.count) {
      StorageService.saveHeartsState(hearts);
    }
    state = state.copyWith(hearts: hearts);
  }

  /// Hearts do not come back while a level is being played: the regen clock
  /// stops when it starts and carries on, from where it was, when it ends.
  /// (Before this, a heart could reappear mid-level, so what the menu showed
  /// afterwards did not match the level.)
  bool _inLevel = false;
  Duration? _remainingAtLevelStart;

  void enterLevel() {
    if (_inLevel) return;
    final now = DateTime.now();
    final hearts = state.hearts.regenerated(now);
    _remainingAtLevelStart = hearts.timeUntilNext(now);
    _inLevel = true;
    StorageService.saveHeartsState(hearts);
    state = state.copyWith(hearts: hearts);
  }

  void exitLevel() {
    if (!_inLevel) return;
    _inLevel = false;
    final hearts =
        state.hearts.resumedAfterLevel(DateTime.now(), _remainingAtLevelStart);
    _remainingAtLevelStart = null;
    StorageService.saveHeartsState(hearts);
    state = state.copyWith(hearts: hearts);
  }

  /// Whether hearts are not spent: the testing switch that opens every era
  /// (`unlock_all_provider.dart`) is on, so a tester can play on without
  /// waiting for hearts. Read from storage so it needs no provider.
  bool get heartsAreFree => StorageService.getUnlockAll();

  bool get canStartLevel => heartsAreFree || state.hearts.count > 0;

  /// One heart lost to any in-level damage event (enemy contact, hazard
  /// hit, falling) — the same shared pool shown on the menu screens
  /// (GAMEPLAY-V2.md section 8). `ChronoGame.onHeartLost` calls this once
  /// per hit, so the persisted count stays in lockstep with the in-game HUD
  /// instead of only updating once per fully-failed level.
  void loseHeart() {
    if (heartsAreFree) return;
    final now = DateTime.now();
    // In a level nothing is regenerated first: a heart must not appear just
    // before one is taken.
    final hearts = _inLevel
        ? state.hearts.consumed(now)
        : state.hearts.afterLevelFailed(now);
    StorageService.saveHeartsState(hearts);
    state = state.copyWith(hearts: hearts);
  }

  void selectCharacter(String characterId) {
    StorageService.saveCharacter(characterId);
    state = state.copyWith(selectedCharacterId: characterId);
  }

  void setEra(String eraId) {
    state = state.copyWith(currentEraId: eraId);
  }

  void setLevel(int level) {
    state = state.copyWith(currentLevel: level);
  }

  void updatePowerUps(PowerUps powerUps) {
    state = state.copyWith(powerUps: powerUps);
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  void useFiftyFifty() {
    if (state.powerUps.fiftyFifty > 0) {
      state.powerUps.fiftyFifty--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void useTimeFreeze() {
    if (state.powerUps.timeFreeze > 0) {
      state.powerUps.timeFreeze--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void useShield() {
    if (state.powerUps.shield > 0) {
      state.powerUps.shield--;
      state = state.copyWith(powerUps: state.powerUps);
    }
  }

  void awardPowerUp(int level) {
    // Powerup earned at milestones
    // NOTE: level 5 used to award Time Freeze, which has no working use in the
    // game (see question_overlay.dart). Removed rather than left dead — if you
    // want a level-5 reward, consider granting an extra fiftyFifty or shield here.
    if (level == 3) {
      state.powerUps.fiftyFifty++;
    } else if (level == 7) {
      state.powerUps.shield++;
    }
    state = state.copyWith(powerUps: state.powerUps);
  }
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());