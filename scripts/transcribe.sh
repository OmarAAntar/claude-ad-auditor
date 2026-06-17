#!/usr/bin/env bash
# transcribe.sh — transcribe a video's audio locally with Whisper.
#
# Produces timestamped output (SRT) plus plain text in <output_dir>. The SRT
# timestamps let the auditor line up spoken lines with the extracted frames
# (e.g. "the hook line lands at 0:02").
#
# Tries openai-whisper first, then whisper.cpp. If neither is installed it exits
# with code 3 so the caller can fall back to a visuals-only audit and tell the
# user how to enable transcription (see references/setup.md).
#
# Usage: transcribe.sh <video> <output_dir> [model] [language]
#   model:    tiny|base|small|medium|large|turbo   (default: small)
#   language: auto | en | ar | ...                 (default: auto-detect)
set -uo pipefail

INPUT="${1:?usage: transcribe.sh <video> <output_dir> [model] [language]}"
OUTDIR="${2:?usage: transcribe.sh <video> <output_dir> [model] [language]}"
MODEL="${3:-small}"
LANG="${4:-auto}"

mkdir -p "$OUTDIR"

# --- openai-whisper -------------------------------------------------------
if command -v whisper >/dev/null 2>&1; then
  if [ "$LANG" = "auto" ]; then
    whisper "$INPUT" --model "$MODEL" --output_format all \
      --output_dir "$OUTDIR" --verbose False || exit 1
  else
    whisper "$INPUT" --model "$MODEL" --language "$LANG" --output_format all \
      --output_dir "$OUTDIR" --verbose False || exit 1
  fi
  echo "transcriber=openai-whisper model=$MODEL"
  exit 0
fi

# --- whisper.cpp fallback -------------------------------------------------
WCLI=""
command -v whisper-cli >/dev/null 2>&1 && WCLI="whisper-cli"
command -v whisper-cpp >/dev/null 2>&1 && WCLI="whisper-cpp"
if [ -n "$WCLI" ]; then
  if [ -z "${WHISPER_CPP_MODEL:-}" ]; then
    echo "whisper.cpp found but WHISPER_CPP_MODEL (path to a ggml model) is not set. See references/setup.md" >&2
    exit 3
  fi
  WAV="$OUTDIR/audio.wav"
  ffmpeg -nostdin -loglevel error -i "$INPUT" -ar 16000 -ac 1 -y "$WAV" 2>/dev/null
  "$WCLI" -m "$WHISPER_CPP_MODEL" -f "$WAV" -osrt -otxt -of "$OUTDIR/transcript" >/dev/null 2>&1 || exit 1
  echo "transcriber=whisper.cpp"
  exit 0
fi

echo "NO_TRANSCRIBER: install openai-whisper (pip3 install -U openai-whisper) or whisper-cpp. See references/setup.md" >&2
exit 3
