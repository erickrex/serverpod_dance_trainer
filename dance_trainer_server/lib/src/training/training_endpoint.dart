import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dance_domain/dance_domain.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'content_store.dart';

class TrainingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;
  String _user(Session s) => s.authenticated!.userIdentifier;
  Never _fail(String code, String message) =>
      throw TrainingError(code: code, message: message);
  Future<void> _lock(Session s, Transaction tx) async {
    await s.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(hashtextextended(@key, 0))',
      parameters: QueryParameters.named({'key': 'dance:${_user(s)}'}),
      transaction: tx,
    );
  }

  Future<TrainingAttempt> _owned(Session s, int id, Transaction tx) async {
    final row = await TrainingAttempt.db.findById(s, id, transaction: tx);
    if (row == null || row.userId != _user(s)) {
      _fail('notFound', 'Attempt not found.');
    }
    return row;
  }

  Future<LearnerProfile> profile(Session session) async {
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      return await LearnerProfile.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(_user(session)),
            transaction: tx,
          ) ??
          await LearnerProfile.db.insertRow(
            session,
            LearnerProfile(
              userId: _user(session),
              displayName: 'Dancer',
              leaderboardVisible: false,
            ),
            transaction: tx,
          );
    });
  }

  Future<LearnerProfile> updateProfile(
    Session session,
    String name,
    bool visible,
  ) async {
    final display = name.trim();
    if (display.isEmpty ||
        display.length > 40 ||
        RegExp(r'[\x00-\x1f]').hasMatch(display)) {
      _fail('invalid', 'Use a name with 1 to 40 characters.');
    }
    final row = await profile(session);
    row.displayName = display;
    row.leaderboardVisible = visible;
    return LearnerProfile.db.updateRow(session, row);
  }

  Future<TrainingAttempt> begin(
    Session session,
    String routineId,
    String version,
    String modelVersion,
    String clientUuid,
    String? sectionId,
  ) async {
    if (!RegExp(r'^[a-zA-Z0-9-]{16,80}$').hasMatch(clientUuid)) {
      _fail('invalid', 'Invalid attempt identifier.');
    }
    final bundle = ContentStore.load(routineId);
    if (version != bundle.version || modelVersion != poseModelHash) {
      _fail('version', 'Download the current routine and pose model.');
    }
    if (sectionId != null &&
        !bundle.events.any((e) => e.sectionId == sectionId)) {
      _fail('section', 'This section has no reliable targets.');
    }
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      final prior = await TrainingAttempt.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(_user(session)) & t.clientUuid.equals(clientUuid),
        transaction: tx,
      );
      if (prior != null) {
        if (prior.contentVersion != version ||
            prior.routineId != routineId ||
            prior.sectionId != sectionId) {
          _fail('conflict', 'Attempt identifier already used for another run.');
        }
        return prior;
      }
      final now = DateTime.now().toUtc();
      return TrainingAttempt.db.insertRow(
        session,
        TrainingAttempt(
          userId: _user(session),
          clientUuid: clientUuid,
          routineId: routineId,
          contentVersion: version,
          modelVersion: modelVersion,
          mode: sectionId == null ? 'routine' : 'practice',
          sectionId: sectionId,
          ticket: base64UrlEncode(
            List.generate(32, (_) => Random.secure().nextInt(256)),
          ),
          createdAt: now,
          expiresAt: now.add(
            Duration(milliseconds: bundle.durationMs, minutes: 30),
          ),
          status: 'recording',
          nextChunk: 0,
          payloadBytes: 0,
        ),
        transaction: tx,
      );
    });
  }

  Future<int> upload(
    Session session,
    int attemptId,
    String ticket,
    int sequence,
    String payload,
  ) async {
    final bytes = utf8.encode(payload);
    if (sequence < 0 || bytes.length > 256 * 1024) {
      _fail('size', 'Chunk must be under 256 KiB.');
    }
    List<TrainingObservation> observations;
    try {
      observations = jsonList(
        jsonDecode(payload),
      ).map(TrainingObservation.fromJson).toList();
      if (observations.isEmpty || observations.length > 200) {
        throw const FormatException();
      }
      for (var i = 1; i < observations.length; i++) {
        if (observations[i].sequence <= observations[i - 1].sequence ||
            observations[i].timeMs <= observations[i - 1].timeMs) {
          throw const FormatException();
        }
      }
    } catch (_) {
      _fail('invalid', 'Invalid pose evidence.');
    }
    final digest = sha256.convert(bytes).toString();
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      final attempt = await _owned(session, attemptId, tx);
      if (ticket != attempt.ticket) _fail('ticket', 'Invalid run ticket.');
      final old = await TrainingChunk.db.findFirstRow(
        session,
        where: (t) =>
            t.attemptId.equals(attemptId) & t.sequence.equals(sequence),
        transaction: tx,
      );
      if (old != null) {
        if (old.digest != digest) {
          _fail('conflict', 'This chunk sequence contains different evidence.');
        }
        return attempt.nextChunk;
      }
      if (attempt.status != 'recording') {
        _fail('finalized', 'This attempt is already final.');
      }
      if (sequence != attempt.nextChunk) {
        _fail('sequence', 'Upload the next expected chunk.');
      }
      if (attempt.payloadBytes + bytes.length > 6 * 1024 * 1024) {
        _fail('size', 'Attempt evidence exceeds 6 MiB.');
      }
      await TrainingChunk.db.insertRow(
        session,
        TrainingChunk(
          attemptId: attemptId,
          sequence: sequence,
          digest: digest,
          payloadJson: payload,
        ),
        transaction: tx,
      );
      attempt.nextChunk++;
      attempt.payloadBytes += bytes.length;
      await TrainingAttempt.db.updateRow(session, attempt, transaction: tx);
      return attempt.nextChunk;
    });
  }

  Future<TrainingAttempt> finalize(
    Session session,
    int attemptId,
    String ticket,
    int expectedChunks,
    int finalTimeMs,
    bool interrupted,
  ) async {
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      final attempt = await _owned(session, attemptId, tx);
      if (attempt.ticket != ticket) _fail('ticket', 'Invalid run ticket.');
      if (attempt.status == 'complete') return attempt;
      if (expectedChunks < 1 || expectedChunks != attempt.nextChunk) {
        _fail('incomplete', 'Upload all evidence before finalizing.');
      }
      final bundle = ContentStore.load(attempt.routineId);
      if (bundle.version != attempt.contentVersion) {
        _fail('version', 'The referenced routine version is unavailable.');
      }
      final end = attempt.sectionId == null
          ? bundle.durationMs
          : wholeNumber(
              bundle.sections.firstWhere(
                (s) => s['id'] == attempt.sectionId,
              )['endMs'],
            );
      if (finalTimeMs < end - 500 || finalTimeMs > end + 1000) {
        _fail('incomplete', 'The run did not reach the end.');
      }
      final chunks = await TrainingChunk.db.find(
        session,
        where: (t) => t.attemptId.equals(attemptId),
        orderBy: (t) => t.sequence,
        transaction: tx,
      );
      final observations = chunks
          .expand(
            (c) => jsonList(
              jsonDecode(c.payloadJson),
            ).map(TrainingObservation.fromJson),
          )
          .toList();
      Map<String, dynamic> result;
      try {
        result = scoreTraining(
          bundle,
          observations,
          sectionId: attempt.sectionId,
          interrupted: interrupted,
        );
      } catch (_) {
        _fail('invalid', 'The evidence timeline is invalid.');
      }
      // A device trial must approve a model/configuration before ranked scores
      // are enabled in production. Development content remains unranked.
      if (DateTime.now().isAfter(attempt.expiresAt)) {
        result['ranked'] = false;
        result['rankReason'] = 'Upload grace period expired';
      }
      attempt.status = 'complete';
      attempt.resultJson = jsonEncode(result);
      await TrainingAttempt.db.updateRow(session, attempt, transaction: tx);
      if (result['ranked'] == true) {
        final board =
            '${attempt.contentVersion}:$scoringVersion:${attempt.modelVersion}';
        final prior = await TrainingBest.db.findFirstRow(
          session,
          where: (t) =>
              t.userId.equals(_user(session)) & t.boardKey.equals(board),
          transaction: tx,
        );
        final score = wholeNumber(result['totalScore']);
        if (prior == null) {
          await TrainingBest.db.insertRow(
            session,
            TrainingBest(
              userId: _user(session),
              boardKey: board,
              attemptId: attemptId,
              score: score,
              achievedAt: DateTime.now().toUtc(),
            ),
            transaction: tx,
          );
        } else if (score > prior.score) {
          prior.score = score;
          prior.attemptId = attemptId;
          prior.achievedAt = DateTime.now().toUtc();
          await TrainingBest.db.updateRow(session, prior, transaction: tx);
        }
      }
      return attempt;
    });
  }

  Future<List<TrainingAttempt>> history(
    Session session, {
    int offset = 0,
  }) async {
    if (offset < 0 || offset > 100000) _fail('invalid', 'Invalid page.');
    return TrainingAttempt.db.find(
      session,
      where: (t) =>
          t.userId.equals(_user(session)) & t.status.equals('complete'),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 30,
      offset: offset,
    );
  }

  Future<List<BoardEntry>> leaderboard(
    Session session,
    String routineId,
  ) async {
    final bundle = ContentStore.load(routineId);
    final board = '${bundle.version}:$scoringVersion:$poseModelHash';
    final rows = await session.db.unsafeQuery(
      '''SELECT p."displayName", b.score, b."achievedAt"
      FROM training_best b JOIN learner_profile p ON p."userId"=b."userId"
      WHERE b."boardKey"=@board AND p."leaderboardVisible"=true
      ORDER BY b.score DESC,b."achievedAt",b.id LIMIT 50''',
      parameters: QueryParameters.named({'board': board}),
    );
    return rows
        .map(
          (r) => BoardEntry(
            displayName: r[0] as String,
            score: r[1] as int,
            achievedAt: r[2] as DateTime,
          ),
        )
        .toList();
  }

  Future<PracticeAssignment> practice(
    Session session,
    int sourceAttemptId,
  ) async {
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      final attempt = await _owned(session, sourceAttemptId, tx);
      if (attempt.resultJson == null || attempt.sectionId != null) {
        _fail('incomplete', 'Complete a full routine first.');
      }
      final result = jsonObject(jsonDecode(attempt.resultJson!));
      if (result['sectionId'] == null) {
        _fail('practice', result['feedback'] as String);
      }
      final prior = await PracticeAssignment.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(_user(session)) &
            t.sourceAttemptId.equals(sourceAttemptId),
        transaction: tx,
      );
      return prior ??
          await PracticeAssignment.db.insertRow(
            session,
            PracticeAssignment(
              userId: _user(session),
              sourceAttemptId: sourceAttemptId,
              routineId: attempt.routineId,
              contentVersion: attempt.contentVersion,
              sectionId: result['sectionId'] as String,
              completedRepetitions: 0,
              completed: false,
            ),
            transaction: tx,
          );
    });
  }

  Future<PracticeAssignment> completeRepetition(
    Session session,
    int assignmentId,
    int attemptId,
  ) async {
    return session.db.transaction((tx) async {
      await _lock(session, tx);
      final assignment = await PracticeAssignment.db.findById(
        session,
        assignmentId,
        transaction: tx,
      );
      if (assignment == null || assignment.userId != _user(session)) {
        _fail('notFound', 'Assignment not found.');
      }
      final attempt = await _owned(session, attemptId, tx);
      if (attempt.status != 'complete' ||
          attempt.routineId != assignment.routineId ||
          attempt.sectionId != assignment.sectionId ||
          attempt.contentVersion != assignment.contentVersion) {
        _fail('practice', 'Complete this section with matching content first.');
      }
      final result = jsonObject(jsonDecode(attempt.resultJson!));
      if (result['judgmentAvailable'] != true) {
        _fail('coverage', 'Keep your body visible and repeat the section.');
      }
      final old = await PracticeRepetition.db.findFirstRow(
        session,
        where: (t) => t.attemptId.equals(attemptId),
        transaction: tx,
      );
      if (old != null) {
        if (old.assignmentId != assignmentId) {
          _fail(
            'practice',
            'This attempt already counts toward another drill.',
          );
        }
        return assignment;
      }
      if (assignment.completed) return assignment;
      await PracticeRepetition.db.insertRow(
        session,
        PracticeRepetition(assignmentId: assignmentId, attemptId: attemptId),
        transaction: tx,
      );
      assignment.completedRepetitions++;
      assignment.completed = assignment.completedRepetitions >= 3;
      return PracticeAssignment.db.updateRow(
        session,
        assignment,
        transaction: tx,
      );
    });
  }
}
