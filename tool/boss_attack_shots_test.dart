// A development tool, not a test of behaviour: draws every boss attack (flying at 30%, 60% and
// sent back) next to a boss and a hero marker, so the drawings can be reviewed without a device.
//
//   flutter test tool/boss_attack_shots_test.dart --dart-define=BOSS_SHOTS_OUT=C:/temp/attacks.png
//
// Without BOSS_SHOTS_OUT it does nothing, so it is safe in a full `flutter test tool` run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chronoquest/game/boss_attack_profile.dart';
import 'package:chronoquest/game/components/boss_attack_component.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = String.fromEnvironment('BOSS_SHOTS_OUT');

void main() {
  testWidgets('boss attack sheet', (tester) async {
    if (_out.isEmpty) return;
    const cellW = 620.0, cellH = 190.0, cols = 3;
    const kinds = BossAttackKind.values;
    final rows = kinds.length;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, cellW * cols, cellH * rows),
        ui.Paint()..color = const ui.Color(0xFF2B2230));
    for (var r = 0; r < rows; r++) {
      final kind = kinds[r];
      for (var c = 0; c < cols; c++) {
        canvas.save();
        canvas.translate(c * cellW, r * cellH);
        canvas.clipRect(const ui.Rect.fromLTWH(0, 0, cellW, cellH));
        canvas.scale(0.62, 0.62);
        // the floor, the hero (96x120) at the left and the boss (120x140) at the right
        const floor = 300.0;
        canvas.drawRect(const ui.Rect.fromLTWH(0, floor, 1000, 40),
            ui.Paint()..color = const ui.Color(0xFF46302C));
        canvas.drawRect(const ui.Rect.fromLTWH(100, floor - 120, 96, 120),
            ui.Paint()..color = const ui.Color(0x8880C0FF));
        canvas.drawRect(const ui.Rect.fromLTWH(800, floor - 140, 120, 140),
            ui.Paint()..color = const ui.Color(0x88FF8080));
        final a = BossAttackComponent(
          kind: kind,
          start: Vector2(860 + kind.start.dx, floor - kind.start.up),
          end: Vector2(148 + kind.end.dx, floor - kind.end.up),
        );
        if (c == 2) {
          a.progress = 0.5;
          a.sendBack(Vector2(860 - 36, floor - 80));
          a.reflectProgress = 0.45;
        } else {
          a.progress = c == 0 ? 0.3 : 0.6;
        }
        a.update(c == 0 ? 2.0 : 5.0);
        a.render(canvas);
        canvas.restore();
      }
    }
    final picture = recorder.endRecording();
    final bytes = await tester.runAsync(() async {
      final image =
          await picture.toImage((cellW * cols).round(), (cellH * rows).round());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File(_out)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
