/// How an enemy moves and how many hits it takes to defeat
/// (GAMEPLAY-V2.md Section 5's behaviour table).
///
/// - walker: paces back and forth, turns to face a student who comes close. 1 hit.
/// - chaser: walks towards a student who comes close (CombatConstants.chaser*). 1 hit.
/// - heavy: stands still until a student comes close, then flashes and lunges. 2 hits.
enum EnemyBehavior { walker, chaser, heavy }

class EnemyTypeData {
  final EnemyBehavior behavior;
  final int maxHp;

  const EnemyTypeData({required this.behavior, required this.maxHp});
}

/// Every enemy sprite this game has art for, mapped to its behaviour and HP.
/// Looked up by the same sprite-name string `EnemyComponent._getEnemyTypeForEra()`
/// already picks.
const Map<String, EnemyTypeData> enemyTypeTable = {
  // Walkers — 1 hit.
  'tribal_warrior': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'spanish_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'american_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'japanese_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  // Chasers — 1 hit. The three that used to run as Walkers until this existed.
  'dark_spirit': EnemyTypeData(behavior: EnemyBehavior.chaser, maxHp: 1),
  'propaganda': EnemyTypeData(behavior: EnemyBehavior.chaser, maxHp: 1),
  'misinfo_cloud': EnemyTypeData(behavior: EnemyBehavior.chaser, maxHp: 1),
  // Heavies — 2 hits, lunge when you come close.
  'tank': EnemyTypeData(behavior: EnemyBehavior.heavy, maxHp: 2),
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
