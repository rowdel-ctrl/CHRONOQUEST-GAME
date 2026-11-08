import 'artifact_art.dart';

/// One artifact a student has claimed by answering its question correctly
/// (GAMEPLAY-V2.md Section 6, "The Codex").
///
/// The history blurb is the question's own `explanation` text — the same
/// string already shown when an answer is wrong. That reuse is the point:
/// the Codex turns content that was previously seen once, in passing, into
/// a permanent record of what the student learned.
class CodexEntry {
  /// Which era this artifact belongs to — the Codex groups by era.
  final String eraId;

  /// The question whose correct answer claimed this artifact. Doubles as the
  /// entry's identity: claiming the same question twice (on a replay) must
  /// not create a duplicate tile.
  final String questionId;

  /// 1-10, picking one of the era's ten icons,
  /// `assets/collectibles/artifact_<eraId>_<n>.png`. Stored rather than derived
  /// so a tile keeps the art it was claimed with, even if the sprite-picking
  /// rule changes later. Entries saved before the era icons (1-5) stay valid.
  final int artifactSprite;

  /// The question text, shown as the tile's title.
  final String questionText;

  /// The one-paragraph history blurb (the question's `explanation`).
  final String blurb;

  /// When it was claimed, epoch milliseconds — newest-first ordering.
  final int claimedAtMs;

  const CodexEntry({
    required this.eraId,
    required this.questionId,
    required this.artifactSprite,
    required this.questionText,
    required this.blurb,
    required this.claimedAtMs,
  });

  String get assetPath => artifactAsset(eraId, artifactSprite);

  Map<String, dynamic> toJson() => {
        'eraId': eraId,
        'questionId': questionId,
        'artifactSprite': artifactSprite,
        'questionText': questionText,
        'blurb': blurb,
        'claimedAtMs': claimedAtMs,
      };

  factory CodexEntry.fromJson(Map<String, dynamic> json) => CodexEntry(
        eraId: json['eraId'] as String? ?? '',
        questionId: json['questionId'] as String? ?? '',
        // Defensive: an out-of-range or missing sprite index would throw on
        // Image.asset at render time, which is a crash in a screen the
        // student opened to look at their achievements.
        artifactSprite: _clampSprite(json['artifactSprite']),
        questionText: json['questionText'] as String? ?? '',
        blurb: json['blurb'] as String? ?? '',
        claimedAtMs: json['claimedAtMs'] as int? ?? 0,
      );

  static int _clampSprite(Object? raw) {
    final n = raw is int ? raw : 1;
    return clampArtifactIndex(n);
  }
}
