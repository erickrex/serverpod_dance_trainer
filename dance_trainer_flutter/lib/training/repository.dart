import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:sqflite/sqflite.dart';

class TrainingRepository {
  TrainingRepository(
    this.client,
    this.apiUrl, {
    this.storageDirectory,
    this.databaseFactoryOverride,
  });
  final Client client;
  final String apiUrl;
  final Directory? storageDirectory;
  final DatabaseFactory? databaseFactoryOverride;
  Future<Database>? _db;
  final _syncs = <String, Future<TrainingAttempt>>{};
  final _downloads = <String, Future<File>>{};
  bool _deleting = false;
  Future<Directory> directory() async =>
      storageDirectory ?? await getApplicationSupportDirectory();
  String get user => client.auth.authInfo?.authUserId.toString() ?? '';
  Uri asset(String path) {
    const configured = String.fromEnvironment('ASSET_URL');
    final base = configured.isNotEmpty
        ? Uri.parse(configured)
        : Uri.parse(apiUrl).replace(port: 8082, path: '/');
    return base.resolve(path);
  }

  Future<Database> database() => _db ??= _openDatabase();
  Future<Database> _openDatabase() async {
    final root = await directory();
    await root.create(recursive: true);
    return (databaseFactoryOverride ?? databaseFactory).openDatabase(
      '${root.path}/attempts.db',
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE runs (id INTEGER PRIMARY KEY, user TEXT NOT NULL, attempt TEXT NOT NULL, endMs INTEGER, interrupted INTEGER NOT NULL DEFAULT 0, assignment INTEGER, result TEXT)',
          );
          await db.execute(
            'CREATE TABLE observations (run INTEGER NOT NULL, sequence INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(run,sequence))',
          );
          await _upgrade(db);
          await db.execute('ALTER TABLE runs ADD COLUMN entry TEXT');
        },
        onUpgrade: (db, old, next) async {
          if (old < 2) await _upgrade(db);
          if (old < 3) {
            await db.execute('ALTER TABLE runs ADD COLUMN entry TEXT');
          }
        },
      ),
    );
  }

  Future<void> _upgrade(Database db) async {
    await db.execute(
      'ALTER TABLE runs ADD COLUMN acknowledged INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE runs ADD COLUMN retries INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE runs ADD COLUMN retryAt INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute('ALTER TABLE runs ADD COLUMN error TEXT');
    await db.execute('CREATE INDEX runs_pending ON runs(user, result, endMs)');
  }

  void _checkOwner(String owner) {
    if (_deleting || owner.isEmpty || user != owner) {
      throw StateError('Sign back in to the original account to sync.');
    }
  }

  Future<File> download(
    String path,
    String expected, {
    void Function(double)? progress,
  }) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected)) {
      throw StateError('Invalid asset checksum.');
    }
    final existing = _downloads[expected];
    if (existing != null) return existing;
    final task = _download(path, expected, progress: progress);
    _downloads[expected] = task;
    try {
      return await task;
    } finally {
      _downloads.remove(expected);
    }
  }

  Future<File> _download(
    String path,
    String expected, {
    void Function(double)? progress,
  }) async {
    final root = await directory();
    await root.create(recursive: true);
    final file = File(
      '${root.path}/$expected${path.endsWith('.mp4') ? '.mp4' : '.pte'}',
    );
    if (await file.exists() &&
        (await sha256.bind(file.openRead()).first).toString() == expected) {
      return file;
    }
    final part = File('${file.path}.part');
    final request = http.Request('GET', asset(path));
    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw StateError('Download failed. Check the server connection.');
    }
    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        received += chunk.length;
        if (received > 250 * 1024 * 1024) {
          throw StateError('Asset exceeds download limit.');
        }
        progress?.call(
          response.contentLength == null
              ? 0
              : (received / response.contentLength!).clamp(0.0, 1.0),
        );
      }
      await sink.close();
      if ((await sha256.bind(part.openRead()).first).toString() != expected) {
        throw StateError(
          'Download checksum does not match. Retry the download.',
        );
      }
      return await part.rename(file.path);
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  Future<Uint8List> model() async => (await download(
    '/content/models/yolov8n-pose_xnnpack.pte',
    poseModelHash,
  )).readAsBytes();
  Future<void> saveRun(
    TrainingAttempt attempt, {
    int? assignmentId,
    TrainingCatalogEntry? entry,
  }) async {
    final owner = user;
    _checkOwner(owner);
    if (attempt.userId != owner) {
      throw StateError('This run belongs to another account.');
    }
    final db = await database();
    _checkOwner(owner);
    await db.insert('runs', {
      'id': attempt.id,
      'user': owner,
      'attempt': jsonEncode(attempt.toJson()),
      'assignment': assignmentId,
      'entry': entry == null ? null : jsonEncode(entry.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> append(int run, TrainingObservation observation) async {
    final owner = user;
    final db = await database();
    await db.transaction((tx) async {
      _checkOwner(owner);
      final rows = await tx.query(
        'runs',
        where: 'id=? AND user=? AND endMs IS NULL',
        whereArgs: [run, owner],
      );
      if (rows.isEmpty) throw StateError('This run is no longer recording.');
      await tx.insert('observations', {
        'run': run,
        'sequence': observation.sequence,
        'payload': jsonEncode(observation.toJson()),
      });
    });
  }

  Future<void> markComplete(int run, int endMs, bool interrupted) async {
    final owner = user;
    final db = await database();
    _checkOwner(owner);
    final changed = await db.update(
      'runs',
      {'endMs': endMs, 'interrupted': interrupted ? 1 : 0},
      where: 'id=? AND user=? AND endMs IS NULL',
      whereArgs: [run, owner],
    );
    if (changed != 1) {
      throw StateError(
        'This run is already complete or belongs to another account.',
      );
    }
  }

  Future<TrainingAttempt> sync(int run) async {
    final owner = user;
    _checkOwner(owner);
    final key = '$owner:$run';
    final active = _syncs[key];
    if (active != null) return active;
    final task = _sync(run, owner);
    _syncs[key] = task;
    try {
      return await task;
    } catch (error) {
      final db = await database();
      final rows = await db.query(
        'runs',
        where: 'id=? AND user=?',
        whereArgs: [run, owner],
      );
      if (rows.isNotEmpty) {
        final retries = ((rows.single['retries'] as int) + 1).clamp(1, 7);
        await db.update(
          'runs',
          {
            'retries': retries,
            'retryAt':
                DateTime.now().millisecondsSinceEpoch +
                (5 * (1 << (retries - 1))).clamp(5, 300) * 1000,
            'error': error is TrainingError
                ? error.message
                : 'Upload failed. Sign in and check your connection, then retry.',
          },
          where: 'id=? AND user=?',
          whereArgs: [run, owner],
        );
      }
      rethrow;
    } finally {
      _syncs.remove(key);
    }
  }

  Future<TrainingAttempt> _sync(int run, String owner) async {
    final db = await database();
    final rows = await db.query(
      'runs',
      where: 'id=? AND user=?',
      whereArgs: [run, owner],
    );
    if (rows.isEmpty) throw StateError('This run belongs to another account.');
    final row = rows.single;
    if (row['endMs'] == null) throw StateError('This run was not completed.');
    final attempt = TrainingAttempt.fromJson(
      jsonObject(jsonDecode(row['attempt'] as String)),
    );
    final payload = await db.query(
      'observations',
      where: 'run=?',
      whereArgs: [run],
      orderBy: 'sequence',
    );
    _checkOwner(owner);
    var result = await client.training.resumeUpload(run, attempt.ticket);
    _checkOwner(owner);
    final chunks = (payload.length / 50).ceil();
    if (result.status != 'complete' && result.nextChunk > chunks) {
      throw StateError(
        'Local evidence is incomplete. Keep this run and contact support.',
      );
    }
    for (
      var chunk = result.nextChunk;
      result.status != 'complete' && chunk < chunks;
      chunk++
    ) {
      _checkOwner(owner);
      final start = chunk * 50;
      final end = (start + 50).clamp(0, payload.length);
      await client.training.upload(
        run,
        attempt.ticket,
        chunk,
        jsonEncode([
          for (final item in payload.sublist(start, end))
            jsonDecode(item['payload'] as String),
        ]),
      );
      _checkOwner(owner);
      await db.update(
        'runs',
        {'acknowledged': chunk + 1},
        where: 'id=? AND user=?',
        whereArgs: [run, owner],
      );
    }
    _checkOwner(owner);
    if (result.status != 'complete') {
      result = await client.training.finalize(
        run,
        attempt.ticket,
        chunks,
        row['endMs'] as int,
        row['interrupted'] == 1,
      );
    }
    _checkOwner(owner);
    if (row['assignment'] != null &&
        jsonObject(jsonDecode(result.resultJson!))['judgmentAvailable'] ==
            true) {
      await client.training.completeRepetition(row['assignment'] as int, run);
    }
    _checkOwner(owner);
    await db.transaction((tx) async {
      await tx.update(
        'runs',
        {
          'result': result.resultJson,
          'error': null,
          'retryAt': 0,
          'retries': 0,
        },
        where: 'id=? AND user=?',
        whereArgs: [run, owner],
      );
      await tx.delete('observations', where: 'run=?', whereArgs: [run]);
    });
    return result;
  }

  Future<SyncReport> syncPending({bool force = false}) async {
    final owner = user;
    _checkOwner(owner);
    final db = await database();
    final rows = await db.query(
      'runs',
      where: 'user=? AND endMs IS NOT NULL AND result IS NULL',
      whereArgs: [owner],
      orderBy: 'id',
    );
    var saved = 0, pending = 0;
    for (final row in rows) {
      if (user != owner || _deleting) break;
      if (!force &&
          (row['retryAt'] as int) > DateTime.now().millisecondsSinceEpoch) {
        pending++;
        continue;
      }
      try {
        await sync(row['id'] as int);
        saved++;
      } catch (_) {
        pending++;
      }
    }
    return SyncReport(saved, pending);
  }

  Future<List<Map<String, Object?>>> localRuns() async {
    final owner = user;
    final db = await database();
    _checkOwner(owner);
    return db.query(
      'runs',
      where: 'user=? AND result IS NULL',
      whereArgs: [owner],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>> provisionalResult(int run) async {
    final owner = user;
    final db = await database();
    final rows = await db.query(
      'runs',
      where: 'id=? AND user=? AND endMs IS NOT NULL',
      whereArgs: [run, owner],
    );
    _checkOwner(owner);
    if (rows.isEmpty || rows.single['entry'] == null) {
      throw StateError(
        'This older run needs a connection to restore its result.',
      );
    }
    final row = rows.single;
    if (row['result'] != null) {
      return jsonObject(jsonDecode(row['result'] as String));
    }
    final attempt = TrainingAttempt.fromJson(
      jsonObject(jsonDecode(row['attempt'] as String)),
    );
    final entry = TrainingCatalogEntry.fromJson(
      jsonObject(jsonDecode(row['entry'] as String)),
    );
    final observations = await db.query(
      'observations',
      where: 'run=?',
      whereArgs: [run],
      orderBy: 'sequence',
    );
    _checkOwner(owner);
    return scoreTraining(
      TrainingBundle.fromJson(jsonDecode(entry.bundleJson)),
      [
        for (final observation in observations)
          TrainingObservation.fromJson(
            jsonDecode(observation['payload'] as String),
          ),
      ],
      sectionId: attempt.sectionId,
      interrupted: row['interrupted'] == 1,
    );
  }

  Future<void> discardLocalRun(int run) async {
    final owner = user;
    if (_syncs.containsKey('$owner:$run')) {
      throw StateError('Wait for this upload to finish.');
    }
    final db = await database();
    await db.transaction((tx) async {
      _checkOwner(owner);
      final rows = await tx.query(
        'runs',
        where: 'id=? AND user=?',
        whereArgs: [run, owner],
      );
      if (rows.isEmpty) return;
      await tx.delete('observations', where: 'run=?', whereArgs: [run]);
      await tx.delete(
        'runs',
        where: 'id=? AND user=?',
        whereArgs: [run, owner],
      );
    });
  }

  Future<void> deleteAccount() async {
    final owner = user;
    _checkOwner(owner);
    _deleting = true;
    try {
      await Future.wait(
        _syncs.values.map((f) => f.then<void>((_) {}, onError: (Object _) {})),
      );
      if (user != owner) throw StateError('Account changed. Sign in again.');
      final db = await database();
      await db.transaction((tx) async {
        if (user != owner) throw StateError('Account changed. Sign in again.');
        await tx.rawDelete(
          'DELETE FROM observations WHERE run IN (SELECT id FROM runs WHERE user=?)',
          [owner],
        );
        await tx.delete('runs', where: 'user=?', whereArgs: [owner]);
      });
      // Clear the confirmed local deletion before revoking the account. A lost
      // response must not leave evidence behind an identity that cannot sign in.
      try {
        if (user != owner) throw StateError('Account changed.');
        await client.training.deleteAccount();
      } catch (_) {
        throw StateError(
          'Local training data was removed. Account deletion was not confirmed. Sign in to the original account and retry deleting it.',
        );
      }
    } finally {
      _deleting = false;
    }
  }

  Future<List<CachedAsset>> cachedAssets() async {
    final root = await directory();
    if (!await root.exists()) return [];
    final files = await root
        .list()
        .where(
          (f) =>
              f is File &&
              RegExp(r'/[a-f0-9]{64}\.(mp4|pte)(\.part)?$').hasMatch(f.path),
        )
        .cast<File>()
        .toList();
    return [for (final file in files) CachedAsset(file, await file.length())];
  }

  Future<void> removeAsset(CachedAsset asset) async {
    final name = asset.file.uri.pathSegments.last;
    if (_downloads.containsKey(name.split('.').first)) {
      throw StateError('Wait for the download to finish.');
    }
    final root = await directory();
    if (asset.file.parent.path != root.path) {
      throw StateError('Invalid cached asset.');
    }
    if (await asset.file.exists()) await asset.file.delete();
  }
}

class SyncReport {
  const SyncReport(this.saved, this.pending);
  final int saved, pending;
}

class CachedAsset {
  const CachedAsset(this.file, this.bytes);
  final File file;
  final int bytes;
}
