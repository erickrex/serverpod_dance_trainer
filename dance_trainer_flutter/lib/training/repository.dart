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
  TrainingRepository(this.client, this.apiUrl);
  final Client client;
  final String apiUrl;
  Database? _db;
  String get user => client.auth.authInfo?.authUserId.toString() ?? '';
  Uri asset(String path) {
    const configured = String.fromEnvironment('ASSET_URL');
    final base = configured.isNotEmpty
        ? Uri.parse(configured)
        : Uri.parse(apiUrl).replace(port: 8082, path: '/');
    return base.resolve(path);
  }

  Future<Database> database() async {
    if (_db != null) return _db!;
    final root = await getApplicationSupportDirectory();
    return _db = await openDatabase(
      '${root.path}/attempts.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE runs (id INTEGER PRIMARY KEY, user TEXT NOT NULL, attempt TEXT NOT NULL, endMs INTEGER, interrupted INTEGER NOT NULL DEFAULT 0, assignment INTEGER, result TEXT)',
        );
        await db.execute(
          'CREATE TABLE observations (run INTEGER NOT NULL, sequence INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(run,sequence))',
        );
      },
    );
  }

  Future<File> download(
    String path,
    String expected, {
    void Function(double)? progress,
  }) async {
    final root = await getApplicationSupportDirectory();
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
              : received / response.contentLength!,
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
  Future<void> saveRun(TrainingAttempt attempt, {int? assignmentId}) async {
    if (user.isEmpty) throw StateError('Sign in before dancing.');
    final db = await database();
    await db.insert('runs', {
      'id': attempt.id,
      'user': user,
      'attempt': jsonEncode(attempt.toJson()),
      'assignment': assignmentId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> append(int run, TrainingObservation observation) async {
    final db = await database();
    await db.insert('observations', {
      'run': run,
      'sequence': observation.sequence,
      'payload': jsonEncode(observation.toJson()),
    });
  }

  Future<void> markComplete(int run, int endMs, bool interrupted) async {
    final db = await database();
    await db.update(
      'runs',
      {'endMs': endMs, 'interrupted': interrupted ? 1 : 0},
      where: 'id=? AND user=?',
      whereArgs: [run, user],
    );
  }

  Future<TrainingAttempt> sync(int run) async {
    final db = await database();
    final owner = user;
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
    var chunk = 0;
    for (var start = 0; start < payload.length; start += 50) {
      if (user != owner) {
        throw StateError('Sign back in to the original account to sync.');
      }
      final end = (start + 50).clamp(0, payload.length);
      await client.training.upload(
        run,
        attempt.ticket,
        chunk++,
        jsonEncode([
          for (final item in payload.sublist(start, end))
            jsonDecode(item['payload'] as String),
        ]),
      );
    }
    if (user != owner) throw StateError('Account changed while syncing.');
    final result = await client.training.finalize(
      run,
      attempt.ticket,
      chunk,
      row['endMs'] as int,
      row['interrupted'] == 1,
    );
    if (row['assignment'] != null &&
        jsonObject(jsonDecode(result.resultJson!))['judgmentAvailable'] ==
            true) {
      await client.training.completeRepetition(row['assignment'] as int, run);
    }
    await db.update(
      'runs',
      {'result': result.resultJson},
      where: 'id=? AND user=?',
      whereArgs: [run, owner],
    );
    return result;
  }

  Future<int> syncPending() async {
    final db = await database();
    final rows = await db.query(
      'runs',
      where: 'user=? AND endMs IS NOT NULL AND result IS NULL',
      whereArgs: [user],
    );
    var saved = 0;
    for (final row in rows) {
      await sync(row['id'] as int);
      saved++;
    }
    return saved;
  }
}
