// Level end is a distance goal, not "all enemies dead" (GAMEPLAY-V2.md
// Section 14, Phase 2). Enemies no longer gate progress — contact damage
// replaced the quiz-on-contact loop — so the acceptance criterion is that
// "a level ends on the distance goal and can be finished without killing a
// single enemy". These tests assert exactly that, including the
// no-enemies-ever case, which is the part that would silently regress if
// the old rule crept back in.
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';

ChronoGame _bareGameWithPlayer({
  String era = 'spanish',
  int level = 1,
  double playerWorldX = 0,
}) {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';
  game.currentEra = era;
  game.currentLevel = level;
  final player = PlayerComponent(characterId: 'rizal')
    ..size = Vector2(96, 120)
    ..position = Vector2(playerWorldX, game.groundY - 120);
  player.game = game;
  game.player = player;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not end the level before the distance goal is reached', () {
    final game = _bareGameWithPlayer();
    var completed = false;
    game.onLevelComplete = (_, __, ___, ____) => completed = true;

    game.player.position.x = game.currentLevelData.lengthUnits - 1;
    game.checkLevelEnd();

    expect(completed, false);
  });

  test('ends the level once worldX reaches lengthUnits', () {
    final game = _bareGameWithPlayer();
    var completed = false;
    game.onLevelComplete = (_, __, ___, ____) => completed = true;

    game.player.position.x = game.currentLevelData.lengthUnits;
    game.checkLevelEnd();

    expect(completed, true);
  });

  test('a level can be finished without killing a single enemy', () {
    // The acceptance criterion, asserted directly: no EnemyComponent is ever
    // added to the world, and the level still completes on distance alone.
    final game = _bareGameWithPlayer();
    var completed = false;
    game.onLevelComplete = (_, __, ___, ____) => completed = true;

    expect(game.world.children.whereType<EnemyComponent>(), isEmpty);

    game.player.position.x = game.currentLevelData.lengthUnits + 10;
    game.checkLevelEnd();

    expect(completed, true);
    expect(game.world.children.whereType<EnemyComponent>(), isEmpty,
        reason: 'the level must not require any enemy to exist, let alone die');
  });

  test('live enemies do not block the level from ending', () async {
    final game = _bareGameWithPlayer();
    var completed = false;
    game.onLevelComplete = (_, __, ___, ____) => completed = true;

    game.world.add(
      EnemyComponent(eraId: 'spanish', enemyTypeOverride: 'spanish_soldier'),
    );
    await game.ready();
    expect(game.world.children.whereType<EnemyComponent>(), isNotEmpty);

    game.player.position.x = game.currentLevelData.lengthUnits;
    game.checkLevelEnd();

    expect(completed, true,
        reason: 'under the old "all enemies dead" rule this would not end');
  });

  test('a boss level starts the boss fight instead of completing', () {
    // The last level of an era is its boss level; the distance goal routes
    // there rather than straight to levelComplete().
    final bossLevel = getEraById('spanish').levels.length;
    final game = _bareGameWithPlayer(level: bossLevel);
    var completed = false;
    game.onLevelComplete = (_, __, ___, ____) => completed = true;
    // startBossFight() adds the boss health overlay by name; a bare game has
    // no builders registered (GameWidget normally supplies them), and
    // OverlayManager asserts on unknown names. Register a stub so the real
    // code path can run end to end here.
    game.overlays.addEntry(
      'BossHealthOverlay',
      (context, _) => const SizedBox.shrink(),
    );

    expect(game.isBossLevel, true);
    game.player.position.x = game.currentLevelData.lengthUnits;
    game.checkLevelEnd();

    expect(game.bossPhase, true);
    expect(completed, false,
        reason: 'a boss level must not complete before its fight happens');
  });
}
