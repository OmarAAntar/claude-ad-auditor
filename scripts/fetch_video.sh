#!/usr/bin/env bash
# fetch_video.sh — download an ad video from a URL via yt-dlp.
#
# Works well for TikTok, YouTube/Shorts, and most public video URLs.
# Note: Meta Ad Library pages don't expose a direct video file reliably — if a
# Facebook/Instagram link fails, ask the user to download the .mp4 manually and
# pass the local file instead.
#
# Exits with code 3 if yt-dlp isn't installed (see references/setup.md).
#
# Usage: fetch_video.sh <url> <output_dir>
set -uo pipefail

URL="${1:?usage: fetch_video.sh <url> <output_dir>}"
OUTDIR="${2:?usage: fetch_video.sh <url> <output_dir>}"
mkdir -p "$OUTDIR"

if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "NO_YTDLP: install yt-dlp (brew install yt-dlp). See references/setup.md" >&2
  exit 3
fi

yt-dlp -o "$OUTDIR/%(id)s.%(ext)s" \
  -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b" \
  --no-playlist --merge-output-format mp4 "$URL" || exit 1

# Echo the resulting file path for the caller.
DOWNLOADED=$(ls -1t "$OUTDIR"/*.mp4 2>/dev/null | head -n1)
[ -n "$DOWNLOADED" ] && echo "video_file=$DOWNLOADED" || { echo "DOWNLOAD_FAILED" >&2; exit 1; }
