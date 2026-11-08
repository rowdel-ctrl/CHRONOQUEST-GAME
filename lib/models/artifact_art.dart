/// Which picture an artifact wears. Every era has ten artifact icons, so the
/// picture is chosen by era and a number 1..10:
/// `assets/collectibles/artifact_<eraId>_<n>.png` (60 icons in all, made by
/// `tools/art-import/artifacts.js`).
///
/// The five old generic pictures (`artifact_1.png` .. `artifact_5.png`) stay
/// for the places that show "an artifact" with no era (HUD, boss scroll) and as
/// the fallback for an era id this build does not know.
const int artifactIconsPerEra = 10;

/// The era ids that have artifact icons. Matches `allEras` in constants.dart
/// (a test checks the two lists agree).
const List<String> artifactEraIds = [
  'pre-colonial',
  'spanish',
  'nationalism',
  'american',
  'ww2',
  'modern',
];

/// Keeps [index] inside 1..[artifactIconsPerEra]; anything outside becomes 1.
int clampArtifactIndex(int index) =>
    (index < 1 || index > artifactIconsPerEra) ? 1 : index;

/// Asset path (as `Image.asset` wants it) of the icon for [eraId] and [index].
/// An unknown era falls back to the old generic picture with that number
/// (wrapped into 1..5).
String artifactAsset(String eraId, int index) {
  final n = clampArtifactIndex(index);
  if (!artifactEraIds.contains(eraId)) {
    return 'assets/collectibles/artifact_${((n - 1) % 5) + 1}.png';
  }
  return 'assets/collectibles/artifact_${eraId}_$n.png';
}

/// The same picture as the key Flame's `game.loadSprite` wants (no `assets/`).
String artifactImageKey(String eraId, int index) =>
    artifactAsset(eraId, index).substring('assets/'.length);
