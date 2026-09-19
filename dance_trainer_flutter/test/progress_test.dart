import 'dart:convert';
import 'package:dance_trainer_flutter/training/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'repository_test.dart' show attempt;

void main() {
  test(
    'score comparisons gate versions, modes, sections, speed and tracking',
    () {
      final older = attempt(1)
        ..resultJson = jsonEncode({
          'judgmentAvailable': true,
          'scoringVersion': 'v2',
          'totalScore': 6000,
        });
      final newer = attempt(2)
        ..resultJson = jsonEncode({
          'judgmentAvailable': true,
          'scoringVersion': 'v2',
          'totalScore': 7000,
        });
      expect(scoreChange(newer, older), 1000);
      for (final changed in [
        older.copyWith(contentVersion: 'v3'),
        older.copyWith(modelVersion: 'other'),
        older.copyWith(routineId: 'other'),
        older.copyWith(mode: 'practice'),
        older.copyWith(sectionId: 'section-1'),
        older.copyWith(
          resultJson: jsonEncode({
            'judgmentAvailable': false,
            'scoringVersion': 'v2',
            'totalScore': 9000,
          }),
        ),
        older.copyWith(
          resultJson: jsonEncode({
            'judgmentAvailable': true,
            'scoringVersion': 'v1',
            'totalScore': 9000,
          }),
        ),
        older.copyWith(
          resultJson: jsonEncode({
            'judgmentAvailable': true,
            'scoringVersion': 'v2',
            'totalScore': 9000,
            'playbackRate': 0.75,
          }),
        ),
        older.copyWith(
          resultJson: jsonEncode({
            'judgmentAvailable': true,
            'scoringVersion': 'v2',
            'totalScore': 9000,
            'rankReason': 'Run interrupted',
          }),
        ),
      ]) {
        expect(scoreChange(newer, changed), isNull);
      }
    },
  );
}
