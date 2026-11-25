import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A blank hop between a level and the same level again ("Ulitin" in the pause menu).
///
/// Going to the same route from inside it would keep the running screen, and replacing it
/// would build the new level before the old one has stopped its music and restarted the
/// hearts clock. Going through here lets the old screen end first; the next frame this
/// opens the level, straight to the game (the lesson was read already).
class RestartLevelScreen extends StatefulWidget {
  final String eraId;
  final int level;
  const RestartLevelScreen({super.key, required this.eraId, required this.level});

  @override
  State<RestartLevelScreen> createState() => _RestartLevelScreenState();
}

class _RestartLevelScreenState extends State<RestartLevelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/game/${widget.eraId}/${widget.level}');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Colors.black);
}
