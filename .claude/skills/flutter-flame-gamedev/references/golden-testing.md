# Golden/Widget Testing for Flame Components

Flutter's equivalent to "let the agent see what it built" without a human
manually checking every change.

## Why

Claude Code can write correct-looking Flame component code but can't watch
the game run. Golden tests render a widget/component tree to an image and
diff it against a saved reference — so a broken layout, wrong sprite
frame, or misplaced HUD element fails the test automatically instead of
waiting for you to notice during playtesting.

## Setup

Flutter ships this in `flutter_test` — no extra package needed for basic
golden tests. For testing Flame components specifically, pair it with
`flame_test`, which provides a `FlameTester` harness that pumps a game
instance inside the widget test environment.

```dart
// pubspec.yaml (dev_dependencies)
flame_test: ^<latest>
```

## Pattern: golden test for a component

```dart
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tester = FlameTester(ChronoQuestGame.new);

  tester.testGameWidget(
    'player idle animation renders correctly',
    verify: (game, tester) async {
      await tester.pump();
      await expectLater(
        find.byGame<ChronoQuestGame>(),
        matchesGoldenFile('goldens/player_idle.png'),
      );
    },
  );
}
```

- First run generates the reference image (`--update-goldens`); subsequent
  runs diff against it and fail on pixel drift beyond tolerance.
- Commit golden images to the repo so the whole team (and Claude Code) can
  verify against the same baseline.

## Pattern: logic-only test (no rendering)

For pure gameplay logic (collision outcomes, score changes, era unlock
conditions) a plain `flame_test` unit test is cheaper than a golden image
and should be preferred when no visual output is being verified:

```dart
testWithGame<ChronoQuestGame>(
  'enemy hit reduces player HP',
  ChronoQuestGame.new,
  (game) async {
    await game.ready();
    final player = game.player;
    final startHp = player.hp;
    player.onCollision(<enemy hitbox intersection points>, enemy);
    expect(player.hp, lessThan(startHp));
  },
);
```

## When to write one

- Any new visual component (sprite, HUD element, parallax layer) → golden
  test.
- Any change to movement, collision, scoring, or era-progression logic →
  logic test.
- Skip for pure refactors with no behavior change — rely on existing tests
  passing instead of writing a new one.

## Running

```bash
flutter test                          # run all tests
flutter test --update-goldens         # regenerate goldens after an intentional visual change
```

Claude Code should run `flutter test` after any Flame component change and
report failures rather than assuming the change is correct because it
compiles.
