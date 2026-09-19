import '../pose/geometry.dart';
import '../pose/landmark.dart';
import '../scoring/attempt_score.dart';
import '../scoring/event_matching.dart';
import '../scoring/normalization.dart';

const scoringVersion = 'pose-v2-dev';
const poseModelHash =
    'a0d74638c8c055b09a5e906f341e4e8a8c8e1151758ceaa51e5581d4d682b1d1';
const trainingLandmarks = [
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object.');
  return Map<String, dynamic>.from(value);
}

double finiteNumber(Object? value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('Expected a finite number.');
  }
  return value.toDouble();
}

int wholeNumber(Object? value) {
  if (value is! int) throw const FormatException('Expected an integer.');
  return value;
}

List<dynamic> jsonList(Object? value) {
  if (value is! List) throw const FormatException('Expected a list.');
  return value;
}

/// Wire coordinates are normalized per image axis. Restoring width and height
/// before geometry avoids stretching the pose on non-square images.
LandmarkFrame decodeLandmarks(Object? data, double width, double height) {
  if (!width.isFinite ||
      !height.isFinite ||
      width <= 0 ||
      height <= 0 ||
      width > 8192 ||
      height > 8192) {
    throw const FormatException('Invalid image dimensions.');
  }
  final points = jsonList(data);
  if (points.length != 17) {
    throw const FormatException('Expected 17 landmarks.');
  }
  final result = <String, Landmark>{};
  for (var i = 0; i < 17; i++) {
    final point = jsonList(points[i]);
    if (point.length != 3) {
      throw const FormatException('Expected x, y, confidence.');
    }
    final confidence = finiteNumber(point[2]);
    if (confidence < 0 || confidence > 1) {
      throw const FormatException('Invalid confidence.');
    }
    if (point[0] == null && point[1] == null) {
      if (confidence != 0) {
        throw const FormatException(
          'Absent landmark must have zero confidence.',
        );
      }
      result[kLandmarkNames[i]] = Landmark.absent();
    } else {
      final x = finiteNumber(point[0]);
      final y = finiteNumber(point[1]);
      if (x < 0 || x > 1 || y < 0 || y > 1) {
        throw const FormatException('Coordinate outside image.');
      }
      result[kLandmarkNames[i]] = Landmark(
        x: x * width,
        y: y * height,
        confidence: confidence,
        validity: confidence >= 0.5
            ? LandmarkValidity.observed
            : LandmarkValidity.lowConfidence,
      );
    }
  }
  return LandmarkFrame(result);
}

final class TrainingObservation {
  TrainingObservation({
    required this.timeMs,
    required this.width,
    required this.height,
    required List<dynamic> points,
    required this.sequence,
    required this.segment,
  }) : points = List<dynamic>.unmodifiable(
         points.map((p) => List<dynamic>.unmodifiable(jsonList(p))),
       ) {
    if (timeMs < 0 || timeMs > 3600000 || sequence < 0 || segment < 0) {
      throw const FormatException('Invalid observation time or sequence.');
    }
    landmarks = decodeLandmarks(this.points, width, height);
  }
  factory TrainingObservation.fromJson(Object? value) {
    final data = jsonObject(value);
    return TrainingObservation(
      timeMs: wholeNumber(data['t']),
      width: finiteNumber(data['w']),
      height: finiteNumber(data['h']),
      points: jsonList(data['p']),
      sequence: wholeNumber(data['q']),
      segment: wholeNumber(data['s']),
    );
  }
  final int timeMs, sequence, segment;
  final double width, height;
  final List<dynamic> points;
  late final LandmarkFrame landmarks;
  Map<String, dynamic> toJson() => {
    't': timeMs,
    'w': width,
    'h': height,
    'p': points,
    'q': sequence,
    's': segment,
  };
  MatchableObservation toMatchable() => MatchableObservation(
    contentTime: Duration(milliseconds: timeMs),
    features: normalizeFeatures(landmarks),
    observedLandmarks: {
      for (final name in kLandmarkNames)
        if (landmarks[name].isUsable) name,
    },
  );
}

Map<String, dynamic> featuresToJson(NormalizedFeatures features) => {
  'angles': features.jointAngles,
  'directions': {
    for (final e in features.limbDirections.entries)
      e.key: e.value == null ? null : [e.value!.x, e.value!.y],
  },
  'positions': {
    for (final e in features.scaledPositions.entries)
      e.key: e.value == null ? null : [e.value!.x, e.value!.y],
  },
  'scale': features.bodyScale,
};
NormalizedFeatures featuresFromJson(Object? value) {
  final data = jsonObject(value);
  Map<String, Point2D?> vectors(Object? value) => {
    for (final e in jsonObject(value).entries)
      e.key: e.value == null
          ? null
          : Point2D(
              finiteNumber(jsonList(e.value)[0]),
              finiteNumber(jsonList(e.value)[1]),
            ),
  };
  return NormalizedFeatures(
    jointAngles: {
      for (final e in jsonObject(data['angles']).entries)
        e.key: e.value == null ? null : finiteNumber(e.value),
    },
    limbDirections: vectors(data['directions']),
    scaledPositions: vectors(data['positions']),
    bodyScale: finiteNumber(data['scale']),
  );
}

final class TrainingBundle {
  TrainingBundle({
    required this.id,
    required this.title,
    required this.version,
    required this.durationMs,
    required this.mediaSha256,
    required this.reviewed,
    required this.events,
    required this.sections,
  }) {
    if (durationMs <= 0 ||
        durationMs > 3600000 ||
        events.isEmpty ||
        sections.isEmpty ||
        events.any((e) => e.targetContentTime.inMilliseconds > durationMs) ||
        events.map((e) => e.id).toSet().length != events.length) {
      throw const FormatException('Invalid bundle.');
    }
  }
  factory TrainingBundle.fromJson(Object? value) {
    final data = jsonObject(value);
    if (data['schema'] != 1 || data['scoringVersion'] != scoringVersion) {
      throw const FormatException('Unsupported bundle/scoring version.');
    }
    return TrainingBundle(
      id: data['id'] as String,
      title: data['title'] as String,
      version: data['version'] as String,
      durationMs: wholeNumber(data['durationMs']),
      mediaSha256: data['mediaSha256'] as String,
      reviewed: data['reviewed'] == true,
      sections: jsonList(data['sections']).map(jsonObject).toList(),
      events: jsonList(data['events']).map((value) {
        final e = jsonObject(value);
        return ReferenceEvent(
          id: e['id'] as String,
          sectionId: e['section'] as String,
          targetContentTime: Duration(milliseconds: wholeNumber(e['timeMs'])),
          weight: finiteNumber(e['weight']),
          matchWindow: const Duration(milliseconds: 300),
          timingFullCreditWindow: const Duration(milliseconds: 100),
          timingZeroCreditWindow: const Duration(milliseconds: 300),
          requiredLandmarks: jsonList(e['required']).cast<String>(),
          referenceFeatures: featuresFromJson(e['features']),
        );
      }).toList(),
    );
  }
  final String id, title, version, mediaSha256;
  final int durationMs;
  final bool reviewed;
  final List<ReferenceEvent> events;
  final List<Map<String, dynamic>> sections;
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'id': id,
    'title': title,
    'version': version,
    'durationMs': durationMs,
    'mediaSha256': mediaSha256,
    'reviewed': reviewed,
    'scoringVersion': scoringVersion,
    'sections': sections,
    'events': [
      for (final e in events)
        {
          'id': e.id,
          'section': e.sectionId,
          'timeMs': e.targetContentTime.inMilliseconds,
          'weight': e.weight,
          'required': e.requiredLandmarks,
          'features': featuresToJson(e.referenceFeatures),
        },
    ],
  };
}

/// The same function runs for immediate client feedback and saved server results.
/// No client-supplied total is accepted. Only observations reach this boundary.
Map<String, dynamic> scoreTraining(
  TrainingBundle bundle,
  List<TrainingObservation> observations, {
  String? sectionId,
  bool interrupted = false,
}) {
  if (observations.length > 10000) {
    throw const FormatException('Too many observations.');
  }
  var previousTime = -1, previousSequence = -1;
  for (final o in observations) {
    if (o.timeMs <= previousTime ||
        o.sequence <= previousSequence ||
        o.timeMs > bundle.durationMs + 1000) {
      throw const FormatException(
        'Observations must have unique increasing times and sequences.',
      );
    }
    previousTime = o.timeMs;
    previousSequence = o.sequence;
  }
  final targets =
      bundle.events
          .where((e) => sectionId == null || e.sectionId == sectionId)
          .toList()
        ..sort((a, b) => a.targetContentTime.compareTo(b.targetContentTime));
  if (targets.isEmpty) {
    throw const FormatException('No scoreable events in this section.');
  }
  final results = matchAttemptEvents(
    events: targets,
    observations: observations.map((o) => o.toMatchable()).toList(),
  );
  final total = aggregateAttemptScore(results);
  var span = 0, longest = 0;
  for (final result in results) {
    span = result.quality.assessment == EventAssessment.unassessed
        ? span + 1
        : 0;
    if (span > longest) longest = span;
  }
  final enough = total.weightedCoverage >= 0.85 && longest <= 5;
  final sectionResults = <Map<String, dynamic>>[];
  for (final section in bundle.sections) {
    final selected = <WeightedEventResult>[];
    for (var i = 0; i < targets.length; i++) {
      if (targets[i].sectionId == section['id']) selected.add(results[i]);
    }
    if (selected.isEmpty) continue;
    final score = aggregateAttemptScore(selected);
    sectionResults.add({
      ...section,
      'score': score.totalScore,
      'coverage': score.weightedCoverage,
    });
  }
  final reliable =
      sectionResults.where((s) => finiteNumber(s['coverage']) >= 0.85).toList()
        ..sort(
          (a, b) => wholeNumber(a['score']).compareTo(wholeNumber(b['score'])),
        );
  final candidate = reliable.isEmpty ? null : reliable.first;
  final recommendation = !enough
      ? 'recalibrateCamera'
      : candidate != null && wholeNumber(candidate['score']) < 8500
      ? 'practiceSection'
      : 'replayRoutine';
  return {
    'totalScore': total.totalScore,
    'coverage': total.weightedCoverage,
    'judgmentAvailable': enough,
    'ranked':
        enough &&
        !interrupted &&
        observations.every((o) => o.segment == 0) &&
        bundle.reviewed &&
        sectionId == null,
    'rankReason': !enough
        ? 'Not enough tracking coverage'
        : interrupted
        ? 'Run interrupted'
        : sectionId != null
        ? 'Practice run'
        : !bundle.reviewed
        ? 'Development content awaits review'
        : 'Eligible',
    'sections': sectionResults,
    'recommendation': recommendation,
    'sectionId': recommendation == 'practiceSection' ? candidate!['id'] : null,
    'feedback': !enough
        ? 'Step back until your shoulders, hands and feet stay visible.'
        : recommendation == 'practiceSection'
        ? 'Practice the highlighted section and match the instructor’s arm and leg positions.'
        : 'Replay the routine to check consistency.',
    'scoringVersion': scoringVersion,
    'contentVersion': bundle.version,
  };
}
