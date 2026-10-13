import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/hearts_state.dart';
import '../models/student.dart';
import '../services/server_clock.dart';
import 'auth_provider.dart';
import '../services/storage_service.dart';

class GameState {
  final String selectedCharacterId;
  final String currentEraId;
  final int currentLevel;
  final PowerUps powerUps;
  final int coins;
  final HeartsState hearts;

  /// Characters this student has bought (the free ones are not listed).
  final Set<String> unlockedCharacters;

  GameState({
    this.selectedCharacterId = 'rizal',
    this.currentEraId = 'pre-colonial',
    this.currentLevel = 1,
    PowerUps? powerUps,
    this.coins = 0,
    HeartsState? hearts,
    this.unlockedCharacters = const {},
  })  : powerUps = powerUps ?? PowerUps(),
        hearts = hearts ?? HeartsState.initial();

  GameState copyWith({
    String? selectedCharacterId,
    String? currentEraId,
    int? currentLevel,
    PowerUps? powerUps,
    int? coins,
    HeartsState? hearts,
    Set<String>? unlockedCharacters,
  }) {
    return GameState(
      selectedCharacterId:
          selectedCharacterId ?? this.selectedCharacterId,
      currentEraId: currentEraId ?? this.currentEraId,
      currentLevel: currentLevel ?? this.currentLevel,
      powerUps: powerUps ?? this.powerUps,
      coins: coins ?? this.coins,
      hearts: hearts ?? this.hearts,
      unlockedCharacters: unlockedCharacters ?? this.unlockedCharacters,
    );
  }
}

/// What can be bought with coins besides a heart.
enum PowerUpKind {
  fiftyFifty(GameConstants.fiftyFiftyPriceCoins),
  shield(GameConstants.shieldPriceCoins),
  timeFreeze(GameConstants.timeFreezePriceCoins);

  const PowerUpKind(this.priceCoins);
  final int priceCoins;
}

class GameNotifier extends StateNotifier<GameState> {
  /// Hearts are counted in the server's time ([ServerClock]), never the phone's:
  /// the phone's clock is the student's to change.
  GameNotifier({ServerClock? clock})
      : _clock = clock ?? ServerClock.instance,
        super(GameState()) {
    _loadCharacter();
    _loadHearts();
    _clock.sync().then((_) {
      if (mounted) refreshHearts();
    });
  }

  final ServerClock _clock;

  void _loadCharacter() {
    final char = StorageService.getCharacter();
    state = state.copyWith(selectedCharacterId: char);
  }

  /// [hearts] with the countdown started if it had no time to start with, and
  /// whatever has come back since applied. Unchanged until the server's time is
  /// known: without it nothing comes back.
  HeartsState _settled(HeartsState hearts) {
    final now = _clock.now;
    if (now == null) return hearts;
    return hearts.anchoredAt(now).regenerated(now);
  }

  void _store(HeartsState hearts) {
    final before = state.hearts;
    if (hearts.count != before.count || hearts.regenStartMs != before.regenStartMs) {
      StorageService.saveHeartsState(hearts);
    }
    state = state.copyWith(hearts: hearts);
  }

  void _loadHearts() {
    final hearts = _settled(StorageService.getHeartsState());
    StorageService.saveHeartsState(hearts);
    state = state.copyWith(hearts: hearts);
  }

  /// Re-applies pending regen so anything watching [GameState.hearts] (e.g.
  /// a level-select countdown) reflects real elapsed time, not just the
  /// value from when the provider was created.
  void refreshHearts() {
    _clock.syncIfNeeded();
    if (_inLevel) return; // the clock is stopped during a level
    _store(_settled(state.hearts));
  }

  /// Time until the next heart, in server time, or null if the pool is full or
  /// the server's time is not known yet (hearts wait for it).
  Duration? get heartCountdown {
    final now = _clock.now;
    return now == null ? null : state.hearts.timeUntilNext(now);
  }

  /// Hearts do not come back while a level is being played: the regen clock
  /// stops when it starts and carries on, from where it was, when it ends.
  /// (Before this, a heart could reappear mid-level, so what the menu showed
  /// afterwards did not match the level.)
  bool _inLevel = false;
  Duration? _remainingAtLevelStart;

  void enterLevel() {
    if (_inLevel) return;
    final hearts = _settled(state.hearts);
    final now = _clock.now;
    _remainingAtLevelStart = now == null ? null : hearts.timeUntilNext(now);
    _inLevel = true;
    _store(hearts);
  }

  void exitLevel() {
    if (!_inLevel) return;
    _inLevel = false;
    final now = _clock.now;
    // With no server time the countdown starts afresh when there is one.
    final hearts = now == null
        ? state.hearts.unanchored()
        : state.hearts.resumedAfterLevel(now, _remainingAtLevelStart);
    _remainingAtLevelStart = null;
    _store(hearts);
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
    final now = _clock.now;
    // In a level nothing is regenerated first: a heart must not appear just
    // before one is taken.
    final HeartsState hearts;
    if (now == null) {
      hearts = state.hearts.spentWithoutClock();
    } else {
      hearts = _inLevel
          ? state.hearts.anchoredAt(now).consumed(now)
          : state.hearts.afterLevelFailed(now);
    }
    _store(hearts);
  }

  /// Whose wallet is loaded, or null with nobody logged in.
  String? _walletOwner;

  /// Loads [studentId]'s coins, power-ups and bought characters from this phone
  /// (a student with none starts empty), or empties them when nobody is logged
  /// in. A shared phone keeps one wallet per student.
  ///
  /// Spending is kept on the phone: the server has no coins to keep. A reinstall
  /// starts the wallet again.
  void loadWallet(String? studentId) {
    if (studentId == _walletOwner) return;
    _walletOwner = studentId;
    final saved = studentId == null ? null : StorageService.getWallet(studentId);
    final powerUps = PowerUps(
      fiftyFifty: (saved?['fiftyFifty'] as num?)?.toInt() ?? 0,
      timeFreeze: (saved?['timeFreeze'] as num?)?.toInt() ?? 0,
      shield: (saved?['shield'] as num?)?.toInt() ?? 0,
    );
    final unlocked = {
      for (final id in (saved?['unlocked'] as List?) ?? const []) '$id',
    };
    var character = state.selectedCharacterId;
    final keptCharacter = _isUnlocked(character, unlocked);
    if (!keptCharacter) character = _firstFree.id;
    state = state.copyWith(
      coins: (saved?['coins'] as num?)?.toInt() ?? 0,
      powerUps: powerUps,
      unlockedCharacters: unlocked,
      selectedCharacterId: character,
    );
    if (!keptCharacter) StorageService.saveCharacter(character);
  }

  /// Writes the wallet to the phone. Call after anything that changes it,
  /// including a level where power-ups were used (they are changed in place).
  void saveWallet() {
    final id = _walletOwner;
    if (id == null) return;
    StorageService.saveWallet(id, {
      'coins': state.coins,
      'fiftyFifty': state.powerUps.fiftyFifty,
      'timeFreeze': state.powerUps.timeFreeze,
      'shield': state.powerUps.shield,
      'unlocked': state.unlockedCharacters.toList()..sort(),
    });
  }

  static CharacterData get _firstFree => allCharacters.firstWhere((c) => c.unlockCost == 0);

  /// The testing switch that opens every era also opens every character.
  bool _isUnlocked(String characterId, Set<String> bought) {
    final c = allCharacters.where((c) => c.id == characterId).firstOrNull;
    if (c == null) return false;
    return c.unlockCost == 0 || bought.contains(characterId) || StorageService.getUnlockAll();
  }

  bool isCharacterUnlocked(String characterId) =>
      _isUnlocked(characterId, state.unlockedCharacters);

  /// Picks a character. A locked one is refused: it has to be bought first.
  void selectCharacter(String characterId) {
    if (!isCharacterUnlocked(characterId)) return;
    StorageService.saveCharacter(characterId);
    state = state.copyWith(selectedCharacterId: characterId);
  }

  /// Pays for a locked character. False, with nothing changed, if it is free
  /// already, unknown, or the student cannot afford it.
  bool unlockCharacter(String characterId) {
    final c = allCharacters.where((c) => c.id == characterId).firstOrNull;
    if (c == null || isCharacterUnlocked(characterId) || state.coins < c.unlockCost) {
      return false;
    }
    state = state.copyWith(
      coins: state.coins - c.unlockCost,
      unlockedCharacters: {...state.unlockedCharacters, characterId},
    );
    saveWallet();
    return true;
  }

  /// Pays [GameConstants.heartPriceCoins] for one heart. False, with nothing
  /// changed, if the pool is full or the student cannot afford it.
  bool buyHeart() {
    if (state.hearts.count >= GameConstants.maxHearts) return false;
    if (state.coins < GameConstants.heartPriceCoins) return false;
    state = state.copyWith(coins: state.coins - GameConstants.heartPriceCoins);
    _store(state.hearts.withHeart());
    saveWallet();
    return true;
  }

  /// Fills the heart pool in one go: all or nothing, so a student never pays
  /// for some of the hearts and is left short of the rest.
  bool buyAllHearts() {
    final missing = GameConstants.maxHearts - state.hearts.count;
    final cost = missing * GameConstants.heartPriceCoins;
    if (missing <= 0 || state.coins < cost) return false;
    var hearts = state.hearts;
    for (var i = 0; i < missing; i++) {
      hearts = hearts.withHeart();
    }
    state = state.copyWith(coins: state.coins - cost);
    _store(hearts);
    saveWallet();
    return true;
  }

  /// Pays for one power-up. False, with nothing changed, if the student cannot
  /// afford it.
  bool buyPowerUp(PowerUpKind kind) {
    if (state.coins < kind.priceCoins) return false;
    final p = state.powerUps;
    switch (kind) {
      case PowerUpKind.fiftyFifty:
        p.fiftyFifty++;
      case PowerUpKind.shield:
        p.shield++;
      case PowerUpKind.timeFreeze:
        p.timeFreeze++;
    }
    state = state.copyWith(coins: state.coins - kind.priceCoins, powerUps: p);
    saveWallet();
    return true;
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

  /// Adds coins picked up in a level to the wallet.
  void addCoins(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(coins: state.coins + amount);
    saveWallet();
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
    saveWallet();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final notifier = GameNotifier();
  // The wallet follows whoever is logged in.
  ref.listen<String?>(
    authProvider.select((s) => s.student?.id),
    (_, id) => notifier.loadWallet(id),
    fireImmediately: true,
  );
  return notifier;
});