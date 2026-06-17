#!/usr/bin/env bash
# probe.sh — read a video's specs and guess its placement from aspect ratio.
# Usage: probe.sh <video>
# Prints key=value lines (width, height, duration_s, fps, has_audio, aspect_ratio,
# orientation, likely_placement) that the skill reads to choose the right rubric.
set -uo pipefail

INPUT="${1:?usage: probe.sh <video>}"

W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width  -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)
AUD=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$INPUT" 2>/dev/null | head -n1)

echo "width=${W:-unknown}"
echo "height=${H:-unknown}"
echo "duration_s=${DUR:-unknown}"
echo "fps=${FPS:-unknown}"
[ -n "${AUD:-}" ] && echo "has_audio=1" || echo "has_audio=0"

awk -v w="${W:-0}" -v h="${H:-0}" 'BEGIN{
  if(h>0){
    r=w/h
    printf "aspect_ratio=%.3f\n", r
    if(r<0.62){      print "orientation=vertical_9x16";  print "likely_placement=Reels/Stories/TikTok/Shorts" }
    else if(r<0.85){ print "orientation=portrait_4x5";   print "likely_placement=Meta_feed_4x5" }
    else if(r<1.15){ print "orientation=square_1x1";     print "likely_placement=feed_1x1" }
    else {           print "orientation=landscape_16x9"; print "likely_placement=YouTube/feed_landscape" }
  } else {
    print "aspect_ratio=unknown"
  }
}'
