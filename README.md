# claude-ad-auditor

A [Claude Code](https://claude.com/claude-code) skill that **audits your video ads** —
frame by frame *and* by transcript — then scores them for paid-social performance
with a clear verdict and a ranked fix list.

Claude can't watch a video or hear audio on its own. This skill bridges that:
it pulls timestamped **frames** with `ffmpeg` (densely across the first 3-second
hook), **transcribes** the audio locally with Whisper, and scores both against a
DTC creative rubric tuned for **Meta (Facebook/Instagram)** and **TikTok**.

## What you get
- **0–100 score** across 10 weighted criteria (hook, message clarity, pacing,
  CTA, script/VO, captions, social proof, production, mobile/safe-zone fit,
  branding).
- A **verdict** — 🟢 LAUNCH-READY / 🟡 NEEDS WORK / 🔴 REWORK.
- **Prioritized, specific fixes** that cite real timestamps ("at 0:00 you open
  on a 2-second logo animation…").
- **Variation comparison** — audit several creatives and get a ranked
  recommendation on which to run or scale.

## Inputs
- **Upload your video files** (`.mp4` / `.mov`) — the main, expected way to use it.
- *Optional fallback:* an ad **URL** (TikTok, YouTube/Shorts, via `yt-dlp`).
  (Meta Ad Library links often can't be downloaded — just upload the file.)

Placement (Reels / TikTok / feed / YouTube) is **auto-detected** from the aspect
ratio, and the safe-zone checks adapt accordingly.

## Install
1. Copy this folder into your Claude Code skills directory (e.g.
   `~/.claude/skills/claude-ad-auditor`).
2. Install the tools (macOS):
   ```bash
   brew install ffmpeg            # required
   pip3 install -U openai-whisper # audio transcription
   brew install yt-dlp            # only for auditing URLs
   ```
   See [`references/setup.md`](references/setup.md) for details, the whisper.cpp
   alternative, and notes on Arabic / mixed-language audio.

## Usage
Upload your ad video(s), then ask Claude things like:
- "Audit this ad" *(with your .mp4)*
- "Is this TikTok ad any good?" *(upload the video)*
- "Score these 3 ad variations and tell me which to run"
- "Why isn't my Facebook creative converting?"

If Whisper isn't installed, the skill still runs a visuals-only audit and tells
you how to enable audio scoring.

## How it works
```
SKILL.md            workflow + auditing principles
scripts/
  probe.sh          specs + aspect-ratio → placement
  extract_frames.sh timestamped frames, dense on the hook
  transcribe.sh     local Whisper (openai-whisper or whisper.cpp) → SRT/TXT
  fetch_video.sh    yt-dlp download for URLs
references/
  rubric.md         the 100-point scoring framework
  platform-specs.md Meta + TikTok specs & safe zones
  setup.md          installing the tools
assets/
  report-template.md the output format
```

## Privacy
Frames and transcription run **locally** on your machine. Nothing about your ads
is uploaded (unless you choose the cloud-transcription path documented in setup).

---
Part of the `claude-` line of e-commerce skills.
