import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/gate_icon.dart';
import '../chrono_game.dart';

/// World units in one metre on the gate indicator. The player is 120 units
/// tall, so 100 units to the metre makes them a child of about 1.2 m, and the
/// 210 units/s walking pace about 2 m/s. A 25,000-unit level is 250 m.
const double gateUnitsPerMetre = 100;

/// The distance shown for [units]: whole metres, rounded up so it never reads
/// "0 m" while there is still ground to cover.
int gateMetres(double units) => (units / gateUnitsPerMetre).ceil();

/// Tells the student the gate is ready and how far away it is.
///
/// Appears once every artifact has been answered, which is the one condition
/// for the end gate to open (GAMEPLAY-V2.md Section 6). It is two things:
///
///  * a small chip, kept on screen for the rest of the level, with a lock-open
///    icon and the distance that counts down as they walk, and
///  * a message that appears once, the moment the last artifact is answered,
///    and goes away after a few seconds.
///
/// Distance changes every frame but the HUD only rebuilds when game state
/// notifies, so this runs its own short ticker. The message waits for the
/// question window to close so it is not shown underneath it.
class GateHud extends StatefulWidget {
  final ChronoGame game;
  const GateHud({super.key, required this.game});

  @override
  State<GateHud> createState() => _GateHudState();
}

class _GateHudState extends State<GateHud> {
  static const _tick = Duration(milliseconds: 250);
  static const _messageFor = Duration(seconds: 4);

  Timer? _ticker;
  Timer? _hideMessage;
  bool _messageShown = false;
  bool _messageVisible = false;
  double? _units;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hideMessage?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final game = widget.game;
    final units = game.gateDistanceUnits();

    var show = false;
    if (units != null && !_messageShown && !game.questionShowing) {
      _messageShown = true;
      show = true;
      _hideMessage?.cancel();
      _hideMessage = Timer(_messageFor, () {
        if (mounted) setState(() => _messageVisible = false);
      });
    }
    if (units != _units || show) {
      setState(() {
        _units = units;
        if (show) _messageVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;
    if (units == null) return const SizedBox.shrink();
    final metres = gateMetres(units);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(metres: metres),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _messageVisible
              ? Padding(
                  key: const ValueKey('message'),
                  padding: const EdgeInsets.only(top: 8),
                  child: _Message(metres: metres),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final int metres;
  const _Chip({required this.metres});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bukas na ang gate, $metres metro ang layo',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GateIcon(size: 20),
            const SizedBox(width: 6),
            Text(
              '$metres m',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final int metres;
  const _Message({required this.metres});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [
          BoxShadow(
              color: AppColors.primaryDark, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GateIcon(size: 32),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Nasagot na ang lahat ng artifact! Bukas na ang gate, '
              '$metres m sa unahan.',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
