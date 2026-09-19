# Pose model provenance

- File: `yolov8n-pose_xnnpack.pte`
- Model: Ultralytics YOLOv8n pose, COCO 17-keypoint layout.
- Download: https://github.com/abdelaziz-mahdy/executorch_flutter_models/releases/download/v1.3.1/yolov8n-pose_xnnpack.pte
- Index: https://raw.githubusercontent.com/abdelaziz-mahdy/executorch_flutter_models/main/1.3.1/index.json
- SHA-256: `a0d74638c8c055b09a5e906f341e4e8a8c8e1151758ceaa51e5581d4d682b1d1`
- Size: 13,363,716 bytes.
- Runtime: ExecuTorch 1.3.1, `executorch_flutter` 0.5.0, XNNPACK backend.
- Input verified on Linux x64: float32 RGB NCHW `[1,3,640,640]`, normalized to 0–1 with gray letterbox padding.
- Output verified: seven tensors. The first is decoded predictions `[1,56,8400]`; the remaining six are auxiliary heads. The app reads only the first tensor and validates its shape.
- Actual inference test: recorded instructor frame produces at least 12 confident landmarks; black frame produces absent landmarks; mirrored output reflects x and swaps COCO left/right indices.

The Linux host test is not a phone performance measurement. Android camera conversion, capture clock alignment, thermal behavior and sustained inference rate still need device validation.

The upstream repository identifies YOLO models as AGPL-3.0. `YOLO-POSE-LICENSE.md` is its original attribution notice, retrieved from https://github.com/abdelaziz-mahdy/executorch_flutter_models/blob/main/LICENSES/YOLO-POSE.md. It is not a license grant for this project's source or choreography media. Publication licensing remains part of release preparation.
