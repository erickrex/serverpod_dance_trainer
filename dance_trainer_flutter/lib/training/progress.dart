import 'dart:convert';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_client/dance_trainer_client.dart';

/// Compares only the same routine, section, content, model, scorer and speed.
/// Existing development results were all recorded at normal playback speed.
int? scoreChange(TrainingAttempt newer, TrainingAttempt older) {
  if (newer.resultJson == null ||
      older.resultJson == null ||
      newer.routineId != older.routineId ||
      newer.contentVersion != older.contentVersion ||
      newer.modelVersion != older.modelVersion ||
      newer.mode != older.mode ||
      newer.sectionId != older.sectionId) {
    return null;
  }
  final a = jsonObject(jsonDecode(newer.resultJson!));
  final b = jsonObject(jsonDecode(older.resultJson!));
  if (a['judgmentAvailable'] != true ||
      b['judgmentAvailable'] != true ||
      a['scoringVersion'] == null ||
      a['scoringVersion'] != b['scoringVersion'] ||
      (a['playbackRate'] ?? 1.0) != (b['playbackRate'] ?? 1.0) ||
      a['rankReason'] == 'Run interrupted' ||
      b['rankReason'] == 'Run interrupted') {
    return null;
  }
  return wholeNumber(a['totalScore']) - wholeNumber(b['totalScore']);
}
