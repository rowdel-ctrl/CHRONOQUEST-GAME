import 'package:flutter/material.dart';
import '../../core/combat_constants.dart';
import '../../core/constants.dart';

/// One page of the "how to play" tutorial.
class TutorialStep {
  final String title;
  final String body;
  final Widget illustration;

  const TutorialStep({
    required this.title,
    required this.body,
    required this.illustration,
  });
}

/// The tutorial's pages, in order. Built from sprites and icons that already
/// exist elsewhere in the game — no art was made for it. [charId] is the
/// student's selected character, shown on the first page.
List<TutorialStep> tutorialSteps(String charId) => [
      TutorialStep(
        title: 'ANG IYONG BAYANI',
        body: 'Gamitin ang joystick para gumalaw, ang JUMP para tumalon, at '
            'ang ATK para umatake sa mga kaaway.',
        illustration: _SpriteIllustration(
          paths: ['assets/characters/${charId}_walk_1.png'],
        ),
      ),
      const TutorialStep(
        title: 'IWASAN ANG BALAKID',
        body: 'Tumalon sa mga butas at iwasan ang mga kaaway sa daan. Ang '
            'pagbangga sa kanila o pagkahulog ay nawawalan ka ng buhay.',
        illustration: _SpriteIllustration(
          paths: [
            'assets/enemies/spanish_soldier_1.png',
            'assets/obstacles/spanish_wall.png',
          ],
        ),
      ),
      const TutorialStep(
        title: 'KOLEKTAHIN ANG BARYA',
        body: 'Mangolekta ng barya habang tumatakbo para dumagdag ang iyong '
            'puntos.',
        illustration: _SpriteIllustration(
          paths: ['assets/collectibles/coin.png'],
        ),
      ),
      const TutorialStep(
        title: 'ARTIFACT AT TARANGKAHAN',
        body: 'Lapitan ang bawat artifact para sumagot ng tanong. Bubukas '
            'ang tarangkahan sa dulo kapag nasagot mo na ang lahat ng '
            'artifact. Sa itaas, makikita mo kung ilan na ang nasagot mo.',
        illustration: _SpriteIllustration(
          paths: [
            'assets/collectibles/artifact_1.png',
            'assets/ui/lock_icon.png',
          ],
        ),
      ),
      const TutorialStep(
        title: 'SAGUTIN NANG TAMA',
        body: 'Tamang sagot: may Kaalaman ka. Maling sagot: walang parusa, '
            'pero bibilangin pa rin ito. Basahin ang paliwanag para matuto.',
        illustration: _AnswerIconsIllustration(),
      ),
      const TutorialStep(
        title: 'KAALAMAN ANG IYONG LAKAS',
        body: 'Ang asul na bar ay ang iyong Kaalaman. Nababawasan ito kapag '
            'tumama ang atake mo sa kaaway. Kapag naubos, may bumabalik na '
            'isa pagkaraan ng ilang segundo.',
        illustration: _SegmentBarIllustration(
          segments: CombatConstants.kaalamanDisplayMax,
          filled: 4,
          color: AppColors.info,
        ),
      ),
      const TutorialStep(
        title: 'ALAGAAN ANG PUSO',
        body: 'Ang pulang bar ay ang iyong puso. May ${GameConstants.maxHearts} '
            'kang dala sa buong laro, hindi lang sa isang antas. Kapag '
            'naubos, maghintay ng isang minuto bago ka makapagsimula ulit.',
        illustration: _SegmentBarIllustration(
          segments: GameConstants.maxHearts,
          filled: 4,
          color: AppColors.danger,
          height: 30,
        ),
      ),
      const TutorialStep(
        title: 'GAMITIN ANG POWER-UP',
        body: 'Makakakuha ka ng power-up sa ilang antas. Gamitin ang mga ito '
            'kapag mahirap na ang tanong.',
        illustration: _SpriteIllustration(
          paths: [
            'assets/powerups/fifty_fifty.png',
            'assets/powerups/shield.png',
            'assets/powerups/time_freeze.png',
          ],
        ),
      ),
    ];

/// Renders one or more existing game sprites side by side, falling back to
/// a placeholder icon if an asset is missing so a typo never blanks a page.
class _SpriteIllustration extends StatelessWidget {
  final List<String> paths;
  const _SpriteIllustration({required this.paths});

  static const double size = 80;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: paths
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Image.asset(
                p,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Icon(
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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 56, color: AppColors.success),
        SizedBox(width: 24),
        Icon(Icons.cancel, size: 56, color: AppColors.danger),
      ],
    );
  }
}

/// A small copy of one of the HUD's segmented bars, partly filled, so the
/// page shows the thing it is describing.
class _SegmentBarIllustration extends StatelessWidget {
  final int segments;
  final int filled;
  final Color color;
  final double height;

  const _SegmentBarIllustration({
    required this.segments,
    required this.filled,
    required this.color,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryDark, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Row(
          children: List.generate(
            segments,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 2),
                color: i < filled ? color : Colors.black26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
