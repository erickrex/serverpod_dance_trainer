import 'dart:io';
import 'dart:typed_data';
import 'package:dance_trainer_flutter/training/pose_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'trained model detects recorded dancer and rejects an empty image',
    () async {
      final engine = PoseEngine();
      addTearDown(engine.dispose);
      await engine.load(
        await File('../content/models/yolov8n-pose_xnnpack.pte').readAsBytes(),
      );
      final decoded = await Process.run('ffmpeg', [
        '-v',
        'error',
        '-ss',
        '5',
        '-i',
        '../content/source/howdeepisyourlove/howdeepisyourlove.mp4',
        '-frames:v',
        '1',
        '-vf',
        'scale=640:360,pad=640:640:0:140:color=0x727272',
        '-f',
        'rawvideo',
        '-pix_fmt',
        'rgb24',
        'pipe:1',
      ], stdoutEncoding: null);
      expect(decoded.exitCode, 0, reason: decoded.stderr.toString());
      final rgb = decoded.stdout as List<int>;
      expect(rgb.length, 640 * 640 * 3);
      final tensor = Float32List(rgb.length);
      for (var pixel = 0; pixel < 640 * 640; pixel++) {
        for (var channel = 0; channel < 3; channel++) {
          tensor[channel * 640 * 640 + pixel] = rgb[pixel * 3 + channel] / 255;
        }
      }
      final frame = <Object?, Object?>{
        'bytes': tensor.buffer.asUint8List(),
        'width': 1280,
        'height': 720,
        'scale': 0.5,
        'padX': 0.0,
        'padY': 140.0,
      };
      final points = await engine.infer(frame);
      expect(points.length, 17);
      expect(
        points.where((p) => (p[2] as num) >= 0.5).length,
        greaterThanOrEqualTo(12),
      );
      final mirrored = await engine.infer(frame, mirror: true);
      expect(mirrored[5][0], closeTo(1 - (points[6][0] as num), 0.0001));
      expect(mirrored[5][1], closeTo(points[6][1] as num, 0.0001));
      final blank = await engine.infer({
        ...frame,
        'bytes': Float32List(rgb.length).buffer.asUint8List(),
      });
      expect(
        blank.every((p) => p[0] == null && p[1] == null && p[2] == 0),
        isTrue,
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
