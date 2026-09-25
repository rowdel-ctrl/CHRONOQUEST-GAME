/// A level's curriculum alignment: which grade and term it belongs to, and
/// which DepEd Budget of Work weeks it covers — sourced from GAMEPLAY-V2.md
/// Section 1's "Curriculum weeks, sourced" table (transcribed from the real
/// BOW PDFs), not invented, since CHRONO-DASHBOARD reports to teachers by
/// this data.
class CurriculumTag {
  final int grade;
  final int term;
  final List<int> weeks;

  const CurriculumTag({
    required this.grade,
    required this.term,
    this.weeks = const [],
  });
}

/// One playable stage within an era. Eras carry variable-length level lists
/// (Section 1: 10/5/7/8/8/5, 43 total) rather than a uniform count, so a level is
/// identified by its era and its 1-based position within that era's list,
/// not by a global number. There is no separate "question pool" field —
/// `QuestionBank.getQuestions(eraId, index)` already looks a level's
/// questions up by exactly that pair.
class Level {
  final String eraId;
  final int index;
  final CurriculumTag curriculum;
  final bool isBoss;

  const Level({
    required this.eraId,
    required this.index,
    required this.curriculum,
    this.isBoss = false,
  });
}
