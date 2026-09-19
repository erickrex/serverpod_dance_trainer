# Pose extraction

Two tools. `extract_poses.py` turns a choreography video into a reference pose file. `audit_poses.py` checks any reference pose file — new or preserved — and gates CI.

This is what makes swapping in original content a data operation instead of a rewrite (task 2.17). New footage arrives with no pose data; this is where it comes from.

## Usage

Extraction needs a GPU-class machine or patience — the model runs on every frame, and there are 12,012 of them in the longer preserved routine.

```bash
# dependencies are declared inline (PEP 723); uv resolves them in isolation
uv run extract_poses.py path/to/routine.mp4 \
    --routine-id my-routine \
    --out ../../../content/derived/my-routine/

# smoke test on 300 frames first, and keep the raw tracks so you can
# re-emit with a different dancer without paying for inference twice
uv run extract_poses.py path/to/routine.mp4 \
    --routine-id my-routine --out /tmp/probe --limit 300 \
    --dump-raw /tmp/probe/raw.json

# read the QA report, then override the dancer choice for free
uv run extract_poses.py path/to/routine.mp4 \
    --routine-id my-routine --out ../../../content/derived/my-routine/ \
    --from-raw /tmp/probe/raw.json --track-id 3
```

Auditing needs nothing but the standard library:

```bash
python3 audit_poses.py ../../../content/source/*/*.json \
    --media-dir ../../../content/source
```

Exit status is 1 on a hard failure — irregular or non-monotonic timeline, frame-count
mismatch, core coverage under the floor, or a pose timeline that disagrees with its
video. Tracking instability and person-absent spans are warnings: they are annotation
work, not a corrupt file.

## Output

`extract_poses.py` writes two files:

- `<routine-id>.json` — schema v2 pose document: provenance, landmark names, angle definitions, and per-frame keypoints with explicit validity.
- `<routine-id>.qa.json` — the spans a human must review, as frame and second ranges, ready to become exclusion-interval annotations.

Schema v2 differs from the preserved v1 files in three ways the importer must handle:

| | v1 (preserved) | v2 (this tool) |
|---|---|---|
| Missing landmark | `{x: 0, y: 0, confidence: 0}` | `{x: null, y: null, confidence: 0, validity: "absent"}` |
| Unmeasurable angle | `0.0` | `null` |
| Angle keys | 8 names collapsing to 4 values | 4 names, one per real joint bend |

Both schemas carry the same 17 COCO landmark names, so the landmark vocabulary is shared. `audit_poses.py` reads both.

## What changed from `preprocess_video_yolov8.py`

Four defects in the origin tool are fixed. Each one changes the output, so v2 files are not byte-comparable with v1.

**Track identity.** The original called `boxes.conf.argmax()` independently on every frame, with no tracker. Whenever a second person scored marginally higher for a few frames, the reference dancer silently changed. The measured cost on the preserved content: **13.6%** of `30minutos` frames sit inside a tracking-unstable span, against **1.9%** for `howdeepisyourlove`. This tool runs a real tracker, scores each track for presence, usable-skeleton ratio, size and centring, then follows one track id for the whole video — and reports every candidate so a human can override it.

`visualize_tracking.py` labelled the per-frame argmax winner "TRACKED". That was a display label, not tracking.

**Colour order.** The original did `cvtColor(frame, COLOR_BGR2RGB)` before handing the array to YOLO. Ultralytics takes numpy input in BGR and converts internally, so the model was fed channel-swapped frames for every extraction ever run. This tool passes BGR untouched. Confirm on a sample before trusting either result — it plausibly accounts for part of the confidence and stability gap above, but that is inference from the API contract, not something measured here.

**Angle geometry.** The original computed joint angles from coordinates already normalized as `x/width, y/height`. Dividing the axes by different numbers shears every angle on non-square video, and both routines are 1280×720. Every angle in the v1 files is systematically distorted, independently of the 8→4 duplication. This tool computes angles in pixel space and normalizes only for storage.

**Missing data.** The original initialised keypoints to `{x: 0, y: 0, confidence: 0}` and returned `0.0` degrees when confidence was too low. Zero degrees is a fully-extended joint and (0, 0) is the top-left corner — both are legitimate values, indistinguishable from real observations downstream. This tool emits `null` and an explicit validity.

Incidentally: the original's `INPUT_SIZE = 256` was dead code, never referenced. Inference ran at ultralytics' default 640, which is what the v1 files contain. That settles part of the spec's open question about conflicting 192/256 input assumptions.

## Coverage is judged on eight landmarks, not seventeen

`CORE_LANDMARKS` is shoulders, hips, knees and ankles — what the event vocabulary actually scores. Measured on the preserved content: 94.4% and 93.3% of frames have all eight confident, but only ~59% have all seventeen. The gap is the face group, which nothing needs. An all-17 gate throws away 41% of usable frames for no benefit.

## Status

`audit_poses.py` runs and is verified against both preserved routines, including a
negative control confirming the coverage floor and exit code gate correctly.

`extract_poses.py` has **not been executed** — this host has no ultralytics, torch or
GPU. It is unproven code. Before trusting an extraction:

1. Run with `--limit 300` and read the QA report.
2. A/B the colour-order fix on a handful of frames against the original tool.
3. Confirm the selected track is the instructor, by eye, on a few sampled frames.
4. Audit the result: `python3 audit_poses.py <output> --media-dir <dir>`.
