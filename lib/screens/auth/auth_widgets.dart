import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../widgets/game_ui.dart';
import '../../widgets/pixel_icon.dart';

/// Pieces the sign-in and the change-password screens share, so both read as one
/// game screen: the wordmark, a big answer box, the guide with a speech bubble,
/// a row of step marks and an error banner.

const _fieldFill = Color(0xFFFBF0D6);
const _fieldFillOk = Color(0xFFEAF6DC);
const _fieldFillBad = Color(0xFFFDE9E3);

/// Text on the dark backdrop: hints under a box, the line next to the guide.
const authSoftText = Color(0xFFCDBA94);
const authOkText = Color(0xFF8BE08A);
const authBadText = Color(0xFFFF9C92);

/// CHRONOQUEST with the small book, as in the corner of the old login screen.
class AuthWordmark extends StatelessWidget {
  final double fontSize;
  const AuthWordmark({super.key, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelIcon(PixelGlyph.book, size: fontSize + 2, color: AppColors.accent),
          SizedBox(width: fontSize * 0.45),
          Text(
            'CHRONOQUEST',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: fontSize * 0.04,
              color: AppColors.accent,
              shadows: const [Shadow(color: AppColors.primaryDark, offset: Offset(0, 2))],
            ),
          ),
        ],
      ),
    );
  }
}

enum AuthFieldState { normal, ok, bad }

/// The big answer box: parchment, thick dark border, hard shadow. Gold glow while
/// typing, green when right, red when wrong. A password box has an eye that shows
/// what was typed.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final AuthFieldState state;
  final bool password;
  final bool autofocus;
  final TextCapitalization capitalization;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  /// Shown at the right end of a box that is not a password box: the green tick
  /// or the scan button.
  final Widget? trailing;
  final double height;
  final double fontSize;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.state = AuthFieldState.normal,
    this.password = false,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
    this.action = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.height = 56,
    this.fontSize = 20,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final _focus = FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = switch (widget.state) {
      AuthFieldState.ok => _fieldFillOk,
      AuthFieldState.bad => _fieldFillBad,
      AuthFieldState.normal => _fieldFill,
    };
    final border = switch (widget.state) {
      AuthFieldState.ok => AppColors.success,
      AuthFieldState.bad => AppColors.danger,
      AuthFieldState.normal => AppColors.primaryDark,
    };
    final trailing = widget.password
        ? IconButton(
            tooltip: _hidden ? 'Ipakita ang password' : 'Itago ang password',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary, size: 24),
            onPressed: () => setState(() => _hidden = !_hidden),
          )
        : widget.trailing;
    return Container(
      height: widget.height,
      padding: EdgeInsets.only(left: 14, right: trailing == null ? 14 : 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 3),
        boxShadow: [
          if (_focus.hasFocus && widget.state == AuthFieldState.normal)
            const BoxShadow(color: AppColors.accent, spreadRadius: 3),
          const BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              obscureText: widget.password && _hidden,
              textCapitalization: widget.capitalization,
              textInputAction: widget.action,
              autocorrect: false,
              enableSuggestions: !widget.password,
              cursorColor: AppColors.primaryDark,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
              style: GoogleFonts.poppins(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: widget.fontSize - 2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

/// A round green tick for a box that is right.
class AuthTick extends StatelessWidget {
  const AuthTick({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 28),
      );
}

/// A line under a box: a hint, or a tick that turns green as a rule is met.
class AuthHelp extends StatelessWidget {
  final String text;
  final bool? good;
  const AuthHelp(this.text, {super.key, this.good});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.35,
        fontWeight: good == null ? FontWeight.w400 : FontWeight.w600,
        color: good == null
            ? authSoftText
            : good!
                ? authOkText
                : authBadText,
      ),
    );
  }
}

/// A red banner that says what to fix.
class AuthError extends StatelessWidget {
  final String text;
  const AuthError(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A button that says the server is busy. Same size as [GameButton], so the
/// screen does not jump.
class AuthBusyButton extends StatelessWidget {
  final String label;
  const AuthBusyButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD9B04A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.primaryDark, offset: Offset(4, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

/// A row of step marks: green for done, gold for now, dark for to come.
class AuthStepBar extends StatelessWidget {
  final int count;
  final int index;
  final String caption;
  const AuthStepBar({
    super.key,
    required this.count,
    required this.index,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 28,
                height: 10,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i < index
                      ? AppColors.success
                      : i == index
                          ? AppColors.accent
                          : Colors.black.withValues(alpha: 0.4),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: authSoftText),
        ),
      ],
    );
  }
}

/// The game's guide: a character with a speech bubble above. A stand-in sprite,
/// because the student has not picked a hero before signing in.
class AuthGuide extends StatelessWidget {
  final String say;
  final double sprite;
  final double fontSize;
  const AuthGuide({super.key, required this.say, this.sprite = 104, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamePanel(
          shadowOffset: 4,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            say,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Image.asset(
          'assets/characters/luna_walk_1.png',
          width: sprite,
          height: sprite,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => SizedBox(width: sprite, height: sprite),
        ),
      ],
    );
  }
}
