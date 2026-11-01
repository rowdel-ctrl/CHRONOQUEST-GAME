import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'pixel_icon.dart';
import 'update_card.dart';

/// "Play as a guest?": what a guest gets, asked once before starting. Shown by
/// [showGuestConfirm]; answers true for MAGLARO.
class GuestConfirmCard extends StatelessWidget {
  const GuestConfirmCard({super.key});

  static const Key cardKey = Key('guest_confirm');
  static const Key playKey = Key('guest_confirm_play');
  static const Key backKey = Key('guest_confirm_back');

  @override
  Widget build(BuildContext context) {
    return _GuestPanel(
      key: cardKey,
      ribbon: 'GUEST',
      title: 'Play as a guest?',
      heading: 'ANO ANG MAKUKUHA MO',
      lines: const [
        'Unang panahon lang: Sinaunang Pilipinas',
        'Hindi ito makikita ng teacher mo',
        'Sa phone na ito lang ang coins at progress',
      ],
      buttons: [
        Expanded(
          flex: 3,
          child: GoldButton(
            key: playKey,
            label: 'MAGLARO',
            icon: null,
            semanticLabel: 'Maglaro bilang guest',
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: WoodButton(
            key: backKey,
            label: 'BUMALIK',
            semanticLabel: 'Bumalik',
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}

/// Asks "Play as a guest?" over the current screen. True if the student chose to play.
Future<bool> showGuestConfirm(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xC40A0612),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: const SingleChildScrollView(child: GuestConfirmCard()),
        ),
      ),
    ),
  );
  return yes == true;
}

/// "Are you sure you want to exit Guest Mode?": asked from Settings before a guest
/// leaves. Shown by [showGuestExitConfirm]; answers true for EXIT.
class GuestExitCard extends StatelessWidget {
  const GuestExitCard({super.key});

  static const Key cardKey = Key('guest_exit');
  static const Key exitKey = Key('guest_exit_yes');
  static const Key cancelKey = Key('guest_exit_cancel');

  @override
  Widget build(BuildContext context) {
    return _GuestPanel(
      key: cardKey,
      ribbon: 'GUEST',
      title: 'Are you sure you want to exit Guest Mode?',
      buttons: [
        Expanded(
          flex: 3,
          child: GoldButton(
            key: exitKey,
            label: 'EXIT',
            icon: null,
            semanticLabel: 'Exit Guest Mode',
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: WoodButton(
            key: cancelKey,
            label: 'CANCEL',
            semanticLabel: 'Cancel',
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}

/// Asks "Are you sure you want to exit Guest Mode?". True if the guest chose EXIT.
Future<bool> showGuestExitConfirm(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xC40A0612),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: const SingleChildScrollView(child: GuestExitCard()),
        ),
      ),
    ),
  );
  return yes == true;
}

/// "Tapos mo na ang Guest preview": the guest finished the first era. MAG-SIGN IN
/// goes to the sign-in screen; LARO ULIT starts a fresh guest.
class GuestDoneCard extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onPlayAgain;
  const GuestDoneCard(
      {super.key, required this.onSignIn, required this.onPlayAgain});

  static const Key cardKey = Key('guest_done');
  static const Key signInKey = Key('guest_done_sign_in');
  static const Key againKey = Key('guest_done_again');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0xC40A0612)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: _GuestPanel(
                  key: cardKey,
                  ribbon: 'TAPOS NA!',
                  title: 'Tapos mo na ang Guest preview',
                  body:
                      'Gusto mo ng buong laro? Mag-sign in gamit ang class code ng teacher mo.',
                  buttons: [
                    Expanded(
                      flex: 3,
                      child: GoldButton(
                        key: signInKey,
                        label: 'MAG-SIGN IN',
                        icon: null,
                        semanticLabel: 'Mag-sign in',
                        onTap: onSignIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: WoodButton(
                        key: againKey,
                        label: 'LARO ULIT',
                        semanticLabel: 'Maglaro ulit bilang guest',
                        onTap: onPlayAgain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dark panel both guest cards share.
class _GuestPanel extends StatelessWidget {
  final String ribbon;
  final String title;
  final String? heading;
  final List<String> lines;
  final String? body;
  final List<Widget> buttons;
  const _GuestPanel({
    super.key,
    required this.ribbon,
    required this.title,
    this.heading,
    this.lines = const [],
    this.body,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: PanelCard(
        tone: AppColors.accent,
        ribbon: ribbon,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 10),
              PanelNotes(
                  heading: heading ?? '', lines: lines, tone: AppColors.accent),
            ],
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12, height: 1.35, color: AppColors.surface),
              ),
            ],
            const SizedBox(height: 14),
            Row(children: buttons),
          ],
        ),
      ),
    );
  }
}

/// The dashed gold "GUEST" tag for a menu's top bar, so a guest always knows.
class GuestTag extends StatelessWidget {
  const GuestTag({super.key});

  static const Key tagKey = Key('guest_tag');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Naglalaro bilang guest',
      excludeSemantics: true,
      child: Padding(
        key: tagKey,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelIcon(PixelGlyph.profile,
                  size: 13, color: AppColors.accent),
              const SizedBox(width: 5),
              Text(
                'GUEST',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
