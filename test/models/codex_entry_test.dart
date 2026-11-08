// CodexEntry is what a claimed artifact becomes (GAMEPLAY-V2.md Section 6).
// It round-trips through Hive as a plain map, so the JSON conversion and its
// defensive parsing are what these cover — a malformed stored entry must not
// crash the screen a student opened to look at their achievements.
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/models/codex_entry.dart';

CodexEntry _entry({String questionId = 'q1', int sprite = 2}) => CodexEntry(
      eraId: 'spanish',
      questionId: questionId,
      artifactSprite: sprite,
      questionText: 'Sino ang pambansang bayani?',
      blurb: 'Si Dr. Jose Rizal ang Pambansang Bayani ng Pilipinas.',
      claimedAtMs: 1727700000000,
    );

void main() {
  group('round trip', () {
    test('survives toJson/fromJson unchanged', () {
      final original = _entry();
      final restored = CodexEntry.fromJson(original.toJson());

      expect(restored.eraId, original.eraId);
      expect(restored.questionId, original.questionId);
      expect(restored.artifactSprite, original.artifactSprite);
      expect(restored.questionText, original.questionText);
      expect(restored.blurb, original.blurb);
      expect(restored.claimedAtMs, original.claimedAtMs);
    });
  });

  group('asset path', () {
    test('points at the era icon it was claimed with', () {
      expect(_entry(sprite: 3).assetPath,
          'assets/collectibles/artifact_spanish_3.png');
      expect(_entry(sprite: 10).assetPath,
          'assets/collectibles/artifact_spanish_10.png');
    });

    test('an entry saved with an unknown era shows the old generic picture',
        () {
      final e = CodexEntry.fromJson({'eraId': 'atlantis', 'artifactSprite': 7});
      expect(e.assetPath, 'assets/collectibles/artifact_2.png');
    });
  });

  group('defensive parsing', () {
    test('an out-of-range sprite index falls back to 1 rather than crashing',
        () {
      // Image.asset on a nonexistent path throws at render time, inside the
      // Codex screen — worse than quietly showing the wrong artwork.
      expect(CodexEntry.fromJson({'artifactSprite': 99}).artifactSprite, 1);
      expect(CodexEntry.fromJson({'artifactSprite': 11}).artifactSprite, 1);
      expect(CodexEntry.fromJson({'artifactSprite': 0}).artifactSprite, 1);
      expect(CodexEntry.fromJson({'artifactSprite': -4}).artifactSprite, 1);
    });

    test('every index 1..10 is kept, so the ten era icons all survive a save',
        () {
      for (var i = 1; i <= 10; i++) {
        expect(CodexEntry.fromJson({'artifactSprite': i}).artifactSprite, i);
      }
    });

    test('an old saved entry (index 1-5) now shows its era icon', () {
      final e = CodexEntry.fromJson(
          {'eraId': 'ww2', 'questionId': 'q', 'artifactSprite': 4});
      expect(e.artifactSprite, 4);
      expect(e.assetPath, 'assets/collectibles/artifact_ww2_4.png');
    });

    test('a missing or wrong-typed sprite index falls back to 1', () {
      expect(CodexEntry.fromJson(const {}).artifactSprite, 1);
      expect(CodexEntry.fromJson({'artifactSprite': 'two'}).artifactSprite, 1);
    });

    test('missing text fields become empty strings, not nulls', () {
      final e = CodexEntry.fromJson(const {});
      expect(e.eraId, '');
      expect(e.questionText, '');
      expect(e.blurb, '');
      expect(e.claimedAtMs, 0);
    });
  });
}
