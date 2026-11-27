// The questions from the Term documents (the DepEd PDFs of 2026-11-27: 15 a Linggo in Grade 5, 10 in
// Grade 6): at least a full lesson of 10 for every level, a boss level that holds its own lesson plus 12
// of review, an explanation for every one, and shaped so a teacher can still edit them in the
// dashboard question bank (which limits a question to 400 characters and a choice to 150).
import 'dart:convert';
import 'dart:io';

import 'package:chronoquest/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

const _imported = ['pre-colonial', 'spanish', 'nationalism', 'american', 'ww2', 'modern'];

Map<String, dynamic> _load(String era) =>
    jsonDecode(File('assets/data/questions_$era.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  for (final era in _imported) {
    group(era, () {
      final data = _load(era);
      final levels = getEraById(era).levels.length;

      test('has a set for every level and nothing past the boss', () {
        expect(data.keys.map(int.parse).toList()..sort(), [for (var l = 1; l <= levels; l++) l]);
      });

      test('has at least 10 questions a level and at least 22 on the boss level', () {
        for (final entry in data.entries) {
          final level = int.parse(entry.key);
          final want = level == levels
              ? GameConstants.bossWarmupQuestions + GameConstants.bossFightQuestions
              : GameConstants.questionsPerLevel;
          expect((entry.value as List).length, greaterThanOrEqualTo(want), reason: 'level $level');
        }
      });

      test('every question has an explanation to show after a wrong answer', () {
        for (final entry in data.entries) {
          for (final raw in entry.value as List) {
            final q = raw as Map<String, dynamic>;
            expect((q['explanation'] as String? ?? '').trim().length, greaterThan(20), reason: q['id'] as String);
          }
        }
      });

      test('every question can be played and edited', () {
        final ids = <String>{};
        for (final entry in data.entries) {
          final texts = <String>{};
          for (final raw in entry.value as List) {
            final q = raw as Map<String, dynamic>;
            final id = q['id'] as String;
            expect(ids.add(id), isTrue, reason: 'duplicate id $id');
            expect(q['era'], era, reason: id);
            expect(q['level'], int.parse(entry.key), reason: id);

            final text = q['questionText'] as String;
            expect(text.length, inInclusiveRange(10, 400), reason: id);
            expect(texts.add(text), isTrue, reason: 'level ${entry.key} asks "$text" twice');

            final options = (q['options'] as List).cast<Map<String, dynamic>>();
            expect(options.map((o) => o['label']).join(), 'ABCD', reason: id);
            for (final o in options) {
              expect((o['text'] as String).trim(), isNotEmpty, reason: id);
              expect((o['text'] as String).length, lessThanOrEqualTo(150), reason: id);
            }
            expect(options.map((o) => o['text']).toSet().length, 4, reason: '$id has two equal choices');
            expect('ABCD'.contains(q['correctAnswer'] as String), isTrue, reason: id);
          }
        }
      });

      test('the boss level reviews the earlier lessons', () {
        final boss = (data['$levels'] as List).cast<Map<String, dynamic>>();
        final topics = boss.map((q) => q['subTopic']).toSet();
        expect(topics.length, greaterThan(1));
        expect(boss.take(GameConstants.bossWarmupQuestions).map((q) => q['subTopic']).toSet().length, 1,
            reason: 'the first 10 are the boss lesson itself');
      });
    });
  }
}
