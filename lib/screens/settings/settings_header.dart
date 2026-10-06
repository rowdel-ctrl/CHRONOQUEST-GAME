import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/menu_top_bar.dart';

/// The header Settings and Controls share with the rest of the menu screens:
/// the menu's back chip on the left, the title in gold in the middle.
///
/// Back pops, so it returns to whichever screen opened Settings (the main
/// menu, or the pause menu over a level). The `go` fallback is only for a
/// screen reached with nothing beneath it, such as a restored session.
class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return MenuTopBar(
      title: title,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go('/character-selection'),
    );
  }
}
