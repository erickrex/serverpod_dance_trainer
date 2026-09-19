# Content audit — measured 19 September 2026

Measurements on the preserved source content in `content/source/`, taken before any application code existed. Tools: `ffprobe` for media, Python for the pose JSON. Everything below is measured, not estimated.

Purpose: decide whether the existing content is good enough to prove the concept on, and which routine to build against first.

**Verdict: yes, the content is usable, and the build order in the plan should be reversed.**

---

## 1. Media durations and playback master

| Routine | MP4 video | MP4 audio (AAC) | Separate MP3 | Verdict |
|---|---|---|---|---|
| `30minutos` | 200.200 s @ 60 fps | 200.249 s | 200.232 s | all three agree within 49 ms |
| `howdeepisyourlove` | 171.033 s @ 30 fps | 171.085 s | **197.832 s** | MP3 is **26.75 s longer** than the video |

Both videos are 1280×720 h264 with an embedded stereo AAC track at 44.1 kHz. The separate MP3s are 48 kHz stereo.

### Decision: the MP4's embedded audio is the playback master for both routines

The `howdeepisyourlove` MP3 cannot be the master. It is 26.75 s longer than its video, so the video is a trimmed excerpt of the full song — and nothing tells us from where. Using it would require recovering an unknown offset by audio correlation, and any error in that offset becomes a systematic timing error in every single score for that routine.

The MP4's own audio track is, by construction, aligned with the video the pose data was extracted from. Using it makes the offset exactly zero and removes an entire class of sync bug.

The MP3s stay as archival source (they cost 9.5 MB) but are not played. This collapses the hardest part of task 2.3 from "recover and verify per-routine offsets" to "read the MP4's audio track".

---

## 2. Pose timeline integrity

| Measure | `30minutos` | `howdeepisyourlove` |
|---|---|---|
| Declared vs actual frame count | 12,012 = 12,012 ✓ | 5,131 = 5,131 ✓ |
| Timestamps monotonic | yes | yes |
| Frame interval min/median/max | 16.67 / 16.67 / 16.67 ms | 33.33 / 33.33 / 33.33 ms |
| Intervals off expected by >5% | 0 (0.00%) | 0 (0.00%) |
| Last timestamp vs video duration | 200.183 s vs 200.200 s (−17 ms) | 171.000 s vs 171.033 s (−33 ms) |

**The reference timeline is pristine.** Exactly uniform frame intervals, strictly monotonic, no dropped or duplicated timestamps, and the final timestamp lands within one frame of the video duration in both cases.

This matters more than it looks. The design's whole time-alignment approach — anchored playback clock, beat markers in content time, bounded event windows, signed offsets for timing quality — rests on the reference timeline being trustworthy. It is. The remaining timing risk is entirely on the *capture* side (camera timestamps on a real phone), not the reference side.

---

## 3. Landmark confidence

| Measure | `30minutos` | `howdeepisyourlove` |
|---|---|---|
| Confidence p10 / p50 / p90 | 0.578 / 0.972 / 0.996 | 0.732 / 0.980 / 0.998 |
| Frames with all 8 core landmarks ≥ 0.5 | 11,342 (**94.4%**) | 4,787 (**93.3%**) |
| Frames with all 17 landmarks ≥ 0.5 | 7,088 (59.0%) | 3,042 (59.3%) |
| Frames with no landmark above 0.1 (no person) | 490 (**4.1%**) | 0 (**0.0%**) |

Core landmarks are shoulders, hips, knees and ankles — the eight the event vocabulary actually scores.

Two conclusions:

**Score on core landmarks, not all 17.** Requiring all seventeen would throw away 41% of otherwise usable frames. The gap is the face group (nose, eyes, ears), which is frequently low-confidence and which nothing in the event vocabulary needs. The coverage gate should be defined over the landmarks an event requires, not over the full set.

**`30minutos` has 8.2 seconds with no dancer detected at all.** 490 frames at 60 fps. These need explicit exclusion intervals in the sidecar annotations; they are not scoreable and must not be charged to a student as missed events.

---

## 4. Tracking identity stability

Measured as hip-centre displacement between consecutive frames where both frames have confident hip landmarks. A dancer's hips cannot move 0.15 normalized units in one frame; such a jump means the tracker changed its mind about who it was following.

| Measure | `30minutos` | `howdeepisyourlove` |
|---|---|---|
| Jumps > 0.05 units | 1,601 | 105 |
| Jumps > 0.15 units | 1,239 | 78 |
| Distinct clusters of big jumps | 501 | 42 |
| Frames inside unstable spans | 1,636 (**13.6%**) | 95 (**1.9%**) |
| Cluster sizes | 202 single-frame, 264 of 2–5, 35 over 5 | 19 single-frame, 23 of 2–5, none over 5 |
| Confident hip x, p05 → p95 | 0.392 → 0.649 | 0.422 → 0.625 |

The clusters are **scattered and short**, starting at 6.65 s, 11.52 s, 12.05 s, 12.13 s, 12.78 s, 14.47 s and so on through the routine. Camera cuts would produce few, isolated, widely-spaced discontinuities; this is the tracker flapping. The hip-x distribution is a single band in both routines rather than two, so it is short-lived detection instability and limb swapping rather than the tracker walking off to a different person across the frame.

`30minutos` is **seven times less stable** than `howdeepisyourlove` on this measure, despite being captured at twice the frame rate.

---

## 5. The angle-reduction claim, confirmed

The source `angles` object carries eight names: `leftArm`, `rightArm`, `leftElbow`, `rightElbow`, `leftThigh`, `rightThigh`, `leftLeg`, `rightLeg`.

Frame 0 of `30minutos` contains **4 distinct values across those 8 keys**. Frame 0 of `howdeepisyourlove` contains **1**. The arm/elbow pairs and thigh/leg pairs are the same measurement under two names.

This confirms the spec's position empirically: preserve the angles for provenance, derive the new feature set from the 17 landmarks, and never treat the eight names as eight independent pieces of evidence.

---

## 6. Consequences for the build

1. **Reverse the routine order.** Build and validate against `howdeepisyourlove` first: 1.9% unstable frames versus 13.6%, zero person-absent frames versus 490, 171 s versus 200 s, and 5,131 frames versus 12,012 — less than half the annotation work. `30minutos` becomes routine 2. The plan's order was arbitrary; this one is evidence-based.
2. **MP4 audio is the playback master.** Task 2.3 shrinks accordingly. Never assume the separate MP3 shares a timeline with the video.
3. **Exclusion intervals are a real deliverable, not a contingency.** `30minutos` needs at least 8.2 s of person-absent intervals plus 501 instability spans reviewed; `howdeepisyourlove` needs 42. This is sidecar annotation work — the source JSON is never edited.
4. **Define coverage over required landmarks per event**, not over all 17, or the gate throws away 41% of usable frames for no benefit.
5. **The reference timeline needs no repair.** Timing work belongs on the capture side.

## What this audit does not tell us

It says nothing about whether on-device inference works, what the capture-to-feedback latency is, or whether a phone can sustain 15 Hz. Those need the toolchain and a physical Android device. This audit only establishes that the reference content is sound enough to be worth building against — which it is.
