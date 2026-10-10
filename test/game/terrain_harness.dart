// A bare game with real ground sections and platforms and the real
// PlayerComponent, for tests that play moves frame by frame: the parity test
// (scripted moves against tools/levelgen/sim.js) and the playthrough test (a
// winning run on every level). Not a test itself.
import 'package:flame/components.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/gap_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/components/tile_platform_component.dart';
import 'package:chronoquest/game/game_input.dart';

/// A stretch of ground or a platform: left edge, right edge, surface y.
typedef Surface = ({double start, double end, double top});

/// One frame at 60 fps, the longest step the game ever takes
/// (ChronoGame.maxStepDt).
const double frame = 1 / 60;

/// The game's virtual height: ground reaches to the bottom of it.
const double screenBottom = 720;

Future<ChronoGame> terrainGame({
  required List<Surface> ground,
  List<Surface> platforms = const [],
}) async {
  final game = ChronoGame();
  game.onGameResize(Vector2(800, 450));
  game.images.prefix = 'assets/';

  final player = PlayerComponent(characterId: 'rizal');
  game.player = player;
  game.world.add(player);

  // A bare joystick, never mounted: `delta` is a plain field, and a radius of 10
  // makes a delta of 10 a full pull.
  final input = GameInput(game: game);
  input.joystick = JoystickComponent(
    background: CircleComponent(radius: 10),
  );
  game.gameInput = input;

  await game.ready();
  // The first level of a run has to decode the sprites, which can outlast ready().
  await player.loaded;
  player.size = Vector2(96, 120); // onLoad() sets its own size

  // Sections register themselves on mount, which needs a real mount; these
  // tests drive the player directly, so the lists are filled by hand.
  for (final g in ground) {
    game.groundSections.add(
      GroundSection(
        sectionWidth: g.end - g.start,
        sectionPosition: Vector2(g.start, g.top),
        drawn: false,
      )..size = Vector2(g.end - g.start, screenBottom - g.top),
    );
  }
  for (final p in platforms) {
    game.platforms.add(
      TilePlatformComponent(
        widthInTiles: ((p.end - p.start) / TilePlatformComponent.tileSize).round(),
        surfaceY: p.top,
        spawnPosition: Vector2(p.start, p.top),
      ),
    );
  }
  return game;
}

/// Puts the player standing with the left edge of the sprite at [x], on whatever
/// ground is under the middle of it.
void standAt(ChronoGame game, double x) {
  final p = game.player;
  final centre = x + p.size.x / 2;
  final section = game.groundSections.firstWhere(
    (s) => centre >= s.position.x && centre < s.position.x + s.size.x,
  );
  p.position = Vector2(x, section.position.y - p.size.y);
  p.velocityY = 0;
  p.isOnGround = true;
}

/// Plays one frame: the stick at [h] (-1..1), and the jump button if [jump].
/// Returns true if the player fell out of the level this frame.
bool playFrame(ChronoGame game, double h, bool jump) {
  game.gameInput.joystick.delta.setValues(10 * h, 0);
  final hearts = game.hearts;
  if (jump) game.player.jump();
  game.player.update(frame);
  return game.hearts < hearts;
}
