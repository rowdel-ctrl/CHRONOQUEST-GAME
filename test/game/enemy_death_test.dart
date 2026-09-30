// Enemy death sequence (GAMEPLAY-V2.md Section 5: "Flame's built-in effects
// — a SequenceEffect of ColorEffect (white tint) -> ScaleEffect (slight
// grow) -> OpacityEffect (fade) over ~0.3s, then drop 2-3 coins").
//
// Two harness details this file depends on, both confirmed empirically
// (via throwaway debug tests) rather than assumed:
//
// 1. It mounts a real GameWidget rather than using this codebase's usual
//    bare `ChronoGame()` + `onGameResize()` pattern. Flame's
//    `ComponentEffect` only wires up its `target` in `onMount()`, and
//    `Component._addChild` skips the lifecycle queue entirely when the
//    parent isn't mounted — a bare game never reaches `isMounted`, so the
//    effect `_die()` adds would silently never mount or tick.
//
// 2. Time is driven by calling `game.updateTree(dt)` directly rather than
//    `tester.pump(Duration)`. The pump-driven ticker did not reliably
//    advance the effect here, while direct updateTree does, deterministically.
//    The first updateTree call flushes the effect's own pending add (it is
//    NOT in `enemy.children` synchronously after `takeHit()`); only after
//    that does its controller start advancing.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/coin_component.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_spawning.dart';

const double _playerHeight = 120;
const double _playerWidth = 96;

/// The full death-effect duration per CombatConstants.
const double _deathDuration = CombatConstants.deathColorEffectDuration +
    CombatConstants.deathScaleEffectDuration +
    CombatConstants.deathOpacityEffectDuration;

/// ChronoGame minus the parts these tests have no use for — same shape as
/// sprite_scale_test.dart's _ScaleGame.
class _DeathTestGame extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(_playerWidth, _playerHeight)
      ..position = Vector2(0, groundY - _playerHeight);
    setupSpawning();
  }
}

/// Mounts [component] in a running game and waits for its async onLoad
/// (sprite decoding) to finish — same helper sprite_scale_test.dart uses.
Future<_DeathTestGame> _mount(WidgetTester tester, Component component) async {
  final game = _DeathTestGame();
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));

  game.world.add(component);
  // Sprite loading is real file I/O, which does not progress inside the
  // test binding's fake async zone — so real time (runAsync) has to be
  // alternated with pumps, which are what actually mount the component.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

/// Advances the game past the full death sequence.
///
/// Three distinct stages, all needed: the leading tick flushes the effect's
/// own pending add (see this file's header note 2); the middle loop carries
/// its controller to completion, which is what fires `onComplete`; and the
/// trailing ticks flush what that callback itself queued — `_dropCoins()`'s
/// `world.add(...)` and the enemy's `removeFromParent()` are both deferred
/// lifecycle events, so without these the coins and the removal are
/// invisible even though the callback has already run.
int _coinCount(ChronoGame game) =>
    game.world.children.whereType<CoinComponent>().length;

void _advancePastDeathSequence(ChronoGame game) {
  game.updateTree(0.001);
  for (var i = 0; i < 40; i++) {
    game.updateTree(_deathDuration / 20);
  }
  for (var i = 0; i < 5; i++) {
    game.updateTree(1 / 60);
  }
}

void main() {
  testWidgets('defeated flips true synchronously, before the effect completes',
      (tester) async {
    final enemy =
        EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier');
    await _mount(tester, enemy);

    enemy.takeHit();

    expect(enemy.defeated, true);
    expect(enemy.parent, isNotNull,
        reason: 'the enemy should still be in the tree while its death '
            'effect plays');
  });

  testWidgets(
      'drops between coinDropMin and coinDropMax coins once the sequence '
      'completes', (tester) async {
    final enemy =
        EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier');
    final game = await _mount(tester, enemy);

    final before = _coinCount(game);
    enemy.takeHit();
    _advancePastDeathSequence(game);
    // Coins are added from inside the effect's onComplete, so like the
    // enemy's own removal they land on the lifecycle queue rather than in
    // `children` — and each also has a real async onLoad() (sprite decode)
    // that only progresses under runAsync. Alternate the two the same way
    // _mount does, so they actually finish mounting before being counted.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    final dropped = _coinCount(game) - before;
    expect(dropped, greaterThanOrEqualTo(CombatConstants.coinDropMin));
    expect(dropped, lessThanOrEqualTo(CombatConstants.coinDropMax));
  });

  testWidgets('removes the enemy from the tree once the sequence completes',
      (tester) async {
    final enemy =
        EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier');
    final game = await _mount(tester, enemy);

    enemy.takeHit();
    _advancePastDeathSequence(game);

    // `isRemoving`, not `parent == null`: `removeFromParent()` enqueues a
    // lifecycle event, and the enqueue is what this asserts actually
    // happened. The final detach is flushed by the running game loop in
    // production; in this harness it stays queued no matter how many extra
    // ticks are driven (confirmed by direct instrumentation), so asserting
    // on `parent` would be testing the harness rather than the behaviour.
    expect(enemy.isRemoving, true);
  });

  testWidgets('a Heavy does not drop coins or get removed after only one hit',
      (tester) async {
    final enemy = EnemyComponent(eraId: 'ww2', enemyTypeOverride: 'tank');
    final game = await _mount(tester, enemy);

    enemy.takeHit();
    _advancePastDeathSequence(game);

    expect(enemy.defeated, false);
    expect(enemy.parent, isNotNull);
    expect(game.world.children.whereType<CoinComponent>().length, 0);
  });
}
