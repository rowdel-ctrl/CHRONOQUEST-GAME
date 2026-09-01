import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

/// Shared retro pixel-art UI kit. Every screen builds panels, buttons, and
/// bars from these instead of raw Material widgets, so the whole app reads
/// as one consistent game rather than a pile of differently-styled screens.
///
/// Signature look: solid fill, thick dark pixel border, and a hard-edged
/// offset shadow (blurRadius: 0) instead of Material's soft blurred
/// elevation shadow — that's what reads as "pixel game panel" rather than
/// "phone app card".

/// A solid panel with a thick pixel border and hard offset shadow.
/// Use this instead of Container+BoxDecoration for any card, dialog, or
/// grouped content block.
class GamePanel extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GamePanel({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.primaryDark,
    this.borderWidth = 3,
    this.shadowOffset = 5,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                  color: borderColor,
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A chunky pixel-game button — flat fill, thick border, hard offset
/// shadow that visibly "presses in" on tap. Meets the 48px minimum touch
/// target by default.
class GameButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final double minHeight;
  final double? width;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.accent,
    this.textColor = AppColors.primaryDark,
    this.icon,
    this.fontSize = 13,
    this.minHeight = 52,
    this.width,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final shadowOffset = _pressed ? 0.0 : 4.0;
    final fillColor = disabled ? Colors.grey.shade400 : widget.color;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        width: widget.width,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryDark, width: 3),
          boxShadow: shadowOffset > 0
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark,
                    offset: Offset(shadowOffset, shadowOffset),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.fontSize + 6, color: widget.textColor),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: widget.fontSize + 4,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: disabled ? Colors.grey.shade700 : widget.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pixel-styled label chip — level numbers, tags, counters.
class GameBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;

  const GameBadge({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.textColor = AppColors.primaryDark,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryDark, width: 2),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: textColor,
        ),
      ),
    );
  }
}

/// Chunky segmented progress bar — quiz scores, boss health, learning
/// gain — pixel-blocky fill instead of a smooth Material gradient.
class GameProgressBar extends StatelessWidget {
  final double value; // 0.0–1.0
  final Color fillColor;
  final Color backgroundColor;
  final double height;
  final int segments;

  const GameProgressBar({
    super.key,
    required this.value,
    this.fillColor = AppColors.success,
    this.backgroundColor = AppColors.surfaceAlt,
    this.height = 18,
    this.segments = 10,
  });

  @override
  Widget build(BuildContext context) {
    final filledSegments = (value.clamp(0.0, 1.0) * segments).round();
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.primaryDark, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: List.generate(segments, (i) {
          final filled = i < filledSegments;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 2),
              color: filled ? fillColor : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }
}

/// Full-bleed backdrop used by menu screens — a base color plus an
/// optional scenic image with a scrim so text stays readable on top.
class GameBackdrop extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final Color baseColor;
  final double scrimOpacity;

  const GameBackdrop({
    super.key,
    required this.child,
    this.imagePath,
    this.baseColor = AppColors.background,
    this.scrimOpacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        image: imagePath != null
            ? DecorationImage(
                image: AssetImage(imagePath!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      foregroundDecoration: imagePath != null
          ? BoxDecoration(color: Colors.black.withValues(alpha: scrimOpacity))
          : null,
      child: child,
    );
  }
}