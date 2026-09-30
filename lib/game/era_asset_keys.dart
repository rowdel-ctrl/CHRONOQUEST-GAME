/// Maps an era id to the filename stem its art actually uses.
///
/// Two mismatches, both pre-existing and deliberate:
/// - `pre-colonial` art is named `precolonial_*` (no hyphen).
/// - `nationalism` (Era 3, added in Phase 0.5) has no art of its own and
///   reuses the Spanish set, which GAMEPLAY-V2.md Section 1 calls
///   period-correct rather than a stopgap.
///
/// Extracted from `WallComponent` when gates started needing the same
/// mapping — duplicating it risked the two drifting apart the next time an
/// era is added.
String eraAssetKey(String eraId) {
  if (eraId == 'pre-colonial') return 'precolonial';
  if (eraId == 'nationalism') return 'spanish';
  return eraId;
}
