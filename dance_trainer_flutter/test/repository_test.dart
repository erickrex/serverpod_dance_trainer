import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:dance_trainer_flutter/training/repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// STUB(3.16): Simulates transport failures only in tests. Real endpoint ownership,
// scoring and idempotency are covered by PostgreSQL integration tests.
class FakeTrainingClient extends Client {
  FakeTrainingClient() : super('http://localhost:1/');
  final attempts = <int, TrainingAttempt>{};
  final uploads = <int>[];
  final blocked = <int>{};
  bool loseAcknowledgment = false;
  void Function()? afterResume;
  int finalizations = 0, repetitions = 0;
  bool failRepetition = false;
  bool failDeletion = false;

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (method == 'deleteAccount') {
      if (failDeletion) throw StateError('Deletion response lost');
      return null as T;
    }
    final id = args['attemptId'] as int;
    if (blocked.contains(id)) throw StateError('Disconnected');
    final attempt = attempts[id]!;
    switch (method) {
      case 'resumeUpload':
        afterResume?.call();
        return attempt.copyWith() as T;
      case 'upload':
        final sequence = args['sequence'] as int;
        uploads.add(sequence);
        expect(sequence, attempt.nextChunk);
        attempt.nextChunk++;
        if (loseAcknowledgment) {
          loseAcknowledgment = false;
          throw StateError('Connection lost after acceptance');
        }
        return attempt.nextChunk as T;
      case 'finalize':
        finalizations++;
        attempt.status = 'complete';
        attempt.resultJson = jsonEncode({
          'judgmentAvailable': false,
          'coverage': 0,
        });
        return attempt.copyWith() as T;
      case 'completeRepetition':
        repetitions++;
        if (failRepetition) throw StateError('Disconnected');
        return PracticeAssignment(
              id: 1,
              userId: 'alice',
              sourceAttemptId: 99,
              routineId: 'routine',
              contentVersion: 'v1',
              sectionId: 'section-1',
              completedRepetitions: 1,
              completed: false,
            )
            as T;
      default:
        throw StateError('Unexpected method $method');
    }
  }
}

// STUB(3.16): Supplies test account identity without platform secure storage.
// The production repository reads identity from Serverpod's session manager.
class FakeAccountRepository extends TrainingRepository {
  FakeAccountRepository(FakeTrainingClient client, Directory directory)
    : super(
        client,
        client.host,
        storageDirectory: directory,
        databaseFactoryOverride: databaseFactoryFfi,
      );
  String owner = 'alice';
  Uri? assetBase;
  @override
  String get user => owner;
  @override
  Uri asset(String path) => assetBase?.resolve(path) ?? super.asset(path);
}

TrainingAttempt attempt(int id) => TrainingAttempt(
  id: id,
  userId: 'alice',
  clientUuid: 'local-attempt-$id',
  routineId: 'routine',
  contentVersion: 'v1',
  modelVersion: poseModelHash,
  mode: 'routine',
  ticket: 'ticket-$id',
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2027),
  status: 'recording',
  nextChunk: 0,
  payloadBytes: 0,
);

TrainingObservation observation(int sequence) => TrainingObservation(
  timeMs: sequence * 100,
  sequence: sequence,
  segment: 0,
  width: 640,
  height: 480,
  points: [
    for (var i = 0; i < 17; i++) [null, null, 0],
  ],
);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late FakeTrainingClient client;
  late FakeAccountRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dance-outbox-test-');
    client = FakeTrainingClient();
    repository = FakeAccountRepository(client, directory);
  });
  tearDown(() async {
    await (await repository.database()).close();
    client.close();
    await directory.delete(recursive: true);
  });
  Future<void> record(int id, {int count = 51, int? assignment}) async {
    client.attempts[id] = attempt(id);
    await repository.saveRun(attempt(id), assignmentId: assignment);
    for (var i = 0; i < count; i++) {
      await repository.append(id, observation(i));
    }
    await repository.markComplete(id, 10000, false);
  }

  test(
    'database initialization is shared and completion freezes evidence',
    () async {
      final databases = await Future.wait([
        repository.database(),
        repository.database(),
      ]);
      expect(identical(databases[0], databases[1]), isTrue);
      await record(1);
      await expectLater(
        repository.append(1, observation(99)),
        throwsStateError,
      );
      await expectLater(
        repository.markComplete(1, 9000, true),
        throwsStateError,
      );
    },
  );
  test(
    'reopen after lost acknowledgement resumes after accepted chunk',
    () async {
      await record(1);
      client.loseAcknowledgment = true;
      await expectLater(repository.sync(1), throwsStateError);
      expect(client.uploads, [0]);
      await (await repository.database()).close();
      repository = FakeAccountRepository(client, directory);
      final saved = await repository.sync(1);
      expect(saved.status, 'complete');
      expect(client.uploads, [0, 1]);
      expect(client.finalizations, 1);
      expect(
        await (await repository.database()).query('observations'),
        isEmpty,
      );
    },
  );
  test(
    'one failed run does not block another and retry delay is persisted',
    () async {
      await record(1, count: 1);
      await record(2, count: 1);
      client.blocked.add(1);
      final report = await repository.syncPending();
      expect(report.saved, 1);
      expect(report.pending, 1);
      final row = (await repository.localRuns()).single;
      expect(
        row['retryAt'] as int,
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
      client.blocked.clear();
      expect((await repository.syncPending()).pending, 1);
      expect((await repository.syncPending(force: true)).saved, 1);
    },
  );
  test('concurrent sync calls share one upload and finalization', () async {
    await record(1);
    final results = await Future.wait([repository.sync(1), repository.sync(1)]);
    expect(results.every((r) => r.status == 'complete'), isTrue);
    expect(client.uploads, [0, 1]);
    expect(client.finalizations, 1);
  });
  test('account change during transport prevents subsequent writes', () async {
    await record(1);
    client.afterResume = () => repository.owner = 'bob';
    await expectLater(repository.sync(1), throwsStateError);
    expect(client.uploads, isEmpty);
    expect(await repository.localRuns(), isEmpty);
    await expectLater(repository.append(1, observation(100)), throwsStateError);
    await expectLater(repository.saveRun(attempt(3)), throwsStateError);
    repository.owner = 'alice';
    expect(await repository.localRuns(), hasLength(1));
  });
  test(
    'retry after finalization completes practice without reuploading',
    () async {
      await record(1, assignment: 1);
      client.attempts[1]!
        ..status = 'complete'
        ..resultJson = jsonEncode({'judgmentAvailable': true});
      client.failRepetition = true;
      await expectLater(repository.sync(1), throwsStateError);
      client.failRepetition = false;
      await repository.sync(1);
      expect(client.uploads, isEmpty);
      expect(client.finalizations, 0);
      expect(client.repetitions, 2);
      expect(await repository.localRuns(), isEmpty);
    },
  );
  test(
    'discard affects only the signed-in account and removes evidence',
    () async {
      await record(1);
      repository.owner = 'bob';
      await repository.discardLocalRun(1);
      repository.owner = 'alice';
      expect(await repository.localRuns(), hasLength(1));
      await repository.discardLocalRun(1);
      expect(await repository.localRuns(), isEmpty);
      expect(
        await (await repository.database()).query('observations'),
        isEmpty,
      );
    },
  );
  test(
    'download inventory reports partial files and excludes unrelated data',
    () async {
      final hash = 'a' * 64;
      await File('${directory.path}/$hash.mp4').writeAsBytes([1, 2, 3]);
      await File('${directory.path}/$hash.pte.part').writeAsBytes([4]);
      await File('${directory.path}/unrelated.txt').writeAsString('keep');
      final assets = await repository.cachedAssets();
      expect(assets.map((a) => a.bytes).reduce((a, b) => a + b), 4);
      for (final asset in assets) {
        await repository.removeAsset(asset);
      }
      expect(await repository.cachedAssets(), isEmpty);
      expect(await File('${directory.path}/unrelated.txt').exists(), isTrue);
      await expectLater(
        repository.download('/model', '../outside'),
        throwsStateError,
      );
    },
  );
  test(
    'existing version one databases migrate without losing pending observations',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        '${directory.path}/attempts.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE runs (id INTEGER PRIMARY KEY, user TEXT NOT NULL, attempt TEXT NOT NULL, endMs INTEGER, interrupted INTEGER NOT NULL DEFAULT 0, assignment INTEGER, result TEXT)',
            );
            await db.execute(
              'CREATE TABLE observations (run INTEGER NOT NULL, sequence INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(run,sequence))',
            );
          },
        ),
      );
      await db.insert('runs', {
        'id': 1,
        'user': 'alice',
        'attempt': jsonEncode(attempt(1).toJson()),
        'endMs': 10000,
      });
      await db.insert('observations', {
        'run': 1,
        'sequence': 0,
        'payload': jsonEncode(observation(0).toJson()),
      });
      await db.close();
      client.attempts[1] = attempt(1);
      expect((await repository.localRuns()).single['retries'], 0);
      expect((await repository.sync(1)).status, 'complete');
    },
  );
  test(
    'parallel downloads share one transfer and corrupted files are rejected',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      repository.assetBase = Uri.parse('http://127.0.0.1:${server.port}/');
      var requests = 0;
      final bytes = [1, 3, 5, 7];
      server.listen((request) async {
        requests++;
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      final digest = sha256.convert(bytes).toString();
      final files = await Future.wait([
        repository.download('/video.mp4', digest),
        repository.download('/video.mp4', digest),
      ]);
      expect(requests, 1);
      expect(files[0].path, files[1].path);
      await files[0].writeAsBytes([9]);
      await repository.download('/video.mp4', digest);
      expect(requests, 2);
      expect(await files[0].readAsBytes(), bytes);
      final wrong = 'f' * 64;
      await expectLater(
        repository.download('/video.mp4', wrong),
        throwsStateError,
      );
      expect(await File('${directory.path}/$wrong.mp4.part').exists(), false);
      expect(await File('${directory.path}/$wrong.mp4').exists(), false);
    },
  );
  test(
    'completed provisional results can be reconstructed offline after reopen',
    () async {
      final text = await File(
        '../content/compiled/howdeepisyourlove.json',
      ).readAsString();
      final bundle = TrainingBundle.fromJson(jsonDecode(text));
      final a = attempt(
        1,
      ).copyWith(routineId: bundle.id, contentVersion: bundle.version);
      await repository.saveRun(
        a,
        entry: TrainingCatalogEntry(
          routineId: bundle.id,
          title: bundle.title,
          durationMs: bundle.durationMs,
          version: bundle.version,
          bundleJson: text,
          mediaPath: '/video.mp4',
          mediaSha256: bundle.mediaSha256,
          rankedAvailable: false,
        ),
      );
      await repository.append(1, observation(0));
      await repository.markComplete(1, bundle.durationMs, false);
      await (await repository.database()).close();
      repository = FakeAccountRepository(client, directory);
      final result = await repository.provisionalResult(1);
      expect(result['judgmentAvailable'], false);
      expect(result['coverage'], 0);
      expect(result['totalScore'], 0);
      expect(result['contentVersion'], bundle.version);
    },
  );
  test(
    'confirmed deletion clears owned local data even when the server response is lost',
    () async {
      await record(1);
      repository.owner = 'bob';
      await repository.saveRun(attempt(2).copyWith(userId: 'bob'));
      repository.owner = 'alice';
      client.failDeletion = true;
      await expectLater(
        repository.deleteAccount(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not confirmed'),
          ),
        ),
      );
      expect(await repository.localRuns(), isEmpty);
      expect(
        await (await repository.database()).query('observations'),
        isEmpty,
      );
      repository.owner = 'bob';
      expect(await repository.localRuns(), hasLength(1));
      repository.owner = 'alice';
      client.failDeletion = false;
      await repository.deleteAccount();
    },
  );
}
