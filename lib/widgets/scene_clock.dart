import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'living_backdrop.dart' show motionAllowed;

/// Gives its builder the milliseconds since it appeared. With the phone set to
/// remove animations it stays on [peek], a moment that shows the page's point.
class SceneClock extends StatefulWidget {
  final int peek;
  final Widget Function(BuildContext context, int ms) builder;

  const SceneClock({super.key, this.peek = 0, required this.builder});

  @override
  State<SceneClock> createState() => _SceneClockState();
}

class _SceneClockState extends State<SceneClock>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _ms.value = d.inMilliseconds);
  late final ValueNotifier<int> _ms = ValueNotifier<int>(widget.peek);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionAllowed(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
      _ms.value = widget.peek;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _ms,
      builder: (context, ms, _) => widget.builder(context, ms),
    );
  }
}
