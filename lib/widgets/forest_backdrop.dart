import 'package:flutter/material.dart';

/// The forest of the level, filling whatever space it is given: four layers that
/// slide at their own speeds, with a colour wash over them. [seconds] is how long
/// it has been sliding; 0 holds it still.
class ForestBackdrop extends StatelessWidget {
  final double seconds;
  final Color tint;

  const ForestBackdrop(
      {super.key, this.seconds = 0, this.tint = const Color(0x665E8C3A)});

  static const _layers = [
    ('assets/backgrounds/parallax-forest-back-trees.png', 13.0),
    ('assets/backgrounds/parallax-forest-lights.png', 20.0),
    ('assets/backgrounds/parallax-forest-middle-trees.png', 32.0),
    ('assets/backgrounds/parallax-forest-front-trees.png', 54.0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight.isFinite ? box.maxHeight : 300.0;
        final tileW = h * 272 / 160;
        final copies =
            (box.maxWidth.isFinite ? box.maxWidth / tileW : 4).ceil() + 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final l in _layers)
              ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: double.infinity,
                  child: Transform.translate(
                    offset: Offset(-((l.$2 * seconds * h / 190) % tileW), 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < copies; i++)
                          Image.asset(
                            l.$1,
                            width: tileW,
                            height: h,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) =>
                                SizedBox(width: tileW, height: h),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ColoredBox(color: tint),
          ],
        );
      },
    );
  }
}
