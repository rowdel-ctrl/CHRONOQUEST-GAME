/// Small helpers for the hero pictures shown in menus and cut-scenes.
///
/// Every hero has 4 walk pictures except Lapu-Lapu, who has 5.
const Map<String, int> _walkFrameCounts = {'lapu': 5};

/// How many walk pictures [heroId] has (5 for lapu, 4 for everyone else).
int heroWalkFrameCount(String heroId) => _walkFrameCounts[heroId] ?? 4;

/// The walk picture to show at [ms] milliseconds when the picture changes
/// every [every] milliseconds. Works for heroes with 4 or 5 pictures.
String heroWalkAsset(String heroId, int ms, {int every = 140}) {
  final n = heroWalkFrameCount(heroId);
  return 'assets/characters/${heroId}_walk_${(ms ~/ every) % n + 1}.png';
}
