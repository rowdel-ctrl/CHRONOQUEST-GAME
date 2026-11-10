import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/artifact_art.dart';
import '../../models/codex_entry.dart';
import '../../services/storage_service.dart';
import '../../widgets/living_backdrop.dart';
import '../../widgets/menu_top_bar.dart';

/// The claimed entries of an era grouped by artifact picture (1..10), newest
/// first inside each. A picture is "claimed" once any question that gave it was
/// answered right.
Map<int, List<CodexEntry>> codexSlots(List<CodexEntry> entries) {
  final slots = <int, List<CodexEntry>>{};
  for (final e in entries) {
    slots.putIfAbsent(clampArtifactIndex(e.artifactSprite), () => []).add(e);
  }
  for (final list in slots.values) {
    list.sort((a, b) => b.claimedAtMs.compareTo(a.claimedAtMs));
  }
  return slots;
}

/// How many of the ten artifacts of [eraId] the student has claimed (read from
/// local storage).
int codexClaimedSlots(String eraId) =>
    codexSlots(StorageService.getCodexEntries(eraId)).length;

/// How many of the 60 artifacts (ten in each of the six eras) are claimed.
int codexClaimedTotal() =>
    allEras.fold(0, (sum, era) => sum + codexClaimedSlots(era.id));

/// The Codex (GAMEPLAY-V2.md Section 6): all ten artifacts of an era, always.
/// A claimed one is in colour on a parchment tile; one still to find is a dark
/// shape with a small "?". A row of six tabs picks the era, and the artifact that
/// is tapped is described in a panel (the history blurb it taught, for a claimed
/// one).
///
/// Deliberately plain Flutter — no game code, no package. Reads straight from
/// local storage rather than a provider: claims are written during gameplay and
/// this screen is only opened from the Profile tab, so there is nothing to keep
/// live.
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key, this.entriesFor});

  /// Reads the claimed entries of an era. Tests pass their own; the app reads the
  /// local storage.
  final List<CodexEntry> Function(String eraId)? entriesFor;

  static const Key totalKey = Key('codex_total');
  static const Key detailKey = Key('codex_detail');
  static const Key prevEntryKey = Key('codex_prev_entry');
  static const Key nextEntryKey = Key('codex_next_entry');
  static Key tabKey(int eraIndex) => ValueKey('codex_tab_$eraIndex');

  /// The tile of artifact [n] (1..10) of the era that is showing.
  static Key slotKey(int n) => ValueKey('codex_slot_$n');

  /// Said for an artifact still to find.
  static const String unclaimedText =
      'Sagutin nang tama ang tanong ng artifact na ito sa isang level para makuha ito.';

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  late final List<Map<int, List<CodexEntry>>> _slots;
  late final int _total;
  int _era = 0;
  int _slot = 1;

  /// Which of the entries that gave the artifact is showing (newest first).
  int _entry = 0;

  @override
  void initState() {
    super.initState();
    final read = widget.entriesFor ?? StorageService.getCodexEntries;
    _slots = [for (final era in allEras) codexSlots(read(era.id))];
    _total = _slots.fold(0, (sum, s) => sum + s.length);
    // Open on the first era that has anything, on its first claimed artifact.
    final first = _slots.indexWhere((s) => s.isNotEmpty);
    _era = first < 0 ? 0 : first;
    _slot = _firstSlot(_era);
  }

  int _firstSlot(int era) {
    final keys = _slots[era].keys.toList()..sort();
    return keys.isEmpty ? 1 : keys.first;
  }

  void _pickEra(int i) => setState(() {
        _era = i;
        _slot = _firstSlot(i);
        _entry = 0;
      });

  void _pickSlot(int n) => setState(() {
        _slot = n;
        _entry = 0;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: LivingBackdrop()),
          SafeArea(
            child: Column(
              children: [
                MenuTopBar(
                  title: 'KODEKS',
                  onBack: () => Navigator.of(context).maybePop(),
                  actions: [_TotalPill(total: _total)],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) =>
                        box.maxWidth >= 560 ? _wide(box) : _narrow(box),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── The pieces ─────────────────────────────────────────────────────────────

  Widget _tabs() {
    return Row(
      children: [
        for (var i = 0; i < allEras.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _EraTab(
              key: CodexScreen.tabKey(i),
              number: eraNumberFor(allEras[i].id),
              eraName: allEras[i].name,
              claimed: _slots[i].length,
              selected: i == _era,
              onTap: () => _pickEra(i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eraName() => Text(
        allEras[_era].name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
        ),
      );

  Widget _grid(double tile) {
    final eraId = allEras[_era].id;
    Widget row(int from) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var n = from; n < from + 5; n++) ...[
              if (n > from) const SizedBox(width: 6),
              _SlotTile(
                key: CodexScreen.slotKey(n),
                asset: artifactAsset(eraId, n),
                number: n,
                claimed: _slots[_era].containsKey(n),
                selected: n == _slot,
                size: tile,
                onTap: () => _pickSlot(n),
              ),
            ],
          ],
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [row(1), const SizedBox(height: 6), row(6)],
    );
  }

  Widget _detail({required bool scrolls}) {
    final era = allEras[_era];
    final claimed = _slots[_era][_slot];
    final entries = claimed ?? const <CodexEntry>[];
    final entry =
        entries.isEmpty ? null : entries[_entry.clamp(0, entries.length - 1)];

    final body = <Widget>[
      if (entry != null) ...[
        Text(
          entry.questionText,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.blurb,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.6,
          ),
        ),
        if (entries.length > 1) ...[
          const SizedBox(height: 8),
          _EntryPager(
            index: _entry.clamp(0, entries.length - 1),
            count: entries.length,
            onChange: (i) => setState(() => _entry = i),
          ),
        ],
      ] else ...[
        if (_total == 0) ...[
          Text(
            'Wala ka pang nakukuhang artifact.',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          CodexScreen.unclaimedText,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ],
    ];

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: body,
    );

    return Container(
      key: CodexScreen.detailKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: scrolls ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF241A36),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1B1230), width: 3),
                ),
                child: _Picture(
                  asset: artifactAsset(era.id, _slot),
                  size: 50,
                  claimed: claimed != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artifact $_slot',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      era.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (scrolls)
            Expanded(child: SingleChildScrollView(child: textBlock))
          else
            textBlock,
        ],
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────────

  /// Wide: the grid on the left, the panel to its right.
  Widget _wide(BoxConstraints box) {
    // Room left for the grid once the tabs and the era name are in.
    final gridH = box.maxHeight - 42 - 8 - 22 - 6 - 10;
    final tile = math.max(
      36.0,
      math.min(70.0, math.min((gridH - 6) / 2, (box.maxWidth * 0.6 - 24) / 5)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 42, child: _tabs()),
          const SizedBox(height: 8),
          SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _eraName(),
              )),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grid(tile),
                const SizedBox(width: 16),
                Expanded(child: _detail(scrolls: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Narrow: the tabs, the grid, then the panel under it; the page scrolls.
  Widget _narrow(BoxConstraints box) {
    final tile = math.max(
      32.0,
      math.min(70.0, (box.maxWidth - 32 - 4 * 6) / 5),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 42, child: _tabs()),
          const SizedBox(height: 10),
          _eraName(),
          const SizedBox(height: 8),
          Center(child: _grid(tile)),
          const SizedBox(height: 14),
          _detail(scrolls: false),
        ],
      ),
    );
  }
}

/// The "N ng 60" pill in the top bar.
class _TotalPill extends StatelessWidget {
  final int total;
  const _TotalPill({required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$total ng 60 artifact ang nakuha',
      child: Container(
        key: CodexScreen.totalKey,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF241A36),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1B1230), width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              artifactAsset('pre-colonial', 1),
              width: 20,
              height: 20,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => const SizedBox(width: 20),
            ),
            const SizedBox(width: 6),
            Text(
              '$total ng 60',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the six era tabs: the era's number and "claimed/10". The chosen one is gold.
class _EraTab extends StatelessWidget {
  final int number;
  final String eraName;
  final int claimed;
  final bool selected;
  final VoidCallback onTap;
  const _EraTab({
    super.key,
    required this.number,
    required this.eraName,
    required this.claimed,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final edge = selected ? AppColors.primaryDark : const Color(0xFF1B1230);
    final ink = selected ? AppColors.primaryDark : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: '$eraName, $claimed ng 10 artifact',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : const Color(0xFF241A36),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: edge, width: 3),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                Text(
                  '$claimed/10',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An artifact picture: in colour when claimed, a dark shape when not.
class _Picture extends StatelessWidget {
  final String asset;
  final double size;
  final bool claimed;
  const _Picture({
    required this.asset,
    required this.size,
    required this.claimed,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
    if (claimed) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x59000000), BlendMode.srcIn),
      child: image,
    );
  }
}

/// One of the ten slots of the era: parchment and colour when claimed, dark with a
/// small "?" when not. The one that is picked has a gold edge.
class _SlotTile extends StatelessWidget {
  final String asset;
  final int number;
  final bool claimed;
  final bool selected;
  final double size;
  final VoidCallback onTap;
  const _SlotTile({
    super.key,
    required this.asset,
    required this.number,
    required this.claimed,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final edge = selected
        ? AppColors.accent
        : claimed
            ? AppColors.primaryDark
            : const Color(0xFF1B1230);
    return Semantics(
      button: true,
      selected: selected,
      label: claimed
          ? 'Artifact $number, nakuha'
          : 'Artifact $number, hindi pa nakuha',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: claimed ? AppColors.surface : const Color(0xFF241A36),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: edge, width: 3),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              BoxShadow(
                  color: selected ? AppColors.primaryDark : edge,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Picture(asset: asset, size: size * 0.74, claimed: claimed),
              if (!claimed)
                Positioned(
                  right: 4,
                  bottom: 2,
                  child: Text(
                    '?',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.1,
                      color: const Color(0xFF8E80A8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "1/3" with a small arrow each side, for an artifact that more than one answer gave.
class _EntryPager extends StatelessWidget {
  final int index;
  final int count;
  final ValueChanged<int> onChange;
  const _EntryPager({
    required this.index,
    required this.count,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    Widget arrow(Key key, IconData icon, int to, bool enabled) => Semantics(
          button: true,
          enabled: enabled,
          label: to < index ? 'Nakaraang sagot' : 'Susunod na sagot',
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onChange(to) : null,
            child: SizedBox(
              width: 36,
              height: 32,
              child: Icon(icon,
                  size: 24,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(CodexScreen.prevEntryKey, Icons.chevron_left_rounded, index - 1,
            index > 0),
        Text(
          '${index + 1}/$count',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        arrow(CodexScreen.nextEntryKey, Icons.chevron_right_rounded, index + 1,
            index < count - 1),
      ],
    );
  }
}
