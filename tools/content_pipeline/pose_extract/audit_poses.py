#!/usr/bin/env python3
"""Audit a reference pose file for timeline integrity, coverage and tracking stability.

Standard library only, so it runs on a bare checkout with no environment setup:

    python3 audit_poses.py content/source/howdeepisyourlove/howdeepisyourlove.json
    python3 audit_poses.py content/source/*/*.json --media-dir content/source --json

Reads both schemas: v1 (the preserved files from the origin project, which encode
missing landmarks as x=0, y=0, confidence=0) and v2 (produced by extract_poses.py,
which carries an explicit per-landmark validity).

Exit status is 1 when a HARD check fails -- a non-monotonic or irregular timeline,
a frame-count mismatch, or core coverage under the floor -- so this can gate CI.
Tracking instability is reported but does not fail: it is annotation work, not a
corrupt file.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics as st
import subprocess
import sys
from pathlib import Path
from typing import Any

CORE = ["leftShoulder", "rightShoulder", "leftHip", "rightHip",
        "leftKnee", "rightKnee", "leftAnkle", "rightAnkle"]

DEFAULT_CONF = 0.5
DEFAULT_COVERAGE_FLOOR = 0.85
DEFAULT_JUMP = 0.15
IRREGULAR_TOLERANCE = 0.05   # fraction of the expected frame interval


def media_duration(path: Path) -> float | None:
    """Duration in seconds: the VIDEO stream's where there is one, else the container's.

    The distinction matters. A pose timeline is derived from video frames, so it
    must be compared against the video stream (200.200s for 30minutos), not the
    container (200.249s, which tracks the slightly longer audio stream). Using
    the container for both failed every routine by ~50 ms.

    Audio-only files have no video stream, so they fall back to the container --
    and selecting v:0 unconditionally is what previously made MP3 checks return
    nothing at all, silently skipping the mismatch this exists to catch.
    """
    def probe(args: list[str]) -> float | None:
        try:
            out = subprocess.run(
                ["ffprobe", "-v", "error", *args, "-of",
                 "default=noprint_wrappers=1:nokey=1", str(path)],
                capture_output=True, text=True, check=True, timeout=30)
            text = out.stdout.strip().splitlines()[0] if out.stdout.strip() else ""
            return float(text) if text and text != "N/A" else None
        except Exception:
            return None

    video = probe(["-select_streams", "v:0", "-show_entries", "stream=duration"])
    return video if video is not None else probe(["-show_entries", "format=duration"])


def landmark_confident(entry: dict[str, Any], conf: float) -> bool:
    """True when this landmark is a real observation.

    v2 states validity outright. v1 has to be inferred: a zeroed coordinate with
    zero confidence is the origin tool's way of saying 'absent', which is exactly
    why v2 stopped doing that.
    """
    if (v := entry.get("validity")) is not None:
        return v == "observed"
    return float(entry.get("confidence", 0.0)) >= conf


def hip_centre(kps: dict[str, Any], conf: float) -> tuple[float, float] | None:
    lh, rh = kps.get("leftHip"), kps.get("rightHip")
    if not lh or not rh:
        return None
    if not (landmark_confident(lh, conf) and landmark_confident(rh, conf)):
        return None
    if lh.get("x") is None or rh.get("x") is None:
        return None
    return ((lh["x"] + rh["x"]) / 2, (lh["y"] + rh["y"]) / 2)


def audit(path: Path, media_dir: Path | None, conf: float,
          coverage_floor: float, jump: float) -> dict[str, Any]:
    doc = json.loads(path.read_text())
    schema = doc.get("schemaVersion", 1)
    routine = doc.get("routineId") or doc.get("songId") or path.stem
    frames = doc["frames"]
    fps = float(doc["fps"])
    declared = doc.get("totalFrames")

    failures: list[str] = []
    warnings: list[str] = []

    if declared is not None and declared != len(frames):
        failures.append(f"frame count mismatch: declared {declared}, array has {len(frames)}")

    ts = [float(f["timestamp"]) for f in frames]
    monotonic = all(b > a for a, b in zip(ts, ts[1:]))
    if not monotonic:
        failures.append("timestamps are not strictly increasing")

    deltas = [b - a for a, b in zip(ts, ts[1:])]
    expected = 1.0 / fps
    irregular = sum(1 for d in deltas if abs(d - expected) > expected * IRREGULAR_TOLERANCE)
    if irregular:
        failures.append(
            f"{irregular} frame intervals deviate from {expected*1000:.2f} ms by "
            f">{IRREGULAR_TOLERANCE:.0%}")

    core_ok = 0
    all_ok = 0
    absent = 0
    names = list(frames[0]["keypoints"].keys())
    hips: list[tuple[float, float] | None] = []
    confs: list[float] = []

    for f in frames:
        kps = f["keypoints"]
        if f.get("present") is False:
            absent += 1
        elif all(float(kps[n].get("confidence", 0.0)) < 0.1 for n in names):
            absent += 1
        if all(landmark_confident(kps[n], conf) for n in CORE):
            core_ok += 1
        if all(landmark_confident(kps[n], conf) for n in names):
            all_ok += 1
        confs.extend(float(kps[n].get("confidence", 0.0)) for n in names)
        hips.append(hip_centre(kps, conf))

    total = len(frames)
    core_ratio = core_ok / total if total else 0.0
    if core_ratio < coverage_floor:
        failures.append(
            f"core landmark coverage {core_ratio:.1%} is below the {coverage_floor:.0%} floor")

    jumps = [i for i, (p, q) in enumerate(zip(hips, hips[1:]))
             if p and q and math.dist(p, q) > jump]
    clusters: list[list[int]] = []
    for i in jumps:
        if clusters and i - clusters[-1][-1] <= 3:
            clusters[-1].append(i)
        else:
            clusters.append([i])
    unstable = sum(c[-1] - c[0] + 1 for c in clusters)
    unstable_ratio = unstable / total if total else 0.0
    if clusters:
        warnings.append(
            f"{len(jumps)} implausible hip jumps in {len(clusters)} clusters "
            f"({unstable_ratio:.1%} of frames) -- needs exclusion intervals")
    if absent:
        warnings.append(
            f"{absent} frames ({absent/total:.1%}, {absent/fps:.1f}s) have no dancer "
            f"-- needs exclusion intervals")

    confs.sort()
    q = lambda frac: confs[int(frac * (len(confs) - 1))] if confs else 0.0

    result: dict[str, Any] = {
        "file": str(path),
        "routineId": routine,
        "schemaVersion": schema,
        "fps": fps,
        "frames": total,
        "declaredFrames": declared,
        "timeline": {
            "monotonic": monotonic,
            "firstTimestamp": ts[0] if ts else None,
            "lastTimestamp": ts[-1] if ts else None,
            "expectedIntervalMs": round(expected * 1000, 3),
            "intervalMinMs": round(min(deltas) * 1000, 3) if deltas else None,
            "intervalMedianMs": round(st.median(deltas) * 1000, 3) if deltas else None,
            "intervalMaxMs": round(max(deltas) * 1000, 3) if deltas else None,
            "irregularIntervals": irregular,
        },
        "coverage": {
            "landmarkCount": len(names),
            "coreObserved": core_ok,
            "coreObservedRatio": round(core_ratio, 4),
            "allLandmarksObserved": all_ok,
            "allLandmarksObservedRatio": round(all_ok / total, 4) if total else 0.0,
            "framesWithoutDancer": absent,
            "confidenceP10": round(q(0.10), 4),
            "confidenceP50": round(q(0.50), 4),
            "confidenceP90": round(q(0.90), 4),
        },
        "trackingStability": {
            "hipJumps": len(jumps),
            "clusters": len(clusters),
            "framesInUnstableSpans": unstable,
            "unstableRatio": round(unstable_ratio, 4),
            "firstClusterSeconds": [round(c[0] / fps, 2) for c in clusters[:8]],
        },
        "failures": failures,
        "warnings": warnings,
    }

    if media_dir:
        for suffix in (".mp4", ".mp3"):
            candidate = media_dir / routine / f"{routine}{suffix}"
            if candidate.exists():
                dur = media_duration(candidate)
                if dur is None:
                    continue
                delta = (ts[-1] - dur) if ts else None
                result.setdefault("mediaAlignment", {})[candidate.name] = {
                    "durationSeconds": round(dur, 3),
                    "poseEndMinusMediaSeconds": round(delta, 3) if delta is not None else None,
                }
                # One frame of slack. The pose timeline ends at the last frame's
                # start, so it legitimately sits just under the media duration.
                if delta is not None and abs(delta) > 1.5 * expected and suffix == ".mp4":
                    failures.append(
                        f"{candidate.name}: pose timeline ends {delta:+.3f}s from the "
                        f"video duration, beyond one frame of slack")
                if delta is not None and abs(delta) > 1.0 and suffix == ".mp3":
                    warnings.append(
                        f"{candidate.name} differs from the pose timeline by {delta:+.3f}s "
                        f"-- do not use it as the playback master")
        result["failures"] = failures
        result["warnings"] = warnings

    return result


def render(r: dict[str, Any]) -> None:
    tl, cov, tr = r["timeline"], r["coverage"], r["trackingStability"]
    print("=" * 70)
    print(f"{r['routineId']}   schema v{r['schemaVersion']}   {r['frames']} frames @ {r['fps']} fps")
    print(f"  timeline   {tl['firstTimestamp']:.3f} .. {tl['lastTimestamp']:.3f}s  "
          f"monotonic={tl['monotonic']}  irregular={tl['irregularIntervals']}")
    print(f"             interval min/median/max = {tl['intervalMinMs']}/"
          f"{tl['intervalMedianMs']}/{tl['intervalMaxMs']} ms "
          f"(expected {tl['expectedIntervalMs']})")
    print(f"  coverage   core {cov['coreObserved']}/{r['frames']} "
          f"({cov['coreObservedRatio']:.1%})   all-{cov['landmarkCount']} "
          f"({cov['allLandmarksObservedRatio']:.1%})   no dancer {cov['framesWithoutDancer']}")
    print(f"             confidence p10/p50/p90 = {cov['confidenceP10']}/"
          f"{cov['confidenceP50']}/{cov['confidenceP90']}")
    print(f"  stability  {tr['hipJumps']} jumps in {tr['clusters']} clusters, "
          f"{tr['unstableRatio']:.1%} of frames unstable")
    if tr["firstClusterSeconds"]:
        print(f"             first clusters at {tr['firstClusterSeconds']}s")
    for name, info in (r.get("mediaAlignment") or {}).items():
        print(f"  media      {name}: {info['durationSeconds']}s "
              f"(pose end {info['poseEndMinusMediaSeconds']:+.3f}s)")
    for w in r["warnings"]:
        print(f"  WARN       {w}")
    for f in r["failures"]:
        print(f"  FAIL       {f}")
    if not r["failures"]:
        print("  PASS       no hard failures")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--media-dir", type=Path, default=None,
                    help="Root holding <routineId>/<routineId>.mp4 so pose and media "
                         "timelines can be compared.")
    ap.add_argument("--conf", type=float, default=DEFAULT_CONF)
    ap.add_argument("--coverage-floor", type=float, default=DEFAULT_COVERAGE_FLOOR)
    ap.add_argument("--jump-threshold", type=float, default=DEFAULT_JUMP)
    ap.add_argument("--json", action="store_true", help="Emit machine-readable output.")
    args = ap.parse_args()

    results = [audit(p, args.media_dir, args.conf, args.coverage_floor,
                     args.jump_threshold) for p in args.files]

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        for r in results:
            render(r)
        bad = sum(1 for r in results if r["failures"])
        print("=" * 70)
        print(f"{len(results)} file(s) audited, {bad} with hard failures")

    return 1 if any(r["failures"] for r in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
