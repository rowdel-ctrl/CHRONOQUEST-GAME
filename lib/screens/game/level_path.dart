import 'dart:math' as math;
import 'dart:ui';

/// Across the screen, or down it: which way the winding path of levels runs.
const double levelPathStep = 84;

/// How far the path may sway from its middle line.
const double _wave = 1.05;

/// Where the [count] levels of an era sit on their winding path.
///
/// Wide screens: the path runs left to right across [area], swaying up and down a
/// little. Narrow ones ([vertical]): it runs top to bottom, [levelPathStep] apart,
/// swaying left and right; [levelPathHeight] says how tall that is, and the screen
/// scrolls when it is taller than the room.
List<Offset> levelPathPoints(int count, Size area,
    {required bool vertical, double pad = 44}) {
  if (count <= 0) return const [];
  if (vertical) {
    final amplitude = math.min(area.width * 0.26, 90.0);
    return [
      for (var i = 0; i < count; i++)
        Offset(area.width / 2 + amplitude * math.sin(i * _wave + 0.4),
            pad + i * levelPathStep),
    ];
  }
  final usable = area.width - 2 * pad;
  final step = count > 1 ? usable / (count - 1) : 0.0;
  final amplitude = math.min(34.0, area.height * 0.14);
  final middle = area.height * 0.58;
  return [
    for (var i = 0; i < count; i++)
      Offset(
        count > 1 ? pad + i * step : area.width / 2,
        middle + amplitude * math.sin(i * _wave + 0.4),
      ),
  ];
}

/// The height a vertical path needs: the nodes, the stars under the last, the margins.
double levelPathHeight(int count, {double pad = 44}) =>
    pad * 2 + (count <= 0 ? 0 : (count - 1) * levelPathStep) + 24;
