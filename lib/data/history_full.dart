import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One chapter of an era's full background: a week (or a few weeks) of the lesson.
///
/// The first three eras use the DepEd MATATAG guides' "Kaugnay na Impormasyon" and
/// their term tables; the later three were written from reference sites. The text lives
/// in `assets/data/history_full.json` (see `docs/history-later-eras-sources.md`).
class FullChapter {
  /// The weeks this chapter covers: "3" or "3-5".
  final String weeks;
  final String title;

  /// `**word**` marks the words shown in bold.
  final List<String> paragraphs;

  /// Key terms: (term, meaning).
  final List<(String, String)> terms;

  const FullChapter({
    required this.weeks,
    required this.title,
    required this.paragraphs,
    required this.terms,
  });

  /// "LINGGO 3" or "LINGGO 3-5".
  String get label => 'LINGGO $weeks';

  factory FullChapter.fromJson(Map<String, dynamic> j) => FullChapter(
        weeks: j['weeks'] as String,
        title: j['title'] as String,
        paragraphs: [for (final p in j['paragraphs'] as List) p as String],
        terms: [
          for (final t in j['terms'] as List)
            ((t as List)[0] as String, t[1] as String),
        ],
      );

  /// Words in the paragraphs, bold marks left out.
  int get wordCount => paragraphs
      .join(' ')
      .replaceAll('**', '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;
}

/// The full background of every era.
class HistoryFull {
  HistoryFull._();

  /// How the text is read. A test replaces this with its own.
  static Future<Map<String, List<FullChapter>>> Function() loader = _fromAssets;

  static Future<Map<String, List<FullChapter>>>? _cache;

  static Future<Map<String, List<FullChapter>>> _fromAssets() async {
    final raw = await rootBundle.loadString('assets/data/history_full.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in data.entries)
        e.key: [
          for (final c in e.value as List)
            FullChapter.fromJson(c as Map<String, dynamic>),
        ],
    };
  }

  /// The chapters of [eraId] (none if the era has no full text).
  static Future<List<FullChapter>> chapters(String eraId) async {
    final all = await (_cache ??= loader());
    return all[eraId] ?? const [];
  }

  /// Forgets what was read, so the next call reads again (tests).
  static void reset() => _cache = null;

  /// Which chapter a story card opens: cards and chapters are spread evenly, so card 3 of
  /// 5 in an era of 10 chapters opens chapter 5, and 8 cards in 8 chapters match one to one.
  static int chapterForBeat(int beat, int beatCount, int chapterCount) {
    if (chapterCount <= 0 || beatCount <= 0) return 0;
    return (beat * chapterCount ~/ beatCount).clamp(0, chapterCount - 1);
  }
}
