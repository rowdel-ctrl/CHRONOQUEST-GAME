import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/confetti.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/living_backdrop.dart';

/// The first word of a name: "Juan Dela Cruz" is "Juan". A name with nothing in it
/// gives an empty string.
String firstNameOf(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'));
  return words.first;
}

/// Shown once, right after a new student joins: confetti, a hero jumping for joy
/// and their first name. Then the username screen.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const nameKey = ValueKey('welcome_name');
  static const goKey = ValueKey('welcome_go');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = firstNameOf(ref.watch(authProvider).student?.name ?? '');
    final wide = MediaQuery.sizeOf(context).width > 560;

    final hero = Bounce(
      child: Image.asset(
        'assets/characters/luna_jump.png',
        height: wide ? 150 : 120,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox(height: 120, width: 80),
      ),
    );

    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          name.isEmpty ? 'Maligayang pagdating!' : 'Maligayang pagdating,',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: name.isEmpty ? 30 : 17,
            fontWeight: name.isEmpty ? FontWeight.bold : FontWeight.w600,
            color: name.isEmpty ? AppColors.accent : AppColors.surface,
            shadows: name.isEmpty
                ? const [
                    Shadow(color: AppColors.primaryDark, offset: Offset(0, 3))
                  ]
                : null,
          ),
        ),
        if (name.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: wide ? Alignment.centerLeft : Alignment.center,
            child: Text(
              '$name!',
              key: nameKey,
              style: GoogleFonts.poppins(
                fontSize: 46,
                height: 1.15,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                shadows: const [
                  Shadow(color: AppColors.primaryDark, offset: Offset(0, 4))
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        GameButton(
          key: goKey,
          label: 'TULOY',
          fontSize: 13,
          width: 220,
          onPressed: () => context.go('/your-username'),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: LivingBackdrop(
                    fireflies: 0,
                    center:
                        wide ? const Offset(0.28, 0.5) : const Offset(0.5, 0.3),
                  ),
                ),
                const Positioned.fill(child: Confetti()),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: wide
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              hero,
                              const SizedBox(width: 36),
                              Flexible(child: words)
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [hero, const SizedBox(height: 12), words],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Jumps its child up and down, forever: joy. Still when animations are off.
class Bounce extends StatefulWidget {
  final Widget child;
  final bool? animate;
  const Bounce({super.key, required this.child, this.animate});

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.animate ?? motionAllowed(context);
    if (on && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!on && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Up and back down along a parabola, then a short rest on the ground.
        final t = (_controller.value / 0.8).clamp(0.0, 1.0);
        final lift = 4 * t * (1 - t);
        return Transform.translate(offset: Offset(0, -30 * lift), child: child);
      },
    );
  }
}
