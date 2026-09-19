import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_server/src/generated/protocol.dart';
import 'package:dance_trainer_server/src/training/content_store.dart';
import 'package:dance_trainer_server/src/training/evidence_retention.dart';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Training lifecycle', (sessionBuilder, endpoints) {
    final alice = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '11111111-1111-4111-8111-111111111111',
        {
          Scope('user'),
        },
      ),
    );
    final bob = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        '22222222-2222-4222-8222-222222222222',
        {
          Scope('user'),
        },
      ),
    );
    setUp(() async {
      final session = sessionBuilder.build();
      for (final id in [
        '11111111-1111-4111-8111-111111111111',
        '22222222-2222-4222-8222-222222222222',
      ]) {
        await AuthUser.db.insertRow(
          session,
          AuthUser(
            id: UuidValue.fromString(id),
            blocked: false,
            scopeNames: {'user'},
          ),
        );
      }
    });
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
      expect(await endpoints.health.ready(sessionBuilder), 'ok');
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
    test(
      'deletion removes owned data and rejects a still-valid identity',
      () async {
        final a = await begin('delete-account-0001');
        await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent);
        await endpoints.training.profile(alice);
        final other = await endpoints.training.profile(bob);
        final session = sessionBuilder.build();
        await session.db.unsafeExecute(
          'INSERT INTO serverpod_auth_idp_email_account ("authUserId", "createdAt", email, "passwordHash") VALUES (CAST(@user AS uuid), @now, @email, @hash)',
          parameters: QueryParameters.named({
            'user': a.userId,
            'now': DateTime.now().toUtc(),
            'email': 'deletion-fixture@example.invalid',
            'hash': 'test-fixture-not-a-credential',
          }),
        );
        final assignment = await PracticeAssignment.db.insertRow(
          session,
          PracticeAssignment(
            userId: a.userId,
            sourceAttemptId: a.id!,
            routineId: bundle.id,
            contentVersion: bundle.version,
            sectionId: 'section-1',
            completedRepetitions: 1,
            completed: false,
          ),
        );
        await PracticeRepetition.db.insertRow(
          session,
          PracticeRepetition(assignmentId: assignment.id!, attemptId: a.id!),
        );
        await TrainingBest.db.insertRow(
          session,
          TrainingBest(
            userId: a.userId,
            boardKey: 'deletion-fixture',
            attemptId: a.id!,
            score: 0,
            achievedAt: DateTime.now().toUtc(),
          ),
        );
        await endpoints.training.deleteAccount(alice);
        await endpoints.training.deleteAccount(alice);
        expect(await TrainingAttempt.db.findById(session, a.id!), isNull);
        expect(await TrainingChunk.db.count(session), 0);
        expect(await LearnerProfile.db.count(session), 1);
        expect(await AuthUser.db.count(session), 1);
        expect(await PracticeAssignment.db.count(session), 0);
        expect(await PracticeRepetition.db.count(session), 0);
        expect(await TrainingBest.db.count(session), 0);
        final identities = await session.db.unsafeQuery(
          'SELECT count(*) FROM serverpod_auth_idp_email_account WHERE email=@email',
          parameters: QueryParameters.named({
            'email': 'deletion-fixture@example.invalid',
          }),
        );
        expect(identities.single.single, 0);
        expect((await endpoints.training.profile(bob)).id, other.id);
        for (final action in [
          () => endpoints.training.profile(alice),
          () => endpoints.training.history(alice, offset: 0),
          () => begin('after-delete-0001'),
        ]) {
          await expectLater(
            action(),
            throwsA(
              isA<TrainingError>().having((e) => e.code, 'code', 'account'),
            ),
          );
        }
      },
    );
    test(
      'upload status is owned and finalization discards only raw evidence',
      () async {
        final a = await begin('resume-status-0001');
        await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent);
        expect(
          (await endpoints.training.resumeUpload(
            alice,
            a.id!,
            a.ticket,
          )).nextChunk,
          1,
        );
        await expectLater(
          endpoints.training.resumeUpload(bob, a.id!, a.ticket),
          throwsA(isA<TrainingError>()),
        );
        await endpoints.training.finalize(
          alice,
          a.id!,
          a.ticket,
          1,
          bundle.durationMs,
          false,
        );
        final chunks = await TrainingChunk.db.find(sessionBuilder.build());
        expect(chunks.single.payloadJson, '[]');
        expect(chunks.single.digest, isNotEmpty);
        expect(
          await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent),
          1,
        );
      },
    );
    test(
      'retention removes abandoned runs while preserving saved history',
      () async {
        final abandoned = await begin('retention-abandoned-0001');
        final complete = await begin('retention-complete-0001');
        for (final a in [abandoned, complete]) {
          await endpoints.training.upload(alice, a.id!, a.ticket, 0, absent);
        }
        await endpoints.training.finalize(
          alice,
          complete.id!,
          complete.ticket,
          1,
          bundle.durationMs,
          false,
        );
        final session = sessionBuilder.build();
        await EvidenceRetention().purge(
          session,
          now: DateTime.now().toUtc().add(const Duration(days: 8)),
        );
        expect(
          await TrainingAttempt.db.findById(session, abandoned.id!),
          isNull,
        );
        expect(
          (await TrainingAttempt.db.findById(session, complete.id!))!.status,
          'complete',
        );
        expect(await TrainingChunk.db.count(session), 1);
      },
    );
    test('request quotas are per account and reset after a minute', () async {
      await endpoints.training.profile(alice);
      final session = sessionBuilder.build();
      var quota = (await TrainingQuota.db.find(session)).single;
      quota.requests = 300;
      await TrainingQuota.db.updateRow(session, quota);
      await expectLater(
        endpoints.training.profile(alice),
        throwsA(
          isA<TrainingError>().having((e) => e.code, 'code', 'rateLimit'),
        ),
      );
      await endpoints.training.profile(bob);
      quota.windowStart = DateTime.now().toUtc().subtract(
        const Duration(minutes: 2),
      );
      await TrainingQuota.db.updateRow(session, quota);
      await endpoints.training.profile(alice);
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
      'history cursor has no duplicates or gaps after newer inserts',
      () async {
        final template = await begin('history-template-0001');
        final session = sessionBuilder.build();
        for (var i = 0; i < 34; i++) {
          await TrainingAttempt.db.insertRow(
            session,
            template.copyWith(
              id: null,
              clientUuid: 'history-fixture-$i',
              status: 'complete',
              resultJson: '{}',
            ),
          );
        }
        final page = await endpoints.training.history(alice, offset: 0);
        expect(page, hasLength(30));
        await TrainingAttempt.db.insertRow(
          session,
          template.copyWith(
            id: null,
            clientUuid: 'history-newer-fixture',
            status: 'complete',
            resultJson: '{}',
          ),
        );
        final older = await endpoints.training.history(
          alice,
          offset: 0,
          beforeId: page.last.id,
        );
        expect(older, hasLength(4));
        expect({
          ...page.map((a) => a.id),
          ...older.map((a) => a.id),
        }, hasLength(34));
        expect(
          await endpoints.training.history(
            bob,
            offset: 0,
            beforeId: page.last.id,
          ),
          isEmpty,
        );
      },
    );
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
