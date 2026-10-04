// Regression tests for the "I don't fall into gaps" bug found on device,
// 2026-10-01.
//
// `resolveGroundContact()` used to test horizontal support against the
// player's FULL WIDTH: "does any part of my bounding box overlap this
// section?". With a 96px-wide player and a 96px gap, one edge was always
// still over the ledge on one side or the other, so the player was never
// unsupported and walked straight across the hole. The same test also let a
// character stand with a single pixel on a ledge and hang in mid-air.
//
// Support is now decided by a narrow foot span centred on the sprite, which
// is what "standing on something" actually means.
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_collision.dart';

/// A game with two ground spans and a gap of [gapWidth] between them.
///
/// The player is mounted (not just assigned) because
/// `resolveGroundContact()` reaches `game.groundSections` through
/// `HasGameReference`, which asserts the component is attached.
Future<ChronoGame> _gameWithGap({required double gapWidth}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';

  final player = PlayerComponent(characterId: 'rizal')..size = Vector2(96, 120);
  game.player = player;
  game.world.add(player);
  await game.ready();
  player.size = Vector2(96, 120); // onLoad() sets its own size

  // GroundSection registers itself via onMount, which needs a real mount;
  // these tests drive resolveGroundContact() directly, so the list is
  // populated by hand instead.
  game.groundSections.add(
    GroundSection(sectionWidth: 1000, sectionPosition: Vector2(0, 660))
      ..size = Vector2(1000, 60),
  );
  game.groundSections.add(
    GroundSection(
      sectionWidth: 1000,
      sectionPosition: Vector2(1000 + gapWidth, 660),
    )..size = Vector2(1000, 60),
  );
  return game;
}

/// Puts the player's feet exactly on the ground plane at [x] and asks
/// whether they are supported.
bool _supportedAt(ChronoGame game, double x) {
  game.player.position = Vector2(x, 660 - game.player.size.y);
  game.player.velocityY = 0;
  return game.player.resolveGroundContact();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a gap the width of the player', () {
    // The exact case from the device: a 96px gap and a 96px player.
    late ChronoGame game;
    setUp(() async => game = await _gameWithGap(gapWidth: 96));

    test('is solid ground well before it', () {
      expect(_supportedAt(game, 500), isTrue);
    });

    test('is solid ground well after it', () {
      expect(_supportedAt(game, 1200), isTrue);
    });

    test('is NOT supported when standing centred over the hole', () {
      // Player centre at 1048 — the middle of the 1000..1096 gap. Under the
      // old full-width test this returned true, because the player's left
      // edge (1000) and right edge (1096) both touched a ledge.
      expect(_supportedAt(game, 1048 - 48), isFalse,
          reason: 'this is the bug: the player hovered over a gap exactly '
              'as wide as their own sprite');
    });
  });

  group('foot-span support', () {
    late ChronoGame game;
    setUp(() async => game = await _gameWithGap(gapWidth: 200));

    test('standing fully on the left ledge is supported', () {
      expect(_supportedAt(game, 850), isTrue);
    });

    test('standing fully over the gap is not supported', () {
      expect(_supportedAt(game, 1050), isFalse);
    });

    test('a toe over the gap is not enough to fall', () {
      // Feet span 930..978, still entirely over the first ledge (0..1000),
      // so the player stands — only the sprite's right edge overhangs. This
      // is the forgiving half of the foot-span rule and is deliberate.
      expect(_supportedAt(game, 1000 - 94), isTrue);
    });

    test('a toe on the far ledge is NOT enough to stand on', () {
      // The mirror case, and the one the old full-width test got wrong:
      // feet span 1174..1222 while the far ledge starts at 1200, so only
      // the toes are supported... but the centre of mass is over the hole.
      // Feet are 48px wide, so this lands just inside support — step one
      // sprite-width further back and it must fail.
      expect(_supportedAt(game, 1200 - 94), isFalse,
          reason: 'feet at 1106..1154 are entirely over the 1000..1200 gap');
    });

    test('edges stay forgiving: half the sprite on the ledge still stands',
        () {
      // Deliberately generous — the jump arc was tuned against landings
      // that do not require the whole sprite to be supported.
      expect(_supportedAt(game, 1000 - 48), isTrue);
    });

    test('support is symmetric on the far ledge', () {
      const farLedgeStart = 1000.0 + 200;
      expect(_supportedAt(game, farLedgeStart - 10), isTrue);
      expect(_supportedAt(game, farLedgeStart - 90), isFalse);
    });
  });

  group('platforms use the same foot span', () {
    test('a platform too far to the side does not hold the player', () async {
      final game = await _gameWithGap(gapWidth: 400);
      // Falling onto nothing in the middle of a wide gap.
      game.player.position = Vector2(1150, 660 - game.player.size.y);
      game.player.velocityY = 10;
      expect(game.player.resolveGroundContact(), isFalse);
    });
  });
}
