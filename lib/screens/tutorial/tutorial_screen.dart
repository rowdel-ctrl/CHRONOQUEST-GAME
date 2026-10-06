// Destination in your repo: lib/screens/tutorial/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';
import 'tutorial_content.dart';

/// "How to play" tutorial — shown once automatically the first time a
/// student starts a level (gated in LevelSelectScreen._startLevel, not on
/// app open), and replayable any time from the book icon on character
/// selection. All entry points land on this same screen so there is only
/// one place to keep the explanations in sync.
///
/// The game is landscape-locked, so a phone gives this screen plenty of width
/// and very little height (about 160px for the card on a 360px-tall screen).
/// Each page is therefore laid out in two columns — illustration beside the
/// text — and the page scrolls rather than overflowing if a very short screen
/// still cannot fit it.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  static const Key doneButtonKey = Key('tutorial_done_button');
  static const Key skipButtonKey = Key('tutorial_skip_button');
  static const Key nextButtonKey = Key('tutorial_next_button');

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

  @override
  Widget build(BuildContext context) {
    final charId = ref.watch(gameProvider).selectedCharacterId;
    final steps = tutorialSteps(charId);
    final isLast = _index == steps.length - 1;

    return Scaffold(
      body: GameBackdrop(
        imagePath: 'assets/backgrounds/bookshelf_bg.png',
        scrimOpacity: 0.55,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAANO LARUIN',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    // A plain X, like the close button on any pop-up: the small
                    // "LAKTAWAN" text was easy to miss, and children expect an X.
                    IconButton(
                      key: TutorialScreen.skipButtonKey,
                      tooltip: 'Isara',
                      onPressed: _finish,
                      iconSize: 26,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white70, width: 2),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _TutorialPage(step: steps[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _PageDots(count: steps.length, index: _index),
                    ),
                    GameButton(
                      key: isLast
                          ? TutorialScreen.doneButtonKey
                          : TutorialScreen.nextButtonKey,
                      width: 200,
                      label: isLast ? 'SIMULAN NA!' : 'SUSUNOD',
                      icon: isLast
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: isLast
                          ? _finish
                          : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 4,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == index ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == index ? AppColors.accent : Colors.white54,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final TutorialStep step;
  const _TutorialPage({required this.step});

  /// Below this width there is no room for two columns, so the illustration
  /// goes above the text instead.
  static const double _twoColumnMinWidth = 520;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      step.title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
    final body = Text(
      step.body,
      style: GoogleFonts.poppins(
        fontSize: 15,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
    );
    final illustration = SizedBox(
      height: 96,
      child: FittedBox(fit: BoxFit.scaleDown, child: step.illustration),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GamePanel(
        color: AppColors.surface,
        borderColor: AppColors.primaryDark,
        child: LayoutBuilder(
          builder: (context, box) {
            final twoColumns = box.maxWidth >= _twoColumnMinWidth;
            final content = twoColumns
                ? Row(
                    children: [
                      Expanded(flex: 2, child: Center(child: illustration)),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [title, const SizedBox(height: 8), body],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      illustration,
                      const SizedBox(height: 12),
                      DefaultTextStyle.merge(
                        textAlign: TextAlign.center,
                        child: title,
                      ),
                      const SizedBox(height: 8),
                      DefaultTextStyle.merge(
                        textAlign: TextAlign.center,
                        child: body,
                      ),
                    ],
                  );

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Center(child: content),
              ),
            );
          },
        ),
      ),
    );
  }
}
