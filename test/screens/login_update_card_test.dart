// A phone that is not signed in is told about a new version too: the card shows on
// the first screen, and the small chip stays after LATER.
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/providers/update_provider.dart';
import 'package:chronoquest/screens/auth/login_screen.dart';
import 'package:chronoquest/services/update_check.dart';
import 'package:chronoquest/widgets/update_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<UpdateNotifier> _open(WidgetTester tester,
    {LatestVersion? latest}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.binding.setSurfaceSize(const Size(800, 360));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final notifier = UpdateNotifier(fetch: () async => latest, open: (_) async {});
  await notifier.check();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuth()),
      updateProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      home: LoginScreen(
        scannerBuilder: (context, onRaw, onFailure) => const SizedBox(),
        connection: ValueNotifier<bool?>(true),
        checkConnection: () {},
        lastSignIn: () => null,
      ),
    ),
  ));
  await tester.pump();
  return notifier;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a new version shows the card on the first screen',
      (tester) async {
    await _open(tester, latest: const LatestVersion(version: '9.9.9'));
    expect(find.byKey(UpdateCard.cardKey), findsOneWidget);
    expect(find.byKey(UpdateCard.downloadKey), findsOneWidget);
  });

  testWidgets('no new version, no card and no chip', (tester) async {
    await _open(tester);
    expect(find.byKey(UpdateCard.cardKey), findsNothing);
    expect(find.byKey(UpdateChip.chipKey), findsNothing);
  });

  testWidgets('after LATER the chip stays on the first screen', (tester) async {
    final notifier =
        await _open(tester, latest: const LatestVersion(version: '9.9.9'));
    notifier.dismiss();
    await tester.pump();
    expect(find.byKey(UpdateCard.cardKey), findsNothing);
    expect(find.byKey(UpdateChip.chipKey), findsOneWidget);
  });
}
