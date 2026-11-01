/// What the game knows about a student that badges are worked out from, and which
/// badges they hold. Kept on the phone for each student (see `StorageService`).
///
/// Everything here is a set or a best-so-far, so doing the same thing twice (a
/// replay, the same record read again from the server) never counts twice.
class BadgeFacts {
  /// Best score so far for each level, in percent. Key: `eraId:level`.
  final Map<String, int> best;

  /// Levels finished with 3 stars, with every answer right, and without losing any
  /// health. Keys as above.
  final Set<String> threeStar;
  final Set<String> perfect;
  final Set<String> noDamage;

  /// Times a replay beat the best score before it.
  final int comebacks;

  /// Eras whose boss was beaten.
  final Set<String> bosses;

  /// A boss was beaten without one wrong answer.
  final bool bossClean;

  /// The days played, as `2026-10-30`.
  final Set<String> days;

  /// Something has been bought in the Tindahan.
  final bool bought;

  /// Badge id -> when it was earned (milliseconds).
  final Map<String, int> earned;

  /// Earned, but not looked at on the shelf yet: these carry the red BAGO tag.
  final Set<String> unseen;

  /// Earned without a fanfare (the update, or a new phone) and not yet mentioned in
  /// the one line on the eras screen.
  final int quiet;

  const BadgeFacts({
    this.best = const {},
    this.threeStar = const {},
    this.perfect = const {},
    this.noDamage = const {},
    this.comebacks = 0,
    this.bosses = const {},
    this.bossClean = false,
    this.days = const {},
    this.bought = false,
    this.earned = const {},
    this.unseen = const {},
    this.quiet = 0,
  });

  BadgeFacts copyWith({
    Map<String, int>? best,
    Set<String>? threeStar,
    Set<String>? perfect,
    Set<String>? noDamage,
    int? comebacks,
    Set<String>? bosses,
    bool? bossClean,
    Set<String>? days,
    bool? bought,
    Map<String, int>? earned,
    Set<String>? unseen,
    int? quiet,
  }) =>
      BadgeFacts(
        best: best ?? this.best,
        threeStar: threeStar ?? this.threeStar,
        perfect: perfect ?? this.perfect,
        noDamage: noDamage ?? this.noDamage,
        comebacks: comebacks ?? this.comebacks,
        bosses: bosses ?? this.bosses,
        bossClean: bossClean ?? this.bossClean,
        days: days ?? this.days,
        bought: bought ?? this.bought,
        earned: earned ?? this.earned,
        unseen: unseen ?? this.unseen,
        quiet: quiet ?? this.quiet,
      );

  Map<String, dynamic> toJson() => {
        'best': best,
        'threeStar': threeStar.toList(),
        'perfect': perfect.toList(),
        'noDamage': noDamage.toList(),
        'comebacks': comebacks,
        'bosses': bosses.toList(),
        'bossClean': bossClean,
        'days': days.toList(),
        'bought': bought,
        'earned': earned,
        'unseen': unseen.toList(),
        'quiet': quiet,
      };

  factory BadgeFacts.fromJson(Map<dynamic, dynamic> json) {
    Set<String> strings(String key) => {
          for (final v in (json[key] as List<dynamic>? ?? const []))
            v.toString()
        };
    Map<String, int> ints(String key) => {
          for (final e
              in (json[key] as Map<dynamic, dynamic>? ?? const {}).entries)
            e.key.toString(): (e.value as num).toInt(),
        };
    return BadgeFacts(
      best: ints('best'),
      threeStar: strings('threeStar'),
      perfect: strings('perfect'),
      noDamage: strings('noDamage'),
      comebacks: (json['comebacks'] as num?)?.toInt() ?? 0,
      bosses: strings('bosses'),
      bossClean: json['bossClean'] as bool? ?? false,
      days: strings('days'),
      bought: json['bought'] as bool? ?? false,
      earned: ints('earned'),
      unseen: strings('unseen'),
      quiet: (json['quiet'] as num?)?.toInt() ?? 0,
    );
  }
}
