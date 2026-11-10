// Settings > Kontrol: two cards, each a picture of a real-looking level with the
// player's own hero on the deck. The chosen card is lit with a gold ring, a filled
// round marker and the green NAKAPILI tag; a tap on a card chooses it.
import 'package:chronoquest/core/constants.dart';
import 'package:chronoquest/models/control_scheme.dart';
import 'package:chronoquest/providers/control_scheme_provider.dart';
import 'package:chronoquest/providers/game_provider.dart';
import 'package:chronoquest/screens/settings/controls_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeScheme extends StateNotifier<ControlScheme>
    implements ControlSchemeNotifier {
  final List<ControlScheme> saved = [];
  _FakeScheme(super.state);

  @override
  Future<void> set(ControlScheme scheme) async {
    state = scheme;
    saved.add(scheme);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGame extends StateNotifier<GameState> implements GameNotifier {
  _FakeGame(String hero) : super(GameState(selectedCharacterId: hero));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_FakeScheme> _open(
  WidgetTester tester, {
  Size size = const Size(732, 320),
  ControlScheme initial = ControlScheme.joystick,
  String hero = 'boy',
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  final scheme = _FakeScheme(initial);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      controlSchemeProvider.overrideWith((ref) => scheme),
      gameProvider.overrideWith((ref) => _FakeGame(hero)),
    ],
    child: const MaterialApp(home: ControlsScreen()),
  ));
  await tester.pump();
  return scheme;
}

BoxDecoration _marker(WidgetTester tester, ControlScheme s) {
  final box =
      tester.widget<Container>(find.byKey(ControlSchemeCard.markerKey(s)));
  return box.decoration! as BoxDecoration;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('keeps the two cards and their words', (tester) async {
    await _open(tester);
    expect(find.text('KONTROL'), findsOneWidget);
    expect(find.text('JOYSTICK'), findsOneWidget);
    expect(find.text('I-drag ang bilog para gumalaw'), findsOneWidget);
    expect(find.text('MGA ARROW'), findsOneWidget);
    expect(find.text('Pindutin ang kaliwa o kanan'), findsOneWidget);
    expect(find.text('Saved na sa device na ito.'), findsOneWidget);
  });

  testWidgets('the chosen card is lit: gold ring, filled marker, NAKAPILI',
      (tester) async {
    await _open(tester);

    expect(find.text('NAKAPILI'), findsOneWidget);
    expect(_marker(tester, ControlScheme.joystick).color, AppColors.accent);
    expect(_marker(tester, ControlScheme.arrows).color, isNull,
        reason: 'the other marker is an empty ring');
    final ring = tester.widget<Container>(
        find.byKey(ControlSchemeCard.ringKey(ControlScheme.joystick)));
    expect((ring.decoration! as BoxDecoration).boxShadow, isNotEmpty);
    final other = tester.widget<Container>(
        find.byKey(ControlSchemeCard.ringKey(ControlScheme.arrows)));
    expect((other.decoration! as BoxDecoration).boxShadow, isNull);
    // The tag is green and sits in the chosen card.
    final tag = tester.widget<Container>(find
        .ancestor(of: find.text('NAKAPILI'), matching: find.byType(Container))
        .first);
    expect((tag.decoration! as BoxDecoration).color, AppColors.success);
    expect(
      tester.getCenter(find.text('NAKAPILI')).dx,
      lessThan(tester.getCenter(find.text('MGA ARROW')).dx),
    );
  });

  testWidgets('a tap on a card chooses it and moves the light', (tester) async {
    final scheme = await _open(tester);

    await tester
        .tap(find.byKey(ControlSchemeCard.markerKey(ControlScheme.arrows)));
    await tester.pump();
    expect(scheme.saved, [ControlScheme.arrows]);
    expect(find.text('NAKAPILI'), findsOneWidget);
    expect(_marker(tester, ControlScheme.arrows).color, AppColors.accent);
    expect(_marker(tester, ControlScheme.joystick).color, isNull);

    // A tap on the picture works as well.
    await tester.tap(find.byType(ControlPreview).first);
    await tester.pump();
    expect(scheme.saved.last, ControlScheme.joystick);
  });

  testWidgets('both pictures show the hero the player chose, on the deck',
      (tester) async {
    await _open(tester, hero: 'girl');
    final heroes = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName ==
            'assets/characters/girl_walk_1.png');
    expect(heroes, findsNWidgets(2));
    // Three hearts in each picture.
    expect(
      find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/ui/heart_full.png'),
      findsNWidgets(6),
    );
    // The hero stands inside the picture, above its foot.
    final picture = tester.getRect(find.byType(ControlPreview).first);
    final hero = tester.getRect(heroes.first);
    expect(picture.contains(hero.center), isTrue);
    expect(hero.bottom, lessThan(picture.bottom));
  });

  testWidgets('the painter draws either layout and repaints on a change',
      (tester) async {
    const joystick = ControlLayoutPainter(ControlScheme.joystick);
    expect(
        joystick
            .shouldRepaint(const ControlLayoutPainter(ControlScheme.arrows)),
        isTrue);
    expect(
        joystick
            .shouldRepaint(const ControlLayoutPainter(ControlScheme.joystick)),
        isFalse);
  });

  for (final size in const [Size(732, 320), Size(640, 360), Size(400, 700)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _open(tester, size: size);
      expect(tester.takeException(), isNull);
      expect(find.text('NAKAPILI'), findsOneWidget);
    });
  }

  testWidgets(
      'side by side on a wide screen, one above the other on a narrow one',
      (tester) async {
    await _open(tester);
    var a = tester
        .getRect(find.byKey(ControlSchemeCard.ringKey(ControlScheme.joystick)));
    var b = tester
        .getRect(find.byKey(ControlSchemeCard.ringKey(ControlScheme.arrows)));
    expect(a.right, lessThan(b.left));

    await _open(tester, size: const Size(400, 700));
    a = tester
        .getRect(find.byKey(ControlSchemeCard.ringKey(ControlScheme.joystick)));
    b = tester
        .getRect(find.byKey(ControlSchemeCard.ringKey(ControlScheme.arrows)));
    expect(a.bottom, lessThan(b.top));
  });
}
