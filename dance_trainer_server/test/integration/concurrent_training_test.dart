import 'dart:convert';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_server/src/generated/protocol.dart';
import 'package:dance_trainer_server/src/training/content_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  // Real independent transactions are required to exercise advisory locks.
  withServerpod('Concurrent submissions', (builder, endpoints) {
    test(
      'duplicate submissions commit once and deletion serializes with writes',
      () async {
        final session = builder.build();
        final user = await const AuthUsers().create(session);
        final signedIn = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            user.id.toString(),
            {Scope('user')},
          ),
        );
        try {
          final bundle = ContentStore.load('howdeepisyourlove');
          final attempts = await Future.wait(
            List.generate(
              4,
              (_) => endpoints.training.begin(
                signedIn,
                bundle.id,
                bundle.version,
                poseModelHash,
                'concurrent-attempt-0001',
                null,
              ),
            ),
          );
          expect(attempts.map((a) => a.id).toSet(), hasLength(1));
          final a = attempts.first;
          final payload = jsonEncode([
            TrainingObservation(
              timeMs: 1000,
              width: 640,
              height: 480,
              points: [
                for (var i = 0; i < 17; i++) [null, null, 0],
              ],
              sequence: 0,
              segment: 0,
            ).toJson(),
          ]);
          expect(
            await Future.wait(
              List.generate(
                4,
                (_) => endpoints.training.upload(
                  signedIn,
                  a.id!,
                  a.ticket,
                  0,
                  payload,
                ),
              ),
            ),
            everyElement(1),
          );
          final saved = await Future.wait(
            List.generate(
              4,
              (_) => endpoints.training.finalize(
                signedIn,
                a.id!,
                a.ticket,
                1,
                bundle.durationMs,
                false,
              ),
            ),
          );
          expect(saved.map((a) => a.resultJson).toSet(), hasLength(1));
          expect(
            await TrainingAttempt.db.count(
              session,
              where: (t) => t.userId.equals(user.id.toString()),
            ),
            1,
          );
          await Future.wait([
            endpoints.training.deleteAccount(signedIn),
            endpoints.training
                .updateProfile(signedIn, 'Concurrent', true)
                .then<void>(
                  (_) {},
                  onError: (Object error) {
                    expect(
                      error,
                      isA<TrainingError>().having(
                        (e) => e.code,
                        'code',
                        'account',
                      ),
                    );
                  },
                ),
          ]);
          expect(
            await LearnerProfile.db.count(
              session,
              where: (t) => t.userId.equals(user.id.toString()),
            ),
            0,
          );
          expect(
            await TrainingAttempt.db.count(
              session,
              where: (t) => t.userId.equals(user.id.toString()),
            ),
            0,
          );
        } finally {
          await endpoints.training.deleteAccount(signedIn);
          await session.close();
        }
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
