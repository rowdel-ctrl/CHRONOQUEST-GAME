import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/hearts_pill.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/particles.dart';
import '../../widgets/pixel_icon.dart';

/// The colour of each hero: the light behind it and the tint of its roster tile.
Color characterColor(String id) {
  switch (id) {
    case 'boy':
      return const Color(0xFF9B6BD1);
    case 'girl':
      return const Color(0xFFD97BB6);
    case 'lapu':
      return const Color(0xFFD4A853);
    case 'rizal':
      return const Color(0xFF5B9BD5);
    case 'luna':
      return const Color(0xFF5BA88A);
    case 'bonifacio':
      return const Color(0xFFD45B5B);
    case 'delpilar':
      return const Color(0xFFD4C44A);
    case 'mariaclara':
      return const Color(0xFFCF5C7E);
    default:
      return AppColors.accent;
  }
}

/// How many walking pictures a hero has: 4, and 5 for Lapu-Lapu.
int walkFramesOf(String id) => id == 'lapu' ? 5 : 4;

/// 0 before [a], 1 after [b], a straight line between.
double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

/// The things that move on this screen besides the hero's own idling: the opening,
/// an unlock and the choosing. Each runs 0 to 1; 0 is "not happening" for the last
/// two, and 1 is "done" for the first.
class _Motion {
  final Animation<double> enter;

  /// True the first time the screen opens in a run of the game: the hero walks in.
  /// Later it only pops in.
  final bool full;
  final Animation<double> celebrate;
  final Animation<double> choose;

  const _Motion(
      {required this.enter,
      required this.full,
      required this.celebrate,
      required this.choose});

  Listenable get all => Listenable.merge([enter, celebrate, choose]);
}

/// Pick your hero: one big hero with light behind it in its own colour, its short
/// name, one button, and a row of all five to tap (or swipe). Two arrows beside the
/// hero nudge the way they point. A hero that costs coins is dark, with its price,
/// and the button buys it.
///
/// It moves: the hero walks in when the screen first opens, slides out and in when
/// another is picked, breathes, glints and hops while it waits, lights up in a burst
/// when bought, and jumps and runs off when chosen. All of it is made from the
/// frames the heroes already have (walking and jumping) plus light, dust, sparks and
/// confetti, and all of it stops when the phone is set to remove animations.
class CharacterSelectionScreen extends ConsumerStatefulWidget {
  const CharacterSelectionScreen({super.key});

  static const chooseKey = ValueKey('choose_character');
  static const nameKey = ValueKey('character_name');
  static const priceKey = ValueKey('character_price');
  static const unlockKey = ValueKey('unlock_character');
  static const prevKey = ValueKey('character_prev');
  static const nextKey = ValueKey('character_next');
  static const helpKey = ValueKey('character_help');
  static const coinsKey = ValueKey('character_coins');
  static const shopKey = ValueKey('character_shop');
  static ValueKey<String> rosterKey(String id) => ValueKey('roster_$id');

  /// Makes the next opening walk the hero in again, as on the first visit: for tests.
  @visibleForTesting
  static void resetOpening() =>
      _CharacterSelectionScreenState._walkedIn = false;

  @override
  ConsumerState<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState
    extends ConsumerState<CharacterSelectionScreen>
    with TickerProviderStateMixin {
  /// Set once the hero has walked in, so a later visit only pops it in.
  static bool _walkedIn = false;

  late int _selected;
  late final bool _full;
  late final AnimationController _enter;
  late final AnimationController _celebrate;
  late final AnimationController _choose;
  bool _enterStarted = false;
  String? _lastId;
  bool _lastLocked = false;

  @override
  void initState() {
    super.initState();
    // Start on the hero the student chose last time.
    final i = allCharacters
        .indexWhere((c) => c.id == ref.read(gameProvider).selectedCharacterId);
    _selected = i < 0 ? 0 : i;
    _full = !_walkedIn;
    _enter = AnimationController(
        vsync: this, duration: Duration(milliseconds: _full ? 2000 : 700));
    _celebrate = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _choose = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          context.go('/era-selection');
        }
      });
    // The first-play tutorial is not triggered here: it is gated where a level is
    // started (LevelSelectScreen._startLevel). The book icon opens it any time.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enterStarted) return;
    _enterStarted = true;
    if (motionAllowed(context)) {
      _walkedIn = true;
      _enter.forward();
    } else {
      _enter.value = 1;
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _celebrate.dispose();
    _choose.dispose();
    super.dispose();
  }

  void _show(int i) =>
      setState(() => _selected = i.clamp(0, allCharacters.length - 1));

  void _skipChoose() => _choose.value = 1;

  @override
  Widget build(BuildContext context) {
    final coins =
        ref.watch(gameProvider).coins; // redraw when a character is bought
    final notifier = ref.read(gameProvider.notifier);
    final char = allCharacters[_selected];
    final locked = !notifier.isCharacterUnlocked(char.id);
    final color = characterColor(char.id);
    final wide = MediaQuery.sizeOf(context).width >= 560;
    final topInset = MediaQuery.paddingOf(context).top;
    final moving = motionAllowed(context);

    // A hero that was dark a moment ago and is not now has just been bought.
    if (moving && _lastId == char.id && _lastLocked && !locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _celebrate.forward(from: 0);
      });
    }
    _lastId = char.id;
    _lastLocked = locked;

    final motion = _Motion(
        enter: _enter, full: _full, celebrate: _celebrate, choose: _choose);
    final stage = _Stage(
      char: char,
      locked: locked,
      color: color,
      canPrev: _selected > 0,
      canNext: _selected < allCharacters.length - 1,
      onSwipe: (forward) => _show(_selected + (forward ? 1 : -1)),
      motion: motion,
    );
    final info = _Info(
      char: char,
      locked: locked,
      color: color,
      centered: !wide,
      selected: _selected,
      coins: coins,
      onShop: () => context.push('/shop'),
      isLocked: (id) => !notifier.isCharacterUnlocked(id),
      onPick: _show,
      motion: motion,
      onChoose: () {
        notifier.selectCharacter(char.id);
        if (moving) {
          _choose.forward(from: 0);
        } else {
          context.go('/era-selection');
        }
      },
    );

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: Stack(
          children: [
            // The light comes from behind the hero, in the hero's own colour, and
            // changes to the next hero's colour with a short cross-fade.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration:
                    moving ? const Duration(milliseconds: 450) : Duration.zero,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, if (current != null) current],
                ),
                child: LivingBackdrop(
                  key: ValueKey('backdrop_${char.id}'),
                  color: color,
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _choose,
                builder: (context, child) =>
                    AbsorbPointer(absorbing: _choose.isAnimating, child: child),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, topInset + 52, 16, 12),
                        child: wide
                            ? Row(
                                children: [
                                  Expanded(flex: 3, child: stage),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 5, child: info),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(child: stage),
                                  const SizedBox(height: 8),
                                  info,
                                ],
                              ),
                      ),
                    ),

                    // Leaderboard top-left button. The chips are 48 square to hit and
                    // 40 to look at, so they sit 4 higher and 4 nearer the edge than
                    // the 40 square buttons they replaced.
                    Positioned(
                      top: topInset + 4,
                      left: 8,
                      child: MenuChip(
                        icon: PixelGlyph.trophy,
                        tooltip: 'Leaderboard',
                        onTap: () => context.push('/leaderboard'),
                      ),
                    ),

                    // Hearts, how to play, Profile and Settings, top right. Hearts sit in
                    // this existing icon row rather than taking a new band of vertical
                    // space, which a 320px-tall landscape phone does not have to spare.
                    // Settings is always the right-most chip and Profile just left of it.
                    Positioned(
                      top: topInset + 4,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HeartsPill(),
                          const SizedBox(width: 4),
                          _HelpChip(onTap: () => context.push('/tutorial')),
                          MenuChip(
                            icon: PixelGlyph.profile,
                            tooltip: 'Profile',
                            onTap: () => context.push('/profile'),
                          ),
                          MenuChip(
                            icon: PixelGlyph.gear,
                            tooltip: 'Settings',
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Choosing: a gold curtain sweeps across, and a tap anywhere skips ahead.
            AnimatedBuilder(
              animation: _choose,
              builder: (context, _) => Positioned.fill(
                child: _choose.value <= 0
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _skipChoose,
                        child: CustomPaint(
                            painter:
                                _CurtainPainter(_seg(_choose.value, 0.62, 1))),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gold curtain that wipes the screen when a hero is chosen. At 1 it covers it.
class _CurtainPainter extends CustomPainter {
  final double p;
  const _CurtainPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    if (p <= 0) return;
    final edge = Curves.easeInOut.transform(p) * size.width * 1.12;
    canvas.drawRect(Rect.fromLTWH(0, 0, edge, size.height),
        Paint()..color = AppColors.accent);
    final band = size.width * 0.06;
    canvas.drawRect(Rect.fromLTWH(edge - band, 0, band, size.height),
        Paint()..color = AppColors.primaryDark);
  }

  @override
  bool shouldRepaint(_CurtainPainter old) => old.p != p;
}

// ── The hero, big ──────────────────────────────────────────────────────────────
class _Stage extends StatefulWidget {
  final CharacterData char;
  final bool locked;
  final Color color;
  final bool canPrev;
  final bool canNext;

  /// A swipe or an arrow: true goes to the next hero, false to the one before.
  final ValueChanged<bool> onSwipe;
  final _Motion motion;

  const _Stage({
    required this.char,
    required this.locked,
    required this.color,
    required this.canPrev,
    required this.canNext,
    required this.onSwipe,
    required this.motion,
  });

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with TickerProviderStateMixin {
  /// The arrows nudge sideways, slowly, to say "this way".
  late final AnimationController _nudge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  /// The hero rises and settles, and its shadow shrinks and grows with it.
  late final AnimationController _bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));

  /// One hero leaving and the next arriving.
  late final AnimationController _switch = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 620));

  /// A small hop.
  late final AnimationController _hop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 660));

  final GlobalKey<ParticleLayerState> _particles =
      GlobalKey<ParticleLayerState>();
  final math.Random _random = math.Random();
  Timer? _frameTimer;
  Timer? _glintTimer;
  Timer? _hopTimer;
  final List<Timer> _later = [];
  int _idleFrame = 0;

  CharacterData? _from;
  bool _fromLocked = false;
  int _dir = 1;
  double _hopPower = 20;

  // Where the hero stands, kept from the last layout for the dust and sparks.
  double _stageW = 300;
  double _heroH = 200;
  double _top = 0;
  double _heroDx = 0;

  double _lastCelebrate = 0;
  double _lastChoose = 0;
  int _trail = -1;

  Offset get _feet => Offset(_stageW / 2 + _heroDx, _top + _heroH);

  @override
  void initState() {
    super.initState();
    widget.motion.celebrate.addListener(_onCelebrate);
    widget.motion.choose.addListener(_onChoose);
    _switch.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _from = null;
        _puffs(3, 14);
      }
    });
    _hop.addStatusListener((s) {
      if (s == AnimationStatus.completed) _puffs(3, 12);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _frameTimer?.cancel();
    _glintTimer?.cancel();
    _hopTimer?.cancel();
    if (motionAllowed(context)) {
      if (!_nudge.isAnimating) _nudge.repeat(reverse: true);
      if (!_bob.isAnimating) _bob.repeat(reverse: true);
      // The walk frames are shown slowly as the idle (4 frames, 5 for Lapu-Lapu).
      _frameTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (mounted) {
          setState(() =>
              _idleFrame = (_idleFrame + 1) % walkFramesOf(widget.char.id));
        }
      });
      _glintTimer =
          Timer.periodic(const Duration(milliseconds: 2300), (_) => _glint());
      _hopTimer =
          Timer.periodic(const Duration(milliseconds: 7600), (_) => _idleHop());
    } else {
      _nudge.stop();
      _nudge.value = 0;
      _bob.stop();
      _bob.value = 0;
      _switch.value = 0;
      _hop.value = 0;
    }
  }

  @override
  void didUpdateWidget(_Stage old) {
    super.didUpdateWidget(old);
    if (old.char.id != widget.char.id && motionAllowed(context)) {
      _from = old.char;
      _fromLocked = old.locked;
      _dir = allCharacters.indexWhere((c) => c.id == widget.char.id) >
              allCharacters.indexWhere((c) => c.id == old.char.id)
          ? 1
          : -1;
      _hop.value = 0;
      _switch.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.motion.celebrate.removeListener(_onCelebrate);
    widget.motion.choose.removeListener(_onChoose);
    _frameTimer?.cancel();
    _glintTimer?.cancel();
    _hopTimer?.cancel();
    for (final t in _later) {
      t.cancel();
    }
    _nudge.dispose();
    _bob.dispose();
    _switch.dispose();
    _hop.dispose();
    super.dispose();
  }

  /// Runs [f] after [ms] milliseconds, unless the screen has gone by then.
  void _after(int ms, VoidCallback f) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _later.remove(t);
      if (mounted) f();
    });
    _later.add(t);
  }

  bool get _busy =>
      _switch.isAnimating ||
      _hop.isAnimating ||
      widget.motion.enter.isAnimating ||
      widget.motion.celebrate.isAnimating ||
      widget.motion.choose.isAnimating;

  void _puffs(int n, double spread) {
    final layer = _particles.currentState;
    if (layer == null) return;
    final f = _feet;
    for (var k = 0; k < n; k++) {
      _after(k * 50, () {
        _particles.currentState
            ?.puff(Offset(f.dx + (k - (n - 1) / 2) * spread, f.dy));
      });
    }
  }

  void _glint() {
    if (!mounted || _busy) return;
    final f = _feet;
    _particles.currentState?.spark(
        Offset(f.dx + (_random.nextDouble() * 90 - 45),
            f.dy - (50 + _random.nextDouble() * 110)),
        size: 9);
  }

  void _idleHop() {
    if (!mounted || _busy || widget.locked) return;
    _hopPower = 20;
    _hop.forward(from: 0);
  }

  void _onCelebrate() {
    final v = widget.motion.celebrate.value;
    final layer = _particles.currentState;
    if (_lastCelebrate == 0 && v > 0 && layer != null) {
      final f = _feet;
      layer.ring(Offset(f.dx, f.dy - _heroH * 0.45));
      layer.confetti(Offset(f.dx, f.dy - _heroH * 0.6), [
        widget.color,
        AppColors.accent,
        AppColors.surface,
        Colors.white,
        AppColors.danger
      ]);
      const spots = [
        Offset(-34, -70),
        Offset(30, -96),
        Offset(-8, -128),
        Offset(44, -40),
        Offset(-46, -30)
      ];
      for (var k = 0; k < spots.length; k++) {
        _after(k * 70, () {
          _particles.currentState?.spark(f + spots[k],
              size: 12,
              color: k.isOdd ? Colors.white : const Color(0xFFFFE08A));
        });
      }
    }
    if (_lastCelebrate < 0.233 && v >= 0.233) {
      _hopPower = 26;
      _hop.forward(from: 0);
    }
    _lastCelebrate = v;
  }

  void _onChoose() {
    final v = widget.motion.choose.value;
    if (_lastChoose < 0.115 && v >= 0.115) {
      final f = _feet;
      _particles.currentState?.ring(Offset(f.dx, f.dy - _heroH * 0.45));
    }
    if (v >= 0.5 && v < 1) {
      final k = (v * 1300 / 110).floor();
      if (k != _trail) {
        _trail = k;
        _particles.currentState?.puff(Offset(_feet.dx - 30, _feet.dy));
      }
    }
    if (v == 0) _trail = -1;
    _lastChoose = v;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 200) widget.onSwipe(v < 0);
      },
      child: LayoutBuilder(
        builder: (context, box) {
          final height = (box.maxHeight - 24).clamp(96.0, 230.0);
          _stageW = box.maxWidth;
          _heroH = height;
          _top = (box.maxHeight - (height + 18)) / 2;
          final heroW = height * 52 / 68;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Its shadow on the ground: smaller while the hero is up.
              AnimatedBuilder(
                animation: Listenable.merge([_bob, _hop, widget.motion.choose]),
                builder: (context, _) {
                  final up = Curves.easeInOut.transform(_bob.value);
                  final hopRise =
                      _hop.isAnimating ? math.sin(_hop.value * math.pi) : 0.0;
                  final gone = _seg(widget.motion.choose.value, 0.5, 0.6);
                  return Positioned(
                    left: (box.maxWidth - height * 0.7) / 2,
                    top: _top + height + 6,
                    width: height * 0.7,
                    height: 12,
                    child: Opacity(
                      opacity: 1 - gone,
                      child: Transform.scale(
                        scaleX: 1 - 0.06 * up - 0.25 * hopRise,
                        child: ClipOval(
                            child: Container(
                                color: Colors.black.withValues(alpha: 0.4))),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: (box.maxWidth - heroW) / 2,
                top: _top,
                width: heroW,
                height: height,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [widget.motion.all, _switch, _hop, _bob]),
                  builder: (context, _) => _hero(height, heroW),
                ),
              ),
              Positioned.fill(child: ParticleLayer(key: _particles)),
              // A streak of light crosses when another hero is picked.
              AnimatedBuilder(
                animation: _switch,
                builder: (context, _) {
                  if (!_switch.isAnimating) return const SizedBox.shrink();
                  final p = (_switch.value / 0.8).clamp(0.0, 1.0);
                  final x = _dir > 0
                      ? _lerp(-44, box.maxWidth, p)
                      : _lerp(box.maxWidth, -44, p);
                  return Positioned(
                    left: x,
                    top: -10,
                    bottom: -10,
                    width: 44,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - p).clamp(0.0, 1.0),
                        child: Transform(
                          transform: Matrix4.skewX(-0.32),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color(0x00FFFFFF),
                                Color(0x66FFFFFF),
                                Color(0x00FFFFFF)
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: widget.motion.all,
                builder: (context, child) {
                  final m = widget.motion;
                  final fade = _seg(m.enter.value, m.full ? 0.75 : 0.55,
                          m.full ? 0.9 : 0.8) *
                      (1 - _seg(m.choose.value, 0.5, 0.67));
                  return Opacity(opacity: fade, child: child);
                },
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _Arrow(
                        key: CharacterSelectionScreen.prevKey,
                        forward: false,
                        enabled: widget.canPrev,
                        nudge: _nudge,
                        onTap: () => widget.onSwipe(false),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _Arrow(
                        key: CharacterSelectionScreen.nextKey,
                        forward: true,
                        enabled: widget.canNext,
                        nudge: _nudge,
                        onTap: () => widget.onSwipe(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// The hero with whatever it is doing right now laid over its idling.
  Widget _hero(double height, double heroW) {
    final m = widget.motion;
    final e = m.enter.value,
        ce = m.celebrate.value,
        ch = m.choose.value,
        sw = _switch.value;
    var char = widget.char;
    var dark = widget.locked;
    var underDark = false;
    var reveal = 1.0;
    var dx = 0.0,
        dy = 0.0,
        sx = 1.0,
        sy = 1.0,
        rot = 0.0,
        opacity = 1.0,
        scale = 1.0;
    var jump = false;
    var frame = _idleFrame;
    final heroScale = height / 160;

    // Opening: walks in from the left (the first time), or pops in.
    if (e < 1 && !_switch.isAnimating) {
      if (m.full) {
        final k = _seg(e, 0, 0.475);
        dx = -(1 - Curves.easeOut.transform(k)) * (_stageW / 2 + heroW);
        if (e < 0.475) frame = ((e * 2000) ~/ 110) % walkFramesOf(char.id);
        final s = math.sin(_seg(e, 0.475, 0.6) * math.pi);
        sy = 1 - 0.08 * s;
        sx = 1 + 0.05 * s;
      } else {
        final k = _seg(e, 0, 0.5);
        opacity = k;
        scale = 0.7 + 0.3 * Curves.easeOutBack.transform(k);
      }
    }

    // Switching: the old hero leaves the way it was swiped, the new one arrives.
    if (_switch.isAnimating && _from != null) {
      if (sw < 0.32) {
        final k = Curves.easeIn.transform(sw / 0.32);
        char = _from!;
        dark = _fromLocked;
        dx = -_dir * 64 * k;
        rot = -_dir * 6 * math.pi / 180 * k;
        opacity = 1 - k;
      } else {
        final k = (sw - 0.32) / 0.68;
        final a = Curves.easeOut.transform(_seg(k, 0, 0.72));
        final b = Curves.easeInOut.transform(_seg(k, 0.72, 1));
        dx = _dir * 74 * (1 - a) - _dir * 7 * a * (1 - b);
        rot = _dir * 5 * (1 - a) * math.pi / 180;
        opacity = _seg(k, 0, 0.45);
      }
    }

    // Bought: the colour climbs up the dark shape.
    if (ce > 0 && ce < 0.233) {
      reveal = Curves.easeOut.transform(_seg(ce, 0, 0.233));
      underDark = true;
      dark = false;
    }

    // A hop: waiting, or celebrating.
    if (_hop.isAnimating) {
      final p = _hop.value;
      jump = true;
      final rise = p < 0.45
          ? Curves.easeOut.transform(p / 0.45)
          : (p < 0.9 ? 1 - Curves.easeIn.transform((p - 0.45) / 0.45) : 0.0);
      dy -= _hopPower * heroScale * rise;
      if (p >= 0.9) {
        sx = 1.06;
        sy = 0.92;
      }
    }

    // Chosen: squat, jump, run off to the right.
    if (ch > 0) {
      if (ch < 0.115) {
        final k = ch / 0.115;
        sx = 1 + 0.07 * k;
        sy = 1 - 0.12 * k;
      } else if (ch < 0.5) {
        jump = true;
        final p = (ch - 0.115) / 0.385;
        final rise = p < 0.5
            ? Curves.easeOut.transform(p / 0.5)
            : 1 - Curves.easeIn.transform((p - 0.5) / 0.5);
        dy -= 28 * heroScale * rise;
      } else {
        final p = (ch - 0.5) / 0.5;
        frame = ((ch * 1300) ~/ 90) % walkFramesOf(char.id);
        dx = Curves.easeInCubic.transform(p) *
            (MediaQuery.sizeOf(context).width + heroW);
      }
    }
    _heroDx = dx;

    final bob = Curves.easeInOut.transform(_bob.value);
    final path = jump
        ? 'assets/characters/${char.id}_jump.png'
        : 'assets/characters/${char.id}_walk_'
            '${frame % walkFramesOf(char.id) + 1}.png';
    Widget sprite = _HeroSprite(
      key: ValueKey('hero_${char.id}'),
      path: path,
      charId: char.id,
      width: heroW,
      height: height,
      dark: dark,
      underlayDark: underDark,
      reveal: reveal,
      jump: jump,
    );
    sprite = Transform.translate(offset: Offset(0, -6 * bob), child: sprite);
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.translationValues(dx, dy, 0)
        ..rotateZ(rot)
        ..scaleByDouble(sx * scale, sy * scale, 1, 1),
      child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: sprite),
    );
  }
}

/// One frame of a hero, anchored at its feet. A hero not bought yet is a dark shape;
/// while it is being bought the colour is revealed from the feet up over the dark
/// shape.
class _HeroSprite extends StatelessWidget {
  final String path;
  final String charId;
  final double width;
  final double height;
  final bool dark;
  final bool underlayDark;
  final double reveal;
  final bool jump;

  const _HeroSprite({
    super.key,
    required this.path,
    required this.charId,
    required this.width,
    required this.height,
    required this.dark,
    required this.underlayDark,
    required this.reveal,
    required this.jump,
  });

  /// The new pictures are not all one size, so none is stretched: each is drawn
  /// at its own pixels divided by (300 / [height]), the same rule as the game
  /// (a 300 pixel tall picture fills the stage), standing on its bottom edge.
  Widget _image() => Image.asset(
        path,
        scale: 300 / height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => SizedBox(
          height: height,
          child: Center(
            child: Text(
              charId[0].toUpperCase(),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

  Widget _darkened(Widget child) => ColorFiltered(
        colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.72), BlendMode.srcATop),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (underlayDark) {
      body = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _darkened(_image()),
          ClipRect(clipper: _BottomUp(reveal), child: _image()),
        ],
      );
    } else if (dark) {
      body = _darkened(_image());
    } else {
      body = _image();
    }
    // The new jump picture is the same size as the walk ones, so it needs no
    // scaling down any more.
    return SizedBox(
      width: width,
      height: height,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        child: body,
      ),
    );
  }
}

/// Shows the lower part of a box, [shown] of it, from the bottom.
class _BottomUp extends CustomClipper<Rect> {
  final double shown;
  const _BottomUp(this.shown);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
      0, size.height * (1 - shown), size.width, size.height * shown);

  @override
  bool shouldReclip(_BottomUp old) => old.shown != shown;
}

/// A round arrow beside the hero: it nudges the way it points, and goes dim at
/// the end of the row. 48 to hit, 40 to look at, like the menu chips.
class _Arrow extends StatelessWidget {
  final bool forward;
  final bool enabled;
  final Animation<double> nudge;
  final VoidCallback onTap;

  const _Arrow({
    super.key,
    required this.forward,
    required this.enabled,
    required this.nudge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dir = forward ? 1.0 : -1.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: forward ? 'Susunod na bayani' : 'Nakaraang bayani',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: AnimatedBuilder(
            animation: nudge,
            builder: (context, child) => Transform.translate(
              offset: enabled
                  ? Offset(dir * 5 * Curves.easeInOut.transform(nudge.value), 0)
                  : Offset.zero,
              child: Opacity(opacity: enabled ? 1 : 0.28, child: child),
            ),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primaryDark, offset: Offset(2, 2))
                  ],
                ),
                child: Transform.scale(
                  scaleX: dir,
                  child: const PixelIcon(PixelGlyph.chevron,
                      size: 22, color: AppColors.accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How to play, top right: a round gold ? with the small word PAANO under it. It
/// was a book icon that said nothing. 48 wide and tall to hit, like the menu chips.
class _HelpChip extends StatelessWidget {
  final VoidCallback onTap;
  const _HelpChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Paano Laruin',
      child: Semantics(
        button: true,
        label: 'Paano Laruin',
        child: GestureDetector(
          key: CharacterSelectionScreen.helpKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.primaryDark, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.primaryDark, offset: Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      '?',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'PAANO',
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.surface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The last row under the heroes: the coins in a dark pill and a gold TINDAHAN
/// button, so a student who sees a price they cannot pay knows where to get coins.
class _ShopRow extends StatelessWidget {
  final int coins;
  final VoidCallback onShop;
  const _ShopRow({required this.coins, required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Coins mo: $coins',
          child: ExcludeSemantics(
            child: Container(
              key: CharacterSelectionScreen.coinsKey,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFF3A2D52), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/collectibles/coin.png',
                      width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: GameButton(
            key: CharacterSelectionScreen.shopKey,
            label: 'TINDAHAN',
            fontSize: 8,
            minHeight: 38,
            horizontalPadding: 14,
            leading: const PixelIcon(PixelGlyph.cart,
                size: 16, color: AppColors.primaryDark),
            onPressed: onShop,
          ),
        ),
      ],
    );
  }
}

// ── Name, price, button and the roster ────────────────────────────────────────
class _Info extends StatelessWidget {
  final CharacterData char;
  final bool locked;
  final Color color;
  final bool centered;
  final int selected;

  /// The wallet, and where the shop button goes: the last row under the heroes.
  final int coins;
  final VoidCallback onShop;
  final bool Function(String id) isLocked;
  final ValueChanged<int> onPick;
  final VoidCallback onChoose;
  final _Motion motion;

  const _Info({
    required this.char,
    required this.locked,
    required this.color,
    required this.centered,
    required this.selected,
    required this.coins,
    required this.onShop,
    required this.isLocked,
    required this.onPick,
    required this.onChoose,
    required this.motion,
  });

  /// Fades and slides a piece in during the opening, and out when a hero is chosen.
  Widget _enterOut(Widget child,
      {required double from,
      required double to,
      double dy = 0,
      double dx = 0,
      int tile = -1}) {
    final m = motion;
    final k = _seg(
        m.enter.value, m.full ? from : from - 0.2, m.full ? to : to - 0.12);
    final out = _seg(m.choose.value, 0.5 + (tile < 0 ? 0 : 0.017 * tile),
        0.67 + (tile < 0 ? 0 : 0.017 * tile));
    return Opacity(
      opacity: (k * (1 - out)).clamp(0.0, 1.0),
      child: Transform.translate(
          offset:
              Offset(dx * (1 - k), dy * (1 - k) + (tile < 0 ? 0 : 60 * out)),
          child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final align =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final moving = motionAllowed(context);
    final name = FittedBox(
      key: ValueKey('name_${char.id}'),
      fit: BoxFit.scaleDown,
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Text(
        char.shortName,
        key: CharacterSelectionScreen.nameKey,
        style: GoogleFonts.poppins(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
          shadows: const [
            Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))
          ],
        ),
      ),
    );
    final priceRow = locked
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/ui/lock_icon.png',
                  width: 16, height: 16, filterQuality: FilterQuality.none),
              const SizedBox(width: 8),
              Image.asset('assets/collectibles/coin.png',
                  width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                '${char.unlockCost}',
                key: CharacterSelectionScreen.priceKey,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          )
        : null;
    final button = !locked
        ? GameButton(
            key: CharacterSelectionScreen.chooseKey,
            label: 'PILIIN',
            fontSize: 13,
            width: 230,
            icon: Icons.arrow_forward_rounded,
            onPressed: onChoose,
          )
        : GameButton(
            key: CharacterSelectionScreen.unlockKey,
            label: 'I-UNLOCK',
            fontSize: 13,
            width: 230,
            leading: Image.asset('assets/collectibles/coin.png',
                width: 16, height: 16),
            onPressed: () => showUnlockCharacterDialog(context, char),
          );
    return AnimatedBuilder(
      animation: motion.all,
      builder: (context, _) {
        final ce = motion.celebrate.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: align,
              children: [
                _enterOut(
                  AnimatedSwitcher(
                    duration: moving
                        ? const Duration(milliseconds: 240)
                        : Duration.zero,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, -0.25), end: Offset.zero)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment:
                          centered ? Alignment.center : Alignment.centerLeft,
                      children: [...previous, if (current != null) current],
                    ),
                    child: name,
                  ),
                  from: 0.5,
                  to: 0.66,
                  dy: -14,
                ),
                const SizedBox(height: 6),
                // The price of a hero not bought yet; the same height when there is none,
                // so the button does not jump from hero to hero. Just after a purchase
                // the price floats up and away here.
                _enterOut(
                  SizedBox(
                    height: 22,
                    child: priceRow ?? _spentChip(ce),
                  ),
                  from: 0.54,
                  to: 0.69,
                ),
                const SizedBox(height: 8),
                _enterOut(
                  Transform.scale(
                    scale: ce > 0.233 && ce < 0.4
                        ? _lerp(0.85, 1.0,
                            Curves.easeOutBack.transform(_seg(ce, 0.233, 0.4)))
                        : 1,
                    child: button,
                  ),
                  from: 0.57,
                  to: 0.73,
                  dx: -16,
                ),
                const SizedBox(height: 16),
                // Eight heroes: the tiles get narrower when the row would not fit
                // (a 320 wide phone), down to 30 wide.
                LayoutBuilder(builder: (context, box) {
                  final n = allCharacters.length;
                  // 6 apart when all fit at 48 wide, else closer, then thinner.
                  final gap = !box.maxWidth.isFinite ||
                          box.maxWidth >= 48 * n + 6 * (n - 1)
                      ? 6.0
                      : 3.0;
                  final tileW = box.maxWidth.isFinite
                      ? ((box.maxWidth - gap * (n - 1)) / n).clamp(30.0, 48.0)
                      : 48.0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        _tile(i, tileW),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 10),
                _enterOut(
                  _ShopRow(coins: coins, onShop: onShop),
                  from: 0.7,
                  to: 0.85,
                  dy: 12,
                ),
              ],
            ),
            if (ce > 0.2 && ce < 0.85)
              Positioned(
                  top: -24,
                  left: 0,
                  right: 0,
                  child: Align(
                      alignment:
                          centered ? Alignment.center : Alignment.centerLeft,
                      child: _gotIt(ce))),
          ],
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// "−100" rising from where the price was, in the first moments after a purchase.
  Widget? _spentChip(double ce) {
    if (ce <= 0 || ce >= 0.4) return null;
    final p = ce / 0.4;
    final opacity = p < 0.2 ? p / 0.2 : (p < 0.7 ? 1.0 : 1 - (p - 0.7) / 0.3);
    return Align(
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, -14 * p),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/collectibles/coin.png',
                  width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                '−${char.unlockCost}',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF8F86)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// NAKUHA NA!, popping in over the name and then drifting off.
  Widget _gotIt(double ce) {
    final p = _seg(ce, 0.21, 0.83);
    final scale = p < 0.25
        ? _lerp(0.2, 1.2, p / 0.25)
        : (p < 0.4 ? _lerp(1.2, 1, (p - 0.25) / 0.15) : 1.0);
    final opacity = p < 0.1 ? p / 0.1 : (p > 0.8 ? 1 - (p - 0.8) / 0.2 : 1.0);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, p > 0.8 ? -8 * (p - 0.8) / 0.2 : 0),
        child: Transform.scale(
          scale: scale,
          child: Text(
            'NAKUHA NA!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: AppColors.accent,
              shadows: const [
                Shadow(color: AppColors.primaryDark, offset: Offset(0, 2)),
                Shadow(color: Color(0x59000000), offset: Offset(0, 4))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(int i, double tileW) {
    final c = allCharacters[i];
    final tile = _RosterTile(
      char: c,
      selected: i == selected,
      locked: isLocked(c.id),
      color: characterColor(c.id),
      width: tileW,
      onTap: () => onPick(i),
    );
    final m = motion;
    final k = _seg(m.enter.value, (m.full ? 0.6 : 0.4) + 0.035 * i,
        (m.full ? 0.76 : 0.55) + 0.035 * i);
    final out = _seg(m.choose.value, 0.5 + 0.017 * i, 0.62 + 0.017 * i);
    final pop =
        k < 0.7 ? _lerp(0, 1.15, k / 0.7) : _lerp(1.15, 1, (k - 0.7) / 0.3);
    return Opacity(
      opacity: (k * (1 - out)).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 60 * out),
        child: Transform.scale(scale: pop, child: tile),
      ),
    );
  }
}

/// One small hero in the row: lifted and outlined in gold when it is the one on
/// show, dark with a lock when it has not been bought. It pops when it is picked.
class _RosterTile extends StatelessWidget {
  final CharacterData char;
  final bool selected;
  final bool locked;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _RosterTile({
    required this.char,
    required this.selected,
    required this.locked,
    required this.color,
    this.width = 48,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget sprite = Image.asset(
      'assets/characters/${char.id}_walk_1.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
    if (locked) {
      sprite = ColorFiltered(
        colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.72), BlendMode.srcATop),
        child: sprite,
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '${char.name}, hindi pa na-unlock' : char.name,
      child: GestureDetector(
        key: CharacterSelectionScreen.rosterKey(char.id),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          // A new key each time the tile is picked or put down, so the pop plays
          // when it is picked and does nothing when it is put down.
          key: ValueKey(selected),
          tween: Tween<double>(
              begin: selected && motionAllowed(context) ? 1.16 : 1.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: width * 54 / 48,
            transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.18),
                width: 2,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                          color: AppColors.primaryDark, offset: Offset(0, 3))
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
                      child: sprite),
                ),
                if (locked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Image.asset('assets/ui/lock_icon.png',
                        width: 12,
                        height: 12,
                        filterQuality: FilterQuality.none),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks before spending coins on a locked character. Shows the price and the
/// student's coins, and only offers BILHIN when they can pay.
Future<void> showUnlockCharacterDialog(
    BuildContext context, CharacterData char) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UnlockCharacterDialog(char: char),
  );
}

class _UnlockCharacterDialog extends ConsumerWidget {
  final CharacterData char;
  const _UnlockCharacterDialog({required this.char});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(gameProvider).coins;
    final canAfford = coins >= char.unlockCost;
    final style = GoogleFonts.poppins(
        fontSize: 13, height: 1.5, color: AppColors.textSecondary);

    Widget coinLine(String label, int n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/collectibles/coin.png',
                      width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text('$n',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GamePanel(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'I-unlock si ${char.name}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text('Magagamit mo na siya sa lahat ng level.', style: style),
                const SizedBox(height: 10),
                coinLine('Presyo', char.unlockCost),
                coinLine('Coins mo', coins),
                if (!canAfford)
                  Text(
                    'Kulang ang coins. Kumuha pa ng coins sa mga level.',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: 'KANSELAHIN',
                        color: AppColors.surfaceAlt,
                        fontSize: 8,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GameButton(
                        key: const ValueKey('confirm_unlock'),
                        label: 'BILHIN',
                        fontSize: 8,
                        minHeight: 44,
                        onPressed: canAfford
                            ? () {
                                ref
                                    .read(gameProvider.notifier)
                                    .unlockCharacter(char.id);
                                Navigator.of(context).pop();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
