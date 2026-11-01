import '../core/constants.dart';

/// Where a badge sits on the shelf.
enum BadgeGroup { husay, paglalakbay, kodeks }

/// How a medal is coloured. [era] is the gold of an era or trophy badge.
enum BadgeMetal { tanso, pilak, ginto, era }

/// One level of a badge: what it needs, and the one-time coin gift for earning it.
class BadgeStep {
  /// Unique over all 28 badges, e.g. `perfect:2` or `era:spanish`.
  final String id;
  final BadgeMetal metal;
  final int need;
  final int coins;
  const BadgeStep(this.id, this.metal, this.need, this.coins);
}

/// A badge and its levels. Most come in three (Tanso, Pilak, Ginto); an era, a
/// trophy and the two single badges have one. The 16 families make 28 badges.
class BadgeFamily {
  final String id;
  final String name;

  /// The name on the shelf, when it is shorter than [name] (an era badge).
  final String shelfName;

  /// What it needs, in one line.
  final String rule;
  final BadgeGroup group;

  /// The picture on the medal: a key of `badgeGlyphs`, or `n1` to `n6`.
  final String glyph;

  /// What the count is of: "level", "araw", "beses"... Empty when it is a yes or no.
  final String unit;

  /// A ribbon under the medal (era and trophy badges).
  final bool honor;

  /// Can be worked out again from what the server keeps, so it is still there on a
  /// new phone. The rest are counted on this phone only.
  final bool keep;
  final List<BadgeStep> steps;

  const BadgeFamily({
    required this.id,
    required this.name,
    String? shelfName,
    required this.rule,
    required this.group,
    required this.glyph,
    this.unit = '',
    this.honor = false,
    required this.keep,
    required this.steps,
  }) : shelfName = shelfName ?? name;

  bool get tiered => steps.length > 1;
}

/// A badge a student has just earned.
class EarnedBadge {
  final BadgeFamily family;
  final BadgeStep step;
  const EarnedBadge(this.family, this.step);

  String get id => step.id;
  int get coins => step.coins;

  /// "Perpekto! · Pilak", or just the name for a badge with one level.
  String get title =>
      family.tiered ? '${family.name} · ${metalName(step.metal)}' : family.name;
}

String metalName(BadgeMetal m) => switch (m) {
      BadgeMetal.tanso => 'Tanso',
      BadgeMetal.pilak => 'Pilak',
      BadgeMetal.ginto => 'Ginto',
      BadgeMetal.era => '',
    };

List<BadgeStep> _three(String id, List<int> need,
        {List<int> coins = const [5, 10, 20]}) =>
    [
      for (var i = 0; i < 3; i++)
        BadgeStep('$id:${i + 1}', BadgeMetal.values[i], need[i], coins[i]),
    ];

BadgeStep _one(String id, int need, int coins,
        [BadgeMetal metal = BadgeMetal.ginto]) =>
    BadgeStep(id, metal, need, coins);

/// The eras taught in [grade].
Iterable<EraData> _erasOfGrade(int grade) =>
    allEras.where((e) => e.grade == grade);

/// The 16 families, in shelf order.
final List<BadgeFamily> badgeFamilies = [
  // HUSAY: doing well in a level.
  BadgeFamily(
    id: 'stars3',
    name: 'Tatlong Bituin',
    rule: 'Kumuha ng 3 bituin sa isang level.',
    group: BadgeGroup.husay,
    glyph: 'star',
    unit: 'level',
    keep: true,
    steps: _three('stars3', const [1, 10, 25]),
  ),
  BadgeFamily(
    id: 'perfect',
    name: 'Perpekto!',
    rule: 'Tama lahat ng sagot sa isang level.',
    group: BadgeGroup.husay,
    glyph: 'check',
    unit: 'level',
    keep: true,
    steps: _three('perfect', const [1, 5, 15]),
  ),
  BadgeFamily(
    id: 'comeback',
    name: 'Bumawi',
    rule: 'Ulitin ang level at mas mataas ang score kaysa dati.',
    group: BadgeGroup.husay,
    glyph: 'up',
    unit: 'beses',
    keep: true,
    steps: _three('comeback', const [1, 5, 15]),
  ),
  // PAGLALAKBAY: the journey.
  for (final era in allEras)
    BadgeFamily(
      id: 'era:${era.id}',
      name: 'Bayani ng ${era.name}',
      shelfName: era.name,
      rule: 'Talunin ang boss ng panahong ito.',
      group: BadgeGroup.paglalakbay,
      glyph: 'n${eraNumberFor(era.id)}',
      honor: true,
      keep: true,
      steps: [_one('era:${era.id}', 1, 30, BadgeMetal.era)],
    ),
  for (final grade in const [5, 6])
    BadgeFamily(
      id: 'champ:$grade',
      name: 'Kampeon ng Grade $grade',
      shelfName: 'Kampeon Grade $grade',
      rule:
          'Talunin ang boss ng lahat ng ${_erasOfGrade(grade).length} panahon ng Grade $grade.',
      group: BadgeGroup.paglalakbay,
      glyph: 'trophy',
      unit: 'era',
      honor: true,
      keep: true,
      steps: [_one('champ:$grade', _erasOfGrade(grade).length, 60)],
    ),
  // KODEKS AT SIPAG: collecting, coming back, and a few firsts.
  BadgeFamily(
    id: 'collector',
    name: 'Kolektor',
    rule: 'Mga artifact sa Kodeks mo.',
    group: BadgeGroup.kodeks,
    glyph: 'urn',
    unit: 'artifact',
    keep: false,
    steps: _three('collector', const [10, 50, 100]),
  ),
  BadgeFamily(
    id: 'days',
    name: 'Balik-Laro',
    rule: 'Ilang araw ka naglaro. Hindi kailangang magkakasunod.',
    group: BadgeGroup.kodeks,
    glyph: 'cal',
    unit: 'araw',
    keep: false,
    steps: _three('days', const [3, 7, 15]),
  ),
  BadgeFamily(
    id: 'nodamage',
    name: 'Walang Galos',
    rule: 'Tapusin ang level nang walang nawalang health.',
    group: BadgeGroup.kodeks,
    glyph: 'heart',
    unit: 'level',
    keep: false,
    steps: _three('nodamage', const [1, 5, 15]),
  ),
  BadgeFamily(
    id: 'firstbuy',
    name: 'Unang Bili',
    rule: 'Bumili sa Tindahan sa unang pagkakataon.',
    group: BadgeGroup.kodeks,
    glyph: 'coin',
    keep: false,
    steps: [_one('firstbuy', 1, 5)],
  ),
  BadgeFamily(
    id: 'bossclean',
    name: 'Walang Mali sa Boss',
    rule: 'Talunin ang boss nang walang isang maling sagot.',
    group: BadgeGroup.kodeks,
    glyph: 'shield',
    keep: false,
    steps: [_one('bossclean', 1, 20)],
  ),
];

/// Every badge, 28 of them, family by family.
final List<BadgeStep> allBadgeSteps = [
  for (final f in badgeFamilies) ...f.steps,
];

final Map<String, BadgeFamily> _familyByStep = {
  for (final f in badgeFamilies)
    for (final s in f.steps) s.id: f,
};

BadgeFamily? badgeFamilyOf(String badgeId) => _familyByStep[badgeId];
