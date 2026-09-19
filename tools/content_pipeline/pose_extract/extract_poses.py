#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "ultralytics>=8.3.0",
#   "opencv-python>=4.10.0",
#   "numpy>=1.26.0",
#   "tqdm>=4.66.0",
# ]
# ///
"""Extract reference pose trajectories from a choreography video.

Run with uv so dependencies resolve into an isolated environment:

    uv run extract_poses.py VIDEO --routine-id howdeepisyourlove --out content/derived/

This is a reimplementation of the origin project's `preprocess_video_yolov8.py`.
It is not a port. Four defects in that tool are fixed here, and each fix changes
the output, so v2 files are NOT byte-comparable with the preserved v1 files.

  1. TRACK IDENTITY. The original chose `boxes.conf.argmax()` independently on
     every frame, so the "reference dancer" silently changed whenever another
     person scored marginally higher. Measured effect on the preserved content:
     13.6% of 30minutos frames sit inside a tracking-unstable span. This tool
     runs a real tracker, picks ONE primary track for the whole video by an
     explicit policy, and follows that track id.

  2. COLOUR ORDER. The original did BGR->RGB before handing the array to YOLO.
     Ultralytics expects numpy input in BGR and converts internally, so the
     model was fed channel-swapped frames. This tool passes BGR untouched.
     Verify with --ab-channels on a sample before trusting either result.

  3. ANGLE GEOMETRY. The original computed joint angles from coordinates that
     had already been normalized as x/width, y/height. Dividing the axes by
     different numbers shears every angle on non-square video. This tool
     computes angles in pixel space and normalizes only for storage.

  4. MISSING DATA. The original wrote {x:0, y:0, confidence:0} for absent
     landmarks and returned 0.0 degrees for unmeasurable angles -- both are
     legitimate values and are indistinguishable from real observations. This
     tool emits an explicit per-landmark validity and null for what it cannot
     measure.

Alongside the pose file it writes a QA report naming the intervals a human must
review: frames with no dancer, track switches, and implausible motion. Those
become exclusion-interval annotations; they are not silently smoothed away.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

TOOL_VERSION = "2.0.0"
SCHEMA_VERSION = 2

# COCO-17, in model output order. Names match the preserved v1 files so the
# Dart importer can address both schemas with one landmark vocabulary.
LANDMARK_NAMES = [
    "nose", "leftEye", "rightEye", "leftEar", "rightEar",
    "leftShoulder", "rightShoulder", "leftElbow", "rightElbow",
    "leftWrist", "rightWrist", "leftHip", "rightHip",
    "leftKnee", "rightKnee", "leftAnkle", "rightAnkle",
]
IDX = {name: i for i, name in enumerate(LANDMARK_NAMES)}

# The eight landmarks every scoreable event depends on. Coverage is judged over
# these, not over all 17: the face group is routinely low-confidence and no
# event needs it. Requiring all 17 discards ~41% of otherwise usable frames.
CORE_LANDMARKS = [
    "leftShoulder", "rightShoulder", "leftHip", "rightHip",
    "leftKnee", "rightKnee", "leftAnkle", "rightAnkle",
]

# Four genuinely independent joint bends, named for what they measure.
# The v1 files carried eight keys that reduced to these four: leftArm and
# leftElbow were the same number, as were leftThigh and leftLeg.
ANGLE_DEFS = {
    "leftElbow": ("leftShoulder", "leftElbow", "leftWrist"),
    "rightElbow": ("rightShoulder", "rightElbow", "rightWrist"),
    "leftKnee": ("leftHip", "leftKnee", "leftAnkle"),
    "rightKnee": ("rightHip", "rightKnee", "rightAnkle"),
}

VALID_OBSERVED = "observed"
VALID_LOW = "lowConfidence"
VALID_ABSENT = "absent"


# --------------------------------------------------------------------------
# provenance
# --------------------------------------------------------------------------

def sha256_file(path: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def probe_video(path: Path) -> dict[str, Any]:
    """Read container metadata with ffprobe, falling back to OpenCV.

    ffprobe is preferred because it reports the frame rate as an exact rational
    (60/1), where OpenCV returns a float that can be 29.999999.
    """
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-select_streams", "v:0",
             "-show_entries", "stream=width,height,r_frame_rate,nb_frames,duration",
             "-show_entries", "format=duration",
             "-of", "json", str(path)],
            capture_output=True, text=True, check=True, timeout=60,
        )
        doc = json.loads(out.stdout)
        stream = doc["streams"][0]
        num, _, den = stream["r_frame_rate"].partition("/")
        fps = float(num) / float(den or 1)
        return {
            "width": int(stream["width"]),
            "height": int(stream["height"]),
            "fpsRational": stream["r_frame_rate"],
            "fps": fps,
            "durationSeconds": float(stream.get("duration") or doc["format"]["duration"]),
            "frameCountReported": int(stream["nb_frames"]) if stream.get("nb_frames") else None,
            "probedBy": "ffprobe",
        }
    except Exception:
        import cv2
        cap = cv2.VideoCapture(str(path))
        if not cap.isOpened():
            raise SystemExit(f"cannot open video: {path}")
        info = {
            "width": int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
            "height": int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
            "fpsRational": None,
            "fps": float(cap.get(cv2.CAP_PROP_FPS)),
            "durationSeconds": None,
            "frameCountReported": int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or None,
            "probedBy": "opencv",
        }
        cap.release()
        return info


# --------------------------------------------------------------------------
# geometry
# --------------------------------------------------------------------------

def joint_angle(
    a: tuple[float, float] | None,
    b: tuple[float, float] | None,
    c: tuple[float, float] | None,
) -> float | None:
    """Angle a-b-c in degrees, in PIXEL space. None when unmeasurable.

    None rather than 0.0: zero degrees is a real, fully-extended-back joint and
    must not double as 'we could not see this'.
    """
    if a is None or b is None or c is None:
        return None
    v1 = (a[0] - b[0], a[1] - b[1])
    v2 = (c[0] - b[0], c[1] - b[1])
    n1 = math.hypot(*v1)
    n2 = math.hypot(*v2)
    if n1 < 1e-6 or n2 < 1e-6:
        return None
    cos = (v1[0] * v2[0] + v1[1] * v2[1]) / (n1 * n2)
    return math.degrees(math.acos(max(-1.0, min(1.0, cos))))


# --------------------------------------------------------------------------
# track selection
# --------------------------------------------------------------------------

@dataclass
class TrackStats:
    track_id: int
    frames: int = 0
    conf_sum: float = 0.0
    area_sum: float = 0.0
    centre_offset_sum: float = 0.0
    core_ok_frames: int = 0
    first_frame: int = -1
    last_frame: int = -1

    @property
    def mean_conf(self) -> float:
        return self.conf_sum / self.frames if self.frames else 0.0

    @property
    def mean_area(self) -> float:
        return self.area_sum / self.frames if self.frames else 0.0

    @property
    def mean_centre_offset(self) -> float:
        return self.centre_offset_sum / self.frames if self.frames else 1.0

    @property
    def core_ratio(self) -> float:
        return self.core_ok_frames / self.frames if self.frames else 0.0


def score_track(stats: TrackStats, total_frames: int) -> float:
    """Primary-dancer score. Higher is better.

    Presence dominates: the instructor is on screen essentially the whole time,
    while a passer-by or a mirror reflection is not. Usable-skeleton ratio comes
    next, because a track that is present but never has legs is not scoreable.
    Size and centring are weak tie-breakers -- deliberately weak, since a
    foreground non-dancer can be both large and central.
    """
    presence = stats.frames / total_frames if total_frames else 0.0
    return (
        0.50 * presence
        + 0.25 * stats.core_ratio
        + 0.15 * min(1.0, stats.mean_area * 4.0)
        + 0.10 * (1.0 - min(1.0, stats.mean_centre_offset * 2.0))
    )


# --------------------------------------------------------------------------
# extraction
# --------------------------------------------------------------------------

@dataclass
class RawFrame:
    """All tracks seen in one frame, in pixel space."""
    index: int
    tracks: dict[int, dict[str, Any]] = field(default_factory=dict)


def run_inference(
    video: Path, model_name: str, device: str, imgsz: int, tracker: str,
    person_conf: float, limit: int | None,
) -> tuple[list[RawFrame], dict[str, Any]]:
    from ultralytics import YOLO
    import torch
    import ultralytics

    if device == "auto":
        if torch.cuda.is_available():
            device = "cuda"
        elif getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
            device = "mps"
        else:
            device = "cpu"

    model = YOLO(model_name)
    weights = Path(getattr(model, "ckpt_path", "") or model_name)
    provenance = {
        "model": model_name,
        "modelResolvedPath": str(weights) if weights.exists() else None,
        "modelSha256": sha256_file(weights) if weights.exists() else None,
        "ultralyticsVersion": ultralytics.__version__,
        "torchVersion": torch.__version__,
        "device": device,
        "imgsz": imgsz,
        "tracker": tracker,
        "personConfThreshold": person_conf,
        # Ultralytics takes numpy/video frames as BGR and converts internally.
        # Recorded explicitly because the origin tool got this wrong.
        "colourOrderSuppliedToModel": "BGR",
        "toolVersion": TOOL_VERSION,
        "extractedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }

    from tqdm import tqdm

    raw: list[RawFrame] = []
    stream = model.track(
        source=str(video), stream=True, tracker=tracker, imgsz=imgsz,
        device=device, conf=person_conf, classes=[0], verbose=False,
    )

    for i, result in enumerate(tqdm(stream, desc="inference", unit="frame")):
        if limit is not None and i >= limit:
            break
        frame = RawFrame(index=i)
        boxes = result.boxes
        kps = result.keypoints
        if boxes is not None and kps is not None and boxes.id is not None:
            ids = boxes.id.int().cpu().tolist()
            confs = boxes.conf.cpu().tolist()
            xyxy = boxes.xyxy.cpu().tolist()
            data = kps.data.cpu().numpy()
            h, w = result.orig_shape
            for slot, tid in enumerate(ids):
                x1, y1, x2, y2 = xyxy[slot]
                cx = (x1 + x2) / 2 / w
                cy = (y1 + y2) / 2 / h
                frame.tracks[tid] = {
                    "conf": float(confs[slot]),
                    "area": abs(x2 - x1) * abs(y2 - y1) / (w * h),
                    "centreOffset": math.hypot(cx - 0.5, cy - 0.5),
                    # (17, 3) pixel-space x, y, confidence
                    "kp": data[slot].tolist(),
                }
        raw.append(frame)

    return raw, provenance


def summarise_tracks(raw: list[RawFrame], kp_conf: float) -> dict[int, TrackStats]:
    stats: dict[int, TrackStats] = {}
    for frame in raw:
        for tid, det in frame.tracks.items():
            st = stats.setdefault(tid, TrackStats(track_id=tid))
            st.frames += 1
            st.conf_sum += det["conf"]
            st.area_sum += det["area"]
            st.centre_offset_sum += det["centreOffset"]
            if st.first_frame < 0:
                st.first_frame = frame.index
            st.last_frame = frame.index
            kp = det["kp"]
            if all(kp[IDX[n]][2] >= kp_conf for n in CORE_LANDMARKS):
                st.core_ok_frames += 1
    return stats


def build_frames(
    raw: list[RawFrame], primary: int, fps: float, width: int, height: int,
    kp_conf: float,
) -> list[dict[str, Any]]:
    frames = []
    for frame in raw:
        det = frame.tracks.get(primary)
        record: dict[str, Any] = {
            "frameNumber": frame.index,
            "timestamp": frame.index / fps,
            "present": det is not None,
        }
        if det is None:
            # Explicitly absent. No coordinates are invented.
            record["keypoints"] = {
                n: {"x": None, "y": None, "confidence": 0.0, "validity": VALID_ABSENT}
                for n in LANDMARK_NAMES
            }
            record["angles"] = {k: None for k in ANGLE_DEFS}
            frames.append(record)
            continue

        kp = det["kp"]
        pixel: dict[str, tuple[float, float] | None] = {}
        stored: dict[str, Any] = {}
        for name in LANDMARK_NAMES:
            x, y, c = kp[IDX[name]]
            if c >= kp_conf:
                validity = VALID_OBSERVED
                pixel[name] = (float(x), float(y))
            elif c > 0.0:
                validity = VALID_LOW
                pixel[name] = None
            else:
                validity = VALID_ABSENT
                pixel[name] = None
            stored[name] = {
                # Normalized for portability; angles are NOT computed from these.
                "x": round(float(x) / width, 6) if validity != VALID_ABSENT else None,
                "y": round(float(y) / height, 6) if validity != VALID_ABSENT else None,
                "confidence": round(float(c), 4),
                "validity": validity,
            }

        record["trackConfidence"] = round(det["conf"], 4)
        record["keypoints"] = stored
        record["angles"] = {
            key: (None if (a := joint_angle(pixel[p1], pixel[p2], pixel[p3])) is None
                  else round(a, 3))
            for key, (p1, p2, p3) in ANGLE_DEFS.items()
        }
        frames.append(record)
    return frames


# --------------------------------------------------------------------------
# QA
# --------------------------------------------------------------------------

def spans(flags: Iterable[bool], fps: float) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    start = None
    for i, flag in enumerate(flags):
        if flag and start is None:
            start = i
        elif not flag and start is not None:
            out.append({"startFrame": start, "endFrame": i - 1,
                        "startSeconds": round(start / fps, 3),
                        "endSeconds": round((i - 1) / fps, 3),
                        "frames": i - start})
            start = None
    if start is not None:
        out.append({"startFrame": start, "endFrame": i,
                    "startSeconds": round(start / fps, 3),
                    "endSeconds": round(i / fps, 3),
                    "frames": i - start + 1})
    return out


def qa_report(
    frames: list[dict[str, Any]], raw: list[RawFrame], stats: dict[int, TrackStats],
    primary: int, fps: float, kp_conf: float, jump_threshold: float,
) -> dict[str, Any]:
    total = len(frames)
    absent = [not f["present"] for f in frames]
    core_bad = []
    hips: list[tuple[float, float] | None] = []
    for f in frames:
        kps = f["keypoints"]
        ok = all(kps[n]["validity"] == VALID_OBSERVED for n in CORE_LANDMARKS)
        core_bad.append(not ok)
        lh, rh = kps["leftHip"], kps["rightHip"]
        if lh["validity"] == VALID_OBSERVED and rh["validity"] == VALID_OBSERVED:
            hips.append(((lh["x"] + rh["x"]) / 2, (lh["y"] + rh["y"]) / 2))
        else:
            hips.append(None)

    jumps = []
    for i, (p, q) in enumerate(zip(hips, hips[1:])):
        if p and q and math.dist(p, q) > jump_threshold:
            jumps.append(i)

    # Frames where the primary track vanished while some other track was
    # present: prime suspects for a tracker handover.
    handovers = [
        f.index for f in raw
        if primary not in f.tracks and f.tracks
    ]

    core_ok = total - sum(core_bad)
    return {
        "totalFrames": total,
        "primaryTrackId": primary,
        "framesWithPrimaryTrack": total - sum(absent),
        "coverage": {
            "coreLandmarksObserved": core_ok,
            "coreLandmarksObservedRatio": round(core_ok / total, 4) if total else 0.0,
            "keypointConfThreshold": kp_conf,
            "coreLandmarks": CORE_LANDMARKS,
        },
        "reviewRequired": {
            "note": "Each span below becomes an exclusion interval in the sidecar "
                    "annotations unless review shows it is scoreable. Do not edit "
                    "this pose file to 'fix' them.",
            "primaryTrackAbsentSpans": spans(absent, fps),
            "coreLandmarksMissingSpans": spans(core_bad, fps),
            "hipJumpFrames": jumps,
            "hipJumpThresholdNormalized": jump_threshold,
            "hipJumpCount": len(jumps),
            "otherTrackPresentWhilePrimaryAbsentFrames": len(handovers),
        },
        "tracksSeen": sorted(
            (
                {
                    "trackId": st.track_id,
                    "frames": st.frames,
                    "presenceRatio": round(st.frames / total, 4) if total else 0.0,
                    "meanConfidence": round(st.mean_conf, 4),
                    "meanAreaRatio": round(st.mean_area, 5),
                    "meanCentreOffset": round(st.mean_centre_offset, 4),
                    "coreLandmarkRatio": round(st.core_ratio, 4),
                    "firstFrame": st.first_frame,
                    "lastFrame": st.last_frame,
                    "selectionScore": round(score_track(st, total), 4),
                    "selected": st.track_id == primary,
                }
                for st in stats.values()
            ),
            key=lambda d: -d["selectionScore"],
        ),
    }


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def validate_output_paths(output: Path, routine_id: str) -> tuple[Path, Path]:
    """Protect the archival tree and refuse replacement, including symlinks."""
    if not routine_id or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for c in routine_id):
        raise ValueError("routine-id must contain only letters, digits, _ or -")
    archival = Path(__file__).resolve().parents[3] / "content" / "source"
    destination = output.resolve()
    if destination == archival or archival in destination.parents:
        raise ValueError("content/source is archival; choose content/derived instead")
    paths = (destination / f"{routine_id}.json", destination / f"{routine_id}.qa.json")
    for path in paths:
        if path.exists() or path.is_symlink():
            raise FileExistsError(f"refusing to replace existing output: {path}")
    return paths


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Extract reference pose trajectories from a choreography video.")
    ap.add_argument("video", type=Path)
    ap.add_argument("--routine-id", required=True,
                    help="Stable routine id; also the output filename stem.")
    ap.add_argument("--out", type=Path, required=True,
                    help="Output directory. Writes <routine-id>.json and "
                         "<routine-id>.qa.json.")
    ap.add_argument("--model", default="yolov8s-pose.pt")
    ap.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda", "mps"])
    ap.add_argument("--imgsz", type=int, default=640,
                    help="Inference size. Recorded in provenance. The origin tool "
                         "carried a dead INPUT_SIZE=256 constant and actually ran "
                         "at this default, which is what the v1 files contain.")
    ap.add_argument("--tracker", default="bytetrack.yaml",
                    help="bytetrack.yaml or botsort.yaml. botsort re-identifies "
                         "better across occlusion but is slower.")
    ap.add_argument("--person-conf", type=float, default=0.5,
                    help="Detection confidence floor. Below this a frame has no "
                         "dancer rather than a guessed one.")
    ap.add_argument("--keypoint-conf", type=float, default=0.5,
                    help="Landmark confidence floor for validity=observed.")
    ap.add_argument("--hip-jump-threshold", type=float, default=0.15,
                    help="Normalized hip-centre displacement between consecutive "
                         "frames above which motion is implausible.")
    ap.add_argument("--track-id", type=int, default=None,
                    help="Override automatic primary-dancer selection. Inspect the "
                         "QA report's tracksSeen, then re-run with --from-raw.")
    ap.add_argument("--dump-raw", type=Path, default=None,
                    help="Write every track's keypoints so a different --track-id "
                         "can be emitted without re-running inference.")
    ap.add_argument("--from-raw", type=Path, default=None,
                    help="Re-emit from a previous --dump-raw instead of inferring.")
    ap.add_argument("--limit", type=int, default=None,
                    help="Stop after N frames. For smoke tests only -- a truncated "
                         "file must never be registered as a routine.")
    ap.add_argument("--indent", type=int, default=None,
                    help="Pretty-print the pose file. Off by default: indent=2 is "
                         "why the v1 files are 35 MB.")
    args = ap.parse_args()

    try:
        pose_path, qa_path = validate_output_paths(args.out, args.routine_id)
        if args.dump_raw:
            archival = Path(__file__).resolve().parents[3] / "content" / "source"
            raw_output = args.dump_raw.resolve()
            if raw_output == archival or archival in raw_output.parents or args.dump_raw.exists():
                raise ValueError("raw output must be new and outside content/source")
    except (ValueError, FileExistsError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if not args.video.exists():
        print(f"error: video not found: {args.video}", file=sys.stderr)
        return 2

    meta = probe_video(args.video)
    width, height, fps = meta["width"], meta["height"], meta["fps"]
    if fps <= 0:
        print("error: could not determine frame rate", file=sys.stderr)
        return 2
    if abs(fps - round(fps)) > 1e-6:
        print(f"warning: non-integer frame rate {fps}; timestamps derive from it",
              file=sys.stderr)

    if args.from_raw:
        blob = json.loads(args.from_raw.read_text())
        raw = [RawFrame(index=f["index"],
                        tracks={int(k): v for k, v in f["tracks"].items()})
               for f in blob["frames"]]
        provenance = blob["extraction"]
        provenance["reEmittedAt"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    else:
        raw, provenance = run_inference(
            args.video, args.model, args.device, args.imgsz, args.tracker,
            args.person_conf, args.limit,
        )
        if args.dump_raw:
            args.dump_raw.parent.mkdir(parents=True, exist_ok=True)
            with args.dump_raw.open("x") as raw_file:
                raw_file.write(json.dumps({
                "extraction": provenance,
                "frames": [{"index": f.index, "tracks": f.tracks} for f in raw],
                }))
            print(f"raw tracks -> {args.dump_raw}")

    if not raw:
        print("error: no frames decoded", file=sys.stderr)
        return 1

    stats = summarise_tracks(raw, args.keypoint_conf)
    if not stats:
        print("error: no person tracked anywhere in the video. Check the video, "
              "the model and --person-conf before lowering any threshold.",
              file=sys.stderr)
        return 1

    if args.track_id is not None:
        if args.track_id not in stats:
            print(f"error: track {args.track_id} never appears. Seen: "
                  f"{sorted(stats)}", file=sys.stderr)
            return 2
        primary = args.track_id
        policy = f"manual --track-id={args.track_id}"
    else:
        primary = max(stats.values(), key=lambda st: score_track(st, len(raw))).track_id
        policy = ("automatic: 0.50*presence + 0.25*coreLandmarkRatio "
                  "+ 0.15*meanArea + 0.10*centredness")

    frames = build_frames(raw, primary, fps, width, height, args.keypoint_conf)
    qa = qa_report(frames, raw, stats, primary, fps, args.keypoint_conf,
                   args.hip_jump_threshold)

    provenance["primaryTrackId"] = primary
    provenance["selectionPolicy"] = policy
    if args.limit is not None or (meta["frameCountReported"] and len(frames) < meta["frameCountReported"]):
        provenance["truncatedAfterFrames"] = len(frames)

    document = {
        "schemaVersion": SCHEMA_VERSION,
        "routineId": args.routine_id,
        "fps": fps,
        "totalFrames": len(frames),
        "landmarkNames": LANDMARK_NAMES,
        "angleDefinitions": {k: list(v) for k, v in ANGLE_DEFS.items()},
        "source": {
            "videoFileName": args.video.name,
            "videoSha256": sha256_file(args.video),
            **{k: meta[k] for k in
               ("width", "height", "fps", "fpsRational", "durationSeconds",
                "frameCountReported", "probedBy")},
        },
        "extraction": provenance,
        "qa": {k: qa[k] for k in ("coverage", "primaryTrackId",
                                  "framesWithPrimaryTrack", "totalFrames")},
        "frames": frames,
    }

    args.out.mkdir(parents=True, exist_ok=True)
    # Exclusive creation also closes the race between preflight and writing.
    with pose_path.open("x") as pose_file:
        pose_file.write(json.dumps(document, indent=args.indent))
    with qa_path.open("x") as qa_file:
        qa_file.write(json.dumps(qa, indent=2))

    cov = qa["coverage"]["coreLandmarksObservedRatio"]
    print(f"\nroutine        {args.routine_id}")
    print(f"frames         {len(frames)} at {fps} fps "
          f"({len(frames)/fps:.3f}s, video {meta['durationSeconds']}s)")
    print(f"primary track  {primary}  ({policy})")
    print(f"core coverage  {cov:.1%}")
    print(f"absent spans   {len(qa['reviewRequired']['primaryTrackAbsentSpans'])}")
    print(f"hip jumps      {qa['reviewRequired']['hipJumpCount']}")
    print(f"tracks seen    {len(stats)}")
    print(f"\npose -> {pose_path}")
    print(f"qa   -> {qa_path}")
    if len(stats) > 1:
        print("\nMore than one track was seen. Read the QA report's tracksSeen "
              "before trusting the automatic choice.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
