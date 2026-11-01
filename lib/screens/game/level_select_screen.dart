import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/unlock_all_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/hearts_pill.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'level_node.dart';
import 'level_path.dart';

String _formatCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// The levels of an era as a winding path: gold nodes with their stars for the
/// levels done, the student's hero standing on the next one (with light behind it
/// and a ring spreading out of it), dark locked ones after it, and the boss at the
/// end. Across a wide screen, down a narrow one (which scrolls to the next level).
class LevelSelectScreen extends ConsumerStatefulWidget {
  final String eraId;
  const LevelSelectScreen({super.key, required this.eraId});

  static Key nodeKey(int level) => ValueKey('level_node_$level');
  static const Key pathKey = Key('level_path');

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  Map<int, int> completedLevels = {};
  Timer? _heartsTimer;
  final ScrollController _scroll = ScrollController();
  bool _scrolledToCurrent = false;

  @override
  void initState() {
    super.initState();
    completedLevels = StorageService.getCompletedLevels(widget.eraId);
    // Ticks the persistent-hearts countdown shown below, and applies any
    // regen due since the provider was created — this screen is the main
    // place players wait out that countdown.
    _heartsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => ref.read(gameProvider.notifier).refreshHearts(),
    );
  }

  @override
  void dispose() {
    _heartsTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  bool _isLevelUnlocked(int level, int levelCount) {
    // Testing switch (Profile): everything open.
    if (ref.read(unlockAllProvider)) return true;
    if (level == 1) return true;
    if (level == levelCount) return completedLevels.length >= levelCount - 1;
    return completedLevels.containsKey(level - 1);
  }

  /// The first-play tutorial gates here — the point a student actually
  /// starts a level — rather than on character selection (effectively "on
  /// app open"), which is what the playtest flagged as the wrong trigger.
  void _startLevel(int level) {
    if (!StorageService.hasSeenTutorial()) {
      context.push('/tutorial').then((_) {
        if (mounted) context.go('/game/${widget.eraId}/$level');
      });
    } else {
      context.go('/game/${widget.eraId}/$level');
    }
  }

  void _showNoHeartsDialog(BuildContext context, Duration? timeUntilNext) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: AppColors.primaryDark, width: 3),
        ),
        title: Text(
          'Wala nang Puso',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          timeUntilNext != null
              ? 'Maghintay ng ${_formatCountdown(timeUntilNext)} para sa '
                  'susunod na puso, o bumalik mamaya.'
              : 'Maghintay ng kaunti para sa susunod na puso, o bumalik '
                  'mamaya.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Sige',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the map redraws if the testing switch changes.
    ref.watch(unlockAllProvider);
    final era = getEraById(widget.eraId);
    final levelCount = era.levels.length;
    final game =
        ref.watch(gameProvider); // the map redraws as hearts come and go
    // Also true while the testing switch makes hearts free.
    final hasHearts = ref.read(gameProvider.notifier).canStartLevel;
    final timeUntilNext = ref.read(gameProvider.notifier).heartCountdown;
    final eraColor = _getEraColor(widget.eraId);

    bool unlocked(int level) => _isLevelUnlocked(level, levelCount);
    // The one to play next: the first open level that is not finished.
    final current = [for (var l = 1; l <= levelCount; l++) l].firstWhere(
        (l) => unlocked(l) && !completedLevels.containsKey(l),
        orElse: () => 0);

    LevelNodeState stateOf(int level) {
      if (completedLevels.containsKey(level)) return LevelNodeState.done;
      if (level == current) return LevelNodeState.current;
      return unlocked(level) ? LevelNodeState.open : LevelNodeState.locked;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(const Color(0xFF140E1F), eraColor, 0.65)!,
              const Color(0xFF140E1F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    MenuChip(
                      icon: PixelGlyph.back,
                      tooltip: 'Bumalik',
                      onTap: () => context.go('/era-selection'),
                    ),
                    Expanded(
                      // Shrinks to fit rather than cutting the name: the longest
                      // is 47 characters.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          era.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    // The shared hearts pool, the same pill character select
                    // shows in the same corner. Level select is where hearts
                    // gate starting a level, so it is where they matter most.
                    const HeartsPill(),
                  ],
                ),
              ),

              // The winding path of levels
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final vertical = box.maxWidth < 560;
                    final height = vertical
                        ? math.max(box.maxHeight, levelPathHeight(levelCount))
                        : box.maxHeight;
                    final area = Size(box.maxWidth, height);
                    final points =
                        levelPathPoints(levelCount, area, vertical: vertical);

                    final path = SizedBox(
                      key: LevelSelectScreen.pathKey,
                      width: area.width,
                      height: area.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The light comes from the level to play next.
                          if (current > 0)
                            Positioned.fill(
                              child: LivingBackdrop(
                                color: Color.lerp(eraColor, Colors.white, 0.5)!,
                                fireflies: 0,
                                center: Offset(
                                  points[current - 1].dx / area.width,
                                  points[current - 1].dy / area.height,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RoadPainter(
                                points,
                                done: {
                                  for (var l = 1; l <= levelCount; l++)
                                    l: completedLevels.containsKey(l)
                                },
                              ),
                            ),
                          ),
                          for (var i = 0; i < levelCount; i++)
                            Positioned(
                              left: points[i].dx - LevelNode.target / 2,
                              top: points[i].dy - LevelNode.target / 2,
                              child: LevelNode(
                                key: LevelSelectScreen.nodeKey(i + 1),
                                level: i + 1,
                                state: stateOf(i + 1),
                                stars: completedLevels[i + 1] ?? 0,
                                isBoss: i + 1 == levelCount,
                                heroId: game.selectedCharacterId,
                                onTap: unlocked(i + 1)
                                    ? () {
                                        if (hasHearts) {
                                          _startLevel(i + 1);
                                        } else {
                                          _showNoHeartsDialog(
                                              context, timeUntilNext);
                                        }
                                      }
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    );

                    if (!vertical) return path;
                    // A narrow screen runs the path downwards and starts at the
                    // level to play next.
                    if (!_scrolledToCurrent && current > 0) {
                      _scrolledToCurrent = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_scroll.hasClients) return;
                        final target =
                            points[current - 1].dy - box.maxHeight / 2;
                        _scroll.jumpTo(target.clamp(
                            0.0, _scroll.position.maxScrollExtent));
                      });
                    }
                    return SingleChildScrollView(
                        controller: _scroll, child: path);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEraColor(String id) {
    switch (id) {
      case 'pre-colonial':
        return const Color(0xFF1B5E20);
      case 'spanish':
        return const Color(0xFF4E342E);
      case 'nationalism':
        return const Color(0xFF4A3F8F);
      case 'american':
        return const Color(0xFF0D47A1);
      case 'ww2':
        return const Color(0xFF37474F);
      case 'modern':
        return const Color(0xFF4A148C);
      default:
        return const Color(0xFF4E342E);
    }
  }
}

/// The road between the levels: solid gold where the student has been, a dotted
/// dim line where they have not.
class _RoadPainter extends CustomPainter {
  final List<Offset> points;
  final Map<int, bool> done;
  _RoadPainter(this.points, {required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    final solid = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final dim = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      // Gold from every finished level onwards: that road has been walked.
      if (done[i + 1] == true) {
        canvas.drawLine(a, b, solid);
        continue;
      }
      // Dotted: 3 long, 7 apart.
      final length = (b - a).distance;
      final dir = (b - a) / length;
      for (var t = 0.0; t < length; t += 10) {
        canvas.drawLine(a + dir * t, a + dir * math.min(t + 3, length), dim);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.points != points || old.done != done;
}
