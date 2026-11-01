import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/game_ui.dart';
import 'auth_widgets.dart';

/// Shown once, right after a new student joins: the username the server made from
/// their name. They cannot choose it, so this is where they learn what it is, with
/// a way to copy it. The phone already remembers it for "Balik na ako".
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  static const copyKey = ValueKey('username_copy');
  static const goKey = ValueKey('username_go');
  static const valueKey = ValueKey('username_value');

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  bool _copied = false;

  Future<void> _copy(String username) async {
    await Clipboard.setData(ClipboardData(text: username));
    if (mounted) setState(() => _copied = true);
  }

  void _go() => context.go('/character-selection');

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authProvider).student?.username ?? '';
    final wide = MediaQuery.sizeOf(context).width > 700;

    final question = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ito ang username mo.',
          style: GoogleFonts.poppins(
            fontSize: wide ? 23 : 19,
            height: 1.25,
            fontWeight: FontWeight.bold,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: KeyedSubtree(
                key: UsernameScreen.valueKey,
                child: AuthReadout(label: 'USERNAME', value: username),
              ),
            ),
            const SizedBox(width: 10),
            GameButton(
              key: UsernameScreen.copyKey,
              label: _copied ? 'NAKOPYA' : 'KOPYAHIN',
              fontSize: 11,
              horizontalPadding: 10,
              color: AppColors.surface,
              onPressed: username.isEmpty ? null : () => _copy(username),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const AuthHelp('Kailangan mo ito kapag nag-login ka sa ibang phone. '
            'Sa phone na ito, naaalala na ito ng laro.'),
        const SizedBox(height: 14),
        GameButton(
          key: UsernameScreen.goKey,
          label: 'TULOY',
          fontSize: 13,
          width: double.infinity,
          onPressed: _go,
        ),
      ],
    );

    return PopScope(
      // Back would return to the sign-up questions; the student has joined.
      canPop: false,
      child: Scaffold(
        body: GameBackdrop(
          baseColor: AppColors.background,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: wide
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 262,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AuthWordmark(),
                                SizedBox(height: 10),
                                AuthGuide(
                                    say: 'Isulat mo o i-screenshot ito, ha!'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: question,
                            ),
                          ),
                        ],
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AuthWordmark(),
                            const SizedBox(height: 14),
                            question,
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
