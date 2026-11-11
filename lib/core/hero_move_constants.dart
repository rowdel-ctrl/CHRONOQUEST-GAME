/// What each hero does when the one Attack button is pressed (the 2026-11 hero
/// moves). Every number here is a draft from the approved mockup, to be tuned by
/// playing. Keyed by the hero's id in `allCharacters`.
///
/// A move is either a ranged one (a flying thing that leaves the hero) or a dash
/// (the hero itself moves forward, safe while it does). The cooldown is the hero's
/// own and replaces `CombatConstants.attackCooldown` for the player.
enum HeroMoveKind {
  /// One flying thing that stops at the first enemy it hits (Del Pilar, Maria).
  shot,

  /// Turns back at the first enemy (or at the end of its range) and hits what it
  /// meets on the way home (Juan).
  boomerang,

  /// Passes through every enemy in its path (Luna, Maria Clara).
  wave,

  /// Several flying things one after another, each stopping at one enemy (Rizal).
  burst,

  /// The hero dashes forward, safe from harm, hitting every enemy in the path
  /// (Lapu-Lapu, Bonifacio).
  dash,
}

/// How a flying thing is drawn (all drawn in code, see hero_move_art.dart).
enum HeroMoveShape { star, net, bullet, saber, petals, page }

class HeroMove {
  final String heroId;

  /// Simple everyday Taglish name of the move.
  final String name;
  final HeroMoveKind kind;
  final HeroMoveShape? shape;

  /// Seconds before the next attack.
  final double cooldown;

  /// Ranged moves: how far it flies from the hero's front, and how fast (units/s).
  final double range;
  final double speed;

  /// Net: enemies this close (sideways) to the one it hits are caught too.
  final double groupRadius;

  /// Dash moves: how far, and in how many seconds.
  final double dashDistance;
  final double dashSeconds;

  /// Burst: how many are thrown, and the seconds between them.
  final int count;
  final double gap;

  /// The part of a flying thing that hits (centred on it).
  final double hitWidth;
  final double hitHeight;

  const HeroMove({
    required this.heroId,
    required this.name,
    required this.kind,
    required this.cooldown,
    this.shape,
    this.range = 0,
    this.speed = 0,
    this.groupRadius = 0,
    this.dashDistance = 0,
    this.dashSeconds = 0,
    this.count = 1,
    this.gap = 0,
    this.hitWidth = 30,
    this.hitHeight = HeroMoveConstants.shotHitHeight,
  });

  bool get isDash => kind == HeroMoveKind.dash;
  bool get isRanged => !isDash;

  /// Whether a thrown thing keeps going after it hits (a wave goes through everything;
  /// the boomerang does only on its way back, see [HeroMoveKind.boomerang]).
  bool get passesThrough => kind == HeroMoveKind.wave;
}

class HeroMoveConstants {
  /// How high above the hero's feet a flying thing flies.
  static const double shotHeight = 62;

  /// Where it starts, ahead of the hero's middle (a little past the front edge).
  static const double startAhead = 50;

  /// Default height of the hit area of a flying thing. 70 centred 62 above the
  /// feet reaches from 27 to 97 above them, so a low body (a tank, 60 tall) is hit.
  static const double shotHitHeight = 70;

  /// The boomerang is gone once it is this close to the hero on its way home.
  static const double boomerangCatchDistance = 30;

  /// No flying thing lives longer than this, whatever happens to it.
  static const double failsafeSeconds = 4;

  // ─── Dash ───────────────────────────────────────────────────────────────
  /// How far in front of (and behind) the hero's middle the slash reaches while
  /// dashing, and the height band of the slash above the feet.
  static const double dashReachFront = 64;
  static const double dashReachBack = 20;
  static const double dashBandTop = 100;
  static const double dashBandBottom = 10;

  /// The attack picture stays this long after the dash ends.
  static const double dashAfterSeconds = 0.14;

  /// Afterimages behind a dashing hero.
  static const int afterimages = 3;
  static const double afterimageSpacing = 20;
  static const double afterimageAlpha = 0.22;

  // ─── Counter (a right answer in the boss fight) ─────────────────────────
  /// A flying counter never takes longer than this to arrive: a far target makes
  /// it faster than its own speed.
  static const double counterMaxFlightSeconds = 1.0;

  /// A counter dash stops this far short of the target's middle (about the hero's
  /// half width), so the hero meets the attack rather than passing through it.
  static const double counterMeetGap = 50;

  /// Seconds the hero glides back to where it stood after a counter dash.
  static const double counterGlideSeconds = 0.25;

  /// A counter always ends by itself within this.
  static const double counterFailsafeSeconds = 3;
}

/// Juan, Maria, Del Pilar, Lapu-Lapu, Bonifacio, Luna, Maria Clara, Rizal.
const Map<String, HeroMove> heroMoves = {
  'boy': HeroMove(
    heroId: 'boy',
    name: 'Boomerang na Barya',
    kind: HeroMoveKind.boomerang,
    shape: HeroMoveShape.star,
    range: 200,
    speed: 420,
    cooldown: 0.90,
    hitWidth: 34,
  ),
  'girl': HeroMove(
    heroId: 'girl',
    name: 'Malapad na Lambat',
    kind: HeroMoveKind.shot,
    shape: HeroMoveShape.net,
    range: 220,
    speed: 400,
    groupRadius: 45,
    cooldown: 0.60,
    hitWidth: 40,
  ),
  'delpilar': HeroMove(
    heroId: 'delpilar',
    name: 'Mahabang Tira',
    kind: HeroMoveKind.shot,
    shape: HeroMoveShape.bullet,
    range: 320,
    speed: 700,
    cooldown: 0.80,
    hitWidth: 26,
  ),
  'lapu': HeroMove(
    heroId: 'lapu',
    name: 'Mabigat na Sugod',
    kind: HeroMoveKind.dash,
    dashDistance: 140,
    dashSeconds: 0.22,
    cooldown: 0.90,
  ),
  'bonifacio': HeroMove(
    heroId: 'bonifacio',
    name: 'Mabilis na Sugod',
    kind: HeroMoveKind.dash,
    dashDistance: 100,
    dashSeconds: 0.16,
    cooldown: 0.55,
  ),
  'luna': HeroMove(
    heroId: 'luna',
    name: 'Alon ng Sable',
    kind: HeroMoveKind.wave,
    shape: HeroMoveShape.saber,
    range: 180,
    speed: 380,
    cooldown: 0.80,
    hitWidth: 40,
    hitHeight: 90,
  ),
  'mariaclara': HeroMove(
    heroId: 'mariaclara',
    name: 'Hangin ng Talulot',
    kind: HeroMoveKind.wave,
    shape: HeroMoveShape.petals,
    range: 160,
    speed: 340,
    cooldown: 0.70,
    hitWidth: 56,
    hitHeight: 76,
  ),
  'rizal': HeroMove(
    heroId: 'rizal',
    name: 'Sabog ng Pahina',
    kind: HeroMoveKind.burst,
    shape: HeroMoveShape.page,
    range: 150,
    speed: 480,
    count: 3,
    gap: 0.09,
    cooldown: 0.90,
    hitWidth: 22,
  ),
};

/// The move for [heroId]. An unknown id gets Juan's, so the button always does something.
HeroMove heroMoveFor(String heroId) => heroMoves[heroId] ?? heroMoves['boy']!;
