import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_info.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/cq_tile.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/loading_line.dart';
import '../../widgets/scene_clock.dart';

/// How far the game has got in opening, and whose face rides the line.
class BootProgress {
  /// 0 to 1.
  final ValueNotifier<double> value = ValueNotifier<double>(0);

  /// The hero the student chose, once the saved data has been read.
  final ValueNotifier<String> hero = ValueNotifier<String>('rizal');

  void dispose() {
    value.dispose();
    hero.dispose();
  }
}

/// The first thing the game shows once the phone has drawn its own launch screen
/// (night colour and the CQ tile, in the same place): the tile keeps its spot and
/// rises, light rays come on, the name drops in, and the hero's face rides a line to
/// the gate while the game really loads behind it.
class SplashScreen extends StatelessWidget {
  final BootProgress progress;

  const SplashScreen({super.key, required this.progress});

  static const String tagline = 'KASAYSAYAN NG PILIPINAS';
  static const String name = 'CHRONOQUEST';

  static double _p(num ms, num start, num dur) =>
      ((ms - start) / dur).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SceneClock(
        peek: 4000,
        builder: (context, ms) {
          final rays = _p(ms, 300, 900);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: rays,
                child: const LivingBackdrop(
                    color: AppColors.accent,
                    center: Offset(0.5, 0.44),
                    fireflies: 8),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                      width: 640,
                      height: 300,
                      child: _Board(ms: ms, progress: progress)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final int ms;
  final BootProgress progress;
  const _Board({required this.ms, required this.progress});

  @override
  Widget build(BuildContext context) {
    final up = Curves.easeOut.transform(SplashScreen._p(ms, 300, 600));
    final letters = SplashScreen.name.split('');
    return Stack(
      children: [
        // The tile is where the phone's own launch screen drew it, then rises.
        Positioned(
          left: 320 - 32,
          top: 150 - 32 - 68 * up,
          child: Transform.scale(
              scale: 1 - 0.16 * up, child: const CqTile(size: 64)),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 116,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < letters.length; i++)
                _letter(letters[i], SplashScreen._p(ms, 500 + i * 45, 450)),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 170,
          child: Opacity(
            opacity: SplashScreen._p(ms, 1000, 400),
            child: Text(
              SplashScreen.tagline,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.3,
                color: const Color(0xFFCDBA94),
              ),
            ),
          ),
        ),
        Positioned(
          left: 320 - 120,
          bottom: 40,
          child: Opacity(
            opacity: SplashScreen._p(ms, 1100, 400),
            child: ValueListenableBuilder<String>(
              valueListenable: progress.hero,
              builder: (context, hero, _) => ValueListenableBuilder<double>(
                valueListenable: progress.value,
                builder: (context, p, _) => TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: p),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, v, _) =>
                      LoadingLine(progress: v, charId: hero),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 10,
          child: Opacity(
            opacity: SplashScreen._p(ms, 1000, 400),
            child: Text(
              'v$appVersion',
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x8CF5E3BE)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _letter(String c, double p) {
    // Drops in from above and settles with a small bounce.
    final dy =
        p < 0.6 ? -16 * (1 - p / 0.6) : 3 * math.sin((p - 0.6) / 0.4 * math.pi);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Text(
          c,
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            height: 1.1,
            color: AppColors.accent,
            shadows: const [
              Shadow(color: AppColors.primaryDark, offset: Offset(0, 3)),
              Shadow(color: Color(0x4D000000), offset: Offset(0, 6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the game behind the [SplashScreen]: runs [load], keeps the splash up for
/// at least [minimum] so the name can be seen, then fades into [app]. A failure in
/// [load] is reported and the app is shown anyway, as before.
class BootApp extends StatefulWidget {
  final Future<void> Function(BootProgress progress) load;
  final Widget Function() app;
  final Duration minimum;

  const BootApp({
    super.key,
    required this.load,
    required this.app,
    this.minimum = const Duration(milliseconds: 3000),
  });

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  final BootProgress _progress = BootProgress();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    try {
      await widget.load(_progress);
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(
          exception: e, stack: s, library: 'ChronoQuest boot'));
    }
    _progress.value.value = 1;
    final wait = widget.minimum - DateTime.now().difference(started);
    await Future<void>.delayed(
        wait > Duration.zero ? wait : const Duration(milliseconds: 250));
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.app())
          : KeyedSubtree(
              key: const ValueKey('splash'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                home: SplashScreen(progress: _progress),
              ),
            ),
    );
  }
}
