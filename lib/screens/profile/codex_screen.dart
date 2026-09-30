import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../models/codex_entry.dart';
import '../../services/storage_service.dart';

/// The Codex (GAMEPLAY-V2.md Section 6): a per-era grid of the artifacts a
/// student has claimed by answering their questions correctly, each showing
/// the history blurb it taught.
///
/// Deliberately plain Flutter — no game code, no package. Reads straight
/// from local storage rather than a provider: claims are written during
/// gameplay and this screen is only opened from the Profile tab, so there
/// is nothing to keep live.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final erasWithEntries = allEras
        .map((era) => (era: era, entries: StorageService.getCodexEntries(era.id)))
        .toList();
    final total = erasWithEntries.fold<int>(0, (s, e) => s + e.entries.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(
          'KODEKS',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
      body: total == 0
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '$total na artifact ang nakalap',
                  style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bawat artifact ay may kasaysayang natutunan mo.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final group in erasWithEntries)
                  if (group.entries.isNotEmpty)
                    _EraSection(eraName: group.era.name, entries: group.entries),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/collectibles/artifact_1.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wala ka pang nakalap na artifact',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maglaro ng antas at sagutin nang tama ang mga tanong sa '
              'artifact upang makalap ang mga ito.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EraSection extends StatelessWidget {
  final String eraName;
  final List<CodexEntry> entries;

  const _EraSection({required this.eraName, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                eraName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entries.length}',
                style: GoogleFonts.poppins(
                  color: AppColors.accent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) => _CodexTile(entry: entries[i]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CodexTile extends StatelessWidget {
  final CodexEntry entry;

  const _CodexTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Artifact: ${entry.questionText}',
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _CodexDetailDialog(entry: entry),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(entry.assetPath, width: 40, height: 40),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  entry.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 8,
                    height: 1.3,
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

class _CodexDetailDialog extends StatelessWidget {
  final CodexEntry entry;

  const _CodexDetailDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      title: Row(
        children: [
          Image.asset(entry.assetPath, width: 36, height: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.questionText,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          entry.blurb,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.6,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'ISARA',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
