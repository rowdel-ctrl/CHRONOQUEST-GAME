import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../data/login_facts.dart';
import 'living_backdrop.dart';

/// "Alam mo ba?" and one short history fact, changing every few seconds. A small
/// dark pill with a gold lead-in, for the foot of the first screen.
///
/// It starts on a different fact each time it is shown. With the phone's "remove
/// animations" on it stays on the one it started with.
class FactTicker extends StatefulWidget {
  static const Duration every = Duration(milliseconds: 4400);

  final List<LoginFact> facts;

  /// Which fact comes first. null: any, chosen at random.
  final int? start;

  const FactTicker({super.key, this.facts = loginFacts, this.start});

  @override
  State<FactTicker> createState() => _FactTickerState();
}

class _FactTickerState extends State<FactTicker> {
  late int _index = widget.start ?? math.Random().nextInt(widget.facts.length);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = motionAllowed(context)
        ? Timer.periodic(FactTicker.every, (_) {
            if (mounted) {
              setState(() => _index = (_index + 1) % widget.facts.length);
            }
          })
        : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fact = widget.facts[_index % widget.facts.length];
    return Container(
      constraints: const BoxConstraints(maxWidth: 470, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4A3A5E), width: 2),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Text.rich(
          key: ValueKey(fact.text),
          TextSpan(children: [
            const TextSpan(
              text: 'Alam mo ba? ',
              style: TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: fact.text),
          ]),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
      ),
    );
  }
}
