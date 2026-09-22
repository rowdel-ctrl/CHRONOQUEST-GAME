// Destination in your repo: lib/screens/tutorial/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/game_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/game_ui.dart';

/// "How to play" tutorial — shown once automatically the first time a
/// student reaches character selection, and replayable any time from the
/// book icon on that screen. Both entry points land on this same screen so
/// there is only one place to keep the explanations in sync.
///
/// Built entirely from sprites and icons that already exist elsewhere in the
/// game (character walk frames, enemy/obstacle art, the quiz check/X icons
/// from `answer_feedback.dart`) — no new art was made for it.
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

  List<_TutorialStep> _steps(String charId) => [
        _TutorialStep(
          title: 'ANG IYONG BAYANI',
          body: 'Tumatakbo at tumatalon ang iyong bayani sa buong panahon '
              'ng kasaysayan. I-tap ang screen para tumalon!',
          illustration: _SpriteIllustration(
            paths: ['assets/characters/${charId}_walk_1.png'],
          ),
        ),
        const _TutorialStep(
          title: 'IWASAN ANG BALAKID',
          body: 'Tumalon para maiwasan ang mga kaaway at balakid sa daan. '
              'Ang pagbangga sa kanila ay nawawalan ka ng buhay.',
          illustration: _SpriteIllustration(
            paths: [
              'assets/enemies/spanish_soldier_1.png',
              'assets/obstacles/spanish_wall.png',
            ],
          ),
        ),
        const _TutorialStep(
          title: 'KOLEKTAHIN ANG BARYA',
          body: 'Mangolekta ng barya at artifact habang tumatakbo para '
              'dumagdag ang iyong puntos.',
          illustration: _SpriteIllustration(
            paths: [
              'assets/collectibles/coin.png',
              'assets/collectibles/artifact_1.png',
            ],
          ),
        ),
        const _TutorialStep(
          title: 'SAGUTIN NANG TAMA',
          body: 'Paminsan-minsan may lalabas na tanong tungkol sa '
              'kasaysayan. Tamang sagot ay tumatalo sa kaaway — maling '
              'sagot ay nawawalan ka ng buhay.',
          illustration: _AnswerIconsIllustration(),
        ),
        _TutorialStep(
          title: 'ALAGAAN ANG BUHAY',
          body: 'May 10 buhay ka bawat antas. Kapag naubos ang lahat, '
              'magsisimula ka ulit sa antas na iyon.',
          illustration: _SpriteIllustration(
            paths: [
              ...List.filled(3, 'assets/ui/heart_full.png'),
              ...List.filled(2, 'assets/ui/heart_empty.png'),
            ],
            size: 36,
          ),
        ),
        const _TutorialStep(
          title: 'GAMITIN ANG POWER-UP',
          body: 'Makakakuha ka ng power-up sa ilang antas — gamitin ang mga '
              'ito kapag mahirap na ang tanong.',
          illustration: _SpriteIllustration(
            paths: [
              'assets/powerups/fifty_fifty.png',
              'assets/powerups/shield.png',
              'assets/powerups/time_freeze.png',
            ],
          ),
        ),
      ];

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
    final steps = _steps(charId);
    final isLast = _index == steps.length - 1;

    return Scaffold(
      body: GameBackdrop(
        imagePath: 'assets/backgrounds/bookshelf_bg.png',
        scrimOpacity: 0.65,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAANO LARUIN',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AppColors.accent.withValues(alpha: 0.85),
                      ),
                    ),
                    TextButton(
                      key: TutorialScreen.skipButtonKey,
                      onPressed: _finish,
                      child: Text(
                        'LAKTAWAN',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        steps.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.accent
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GameButton(
                      key: isLast
                          ? TutorialScreen.doneButtonKey
                          : TutorialScreen.nextButtonKey,
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

class _TutorialStep {
  final String title;
  final String body;
  final Widget illustration;

  const _TutorialStep({
    required this.title,
    required this.body,
    required this.illustration,
  });
}

class _TutorialPage extends StatelessWidget {
  final _TutorialStep step;
  const _TutorialPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GamePanel(
        color: Colors.black.withValues(alpha: 0.55),
        borderColor: AppColors.primaryDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 96, child: step.illustration),
            const SizedBox(height: 20),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders one or more existing game sprites side by side, falling back to
/// a placeholder icon if an asset is missing so a typo never blanks a page.
class _SpriteIllustration extends StatelessWidget {
  final List<String> paths;
  final double size;
  const _SpriteIllustration({required this.paths, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: paths
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Image.asset(
                p,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.image_not_supported_outlined,
                  size: size * 0.6,
                  color: Colors.white24,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Shows the same TAMA!/MALI! check and X used on real answer buttons
/// (`answer_feedback.dart`), so the tutorial page matches what the quiz
/// actually looks like instead of describing it in words alone.
class _AnswerIconsIllustration extends StatelessWidget {
  const _AnswerIconsIllustration();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 56, color: AppColors.success),
        SizedBox(width: 24),
        Icon(Icons.cancel, size: 56, color: AppColors.danger),
      ],
    );
  }
}
