import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_server/src/generated/protocol.dart';
import 'package:dance_trainer_server/src/training/content_store.dart';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Training lifecycle', (sessionBuilder, endpoints) {
    final alice = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo('alice', {
        Scope('user'),
      }),
    );
    final bob = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo('bob', {
        Scope('user'),
      }),
    );
    final bundle = ContentStore.load('howdeepisyourlove');
    Future<TrainingAttempt> begin(String id) => endpoints.training.begin(
      alice,
      bundle.id,
      bundle.version,
      poseModelHash,
      id,
      null,
    );
    final absent = jsonEncode([
      {
        't': 1000,
        'q': 0,
        's': 0,
        'w': 640,
        'h': 480,
        'p': [
          for (var i = 0; i < 17; i++) [null, null, 0],
        ],
      },
    ]);
    test('catalog exposes compiled unranked development content', () async {
      final rows = await endpoints.catalog.list(sessionBuilder);
      expect(rows.length, 2);
      expect(rows.every((r) => !r.rankedAvailable), isTrue);
    });
    test('private endpoints reject unauthenticated requests', () async {
      await expectLater(
        endpoints.training.profile(sessionBuilder),
        throwsA(anything),
      );
    });
    test('begin is idempotent and conflicting reuse is rejected', () async {
      final a = await begin('idempotent-attempt-001');
      final b = await begin('idempotent-attempt-001');
      expect(a.id, b.id);
      await expectLater(
        endpoints.training.begin(
          alice,
          bundle.id,
          bundle.version,
          poseModelHash,
          'idempotent-attempt-001',
          bundle.events.first.sectionId,
        ),
        throwsA(isA<TrainingError>()),
      );
    });
    test(
      'cross-account evidence is rejected and history is isolated',
      () async {
        final a = await begin('ownership-attempt-001');
        await expectLater(
          endpoints.training.upload(bob, a.id!, a.ticket, 0, absent),
          throwsA(isA<TrainingError>()),
        );
        expect(await endpoints.training.history(bob, offset: 0), isEmpty);
      },
    );
    test(
      'chunk retries are idempotent; conflicting bytes and gaps fail',
      () async {
        final a = await begin('chunk-retry-attempt-001');
        expect(
          await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent),
          1,
        );
        expect(
          await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent),
          1,
        );
        await expectLater(
          endpoints.training.upload(
            alice,
            a.id!,
            a.ticket,
            0,
            absent.replaceFirst('1000', '1100'),
          ),
          throwsA(isA<TrainingError>()),
        );
        await expectLater(
          endpoints.training.upload(alice, a.id!, a.ticket, 2, absent),
          throwsA(isA<TrainingError>()),
        );
      },
    );
    test('finalization checks completeness and remains idempotent', () async {
      final a = await begin('finalize-attempt-001');
      await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent);
      await expectLater(
        endpoints.training.finalize(
          alice,
          a.id!,
          a.ticket,
          2,
          bundle.durationMs,
          false,
        ),
        throwsA(isA<TrainingError>()),
      );
      await expectLater(
        endpoints.training.finalize(alice, a.id!, a.ticket, 1, 1000, false),
        throwsA(isA<TrainingError>()),
      );
      final saved = await endpoints.training.finalize(
        alice,
        a.id!,
        a.ticket,
        1,
        bundle.durationMs,
        false,
      );
      final retry = await endpoints.training.finalize(
        alice,
        a.id!,
        a.ticket,
        1,
        bundle.durationMs,
        false,
      );
      expect(retry.resultJson, saved.resultJson);
      final result = jsonDecode(saved.resultJson!) as Map;
      expect(result['coverage'], 0);
      expect(result['ranked'], false);
      expect(result['judgmentAvailable'], false);
      expect((await endpoints.training.history(alice, offset: 0)).length, 1);
      expect(await endpoints.training.leaderboard(alice, bundle.id), isEmpty);
    });
    test(
      'server recomputes from observations with exact domain parity',
      () async {
        // Recorded archival poses are test evidence only, never app observations.
        final source = jsonObject(
          jsonDecode(
            File(
              '../content/source/${bundle.id}/${bundle.id}.json',
            ).readAsStringSync(),
          ),
        );
        final frames = jsonList(source['frames']);
        final fps = finiteNumber(source['fps']);
        final observations = <TrainingObservation>[];
        for (final event in bundle.events) {
          final raw = jsonObject(
            frames[(event.targetContentTime.inMilliseconds / 1000 * fps)
                .round()],
          );
          final landmarks = jsonObject(raw['keypoints']);
          observations.add(
            TrainingObservation(
              timeMs: event.targetContentTime.inMilliseconds,
              width: 1280,
              height: 720,
              points: [
                for (final name in kLandmarkNames)
                  [
                    jsonObject(landmarks[name])['x'],
                    jsonObject(landmarks[name])['y'],
                    jsonObject(landmarks[name])['confidence'],
                  ],
              ],
              sequence: observations.length,
              segment: 0,
            ),
          );
        }
        final a = await begin('parity-attempt-0001');
        var chunk = 0;
        for (var start = 0; start < observations.length; start += 50) {
          await endpoints.training.upload(
            alice,
            a.id!,
            a.ticket,
            chunk++,
            jsonEncode(
              observations
                  .sublist(start, (start + 50).clamp(0, observations.length))
                  .map((o) => o.toJson())
                  .toList(),
            ),
          );
        }
        final saved = await endpoints.training.finalize(
          alice,
          a.id!,
          a.ticket,
          chunk,
          bundle.durationMs,
          false,
        );
        expect(
          jsonDecode(saved.resultJson!),
          scoreTraining(bundle, observations),
        );
        expect(jsonObject(jsonDecode(saved.resultJson!))['totalScore'], 10000);
      },
    );
    test('practice counts distinct attempts once and stops at three', () async {
      // Recorded poses, with wrists displaced only in this regression fixture.
      final source = jsonObject(
        jsonDecode(
          File(
            '../content/source/${bundle.id}/${bundle.id}.json',
          ).readAsStringSync(),
        ),
      );
      final frames = jsonList(source['frames']);
      final fps = finiteNumber(source['fps']);
      Future<TrainingAttempt> finish(String uuid, {String? section}) async {
        final a = await endpoints.training.begin(
          alice,
          bundle.id,
          bundle.version,
          poseModelHash,
          uuid,
          section,
        );
        final events = bundle.events
            .where((e) => section == null || e.sectionId == section)
            .toList();
        final observations = <TrainingObservation>[];
        for (final event in events) {
          final raw = jsonObject(
            frames[(event.targetContentTime.inMilliseconds / 1000 * fps)
                .round()],
          );
          final landmarks = jsonObject(raw['keypoints']);
          observations.add(
            TrainingObservation(
              timeMs: event.targetContentTime.inMilliseconds,
              width: 1280,
              height: 720,
              sequence: observations.length,
              segment: 0,
              points: [
                for (final name in kLandmarkNames)
                  [
                    name.endsWith('Wrist')
                        ? 1 - finiteNumber(jsonObject(landmarks[name])['x'])
                        : jsonObject(landmarks[name])['x'],
                    jsonObject(landmarks[name])['y'],
                    jsonObject(landmarks[name])['confidence'],
                  ],
              ],
            ),
          );
        }
        await endpoints.training.upload(
          alice,
          a.id!,
          a.ticket,
          0,
          jsonEncode(observations.map((o) => o.toJson()).toList()),
        );
        final end = section == null
            ? bundle.durationMs
            : wholeNumber(
                bundle.sections.firstWhere((s) => s['id'] == section)['endMs'],
              );
        return endpoints.training.finalize(
          alice,
          a.id!,
          a.ticket,
          1,
          end,
          false,
        );
      }

      final original = await finish('practice-source-0001');
      final assignment = await endpoints.training.practice(alice, original.id!);
      expect(
        (await endpoints.training.practice(alice, original.id!)).id,
        assignment.id,
      );
      await expectLater(
        endpoints.training.practice(bob, original.id!),
        throwsA(isA<TrainingError>()),
      );
      for (var i = 1; i <= 4; i++) {
        final run = await finish(
          'practice-repeat-000$i',
          section: assignment.sectionId,
        );
        final counted = await endpoints.training.completeRepetition(
          alice,
          assignment.id!,
          run.id!,
        );
        final retried = await endpoints.training.completeRepetition(
          alice,
          assignment.id!,
          run.id!,
        );
        expect(counted.completedRepetitions, i.clamp(0, 3));
        expect(retried.completedRepetitions, counted.completedRepetitions);
        expect(counted.completed, i >= 3);
      }
    });
    test(
      'profile visibility defaults off and updates stay account scoped',
      () async {
        expect(
          (await endpoints.training.profile(alice)).leaderboardVisible,
          false,
        );
        await endpoints.training.updateProfile(alice, '  Alice  ', true);
        final profile = await endpoints.training.profile(alice);
        expect(profile.displayName, 'Alice');
        expect(profile.leaderboardVisible, true);
        expect((await endpoints.training.profile(bob)).displayName, 'Dancer');
        await expectLater(
          endpoints.training.updateProfile(alice, '', true),
          throwsA(isA<TrainingError>()),
        );
      },
    );
    test(
      'invalid coordinates and unknown model versions fail closed',
      () async {
        await expectLater(
          endpoints.training.begin(
            alice,
            bundle.id,
            bundle.version,
            'unknown',
            'bad-model-attempt-001',
            null,
          ),
          throwsA(isA<TrainingError>()),
        );
        final a = await begin('bad-payload-attempt-001');
        await expectLater(
          endpoints.training.upload(alice, a.id!, a.ticket, 0, '[{"t":1}]'),
          throwsA(isA<TrainingError>()),
        );
      },
    );
  });
}
