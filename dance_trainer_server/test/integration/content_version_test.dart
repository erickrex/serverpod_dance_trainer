import 'dart:convert';
import 'dart:io';
import 'package:dance_trainer_server/src/generated/protocol.dart';
import 'package:dance_trainer_server/src/training/content_store.dart';
import 'package:test/test.dart';

void main() {
  test(
    'version lookup uses an archived bundle and fails closed for unknown versions',
    () async {
      final current = ContentStore.load('howdeepisyourlove');
      final archive = File(
        '${ContentStore.directory.path}/compiled/versions/${current.id}/${current.version}.json',
      );
      expect(
        await archive.exists(),
        isTrue,
        reason: 'Run the content compiler before this test.',
      );
      expect(
        ContentStore.load(current.id, version: current.version).toJson(),
        jsonDecode(await archive.readAsString()),
      );
      final directory = await Directory.systemTemp.createTemp(
        'dance-version-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final archived = File(
        '${directory.path}/compiled/versions/${current.id}/${current.version}.json',
      );
      await archived.parent.create(recursive: true);
      await archive.copy(archived.path);
      final replacement = {
        ...current.toJson(),
        'version': 'e' * 64,
        'title': 'Replacement catalog version',
      };
      await File(
        '${directory.path}/compiled/${current.id}.json',
      ).writeAsString(jsonEncode(replacement));
      expect(
        ContentStore.load(current.id, contentDirectory: directory).title,
        'Replacement catalog version',
      );
      expect(
        ContentStore.load(
          current.id,
          version: current.version,
          contentDirectory: directory,
        ).title,
        current.title,
      );
      expect(
        () => ContentStore.load(current.id, version: 'f' * 64),
        throwsA(isA<TrainingError>()),
      );
      expect(
        () => ContentStore.load(current.id, version: '../../outside'),
        throwsA(isA<TrainingError>()),
      );
    },
  );
}
