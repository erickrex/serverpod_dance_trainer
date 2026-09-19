import 'dart:convert';
import 'dart:io';
import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

void main() {
  for (final id in ['howdeepisyourlove', '30minutos']) {
    test('$id round trips and missing observations suppress judgment', () {
      final bundle = TrainingBundle.fromJson(
        jsonDecode(File('../../content/compiled/$id.json').readAsStringSync()),
      );
      expect(
        TrainingBundle.fromJson(bundle.toJson()).toJson(),
        bundle.toJson(),
      );
      final result = scoreTraining(bundle, []);
      expect(result['coverage'], 0);
      expect(result['totalScore'], 0);
      expect(result['judgmentAvailable'], false);
      expect(result['ranked'], false);
      expect(result['recommendation'], 'recalibrateCamera');
      expect(
        () => scoreTraining(bundle, [], sectionId: 'missing'),
        throwsFormatException,
      );
    });
  }
  test('evidence owns its coordinates and rejects malformed wire values', () {
    final points = <List<Object?>>[
      for (var i = 0; i < 17; i++) [null, null, 0],
    ];
    final observation = TrainingObservation(
      timeMs: 1,
      width: 640,
      height: 480,
      points: points,
      sequence: 0,
      segment: 0,
    );
    points.first[0] = 0.8;
    expect((observation.points.first as List).first, isNull);
    expect(
      () => (observation.points.first as List)[0] = 0.8,
      throwsUnsupportedError,
    );
    expect(
      () =>
          TrainingObservation.fromJson({...observation.toJson(), 'p': points}),
      throwsFormatException,
    );
    expect(
      () => TrainingObservation.fromJson({
        ...observation.toJson(),
        'w': double.nan,
      }),
      throwsFormatException,
    );
  });
}
