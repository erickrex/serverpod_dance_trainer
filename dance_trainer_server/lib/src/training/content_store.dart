import 'dart:io';
import 'dart:convert';
import 'package:dance_domain/dance_domain.dart';
import '../generated/protocol.dart';

class ContentStore {
  static Directory get directory => Directory(
    Platform.environment['DANCE_CONTENT_DIR'] ??
        (Directory('../content/compiled').existsSync()
            ? '../content'
            : 'content'),
  );
  static TrainingBundle load(
    String routineId, {
    String? version,
    Directory? contentDirectory,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(routineId)) {
      throw TrainingError(code: 'content', message: 'Unknown routine.');
    }
    if (version != null && !RegExp(r'^[a-f0-9]{64}$').hasMatch(version)) {
      throw TrainingError(code: 'version', message: 'Invalid content version.');
    }
    final root = contentDirectory ?? directory;
    var file = File('${root.path}/compiled/$routineId.json');
    if (version != null) {
      final archived = File(
        '${root.path}/compiled/versions/$routineId/$version.json',
      );
      if (archived.existsSync()) file = archived;
    }
    if (!file.existsSync()) {
      throw TrainingError(code: 'content', message: 'Routine is unavailable.');
    }
    final bundle = TrainingBundle.fromJson(jsonDecode(file.readAsStringSync()));
    if (bundle.id != routineId ||
        (version != null && bundle.version != version)) {
      throw TrainingError(
        code: 'version',
        message: 'The referenced routine version is unavailable.',
      );
    }
    return bundle;
  }

  static List<TrainingCatalogEntry> catalog() {
    final folder = Directory('${directory.path}/compiled');
    if (!folder.existsSync()) {
      throw TrainingError(
        code: 'content',
        message: 'Compile the content before starting the server.',
      );
    }
    final files =
        folder
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final file in files)
        (() {
          final text = file.readAsStringSync();
          final bundle = TrainingBundle.fromJson(jsonDecode(text));
          return TrainingCatalogEntry(
            routineId: bundle.id,
            title: bundle.title,
            durationMs: bundle.durationMs,
            version: bundle.version,
            bundleJson: text,
            mediaPath: '/content/source/${bundle.id}/${bundle.id}.mp4',
            mediaSha256: bundle.mediaSha256,
            rankedAvailable: bundle.reviewed,
          );
        })(),
    ];
  }
}
