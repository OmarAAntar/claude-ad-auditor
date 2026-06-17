---
name: ad-auditor
description: >-
  Audit video ads frame-by-frame and by transcript, then score them for paid-social
  performance. Use this whenever the user wants to review, critique, grade, diagnose,
  or improve a video ad / creative — e.g. "audit my Facebook ad", "is this TikTok ad
  any good", "why isn't my creative converting", "review this ad video", "rate my UGC
  ad", "score these 3 ad variations" — or whenever they upload or point to one or more
  video files (.mp4/.mov) and want feedback. Extracts
  frames with ffmpeg (densely across the first 3-second hook), transcribes the audio with
  local Whisper, and scores the hook, pacing, message clarity, captions, CTA, social proof,
  script/voiceover, production, and mobile/safe-zone fit on a 0–100 scale with a
  LAUNCH-READY / NEEDS WORK / REWORK verdict and prioritized fixes. Tuned for Meta
  (Facebook/Instagram) and TikTok DTC e-commerce ads; auto-detects placement from aspect ratio.
---

# Video Ad Auditor

Claude can't watch a video or hear audio directly. This skill bridges that gap:
it uses **ffmpeg** to pull timestamped frames you can *see*, and **Whisper** to
transcribe the audio you can *read*, then scores both against a DTC creative
rubric and returns a verdict with prioritized fixes.

## Requirements (check before running)
Run a quick availability check and act on what's missing:
```bash
for t in ffmpeg ffprobe whisper yt-dlp; do command -v "$t" >/dev/null && echo "$t ✓" || echo "$t ✗"; done
```
- **ffmpeg/ffprobe** — required. If missing, point to `references/setup.md` and stop.
- **whisper** — needed for audio scoring. If missing, you can still audit visuals;
  see step 4 for graceful degradation, and offer the install command from setup.md.
- **yt-dlp** — only needed when the input is a URL.

All scripts live in `scripts/` and print `key=value` lines. Make them executable
once (`chmod +x scripts/*.sh`) or call them with `bash scripts/<name>.sh`.

---

## Workflow

Create a per-run workspace so frames and transcripts stay organized, e.g.
`audit-workspace/<video-stem>/`. Then for **each** video:

### 1. Get the video file
**The main path:** the user uploads or points to one or more local video files
(.mp4/.mov). Use those paths directly — this is the primary, expected input, so
assume it unless a link is explicitly given.

*Optional fallback* — if the user instead gives a URL, run
`bash scripts/fetch_video.sh "<url>" audit-workspace/<stem>/` (reads back
`video_file=...`; exit 3 means yt-dlp isn't installed). Meta Ad Library links
often can't be downloaded — ask for the uploaded file instead.

### 2. Probe specs & detect placement
```bash
bash scripts/probe.sh "<video>"
```
Note `duration_s`, `has_audio`, `aspect_ratio`, and `likely_placement`. The
aspect ratio tells you which section of `references/platform-specs.md` to apply
and whether the video is even the right shape for its placement.

### 3. Extract frames
```bash
bash scripts/extract_frames.sh "<video>" audit-workspace/<stem>/frames
```
Frames are named with timestamps (`frame_03_t1.50s.jpg`) and sampled densely
over the first 3 seconds because the hook matters most.

### 4. Transcribe the audio
Only if `has_audio=1`:
```bash
bash scripts/transcribe.sh "<video>" audit-workspace/<stem>/transcript small auto
```
- For Arabic / Lebanese-dialect / mixed audio, accuracy improves with a bigger
  model — rerun with `medium` (4th arg `ar` to force Arabic) if `small` looks off.
- **Exit code 3 = no transcriber installed.** Don't fail the audit. Continue with
  a visuals-only pass, mark "Script / voiceover" as *not assessable* (redistribute
  its weight per the rubric), and tell the user how to enable audio scoring.
- The SRT carries timestamps — use them to align spoken lines with the frames.

### 5. Read & analyze
- Read the frames **in chronological order** (sort by filename). Pay closest
  attention to the `t0.0`–`t3.0` frames — that's the hook.
- Read the transcript (`.srt` for timing, or `.txt`).
- Load `references/rubric.md` for the scoring framework and the section of
  `references/platform-specs.md` matching the detected aspect ratio.

### 6. Score & report
Score every criterion in the rubric, sum to /100, map to a verdict, and write the
report using `assets/report-template.md`.

---

## What separates a good audit from a generic one

- **Cite what you actually see.** "At 0:00 you open on a 2-second logo animation
  before any product appears" — not "the hook could be stronger." Reference
  timestamps and specific frames/lines. Never invent a scene that isn't in the
  frames or a line that isn't in the transcript; if you're unsure, say so.
- **Lead with the hook.** It's 22% of the score and the top reason ads fail. If
  the first 3 seconds are weak, that's almost always fix #1.
- **"Not shown" ≠ "bad."** No audio track? The script is *not assessable*, not a
  zero. No captions visible? That's a real miss only if the placement is muted-by-
  default (Meta feed) — note the distinction.
- **Make fixes ranked and concrete.** The user should be able to act on each one
  without asking a follow-up. Tie each fix to the criterion and the "why."
- **Be honest, not flattering.** An accurate 64 with a clear path to 85 is more
  useful than a polite 82.

## Multiple videos / variations
Advertisers usually test several creatives. Audit each one fully, then add the
comparison block from the template: rank them, call out which has the strongest
hook, and recommend which to run or scale first. This is often the most valuable
part of the output.

## Cleanup
The extracted frames and transcripts in `audit-workspace/` are intermediate
artifacts. Mention where they are; offer to delete them when the user is done.
