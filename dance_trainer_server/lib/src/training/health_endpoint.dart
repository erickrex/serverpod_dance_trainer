import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'content_store.dart';

class HealthEndpoint extends Endpoint {
  Future<String> ready(Session session) async {
    await session.db.unsafeQuery('SELECT 1');
    if (ContentStore.catalog().isEmpty ||
        !await File(
          '${ContentStore.directory.path}/models/yolov8n-pose_xnnpack.pte',
        ).exists()) {
      throw StateError('Runtime content is unavailable.');
    }
    return 'ok';
  }
}
