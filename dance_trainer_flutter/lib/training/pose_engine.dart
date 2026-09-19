import 'dart:typed_data';
import 'package:executorch_flutter/executorch_flutter.dart';

class PoseEngine {
  ExecuTorchModel? _model;
  bool _disposed = false;
  Future<void> load(Uint8List bytes) async {
    if (_disposed) throw StateError('Pose engine is closed.');
    setNativeDebugLogging(false);
    final model = await ExecuTorchModel.loadFromBytes(bytes);
    if (_disposed) {
      await model.dispose();
      throw StateError('Pose engine is closed.');
    }
    _model = model;
  }

  Future<List<List<Object?>>> infer(
    Map<Object?, Object?> frame, {
    bool mirror = false,
  }) async {
    final model = _model;
    if (model == null) throw StateError('Pose model is not loaded.');
    final output = await model.forward([
      TensorData(
        shape: [1, 3, 640, 640],
        dataType: TensorType.float32,
        data: frame['bytes'] as Uint8List,
      ),
    ]);
    // This pinned export returns the decoded predictions first, followed by
    // six auxiliary head tensors. Only decoded predictions are landmarks.
    if (output.length != 7 ||
        output.first.dataType != TensorType.float32 ||
        output.first.shape.length != 3 ||
        output.first.shape[0] != 1 ||
        output.first.shape[1] != 56 ||
        output.first.shape[2] != 8400) {
      throw StateError('Pose model output does not match its pinned contract.');
    }
    final bytes = output.first.data;
    if (bytes.length != 56 * 8400 * 4) {
      throw StateError('Invalid pose tensor size.');
    }
    final tensor = ByteData.sublistView(bytes);
    double value(int channel, int slot) =>
        tensor.getFloat32((channel * 8400 + slot) * 4, Endian.little);
    int? best;
    var confidence = 0.5;
    for (var i = 0; i < 8400; i++) {
      final score = value(4, i);
      if (score.isFinite && score > confidence && score <= 1) {
        best = i;
        confidence = score;
      }
    }
    if (best == null) {
      return [
        for (var i = 0; i < 17; i++) [null, null, 0.0],
      ];
    }
    // Refuse ambiguous multiple people. Overlapping detections are duplicates
    // of the same body; a separate strong box pauses assessment.
    final bx = value(0, best),
        by = value(1, best),
        bw = value(2, best),
        bh = value(3, best);
    for (var i = 0; i < 8400; i++) {
      if (i == best || value(4, i) < 0.6) continue;
      if ((value(0, i) - bx).abs() > bw * 0.6 ||
          (value(1, i) - by).abs() > bh * 0.6) {
        return [
          for (var k = 0; k < 17; k++) [null, null, 0.0],
        ];
      }
    }
    final scale = frame['scale'] as double,
        padX = frame['padX'] as double,
        padY = frame['padY'] as double;
    final width = (frame['width'] as num).toDouble(),
        height = (frame['height'] as num).toDouble();
    final points = <List<Object?>>[];
    for (var i = 0; i < 17; i++) {
      final x = (value(5 + i * 3, best) - padX) / scale / width;
      final y = (value(6 + i * 3, best) - padY) / scale / height;
      final c = value(7 + i * 3, best);
      if (!x.isFinite ||
          !y.isFinite ||
          !c.isFinite ||
          x < 0 ||
          x > 1 ||
          y < 0 ||
          y > 1 ||
          c <= 0 ||
          c > 1) {
        points.add([null, null, 0.0]);
      } else {
        points.add([mirror ? 1 - x : x, y, c]);
      }
    }
    if (mirror) {
      for (var i = 1; i < 17; i += 2) {
        final point = points[i];
        points[i] = points[i + 1];
        points[i + 1] = point;
      }
    }
    return points;
  }

  Future<void> dispose() async {
    _disposed = true;
    final model = _model;
    _model = null;
    await model?.dispose();
  }
}
