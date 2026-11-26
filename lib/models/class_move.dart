import 'student.dart';

String? _text(Object? value) {
  if (value is! String) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}

/// What the server says about a class that has ended (HTTP 409, code CLASS_ENDED), sent
/// when a student signs in to it. A learner who has an account there gets their name and
/// username back, so the game can offer to move them to the new class. A join into an ended
/// class has neither.
class ClassEndedInfo {
  final String? name;
  final String? username;
  final String? sectionName;

  /// "Grade 5", as the server writes it.
  final String? grade;

  /// "2025-2026".
  final String? schoolYear;

  const ClassEndedInfo({
    this.name,
    this.username,
    this.sectionName,
    this.grade,
    this.schoolYear,
  });

  factory ClassEndedInfo.fromJson(Object? json) {
    if (json is! Map) return const ClassEndedInfo();
    return ClassEndedInfo(
      name: _text(json['name']),
      username: _text(json['username']),
      sectionName: _text(json['sectionName']),
      grade: _text(json['grade']),
      schoolYear: _text(json['schoolYear']),
    );
  }

  /// True when the learner has an account in the ended class, so there is something to
  /// move. False for a new join, which only gets "ask your teacher for the new code".
  bool get hasAccount => username != null;
}

/// The login call found the class has ended. [ApiService.login] throws this.
class ClassEndedException implements Exception {
  final ClassEndedInfo info;
  const ClassEndedException(this.info);

  @override
  String toString() => 'ClassEndedException';
}

/// A class as the server describes it ("Is this your class?"), or the one a learner just
/// moved into.
class ClassInfo {
  final String classCode;
  final String sectionName;
  final String gradeLevel;

  /// "Grade 6".
  final String grade;
  final String teacherName;
  final String schoolName;

  /// "2026-2027".
  final String schoolYear;

  const ClassInfo({
    required this.classCode,
    required this.sectionName,
    this.gradeLevel = '',
    this.grade = '',
    this.teacherName = '',
    this.schoolName = '',
    this.schoolYear = '',
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) => ClassInfo(
        classCode: _text(json['classCode']) ?? '',
        sectionName: _text(json['sectionName']) ?? '',
        gradeLevel: _text(json['gradeLevel']) ?? '',
        grade: _text(json['grade']) ?? '',
        teacherName: _text(json['teacherName']) ?? '',
        schoolName: _text(json['schoolName']) ?? '',
        schoolYear: _text(json['schoolYear']) ?? '',
      );
}

/// A learner who moved to the new class: the account as the server has it now (a new
/// class code, perhaps a new username), the class, and where they came from.
class MoveUpResult {
  final Student student;
  final ClassInfo? section;
  final String? fromSection;
  final String? fromYear;

  const MoveUpResult({
    required this.student,
    this.section,
    this.fromSection,
    this.fromYear,
  });
}

/// Moving up failed. [message] is ready to show; [code] is the server's own code when it
/// sent one (SESSION_ACTIVE means "ask, then send again with takeOver").
class MoveUpError implements Exception {
  final String message;
  final String? code;
  const MoveUpError(this.message, {this.code});

  @override
  String toString() => message;
}
