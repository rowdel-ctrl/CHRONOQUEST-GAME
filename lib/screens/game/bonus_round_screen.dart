import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bonus_constants.dart';
import '../../core/constants.dart';
import '../../game/bonus/bonus_game.dart';
import '../../game/bonus/bonus_session.dart';
import '../../game/overlays/bonus_hud.dart';
import '../../game/overlays/bonus_tally.dart';
import '../../models/control_scheme.dart';
import '../../providers/game_provider.dart';

/// The bonus round, shown on top of the level (which stays where it is, held
/// still, until this screen is popped with a [BonusResult]).
///
/// A gold circle grows out of the portal to show the round, the 20 seconds run,
/// a tally counts the coins, the coins go into the wallet through the same
/// `GameNotifier.addCoins` that every level coin uses (once), and the circle
/// shrinks back onto the portal. Leaving early (the pause menu, the back button)
/// pays what is in the counter so far and goes back the same way.
class BonusRoundScreen extends ConsumerStatefulWidget {
  final BonusRequest request;
  const BonusRoundScreen({super.key, required this.request});

  /// A route that leaves the level showing underneath, so the circle can open and
  /// close over it. No slide of its own: the circle is the transition.
  static Route<BonusResult> route(BonusRequest request) =>
      PageRouteBuilder<BonusResult>(
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => BonusRoundScreen(request: request),
      );

  @override
  ConsumerState<BonusRoundScreen> createState() => _BonusRoundScreenState();
}

class _BonusRoundScreenState extends ConsumerState<BonusRoundScreen>
    with SingleTickerProviderStateMixin {
  late final GameNotifier _wallet = ref.read(gameProvider.notifier);
  late final BonusGame game;

  /// The gold circle: 0 hidden, 1 the round fills the screen.
  late final AnimationController _wipe = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (BonusConstants.wipeSeconds * 1000).round()),
  );

  Timer? _loadWatch;
  bool _begun = false;
  bool _showBanner = false;
  bool _tally = false;
  bool _paused = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    game = BonusGame(
      eraId: r.eraId,
      levelNo: r.levelNo,
      characterId: r.characterId,
      scheme: ControlScheme.fromName(r.controlScheme),
    )
      // The coins go into the wallet the same way a level coin does (and so are
      // saved and synced the same way), in one lump, once.
      ..onPayout = _pay
      ..onTimeUp = () {
        if (mounted) setState(() => _tally = true);
      };
    _wipe.forward();
    _loadWatch =
        Timer.periodic(const Duration(milliseconds: 50), (_) => _checkReady());
  }

  void _pay(int coins) {
    try {
      _wallet.addCoins(coins);
    } catch (_) {
      // The wallet is gone (the app is closing): nothing more to do.
    }
  }

  /// Starts the clock once the round has loaded and the circle has opened.
  void _checkReady() {
    if (!mounted || _begun) return;
    // The clock starts only when the hero and the map are in (nobody loses time to loading).
    if (!game.isLoaded || !game.player.isLoaded || !_wipe.isCompleted) return;
    _begun = true;
    _loadWatch?.cancel();
    game.begin();
    setState(() => _showBanner = true);
  }

  void _pause() {
    if (!_begun || _leaving || _tally || game.timeUp || _paused) return;
    game.pauseEngine();
    game.overlays.add('BonusPause');
    setState(() => _paused = true);
  }

  void _resume() {
    if (!_paused) return;
    game.overlays.remove('BonusPause');
    game.resumeEngine();
    setState(() => _paused = false);
  }

  /// Android back: opens the pause menu, closes it again, or skips the tally.
  void _onBack() {
    if (_leaving) return;
    if (_tally) {
      unawaited(_leave());
    } else if (_paused) {
      _resume();
    } else {
      _pause();
    }
  }

  /// Pays what is in the counter (once, whatever got us here) and closes the
  /// circle back onto the portal.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final result = game.settle();
    game.pauseEngine();
    if (mounted) await _wipe.reverse();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _loadWatch?.cancel();
    _wipe.dispose();
    // Torn down some other way (the app logged out, say): whatever was won is still
    // paid, once. Deferred: a provider may not change while the tree is being torn down.
    if (!game.settled) Future<void>.microtask(game.settle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: AnimatedBuilder(
        animation: _wipe,
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_wipe.value);
          final size = MediaQuery.sizeOf(context);
          final centre = Offset(
            widget.request.portalOnScreen.dx * size.width,
            widget.request.portalOnScreen.dy * size.height,
          );
          final far =
              math.sqrt(size.width * size.width + size.height * size.height);
          final radius = far * v;
          final open = v >= 1;
          // The same widgets in the same places whether the circle is growing or
          // done, so the game underneath is never rebuilt part way through.
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: open ? null : _IrisClipper(centre, radius),
                clipBehavior: open ? Clip.none : Clip.antiAlias,
                child: child,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: open || v <= 0 ? null : _IrisRing(centre, radius),
                ),
              ),
            ],
          );
        },
        child: _round(context),
      ),
    );
  }

  Widget _round(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0626),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Pillarbox on very wide windows, exactly as the level does.
              final maxWidth = constraints.maxHeight * GameConstants.maxAspectRatio;
              final width =
                  constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;
              return Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: GameWidget(
                    game: game,
                    overlayBuilderMap: {
                      'BonusHud': (context, g) =>
                          BonusHudWidget(game: game, onPause: _pause),
                      'BonusPause': (context, g) => BonusPauseWidget(
                            game: game,
                            onResume: _resume,
                            onLeave: _leave,
                          ),
                    },
                    initialActiveOverlays: const ['BonusHud'],
                    loadingBuilder: (context) => const ColoredBox(
                      color: Color(0xFF0D0626),
                      child: Center(
                        child: CircularProgressIndicator(color: BonusColors.gold),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showBanner) const BonusBanner(),
          if (_tally)
            Positioned.fill(
              child: BonusTallyWidget(
                game: game,
                onCounted: game.settle,
                onDone: _leave,
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps only a circle of the round visible.
class _IrisClipper extends CustomClipper<Path> {
  final Offset centre;
  final double radius;
  _IrisClipper(this.centre, this.radius);

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius));

  @override
  bool shouldReclip(_IrisClipper old) =>
      old.centre != centre || old.radius != radius;
}

/// The gold edge of the circle while it grows or shrinks.
class _IrisRing extends CustomPainter {
  final Offset centre;
  final double radius;
  _IrisRing(this.centre, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xCCFFE9A0),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFF2C14E),
    );
  }

  @override
  bool shouldRepaint(_IrisRing old) =>
      old.centre != centre || old.radius != radius;
}
