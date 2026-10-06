// Every gap in every authored or generated level can be crossed by a student
// who holds right and presses jump, and every platform can be landed on.
//
// The level lint checks gap widths and platform heights against numbers. This
// replays the game's own physics instead (PlayerComponent's jump and gravity,
// and the foot-span ground contact in game_collision.dart) so a gap that looks
// fine on paper but cannot actually be cleared fails here.
//
// "Can be crossed" is not enough, a window of one frame is a coin flip, so each
// jump must have a launch window of at least a quarter of a second to land in.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/core/combat_constants.dart';
import 'package:chronoquest/game/components/enemy_component.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_collision.dart';
import 'package:chronoquest/game/level_loader.dart';

const double _groundY = 660;
const double _playerWidth = 96;
const double _band = 20; // game_collision.dart: how far under a surface still counts as landing
const double _dt = 1 / 60;
const double _minWindowUnits = 0.25 * PlayerComponent.forwardSpeed; // a quarter second of walking

class _Platform {
  final double x, width, surfaceY;
  const _Platform(this.x, this.width, this.surfaceY);
}

/// [ground] is the far side of the gap; [back] is the ledge it was launched from.
enum _Landed { ground, back, platform, fell }

/// A jump launched with the sprite's left edge at [x] from whatever it stands
/// on, holding right the whole way. Returns where it comes down.
_Landed _jump(double x, List<({double start, double end})> ground,
    List<_Platform> platforms, double startSurfaceY, double farStart) {
  const foot = _playerWidth * footSpanFraction;
  var px = x;
  var feetY = startSurfaceY; // y-down, like the game
  var vy = PlayerComponent.jumpForce;

  for (var i = 0; i < 400; i++) {
    px += PlayerComponent.forwardSpeed * _dt;
    vy += PlayerComponent.gravity * _dt;
    feetY += vy * _dt;

    final footL = px + _playerWidth / 2 - foot / 2;
    final footR = px + _playerWidth / 2 + foot / 2;

    for (final g in ground) {
      if (footR > g.start && footL < g.end && feetY >= _groundY && feetY <= _groundY + _band) {
        return g.start >= farStart ? _Landed.ground : _Landed.back;
      }
    }
    if (vy >= 0) {
      for (final p in platforms) {
        if (footR > p.x && footL < p.x + p.width && feetY >= p.surfaceY && feetY <= p.surfaceY + _band) {
          return _Landed.platform;
        }
      }
    }
    if (feetY > _groundY + 200) return _Landed.fell;
  }
  return _Landed.fell;
}

/// Width, in world units, of the launch positions in [from]..[to] that end in
/// [want], stepping 2 units at a time.
double _window(double from, double to, _Landed want, List<({double start, double end})> ground,
    List<_Platform> platforms, double startSurfaceY, double farStart) {
  var ok = 0;
  for (var x = from; x <= to; x += 2) {
    if (_jump(x, ground, platforms, startSurfaceY, farStart) == want) ok++;
  }
  return ok * 2.0;
}

/// How long, in seconds, the attack box can swing at a platform enemy before
/// anything touches the student: the box (spawned at the player's right side)
/// overlaps the enemy's hit area while the player's own box does not.
///
/// A jump launched with the sprite's left edge at [launchLeft], holding right.
/// The enemy stands with its sprite's left edge at [enemyLeft] on a platform
/// whose top is [surfaceY]. Its hit area is the middle 55% by 85% of the sprite
/// (EnemyComponent.onLoad).
double _safeSwing(double launchLeft, double enemyLeft, double surfaceY) {
  const hitW = EnemyComponent.spriteWidth * 0.55;
  const hitH = EnemyComponent.spriteHeight * 0.85;
  final hitL = enemyLeft + (EnemyComponent.spriteWidth - hitW) / 2;
  final hitR = hitL + hitW;
  final hitB = surfaceY - (EnemyComponent.spriteHeight - hitH) / 2;
  final hitT = hitB - hitH;
  const playerHeight = 120.0;

  var left = launchLeft;
  var feetY = _groundY;
  var vy = PlayerComponent.jumpForce;
  var touched = false;
  var safe = 0.0;
  for (var i = 0; i < 200; i++) {
    left += PlayerComponent.forwardSpeed * _dt;
    vy += PlayerComponent.gravity * _dt;
    feetY += vy * _dt;
    if (vy >= 0 && feetY >= surfaceY) break; // arrived on the platform
    if (feetY > _groundY + 20) break;
    final top = feetY - playerHeight;
    if (left + _playerWidth > hitL && left < hitR && feetY > hitT && top < hitB) {
      touched = true;
    }
    final boxL = left + _playerWidth;
    final boxT = top + (playerHeight - CombatConstants.attackHitboxHeight) / 2;
    if (!touched &&
        boxL + CombatConstants.attackHitboxWidth > hitL &&
        boxL < hitR &&
        boxT + CombatConstants.attackHitboxHeight > hitT &&
        boxT < hitB) {
      safe += _dt;
    }
  }
  return safe;
}

void main() {
  final files = Directory('assets/tiles/levels')
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'era\d+_\d+\.tmx$').hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('there are levels to check', () => expect(files, isNotEmpty));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('$name: every gap can be cleared and every platform landed on', () {
      final level = LevelLoader.parse(file.readAsStringSync());
      final spans = level.groundSpans;
      final ground = [for (final s in spans) (start: s.startX, end: s.startX + s.width)];
      final platforms = [
        for (final e in level.entities.where((e) => e.type == 'platform'))
          _Platform(e.x, e.width, e.y),
      ];

      for (var i = 0; i + 1 < spans.length; i++) {
        final gapStart = spans[i].startX + spans[i].width;
        final gapEnd = spans[i + 1].startX;
        final width = gapEnd - gapStart;
        final over = platforms.where((p) => p.x < gapEnd && p.x + p.width > gapStart).toList();

        // Launch positions: from well back on the ledge to the very lip.
        // The sprite's left edge is 24 units left of its foot span.
        final lip = gapStart - 1 - (_playerWidth - _playerWidth * footSpanFraction) / 2;
        final from = lip - 240;

        final direct = _window(from, lip, _Landed.ground, ground, const [], _groundY, gapEnd);
        final reason = 'gap at ${gapStart.toInt()} (${width.toInt()} wide)';

        if (over.isEmpty) {
          expect(direct, greaterThanOrEqualTo(_minWindowUnits),
              reason: '$reason has no platform and only a ${direct.toInt()}-unit '
                  'launch window to jump it');
          continue;
        }

        // With a platform: either the whole gap is a fair jump, or the student
        // can hop onto the platform and then across.
        final plat = over.first;
        final onto = _window(from, lip, _Landed.platform, ground, over, _groundY, gapEnd);
        expect(onto, greaterThanOrEqualTo(_minWindowUnits),
            reason: '$reason: landing on the platform has only a ${onto.toInt()}-unit window');

        // Leaving the platform: from any point along it, run and jump for the far ledge.
        final across = _window(plat.x - 24, plat.x + plat.width - 24, _Landed.ground, ground,
            const [], plat.surfaceY, gapEnd);
        final viaPlatform = across >= _minWindowUnits;
        expect(direct >= _minWindowUnits || viaPlatform, isTrue,
            reason: '$reason: no fair way across, direct window ${direct.toInt()}, '
                'off the platform ${across.toInt()}');
      }
    });
  }

  // Platform fights: a gap no jump can cross, a platform with an enemy on it.
  // The platform is the only way over, and the student must be able to hit the
  // enemy from the air before it can touch them.
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('$name: every platform fight needs its platform and can be fought from the air', () {
      final level = LevelLoader.parse(file.readAsStringSync());
      final spans = level.groundSpans;
      final ground = [for (final s in spans) (start: s.startX, end: s.startX + s.width)];
      var fights = 0;

      for (var i = 0; i + 1 < spans.length; i++) {
        final gapStart = spans[i].startX + spans[i].width;
        final gapEnd = spans[i + 1].startX;
        if (gapEnd - gapStart <= 288) continue; // the widest ordinary gap
        fights++;
        final reason = 'fight at ${gapStart.toInt()}';
        final plat = level.entities.firstWhere(
            (e) => e.type == 'platform' && e.x < gapEnd && e.x + e.width > gapStart);
        final platform = _Platform(plat.x, plat.width, plat.y);
        final guard = level.entities.firstWhere((e) =>
            e.type == 'enemy' &&
            level.enemyIsOnPlatform(e) &&
            (e.y - plat.y).abs() < 1 &&
            e.x >= plat.x &&
            e.x < plat.x + plat.width);

        final lip = gapStart - 1 - (_playerWidth - _playerWidth * footSpanFraction) / 2;
        final direct = _window(lip - 240, lip, _Landed.ground, ground, const [], _groundY, gapEnd);
        expect(direct, 0, reason: '$reason can be jumped without the platform');

        // From the launch positions that land on the platform, with the enemy at
        // each end of its patrol and in the middle: how wide a band of launches
        // gives a safe swing (the attack box overlaps the enemy before the
        // player's own box does) lasting at least 0.15 s.
        final patrol = guard.patrol ?? CombatConstants.patrolRange;
        for (final offset in [-patrol, 0.0, patrol]) {
          var good = 0;
          for (var x = lip - 240; x <= lip; x += 2) {
            final landing = _jump(x, ground, [platform], _groundY, gapEnd);
            if (landing != _Landed.platform) continue;
            if (_safeSwing(x, guard.x + offset, plat.y) >= 0.15) good++;
          }
          expect(good * 2.0, greaterThanOrEqualTo(_minWindowUnits),
              reason: '$reason, enemy ${offset.toInt()} off centre: only '
                  '${good * 2} units of launch give a 0.15 s safe swing');
        }
      }
      if (level.entities.any((e) => e.type == 'enemy' && level.enemyIsOnPlatform(e))) {
        expect(fights, greaterThan(0));
      }
    });
  }

  test('a platform above the jump peak cannot be landed on (the check can fail)', () {
    const ground = [(start: 0.0, end: 1000.0), (start: 1200.0, end: 5000.0)];
    // 150 above the ground is past the 128-unit peak.
    final high = [const _Platform(1048, 96, _groundY - 150)];
    final onto = _window(700, 975, _Landed.platform, ground, high, _groundY, 1200);
    expect(onto, 0);
  });

  test('a gap beyond the foot-span reach cannot be cleared (the check can fail)', () {
    const ground = [(start: 0.0, end: 1000.0), (start: 1340.0, end: 5000.0)];
    final direct = _window(700, 975, _Landed.ground, ground, const [], _groundY, 1340);
    expect(direct, 0, reason: 'a 340-unit gap is past 267 + 48');
  });
}
