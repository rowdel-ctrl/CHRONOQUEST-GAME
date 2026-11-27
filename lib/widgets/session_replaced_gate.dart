import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../services/session_replaced.dart';
import 'game_ui.dart';

/// Puts the "your account is open on another device" notice over everything while
/// [SessionReplaced.notifier] is true, or "your login ended" while [SessionReplaced.endedNotifier]
/// is. Nothing under it can be touched; the one button ends this
/// phone's session ([onReturnToLogin]) and goes back to the login screen.
class SessionReplacedGate extends StatelessWidget {
  static const cardKey = ValueKey('session-replaced-card');
  static const buttonKey = ValueKey('session-replaced-button');

  final Widget child;

  /// Signs this phone out and opens the login screen.
  final Future<void> Function() onReturnToLogin;

  const SessionReplacedGate({
    super.key,
    required this.child,
    required this.onReturnToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SessionReplaced.notifier, SessionReplaced.endedNotifier]),
      builder: (context, _) {
        final replaced = SessionReplaced.notifier.value;
        final ended = SessionReplaced.endedNotifier.value;
        final showing = replaced || ended;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (showing) ...[
              const ModalBarrier(color: Color(0xCC000000), dismissible: false),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      key: cardKey,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.primaryDark, width: 3),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primaryDark,
                              offset: Offset(5, 5)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            replaced
                                ? 'Ginamit ang account mo sa ibang device'
                                : 'Tapos na ang login mo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            replaced
                                ? 'Isang device lang ang puwede sa isang account. Para hindi '
                                    'magkagulo ang progress, coins at power-ups mo, na-logout ka na rito.'
                                : 'Hindi na makilala ng server ang login na ito (matagal na ito, o nabura na '
                                    'ang account). Mag-login ulit para ma-save ang progress mo.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GameButton(
                            key: buttonKey,
                            label: 'BUMALIK SA LOGIN',
                            fontSize: 12,
                            width: double.infinity,
                            onPressed: () async {
                              SessionReplaced.notifier.value = false;
                              SessionReplaced.endedNotifier.value = false;
                              await onReturnToLogin();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
