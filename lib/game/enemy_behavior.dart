/// How an enemy moves and how many hits it takes to defeat
/// (GAMEPLAY-V2.md Section 5's behaviour table).
///
/// - walker: paces back and forth, turns to face a student who comes close. 1 hit.
/// - chaser: walks towards a student who comes close (CombatConstants.chaser*). 1 hit.
/// - heavy: stands still until a student comes close, then flashes and lunges. 2 hits.
enum EnemyBehavior { walker, chaser, heavy }

/// How a blast chaser looks when it bursts (EnemyBurstComponent).
enum BurstStyle { smoke, paper, storm }

class EnemyTypeData {
  final EnemyBehavior behavior;
  final int maxHp;

  /// Set for the kinds that fuse and burst when they chase (the spirit, the flyers,
  /// the cloud). Null for the rest: a chaser without one (a soldier the map made a
  /// chaser) crouches and dashes instead.
  final BurstStyle? burst;

  /// The part of this enemy that hurts and can be hit, in game units
  /// (width x height). Null means the old rule: a centred
  /// `enemyHitWidthFraction` x `enemyHitHeightFraction` rectangle of the 90x108 box,
  /// which fits the tall humans. A value means the body is low or wide (a tank, a
  /// cloud), so the rectangle is that size and sits ON THE GROUND (its bottom at
  /// the feet line) instead of floating in the middle of the tall box.
  final double? hitWidth;
  final double? hitHeight;

  const EnemyTypeData({
    required this.behavior,
    required this.maxHp,
    this.burst,
    this.hitWidth,
    this.hitHeight,
  });

  /// Whether the hit area sits on the ground with its own size (see [hitWidth]).
  bool get hasBodyHit => hitWidth != null && hitHeight != null;
}

/// Every enemy sprite this game has art for, mapped to its behaviour and HP.
/// Looked up by the same sprite-name string `EnemyComponent._getEnemyTypeForEra()`
/// already picks.
const Map<String, EnemyTypeData> enemyTypeTable = {
  // Walkers — 1 hit.
  'tribal_warrior': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'spanish_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'american_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  // 85x89 picture with a rifle held out: the body itself is about 50 wide.
  'japanese_soldier': EnemyTypeData(
      behavior: EnemyBehavior.walker, maxHp: 1, hitWidth: 50, hitHeight: 86),
  // Chasers — 1 hit. The three that used to run as Walkers until this existed.
  'dark_spirit': EnemyTypeData(
      behavior: EnemyBehavior.chaser, maxHp: 1, burst: BurstStyle.smoke),
  'propaganda': EnemyTypeData(
      behavior: EnemyBehavior.chaser, maxHp: 1, burst: BurstStyle.paper),
  // Wide and low (85x69): a body-sized hit area on the ground.
  'misinfo_cloud': EnemyTypeData(
      behavior: EnemyBehavior.chaser,
      maxHp: 1,
      burst: BurstStyle.storm,
      hitWidth: 75,
      hitHeight: 66),
  // Heavies — 2 hits, lunge when you come close.
  // Wide and low (85x60): nothing above 60 units can hurt the student or be hit.
  'tank': EnemyTypeData(
      behavior: EnemyBehavior.heavy, maxHp: 2, hitWidth: 80, hitHeight: 60),
  'tax_collector': EnemyTypeData(behavior: EnemyBehavior.heavy, maxHp: 2),
  'corruption_figure': EnemyTypeData(behavior: EnemyBehavior.heavy, maxHp: 2),
};

/// Falls back to a 1-HP Walker for any sprite name not in the table above —
/// shouldn't happen given the 10-sprite closure `_getEnemyTypeForEra`
/// selects from, but defends against it the same way `getEraById`'s
/// `orElse` does rather than throwing.
const EnemyTypeData defaultEnemyTypeData =
    EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1);

EnemyTypeData enemyTypeDataFor(String spriteType) =>
    enemyTypeTable[spriteType] ?? defaultEnemyTypeData;
