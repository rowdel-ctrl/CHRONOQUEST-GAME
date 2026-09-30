/// How an enemy moves and how many hits it takes to defeat
/// (GAMEPLAY-V2.md Section 5's behaviour table). Chaser is explicitly
/// skipped this phase — the three sprites that would use it (dark_spirit,
/// propaganda, misinfo_cloud) run as Walkers instead until it's built.
enum EnemyBehavior { walker, heavy }

class EnemyTypeData {
  final EnemyBehavior behavior;
  final int maxHp;

  const EnemyTypeData({required this.behavior, required this.maxHp});
}

/// Every enemy sprite this game has art for, mapped to its behaviour and HP
/// — a direct transcription of Section 5's table. Looked up by the same
/// sprite-name string `EnemyComponent._getEnemyTypeForEra()` already picks.
const Map<String, EnemyTypeData> enemyTypeTable = {
  // Walkers — 1 hit.
  'tribal_warrior': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'spanish_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'american_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'japanese_soldier': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'dark_spirit': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'propaganda': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  'misinfo_cloud': EnemyTypeData(behavior: EnemyBehavior.walker, maxHp: 1),
  // Heavies — 2 hits, barely move.
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
