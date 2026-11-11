/// All the numbers of the five surprises (unexpected obstacles and enemies in the
/// higher levels), in one place so they can be tuned without hunting. Every
/// timing and size comes from the approved mockup (the Surprises tab); they are
/// guesses until the game has been played on a phone.
///
/// The fairness rules every surprise keeps:
/// - a flash and a "!" (or a growing shadow / a ring) for at least [minWarning]
///   seconds before anything can hurt;
/// - one heart per hit at most;
/// - nothing moves faster than the student ([hopSpeed] and [goldenSpeed] are under
///   the 250 units a second the student walks at);
/// - at most [maxAtOnce] surprises going on at the same time;
/// - never in levels 1 to 3 and never in a boss room.
class SurpriseConstants {
  SurpriseConstants._();

  // ─── The ladder: the first level each kind may appear in ────────────────
  static const int firstHopperLevel = 4;
  static const int firstPopLevel = 5;
  static const int firstRockLevel = 6;
  static const int firstThrowerLevel = 7;
  static const int firstGoldenLevel = 8;

  /// No surprise of any kind before this level.
  static const int firstSurpriseLevel = firstHopperLevel;

  /// At most this many surprises may be in progress (warning, falling, flying,
  /// hopping) at the same time.
  static const int maxAtOnce = 2;

  /// The shortest warning any surprise gives before it can hurt.
  static const double minWarning = 0.5;

  // ─── Hopper: a walker squats, hops once at the student, lands dizzy ─────
  /// Squat, flash and "!" before the hop.
  static const double hopSquat = 0.55;
  static const double hopDuration = 0.7;
  static const double hopDistance = 140;

  /// How high the hop goes at its highest.
  static const double hopPeak = 90;

  /// Dizzy after landing: it cannot hurt and a hit gets it. Then it walks on.
  static const double hopDizzy = 1.4;

  /// Rest between two hops, and how soon after it first sees a student a hopper may
  /// squat for the first time.
  static const double hopCooldown = 3.0;
  static const double hopFirstDelay = 0.4;

  /// A hopper starts a squat for a student at least [hopMinRange] and at most
  /// [hopTriggerRange] away (centre to centre, same level).
  static const double hopMinRange = 120;
  static const double hopTriggerRange = 300;

  /// Average sideways speed of the hop, units a second (under the student's 250).
  static const double hopSpeed = hopDistance / hopDuration;

  /// The squat squashes it by up to this much; the flash is this many a second.
  static const double hopSquashDepth = 0.2;
  static const double hopFlashHz = 12;

  // ─── Ground pop: a crack, then an enemy rises out of the ground ─────────
  /// The crack and the "!" on the ground before anything comes out.
  static const double popWarn = 0.6;

  /// It rises for this long: it can be hit but cannot hurt until it is fully up.
  static const double popRise = 0.5;

  /// The crack wakes when the student is between these distances of it (never right
  /// on top of the student).
  static const double popTriggerNear = 180;
  static const double popTriggerFar = 520;

  /// How far a popped enemy paces from where it came up.
  static const double popPatrol = 80;

  // ─── Falling rock: a growing shadow, then a rock drops and breaks ───────
  static const double rockWarn = 0.8;
  static const double rockDrop = 0.4;

  /// The shadow, grown, reaches this far each side of the spot. Hurts only the
  /// student standing in it at the moment the rock lands.
  static const double rockRadius = 50;

  /// Feet at least this high above the ground clear the rock (a jump does).
  static const double rockClearHeight = 60;

  /// How far above the ground the rock starts its drop.
  static const double rockStartHeight = 460;

  /// Screen shake when it lands, and how long.
  static const double rockShakeSeconds = 0.25;
  static const double rockShakeAmount = 3;

  /// Seconds the broken pieces and the dust stay.
  static const double rockDebris = 1.3;

  /// The shadow starts when the student is between these distances of the spot.
  static const double rockTriggerNear = 200;
  static const double rockTriggerFar = 520;

  // ─── Thrower: stands still, a ring shows where the item will land ───────
  /// Flash and "!" before the throw. The ring shows from the start of it.
  static const double throwWindup = 0.6;

  /// The item flies this long, slowly; the ring is on the ground the whole time.
  static const double throwFlight = 1.4;

  /// How long the thrower shows its throwing picture after it lets go.
  static const double throwShow = 0.35;

  /// Rest after an item has landed before the next throw.
  static const double throwCooldown = 1.6;
  static const double throwFirstDelay = 0.5;

  /// The ring's radius. Only the ring hurts, only when the item lands.
  static const double ringRadius = 46;

  /// Feet at least this high above the ring's ground clear it.
  static const double ringClearHeight = 60;

  /// It throws at a student between these distances (same level, standing on the ground).
  static const double throwMinRange = 140;
  static const double throwRange = 540;

  /// Highest point of the item's arc above the straight line, and how many hits it takes.
  static const double throwArc = 120;
  static const int throwerHits = 1;

  // ─── Golden runner: never hurts, runs away, drops bonus coins ───────────
  /// Sees a student this close, stands still for [goldenAlert] with a "!", then runs.
  static const double goldenSight = 340;
  static const double goldenAlert = 0.3;

  /// Runs this far in this time, then stops to breathe.
  static const double goldenDistance = 200;
  static const double goldenRunTime = 1.0;
  static const double goldenSpeed = goldenDistance / goldenRunTime;
  static const double goldenRest = 3.5;

  /// It says "Golden!" once, when a student first comes this close.
  static const double goldenAnnounce = 700;

  /// Coins dropped when it is hit.
  static const int goldenCoinsMin = 8;
  static const int goldenCoinsMax = 10;
}
