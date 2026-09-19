import 'dart:convert';
import 'dart:io';
import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

void main() {
  for (final id in ['howdeepisyourlove', '30minutos']) {
    test(
      '$id recovers known signed offsets from recorded checkpoint poses',
      () {
        final bundle = TrainingBundle.fromJson(
          jsonDecode(
            File('../../content/compiled/$id.json').readAsStringSync(),
          ),
        );
        final source = jsonObject(
          jsonDecode(
            File('../../content/source/$id/$id.json').readAsStringSync(),
          ),
        );
        final frames = jsonList(source['frames']);
        final fps = finiteNumber(source['fps']);
        for (final offset in [-200, 0, 200, 400]) {
          final observations = <TrainingObservation>[];
          for (final event in bundle.events) {
            final frame = jsonObject(
              frames[(event.targetContentTime.inMilliseconds / 1000 * fps)
                  .round()],
            );
            final points = jsonObject(frame['keypoints']);
            observations.add(
              TrainingObservation(
                timeMs: event.targetContentTime.inMilliseconds + offset,
                sequence: observations.length,
                segment: 0,
                width: 1280,
                height: 720,
                points: [
                  for (final name in kLandmarkNames)
                    [
                      jsonObject(points[name])['x'],
                      jsonObject(points[name])['y'],
                      jsonObject(points[name])['confidence'],
                    ],
                ],
              ),
            );
          }
          final matches = matchAttemptEvents(
            events: bundle.events,
            observations: observations.map((o) => o.toMatchable()).toList(),
          );
          if (offset.abs() <= 300) {
            for (final match in matches) {
              expect(match.quality.signedTimingOffsetMs, offset);
              expect(match.quality.movementQuality, closeTo(1, 1e-8));
            }
            final result = scoreTraining(bundle, observations);
            expect(result['coverage'], 1);
            expect(result['totalScore'], offset == 0 ? 10000 : lessThan(10000));
          } else {
            expect(
              matches.every(
                (m) => m.quality.assessment == EventAssessment.unassessed,
              ),
              isTrue,
            );
          }
          if (offset == 0) {
            final missing = scoreTraining(
              bundle,
              observations.skip(observations.length ~/ 2).toList(),
            );
            expect(missing['judgmentAvailable'], false);
            expect(missing['coverage'] as num, lessThan(0.85));
            expect(
              () => scoreTraining(bundle, [...observations, observations.last]),
              throwsFormatException,
            );
          }
        }
      },
    );
  }
}
