/// What kind of thing floats in the air of an era.
enum ParticleKind { fireflies, petals, leaves, embers, dust }

/// What stands in the distance of an era.
enum SceneryKind { huts, church, houses, school, ruins, skyline }

/// How one row of trees looks.
class TreeStyle {
  const TreeStyle(this.trunk, this.leaf, this.haze, {this.dead = false});

  final int trunk;

  /// Dark, middle and light leaf colours. Empty for bare trees.
  final List<int> leaf;

  /// How much distance haze is washed over the row: far rows fade, near rows do not.
  final double haze;
  final bool dead;
}

/// The colours and mood of one era's world: sky, hills, distant buildings, three rows
/// of trees, light and what drifts in the air. Pure numbers, so a new era or a tweak
/// is one entry here.
class EraLook {
  const EraLook({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.sunX,
    required this.sunY,
    required this.sunRadius,
    required this.fog,
    required this.hillFar,
    required this.hillNear,
    required this.silhouette,
    required this.far,
    required this.mid,
    required this.near,
    required this.ray,
    required this.rayAlpha,
    required this.mist,
    required this.scenery,
    required this.particles,
    required this.particleColor,
    required this.grade,
    required this.foreground,
  });

  final int skyTop;
  final int skyBottom;
  final int sun;

  /// Where the sun sits, as a fraction of the screen width and height.
  final double sunX;
  final double sunY;

  /// As a fraction of the screen height.
  final double sunRadius;

  /// The colour distance fades into.
  final int fog;
  final int hillFar;
  final int hillNear;
  final int silhouette;
  final TreeStyle far;
  final TreeStyle mid;
  final TreeStyle near;
  final int ray;
  final double rayAlpha;
  final int mist;
  final SceneryKind scenery;
  final ParticleKind particles;
  final int particleColor;

  /// A thin wash of colour over the whole picture (alpha is in the number).
  final int grade;

  /// The dark colour of the grass blades and hanging leaves in front of everything.
  final int foreground;

  /// The look for an era id (`pre-colonial`, `spanish`, `nationalism`, `american`,
  /// `ww2`, `modern`). An unknown id gets the first era's look.
  static EraLook of(String eraId) => switch (eraId) {
        'spanish' => _spanish,
        'nationalism' => _nationalism,
        'american' => _american,
        'ww2' => _ww2,
        'modern' => _modern,
        _ => _sinaunang,
      };

  static const List<String> eraIds = [
    'pre-colonial',
    'spanish',
    'nationalism',
    'american',
    'ww2',
    'modern',
  ];

  /// Morning in the forest: huts and palms in the distance, fireflies.
  static const EraLook _sinaunang = EraLook(
    skyTop: 0xFF3F9AA3,
    skyBottom: 0xFFF4E2A0,
    sun: 0xFFFFF0B0,
    sunX: .74,
    sunY: .26,
    sunRadius: .10,
    fog: 0xFFD6ECB4,
    hillFar: 0xFF68AD82,
    hillNear: 0xFF4A9170,
    silhouette: 0xFF245A4C,
    far: TreeStyle(0xFF3D6A4A, [0xFF2F7A55, 0xFF4C9A62, 0xFF7CC36F], .50),
    mid: TreeStyle(0xFF2A3F2E, [0xFF1F6A3F, 0xFF348A4D, 0xFF5FB35A], .26),
    near: TreeStyle(0xFF1D2A21, [0xFF124A2C, 0xFF1F6A3B, 0xFF3D8F4C], .04),
    ray: 0xFFFFF2B0,
    rayAlpha: .16,
    mist: 0xFFE9F7C9,
    scenery: SceneryKind.huts,
    particles: ParticleKind.fireflies,
    particleColor: 0xFFD8FF7A,
    grade: 0x1AFFD678,
    foreground: 0xFF0B2417,
  );

  /// Dusk over a Spanish town: a church tower and a stone arcade, petals.
  static const EraLook _spanish = EraLook(
    skyTop: 0xFF5A3D86,
    skyBottom: 0xFFFFB06A,
    sun: 0xFFFFD28E,
    sunX: .62,
    sunY: .42,
    sunRadius: .15,
    fog: 0xFFF4B48C,
    hillFar: 0xFFA8688A,
    hillNear: 0xFF85507A,
    silhouette: 0xFF35203F,
    far: TreeStyle(0xFF6B4152, [0xFF8A5A62, 0xFFB0755A, 0xFFD89A62], .52),
    mid: TreeStyle(0xFF3A2430, [0xFF5D4A3A, 0xFF8A7440, 0xFFBF9A4E], .26),
    near: TreeStyle(0xFF241520, [0xFF3B3626, 0xFF5E5A30, 0xFF8A7A3A], .04),
    ray: 0xFFFFC88A,
    rayAlpha: .20,
    mist: 0xFFFFD2A8,
    scenery: SceneryKind.church,
    particles: ParticleKind.petals,
    particleColor: 0xFFFF9AB0,
    grade: 0x21FF8C50,
    foreground: 0xFF1C0F1A,
  );

  /// Golden dusty evening of the revolution: stone-and-wood houses, drifting dust.
  static const EraLook _nationalism = EraLook(
    skyTop: 0xFF7A5C7E,
    skyBottom: 0xFFF0C27A,
    sun: 0xFFFFD890,
    sunX: .66,
    sunY: .32,
    sunRadius: .11,
    fog: 0xFFE8C48E,
    hillFar: 0xFF9A7A6A,
    hillNear: 0xFF7A5E58,
    silhouette: 0xFF3A2A38,
    far: TreeStyle(0xFF5E4638, [0xFF7A6A3A, 0xFFA08A48, 0xFFC8AE5C], .50),
    mid: TreeStyle(0xFF3A2A22, [0xFF5A5A32, 0xFF80803E, 0xFFA8A04A], .26),
    near: TreeStyle(0xFF241A16, [0xFF3A4026, 0xFF566032, 0xFF7A8240], .04),
    ray: 0xFFFFE0A0,
    rayAlpha: .18,
    mist: 0xFFF0D8A8,
    scenery: SceneryKind.houses,
    particles: ParticleKind.dust,
    particleColor: 0xFFFFE8B0,
    grade: 0x1AFFC070,
    foreground: 0xFF1E1410,
  );

  /// A bright blue day: a wooden schoolhouse with a flag, falling leaves.
  static const EraLook _american = EraLook(
    skyTop: 0xFF4A8CD8,
    skyBottom: 0xFFCFE8F4,
    sun: 0xFFFFFFE0,
    sunX: .78,
    sunY: .20,
    sunRadius: .08,
    fog: 0xFFDCEEF4,
    hillFar: 0xFF7AB890,
    hillNear: 0xFF5C9C78,
    silhouette: 0xFF3C5A6A,
    far: TreeStyle(0xFF4A6A50, [0xFF3F8A5A, 0xFF5CAA6C, 0xFF90D080], .50),
    mid: TreeStyle(0xFF2F4A36, [0xFF2A7A48, 0xFF48A05C, 0xFF7CC870], .26),
    near: TreeStyle(0xFF22301F, [0xFF1A5A34, 0xFF2E7A44, 0xFF54A060], .04),
    ray: 0xFFFFFFFF,
    rayAlpha: .12,
    mist: 0xFFF0F8F8,
    scenery: SceneryKind.school,
    particles: ParticleKind.leaves,
    particleColor: 0xFFD8E890,
    grade: 0x0FFFF8E0,
    foreground: 0xFF0E2418,
  );

  /// A burning town under a grey sky: ruins, bare trees, embers.
  static const EraLook _ww2 = EraLook(
    skyTop: 0xFF232C3D,
    skyBottom: 0xFF8C9194,
    sun: 0xFFD9D4C4,
    sunX: .76,
    sunY: .28,
    sunRadius: .09,
    fog: 0xFF9AA1A6,
    hillFar: 0xFF56616C,
    hillNear: 0xFF444E58,
    silhouette: 0xFF1F262D,
    far: TreeStyle(0xFF3B434B, [], .55, dead: true),
    mid: TreeStyle(0xFF272C33, [], .30, dead: true),
    near: TreeStyle(0xFF16191E, [], .05, dead: true),
    ray: 0xFFCFD6DA,
    rayAlpha: .10,
    mist: 0xFFB7BEC2,
    scenery: SceneryKind.ruins,
    particles: ParticleKind.embers,
    particleColor: 0xFFFF8A2A,
    grade: 0x24466482,
    foreground: 0xFF0D1013,
  );

  /// A hazy cyan city: towers in the distance, dust in the air.
  static const EraLook _modern = EraLook(
    skyTop: 0xFF3C6E86,
    skyBottom: 0xFFB9D8DC,
    sun: 0xFFE8F4F0,
    sunX: .70,
    sunY: .30,
    sunRadius: .09,
    fog: 0xFFB4D0D4,
    hillFar: 0xFF6A9AA0,
    hillNear: 0xFF52808A,
    silhouette: 0xFF2F4A58,
    far: TreeStyle(0xFF3A5A58, [0xFF2E6E66, 0xFF468A7C, 0xFF6CAE96], .55),
    mid: TreeStyle(0xFF2A403E, [0xFF225A52, 0xFF3A7A6A, 0xFF5E9C84], .30),
    near: TreeStyle(0xFF1C2C2A, [0xFF164440, 0xFF285E54, 0xFF438070], .05),
    ray: 0xFFDFF6F6,
    rayAlpha: .10,
    mist: 0xFFC8E4E4,
    scenery: SceneryKind.skyline,
    particles: ParticleKind.dust,
    particleColor: 0xFFE8F8F4,
    grade: 0x1A50B0C0,
    foreground: 0xFF0C1E20,
  );
}
