import 'dart:convert';
import 'dart:io';
import 'package:dance_domain/dance_domain.dart';
import 'package:crypto/crypto.dart';

// Run from the repository root. Derives development pose checkpoints; these
// are explicitly unreviewed and cannot produce ranked results.
Future<void> main(List<String> args) async {
  for (final routine in ['howdeepisyourlove', '30minutos']) {
    final source = File('content/source/$routine/$routine.json');
    final video = File('content/source/$routine/$routine.mp4');
    final data = jsonObject(jsonDecode(await source.readAsString()));
    final probe = await Process.run('ffprobe', [
      '-v',
      'error',
      '-select_streams',
      'v:0',
      '-show_entries',
      'stream=width,height,duration',
      '-of',
      'json',
      video.path,
    ]);
    if (probe.exitCode != 0) throw StateError('ffprobe failed for $routine');
    final stream = jsonObject(
      jsonList(jsonObject(jsonDecode(probe.stdout as String))['streams']).first,
    );
    final width = finiteNumber(stream['width']),
        height = finiteNumber(stream['height']);
    final durationMs = (double.parse(stream['duration'] as String) * 1000)
        .round();
    final fps = finiteNumber(data['fps']);
    if (fps <= 0) throw const FormatException('Invalid frame rate.');
    final frames = jsonList(data['frames']);
    if (frames.length != data['totalFrames'])
      throw const FormatException('Frame count mismatch.');
    final parsed = <LandmarkFrame>[];
    var lastTime = -1.0;
    final exclusions = <List<int>>[];
    Point2D? previousHip;
    for (var i = 0; i < frames.length; i++) {
      final f = jsonObject(frames[i]);
      final t = finiteNumber(f['timestamp']);
      if (t <= lastTime ||
          (i > 0 && ((t - lastTime) - 1 / fps).abs() > 0.05 / fps))
        throw const FormatException('Irregular timeline.');
      lastTime = t;
      final k = jsonObject(f['keypoints']);
      final points = <List<Object?>>[];
      for (final name in kLandmarkNames) {
        final p = jsonObject(k[name]);
        var c = finiteNumber(p['confidence']);
        if (p['validity'] == 'absent' || c == 0) {
          points.add([null, null, 0]);
          continue;
        }
        if (p['validity'] == 'lowConfidence' && c >= 0.5) c = 0.499;
        points.add([p['x'], p['y'], c]);
      }
      final pose = decodeLandmarks(points, width, height);
      parsed.add(pose);
      if (pose.hasCoreCoverage) {
        final hip = Point2D(
          (pose['leftHip'].x! + pose['rightHip'].x!) / 2 / width,
          (pose['leftHip'].y! + pose['rightHip'].y!) / 2 / height,
        );
        if (previousHip != null && previousHip.distanceTo(hip) > 0.15)
          exclusions.add([(t * 1000 - 500).round(), (t * 1000 + 500).round()]);
        previousHip = hip;
      } else {
        previousHip = null;
        exclusions.add([(t * 1000 - 100).round(), (t * 1000 + 100).round()]);
      }
    }
    if ((lastTime * 1000 - durationMs).abs() > 1500 / fps)
      throw const FormatException('Video/pose duration mismatch.');
    final sections = <Map<String, dynamic>>[];
    for (var start = 0; start < durationMs; start += 8000) {
      sections.add({
        'id': 'section-${start ~/ 8000 + 1}',
        'title': 'Section ${start ~/ 8000 + 1}',
        'startMs': start,
        'endMs': (start + 8000).clamp(0, durationMs),
        'leadInMs': 2000,
      });
    }
    final events = <ReferenceEvent>[];
    for (var ms = 1000; ms < durationMs - 500; ms += 1000) {
      if (exclusions.any((span) => ms >= span[0] && ms <= span[1])) continue;
      final pose =
          parsed[(ms / 1000 * fps).round().clamp(0, parsed.length - 1)];
      if (!pose.allObserved(trainingLandmarks)) continue;
      final features = normalizeFeatures(pose);
      if (features == null) continue;
      final selected = NormalizedFeatures(
        jointAngles: features.jointAngles,
        limbDirections: features.limbDirections,
        scaledPositions: {
          for (final name in [
            'leftWrist',
            'rightWrist',
            'leftAnkle',
            'rightAnkle',
          ])
            name: features.scaledPositions[name],
        },
        bodyScale: features.bodyScale,
      );
      events.add(
        ReferenceEvent(
          id: 'pose-$ms',
          sectionId: 'section-${ms ~/ 8000 + 1}',
          targetContentTime: Duration(milliseconds: ms),
          weight: 1,
          matchWindow: const Duration(milliseconds: 300),
          timingFullCreditWindow: const Duration(milliseconds: 100),
          timingZeroCreditWindow: const Duration(milliseconds: 300),
          requiredLandmarks: trainingLandmarks,
          referenceFeatures: selected,
        ),
      );
    }
    final mediaHash = (await sha256.bind(video.openRead()).first).toString();
    final sourceHash = (await sha256.bind(source.openRead()).first).toString();
    final version = sha256
        .convert(
          utf8.encode('$sourceHash:$mediaHash:$scoringVersion:compiler-1'),
        )
        .toString();
    final bundle = TrainingBundle(
      id: routine,
      title: routine == '30minutos' ? '30 minutos' : 'How deep is your love',
      version: version,
      durationMs: durationMs,
      mediaSha256: mediaHash,
      reviewed: false,
      events: events,
      sections: sections,
    );
    final encoded = jsonEncode(bundle.toJson());
    await File('content/compiled/$routine.json').writeAsString(encoded);
    await File('content/annotations/$routine.development.json').writeAsString(
      jsonEncode({
        'reviewed': false,
        'sourceSha256': sourceHash,
        'compiler': 'compiler-1',
        'playbackMaster': 'mp4-embedded-audio',
        'note':
            'Automatic pose checkpoints and time sections, not reviewed musical beat annotations.',
        'exclusionIntervalsMs': exclusions,
        'bundleSha256': sha256.convert(utf8.encode(encoded)).toString(),
      }),
    );
    stdout.writeln(
      '$routine: ${events.length} pose targets, ${sections.length} sections, unranked development content',
    );
  }
}
