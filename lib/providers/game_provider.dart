import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../services/storage_service.dart';

class GameState {
  final String selectedCharacterId;
  final String currentEraId;
  final int currentLevel;
  final PowerUps powerUps;
  final int coins;

  GameState({
    this.selectedCharacterId = 'rizal',
    this.currentEraId = 'pre-colonial',
    this.currentLevel = 1,
    PowerUps? powerUps,
    this.coins = 0,
  }) : powerUps = powerUps ?? PowerUps();

  GameState copyWith({
    String? selectedCharacterId,
    String? currentEraId,
    int? currentLevel,
    PowerUps? powerUps,
    int? coins,
  }) {
    return GameState(
      selectedCharacterId:
          selectedCharacterId ?? this.selectedCharacterId,
      currentEraId: currentEraId ?? this.currentEraId,
      currentLevel: currentLevel ?? this.currentLevel,
      powerUps: powerUps ?? this.powerUps,
      coins: coins ?? this.coins,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState()) {
    _loadCharacter();
  }

  void _loadCharacter() {
    final char = StorageService.getCharacter();
    state = state.copyWith(selectedCharacterId: char);
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
    if (level == 3) {
      state.powerUps.fiftyFifty++;
    } else if (level == 5) {
      state.powerUps.timeFreeze++;
    } else if (level == 7) {
      state.powerUps.shield++;
    }
    state = state.copyWith(powerUps: state.powerUps);
  }
}

final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier());
