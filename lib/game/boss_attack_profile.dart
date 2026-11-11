import 'dart:ui' show Color;

import 'boss_plan.dart';

/// The attacks the six bosses throw. Rules are the same for all of them; only the look and
/// the path differ, and the path never changes how many seconds the student has.
enum BossAttackKind {
  /// Bakunawa: a stream of water with a rounded head and droplets.
  water,

  /// Bakunawa, phase 3: a standing water whirlpool rolling along the floor.
  whirl,

  /// Governor (Pananakop ng Espanya): a flying gold sword slash.
  gslash,

  /// Governor, phase 3: two blue ghost knights with shields march in along the ground.
  knights,

  /// Governor (Pag-usbong ng Nasyonalismo): two translucent ghost shield knights rush in.
  ghost,

  /// General: pistol shots.
  pistol,

  /// General, phase 3: a three-bullet volley, then a blue sonic blast of arcs.
  sonic,

  /// Commander: a flying katana slash, low along the ground.
  slash,

  /// Commander, phase 3: a green whirlwind ring that grows as it comes.
  wind,

  /// Corruption boss: a flaming fan of five spinning banknotes.
  fan,

  /// Corruption boss, phase 3: a purple money vortex rolling on the floor.
  vortex,
}

extension BossAttackKindGeometry on BossAttackKind {
  /// Where the attack leaves the boss: x from the boss's middle (negative is towards the
  /// hero), and the height above the boss's feet.
  ({double dx, double up}) get start => switch (this) {
        BossAttackKind.water => (dx: -60, up: 88),
        BossAttackKind.whirl => (dx: -70, up: 14),
        BossAttackKind.gslash => (dx: -90, up: 64),
        BossAttackKind.knights => (dx: -70, up: 0),
        BossAttackKind.ghost => (dx: -20, up: 0),
        BossAttackKind.pistol => (dx: -84, up: 96),
        BossAttackKind.sonic => (dx: -84, up: 96),
        BossAttackKind.slash => (dx: -90, up: 28),
        BossAttackKind.wind => (dx: -60, up: 32),
        BossAttackKind.fan => (dx: -64, up: 60),
        BossAttackKind.vortex => (dx: -70, up: 32),
      };

  /// Where it meets the hero: x from the hero's middle (positive is the hero's front), and
  /// the height above the hero's feet.
  ({double dx, double up}) get end => switch (this) {
        BossAttackKind.water => (dx: 34, up: 68),
        BossAttackKind.whirl => (dx: 34, up: 14),
        BossAttackKind.gslash => (dx: 34, up: 64),
        BossAttackKind.knights => (dx: 34, up: 0),
        BossAttackKind.ghost => (dx: 70, up: 0),
        BossAttackKind.pistol => (dx: 34, up: 70),
        BossAttackKind.sonic => (dx: 34, up: 70),
        BossAttackKind.slash => (dx: 34, up: 28),
        BossAttackKind.wind => (dx: 34, up: 32),
        BossAttackKind.fan => (dx: 34, up: 64),
        BossAttackKind.vortex => (dx: 34, up: 32),
      };

  /// Whether the hero's counter can send it back at the boss. The ghost knights are not sent
  /// back: they vanish.
  bool get reflects => this != BossAttackKind.ghost;

  /// Whether it travels along the floor (it is drawn standing on it).
  bool get onFloor =>
      this == BossAttackKind.whirl ||
      this == BossAttackKind.knights ||
      this == BossAttackKind.ghost ||
      this == BossAttackKind.vortex;

  /// The boss shows its special picture (not the attack one) when it throws this.
  bool get usesSpecialPose =>
      this == BossAttackKind.whirl ||
      this == BossAttackKind.knights ||
      this == BossAttackKind.ghost ||
      this == BossAttackKind.sonic ||
      this == BossAttackKind.wind ||
      this == BossAttackKind.vortex;

  /// How far back (in progress) one step of its trail is, and how many steps it has.
  ({double step, int count}) get trail => switch (this) {
        BossAttackKind.water => (step: .008, count: 66),
        BossAttackKind.whirl => (step: .012, count: 8),
        BossAttackKind.gslash => (step: .01, count: 12),
        BossAttackKind.knights => (step: .01, count: 4),
        BossAttackKind.ghost => (step: .01, count: 4),
        BossAttackKind.pistol => (step: .006, count: 12),
        BossAttackKind.sonic => (step: .008, count: 28),
        BossAttackKind.slash => (step: .01, count: 14),
        BossAttackKind.wind => (step: .012, count: 8),
        BossAttackKind.fan => (step: .01, count: 12),
        BossAttackKind.vortex => (step: .012, count: 8),
      };
}

/// What is special about one boss: its name, its attacks, and small tweaks of its pictures.
class BossProfile {
  const BossProfile({
    required this.name,
    required this.main,
    this.extra,
    required this.glow,
    this.attackShift = 0,
    this.specialShift = 0,
    this.hitDx = -36,
    this.hitUp = 70,
  });

  /// What the HUD calls it.
  final String name;

  /// The attack of rounds 1 to 7.
  final BossAttackKind main;

  /// The attack of rounds 8 to 10 (phase 3), if the boss has one.
  final BossAttackKind? extra;

  /// The colour of its glow while it winds up.
  final Color glow;

  /// How far its picture is nudged sideways in the throw pose (attack and special pictures).
  final double attackShift;
  final double specialShift;

  /// Where a sent-back attack hits it: x from its middle, height above its feet.
  final double hitDx;
  final double hitUp;

  /// The attack thrown in [round].
  BossAttackKind attackForRound(int round) {
    final e = extra;
    return (e != null && round >= BossPlan.extraFromRound) ? e : main;
  }

  static const BossProfile bakunawa = BossProfile(
    name: 'Bakunawa',
    main: BossAttackKind.water,
    extra: BossAttackKind.whirl,
    glow: Color(0xFF7FD6FF),
    hitDx: -46,
    hitUp: 88,
  );
  static const BossProfile governorSpain = BossProfile(
    name: 'Governor',
    main: BossAttackKind.gslash,
    extra: BossAttackKind.knights,
    glow: Color(0xFFFFD24A),
    attackShift: -9,
    specialShift: -4,
  );
  static const BossProfile governorNation = BossProfile(
    name: 'Governor',
    main: BossAttackKind.ghost,
    glow: Color(0xFF7FB8FF),
    attackShift: -9,
    specialShift: -4,
    hitUp: 66,
  );
  static const BossProfile general = BossProfile(
    name: 'General',
    main: BossAttackKind.pistol,
    extra: BossAttackKind.sonic,
    glow: Color(0xFF9BD06A),
    attackShift: 2,
    specialShift: 2,
    hitDx: -24,
  );
  static const BossProfile commander = BossProfile(
    name: 'Commander',
    main: BossAttackKind.slash,
    extra: BossAttackKind.wind,
    glow: Color(0xFF58D36A),
    attackShift: -1,
    specialShift: 14,
    hitDx: -24,
    hitUp: 78,
  );
  static const BossProfile corruption = BossProfile(
    name: 'Corruption boss',
    main: BossAttackKind.fan,
    extra: BossAttackKind.vortex,
    glow: Color(0xFFB36BFF),
    attackShift: 20,
    specialShift: 20,
    hitDx: -46,
    hitUp: 64,
  );

  /// The boss of an era, by the era's id.
  static BossProfile forEra(String eraId) => switch (eraId) {
        'pre-colonial' => bakunawa,
        'spanish' => governorSpain,
        'nationalism' => governorNation,
        'american' => general,
        'ww2' => commander,
        'modern' => corruption,
        _ => governorSpain,
      };
}
