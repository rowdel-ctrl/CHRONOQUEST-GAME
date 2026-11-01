// Jump and Attack are round buttons with a picture on them (two chevrons, a
// sword), not the words JUMP and ATK.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoquest/game/chrono_game.dart';
import 'package:chronoquest/game/components/player_component.dart';
import 'package:chronoquest/game/game_input.dart';

class _Game extends ChronoGame {
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    camera.viewfinder.anchor = Anchor.topLeft;
    player = PlayerComponent(characterId: 'rizal')
      ..size = Vector2(96, 120)
      ..position = Vector2(0, groundY - 120);
    gameInput = GameInput(game: this);
    gameInput.setup();
  }
}

Future<List<HudButtonComponent>> _mount(WidgetTester tester) async {
  final game = _Game();
  await tester.pumpWidget(MaterialApp(
    home: SizedBox(width: 2400, height: 1080, child: GameWidget(game: game)),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  // Jump first, then Attack: the order they are added in.
  return game.camera.viewport.children.whereType<HudButtonComponent>().toList();
}

/// The colour of a point on the button's face, away from the picture and the rim.
Future<Color> _faceColour(WidgetTester tester, PositionComponent button) async {
  final recorder = ui.PictureRecorder();
  button.render(Canvas(recorder));
  final image = await recorder.endRecording().toImage(button.size.x.round(), button.size.y.round());
  late ByteData bytes;
  await tester.runAsync(() async => bytes = (await image.toByteData())!);
  const x = 54, y = 14;
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(bytes.getUint8(i + 3), bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('there is one Jump and one Attack, both 108 across and with no words on them',
      (tester) async {
    final buttons = await _mount(tester);

    expect(buttons.length, 2);
    for (final b in buttons) {
      for (final face in [b.button!, b.buttonDown!]) {
        expect(face.size, Vector2.all(108));
        expect(face.descendants().whereType<TextComponent>(), isEmpty, reason: 'a picture, not a word');
      }
    }
  });

  testWidgets('Jump is gold and Attack is red', (tester) async {
    final buttons = await _mount(tester);

    final jump = await _faceColour(tester, buttons[0].button!);
    final attack = await _faceColour(tester, buttons[1].button!);

    expect((jump.g * 255).round(), greaterThan(150), reason: 'gold');
    expect((attack.g * 255).round(), lessThan(110), reason: 'red');
    expect((attack.r * 255).round(), greaterThan(150));
  });

  testWidgets('a pressed button is solid, a resting one lets the level show through', (tester) async {
    final buttons = await _mount(tester);

    final resting = await _faceColour(tester, buttons[0].button!);
    final pressed = await _faceColour(tester, buttons[0].buttonDown!);

    expect(pressed.a, 1.0);
    expect(resting.a, lessThan(1.0));
  });
}
