import 'package:serverpod/serverpod.dart';
import '../generated/future_calls.dart';

/// Removes unfinished evidence after seven days. Completed evidence is erased
/// by finalization; stored aggregate results remain until account deletion.
class EvidenceRetention extends FutureCall {
  static const callName = 'evidenceRetention';
  static const identifier = 'dance-evidence-retention';

  Future<void> purge(Session session, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now().toUtc()).subtract(
      const Duration(days: 7),
    );
    final users = await session.db.unsafeQuery(
      'SELECT DISTINCT "userId" FROM training_attempt WHERE status=\'recording\' AND "createdAt" < @cutoff LIMIT 1000',
      parameters: QueryParameters.named({'cutoff': cutoff}),
    );
    for (final row in users) {
      await session.db.transaction((tx) async {
        final owner = row[0] as String;
        await session.db.unsafeQuery(
          'SELECT pg_advisory_xact_lock(hashtextextended(@key, 0))',
          parameters: QueryParameters.named({'key': 'dance:$owner'}),
          transaction: tx,
        );
        final parameters = QueryParameters.named({
          'user': owner,
          'cutoff': cutoff,
        });
        await session.db.unsafeExecute(
          'DELETE FROM training_chunk WHERE "attemptId" IN (SELECT id FROM training_attempt WHERE "userId"=@user AND status=\'recording\' AND "createdAt" < @cutoff)',
          parameters: parameters,
          transaction: tx,
        );
        await session.db.unsafeExecute(
          'DELETE FROM training_attempt WHERE "userId"=@user AND status=\'recording\' AND "createdAt" < @cutoff',
          parameters: parameters,
          transaction: tx,
        );
      });
    }
  }

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await purge(session);
    } finally {
      await session.serverpod.futureCalls
          .callWithDelay(
            const Duration(hours: 6),
            identifier: identifier,
          )
          .evidenceRetention
          .invoke(null);
    }
  }
}
