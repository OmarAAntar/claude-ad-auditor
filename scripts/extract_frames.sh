#!/usr/bin/env bash
# extract_frames.sh — sample frames from a video for visual auditing.
#
# Sampling strategy (why it's shaped this way):
#   * The first 3 seconds are sampled every 0.5s. In DTC video ads the hook is
#     the single biggest lever on performance, so we look at it closely.
#   * The remaining runtime is spread evenly across the frame budget.
#   * The final frame is always grabbed (end card / CTA usually lives there).
#
# Filenames are timestamped (frame_03_t1.50s.jpg) so whoever reads them knows
# WHEN each frame occurs — essential for judging hook, pacing and CTA timing.
#
# Usage: extract_frames.sh <video> <output_dir> [max_frames]
set -uo pipefail

INPUT="${1:?usage: extract_frames.sh <video> <output_dir> [max_frames]}"
OUTDIR="${2:?usage: extract_frames.sh <video> <output_dir> [max_frames]}"
MAXF="${3:-20}"

mkdir -p "$OUTDIR"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)
DUR=${DUR:-0}

# Build the list of timestamps to grab.
TS=$(awk -v dur="$DUR" -v maxf="$MAXF" 'BEGIN{
  n=0
  hookend = (dur<3 ? dur : 3)
  for(t=0; t<=hookend+0.0001; t+=0.5){ printf "%.2f\n", t; n++ }
  if(dur>3){
    rest = maxf - n - 1            # reserve one slot for the final frame
    if(rest < 1) rest = 1
    step = (dur-3)/(rest+1)
    for(i=1;i<=rest;i++){ printf "%.2f\n", 3 + step*i; n++ }
    f = dur-0.05; if(f<0) f=dur
    printf "%.2f\n", f
  }
}')

i=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  printf -v idx "%02d" "$i"
  out="$OUTDIR/frame_${idx}_t${t}s.jpg"
  # -ss before -i = fast seek. Downscale longest side to 720 (plenty for auditing,
  # keeps files small and fast to read). -2 keeps height even.
  ffmpeg -nostdin -loglevel error -ss "$t" -i "$INPUT" -frames:v 1 \
    -vf "scale='min(720,iw)':-2" -q:v 3 -y "$out" 2>/dev/null || true
  i=$((i+1))
done <<< "$TS"

echo "frames_extracted=$i"
echo "frames_dir=$OUTDIR"
