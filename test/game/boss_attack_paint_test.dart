// The boss attacks are drawn in code (boss_attack_paint*.dart, boss_fx_component.dart): every one of
// the eleven draws something, in every state it can be in (flying, held, sent back, fading), at any
// point of its flight, without throwing. And an attack is a pure function of its progress: where
// it is depends on nothing but start, end and how far along it is.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chronoquest/game/boss_attack_profile.dart';
import 'package:chronoquest/game/components/boss_attack_component.dart';
import 'package:chronoquest/game/components/boss_fx_component.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

const int _w = 900, _h = 400;

BossAttackComponent _attack(BossAttackKind kind) => BossAttackComponent(
      kind: kind,
      start: Vector2(800 + kind.start.dx, 300 - kind.start.up),
      end: Vector2(150 + kind.end.dx, 300 - kind.end.up),
    );

/// How many pixels of a picture of [c] are not empty.
Future<int> _painted(WidgetTester tester, void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas =
      ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()));
  draw(canvas);
  final picture = recorder.endRecording();
  final bytes = await tester.runAsync<Uint8List>(() async {
    final image = await picture.toImage(_w, _h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  });
  var n = 0;
  for (var i = 3; i < bytes!.length; i += 4) {
    if (bytes[i] > 40) n++;
  }
  return n;
}

void main() {
  group('every attack is drawn', () {
    for (final kind in BossAttackKind.values) {
      testWidgets(
          '${kind.name}: flying, at the start, in the middle and at the hero',
          (tester) async {
        for (final p in [0.0, 0.25, 0.5, 1.0]) {
          final a = _attack(kind)..progress = p;
          final n = await _painted(tester, a.render);
          expect(n, greaterThan(50),
              reason: '${kind.name} at $p draws something');
        }
      });

      testWidgets('${kind.name}: held, and fading', (tester) async {
        final a = _attack(kind)..progress = 0.5;
        a.freeze();
        expect(a.mode, BossAttackMode.frozen);
        expect(await _painted(tester, a.render), greaterThan(50));
        a.fadeOut();
        a.update(0.1);
        expect(a.fade, lessThan(1));
        expect(await _painted(tester, a.render), greaterThan(50));
      });

      if (kind.reflects) {
        testWidgets('${kind.name}: sent back at the boss', (tester) async {
          final a = _attack(kind)..progress = 0.4;
          a.sendBack(Vector2(750, 230));
          for (final q in [0.0, 0.5, 1.0]) {
            a.reflectProgress = q;
            expect(await _painted(tester, a.render), greaterThan(50),
                reason: '${kind.name} sent back, $q of the way');
          }
        });
      }
    }
  });

  group('where an attack is', () {
    test('a straight line from the boss to the hero, by progress alone', () {
      final a = _attack(BossAttackKind.gslash);
      for (final p in [0.0, 0.3, 0.5, 1.0]) {
        a.progress = p;
        expect(a.head.x, closeTo(a.start.x + (a.end.x - a.start.x) * p, 1e-3));
        expect(a.head.y, closeTo(a.start.y + (a.end.y - a.start.y) * p, 1e-3));
      }
      a.progress = 1;
      expect(a.head.x, a.end.x);
      expect(a.head.y, a.end.y);
    });

    test('a sent-back attack goes from where it was hit to the boss', () {
      final a = _attack(BossAttackKind.pistol)..progress = 0.5;
      final hit = a.head.clone();
      a.sendBack(Vector2(700, 220));
      a.reflectProgress = 0;
      expect(a.head.x, closeTo(hit.x, 1e-3));
      a.reflectProgress = 1;
      expect(a.head.x, closeTo(700, 1e-3));
      expect(a.head.y, closeTo(220, 1e-3));
    });

    test(
        'the counter aims at the middle of what is drawn: the knights\' bodies, not their feet',
        () {
      final k = _attack(BossAttackKind.knights)..progress = 0.5;
      expect(k.centre.y, lessThan(k.head.y - 30));
      final s = _attack(BossAttackKind.slash)..progress = 0.5;
      expect(s.centre.y, s.head.y);
    });

    test('held, it stays where it is however long it is left', () {
      final a = _attack(BossAttackKind.water)..progress = 0.4;
      final x = a.head.x;
      a.freeze();
      a.update(5);
      expect(a.head.x, x);
    });

    test('a fading attack removes itself when it has faded', () {
      final a = _attack(BossAttackKind.ghost)..fadeOut();
      a.update(0.1);
      expect(a.fade, lessThan(1));
      expect(a.fade, greaterThan(0));
      a.update(0.3);
      expect(a.fade, lessThanOrEqualTo(0));
    });
  });

  group('the hit effects', () {
    for (final kind in BossBurstKind.values) {
      testWidgets('${kind.name} bursts, draws and is gone by itself',
          (tester) async {
        final b =
            BossBurstComponent(kind: kind, at: Vector2(400, 200), seed: 3);
        expect(b.pieceCount, greaterThan(0));
        expect(
            await _painted(tester, (c) {
              c.translate(400, 200);
              b.render(c);
            }),
            greaterThan(10));
        for (var i = 0; i < 60; i++) {
          b.update(1 / 30);
        }
        expect(b.pieceCount, 0, reason: 'every piece has lived out its life');
      });
    }
  });
}
