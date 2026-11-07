import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/control_scheme_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_chip.dart';
import '../../widgets/pixel_icon.dart';
import 'tutorial_content.dart';

/// "Paano laruin": six short pages, each with a little moving picture of the play
/// screen and three short lines. Shown once, the first time a student starts a level
/// (gated in LevelSelectScreen._startLevel, not on app open), and replayable any
/// time from the book icon on character selection. All entry points land on this
/// one screen.
///
/// The game is landscape-locked, so a phone gives this screen plenty of width and
/// very little height. Each page is therefore drawn on a fixed board (the picture
/// beside the words, or above them on a narrow phone) that is scaled to fit.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  static const Key doneButtonKey = Key('tutorial_done_button');
  static const Key skipButtonKey = Key('tutorial_skip_button');
  static const Key nextButtonKey = Key('tutorial_next_button');
  static const Key backButtonKey = Key('tutorial_back_button');
  static Key dotKey(int i) => ValueKey('tutorial_dot_$i');

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await StorageService.markTutorialSeen();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/character-selection');
    }
  }

  void _go(int i) => _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final charId = ref.watch(gameProvider).selectedCharacterId;
    final scheme = ref.watch(controlSchemeProvider);
    final steps = tutorialSteps;
    final step = steps[_index];
    final isLast = _index == steps.length - 1;
    final narrow = MediaQuery.sizeOf(context).width < 520;

    return Scaffold(
      body: GameBackdrop(
        baseColor: AppColors.background,
        child: Stack(
          children: [
            // The light behind the pictures changes colour with the page.
            Positioned.fill(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: step.color),
                duration: const Duration(milliseconds: 450),
                builder: (context, color, _) => LivingBackdrop(
                  color: color ?? step.color,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Row(
                      children: [
                        const SizedBox(width: 48, height: 48),
                        Expanded(
                          child: Text(
                            'PAANO LARUIN',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        // A plain X, like the close button on any pop-up, in the
                        // same wooden chip as the other screens.
                        MenuChip(
                          key: TutorialScreen.skipButtonKey,
                          icon: PixelGlyph.close,
                          tooltip: 'Isara',
                          onTap: _finish,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: steps.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => LayoutBuilder(
                        builder: (context, box) {
                          final wide = box.maxWidth >= 520;
                          return Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: steps[i].build(TutorialContext(
                                  wide: wide, charId: charId, scheme: scheme)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Row(
                      children: [
                        if (_index > 0)
                          MenuChip(
                            key: TutorialScreen.backButtonKey,
                            icon: PixelGlyph.back,
                            tooltip: 'Bumalik',
                            onTap: () => _go(_index - 1),
                          )
                        else
                          const SizedBox(width: 48, height: 48),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _PageDots(
                                count: steps.length, index: _index, onTap: _go),
                          ),
                        ),
                        GameButton(
                          key: isLast
                              ? TutorialScreen.doneButtonKey
                              : TutorialScreen.nextButtonKey,
                          width: narrow ? 148 : 200,
                          minHeight: 44,
                          fontSize: narrow ? 11 : 13,
                          horizontalPadding: narrow ? 8 : 20,
                          label: isLast ? 'SIMULAN NA!' : 'SUSUNOD',
                          leading: PixelIcon(
                            isLast ? PixelGlyph.play : PixelGlyph.chevron,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          onPressed: isLast ? _finish : () => _go(_index + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final ValueChanged<int> onTap;
  const _PageDots(
      {required this.count, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            key: TutorialScreen.dotKey(i),
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == index ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      i == index ? AppColors.accent : const Color(0x66F5E3BE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
