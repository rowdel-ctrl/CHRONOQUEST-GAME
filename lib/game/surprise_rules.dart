import '../core/surprise_constants.dart';
import 'chrono_game.dart';
import 'components/player_component.dart';

/// The five surprises of the higher levels.
enum SurpriseKind { hopper, groundPop, fallingRock, thrower, golden }

/// A surprise an [EnemyComponent] carries on top of its normal behaviour. The map's
/// enemy `behavior` property picks it: `hopper`, `thrower` or `golden`. A ground pop
/// builds its enemy itself, with [popper].
enum EnemySurprise { none, hopper, popper, thrower, golden }

/// Which levels each surprise may appear in, and the map names that switch them on.
class SurpriseRules {
  SurpriseRules._();

  /// The first level of an era each kind may appear in.
  static int firstLevel(SurpriseKind kind) {
    switch (kind) {
      case SurpriseKind.hopper:
        return SurpriseConstants.firstHopperLevel;
      case SurpriseKind.groundPop:
        return SurpriseConstants.firstPopLevel;
      case SurpriseKind.fallingRock:
        return SurpriseConstants.firstRockLevel;
      case SurpriseKind.thrower:
        return SurpriseConstants.firstThrowerLevel;
      case SurpriseKind.golden:
        return SurpriseConstants.firstGoldenLevel;
    }
  }

  /// Whether [kind] may be in level [levelNo]. A boss room ([isArena]) never has one.
  /// A null [levelNo] (a level built without a number, as some tests do) allows it.
  static bool allowed(SurpriseKind kind, {int? levelNo, bool isArena = false}) {
    if (isArena) return false;
    if (levelNo == null) return true;
    return levelNo >= firstLevel(kind);
  }

  /// Whether a student standing with the middle of their body at [centreX] and their
  /// feet at [feetY] is inside a danger zone (a falling rock's shadow, a thrown item's
  /// ring) that is [radius] wide each side of [spotX] on the ground at [groundY].
  /// Feet [clearHeight] or more above the ground clear it, so a jump gets over it.
  static bool insideZone({
    required double centreX,
    required double feetY,
    required double spotX,
    required double groundY,
    required double radius,
    required double clearHeight,
  }) =>
      (centreX - spotX).abs() <= radius &&
      feetY > groundY - clearHeight &&
      feetY < groundY + 60;

  /// The enemy `behavior` values the map may use for a surprise.
  static const String hopperBehavior = 'hopper';
  static const String throwerBehavior = 'thrower';
  static const String goldenBehavior = 'golden';

  /// The surprise an enemy object with this map [behavior] gets in level [levelNo]:
  /// [EnemySurprise.none] for an ordinary behaviour, or when the level is too early
  /// for it (a map that marked a hopper in level 2 plays it as a plain walker).
  static EnemySurprise enemySurpriseFor(String? behavior,
      {int? levelNo, bool isArena = false}) {
    final (kind, surprise) = switch (behavior) {
      hopperBehavior => (SurpriseKind.hopper, EnemySurprise.hopper),
      throwerBehavior => (SurpriseKind.thrower, EnemySurprise.thrower),
      goldenBehavior => (SurpriseKind.golden, EnemySurprise.golden),
      _ => (null, EnemySurprise.none),
    };
    if (kind == null) return EnemySurprise.none;
    return allowed(kind, levelNo: levelNo, isArena: isArena)
        ? surprise
        : EnemySurprise.none;
  }

  /// The era's own walker art for the enemy a ground pop raises. The first era's is the
  /// dark spirit (a spirit that comes up out of the ground), the modern era has no
  /// walker so the cloud walks instead.
  static String popKindFor(String eraId) {
    switch (eraId) {
      case 'pre-colonial':
        return 'dark_spirit';
      case 'american':
        return 'american_soldier';
      case 'ww2':
        return 'japanese_soldier';
      case 'modern':
        return 'misinfo_cloud';
      default:
        return 'spanish_soldier'; // spanish, nationalism
    }
  }
}

/// Counts the surprises that are going on right now, so no more than
/// [SurpriseConstants.maxAtOnce] are at the same time. A surprise asks with
/// [tryStart] before it begins its warning and tells [finish] when it is over; one
/// that is refused just waits and asks again.
class SurpriseRegistry {
  SurpriseRegistry({this.limit = SurpriseConstants.maxAtOnce});

  final int limit;
  final Set<Object> _active = {};

  int get activeCount => _active.length;

  bool isActive(Object who) => _active.contains(who);

  /// True when [who] may go ahead: it already counts, or there is room.
  bool tryStart(Object who) {
    if (_active.contains(who)) return true;
    if (_active.length >= limit) return false;
    _active.add(who);
    return true;
  }

  /// [who] is over (or was removed). Safe to call when it was never counted.
  void finish(Object who) => _active.remove(who);

  void clear() => _active.clear();
}

final Expando<SurpriseRegistry> _registries = Expando<SurpriseRegistry>();

extension SurprisesOnGame on ChronoGame {
  /// The count of surprises in progress in this game. Kept off the game class itself
  /// so it needs no field there.
  SurpriseRegistry get surprises => _registries[this] ??= SurpriseRegistry();
}

extension StudentOnGame on ChronoGame {
  /// The student, or null in a bare game that has none yet.
  PlayerComponent? get studentOrNull {
    try {
      return player;
    } catch (_) {
      return null;
    }
  }
}
