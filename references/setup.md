# Setup — installing the tools

The skill needs **ffmpeg** (frames), **Whisper** (transcription), and — only if
you audit URLs — **yt-dlp** (downloads). On macOS:

## 1. ffmpeg + ffprobe (required)
```bash
brew install ffmpeg
```
`ffprobe` ships with ffmpeg. This is the one hard requirement — without it the
skill can't read or sample the video.

## 2. Whisper — local transcription (recommended)
Pick ONE. openai-whisper is the simplest; whisper.cpp is faster and lighter.

**Option A — openai-whisper (default the script expects):**
```bash
pip3 install -U openai-whisper
```
It pulls in PyTorch, so the first install is a few hundred MB and can take a
minute. Models download on first use. Default model in the script is `small`
(good speed/accuracy balance for short ads).

**Option B — whisper.cpp (faster, lighter):**
```bash
brew install whisper-cpp
# download a model, e.g. base or small:
#   https://huggingface.co/ggerganov/whisper.cpp/tree/main
# then point the skill at it:
export WHISPER_CPP_MODEL=/path/to/ggml-small.bin
```

### Language note (Arabic / mixed audio)
Whisper auto-detects language. For Arabic, Lebanese dialect, or Arabic/English
mix, accuracy improves with a larger model — try `--model medium` (or `large`)
if `small` mistranscribes. You can also force a language, e.g. `ar` or `en`.

If no transcriber is installed, the skill still runs — it audits the visuals
only, scores the script as "not assessable," and reminds you how to enable audio.

## 3. yt-dlp — only for auditing URLs (optional)
```bash
brew install yt-dlp     # or: pip3 install -U yt-dlp
```
Works for TikTok, YouTube/Shorts, and most public video URLs.

**Meta Ad Library caveat:** Facebook/Instagram ad pages don't reliably expose a
direct downloadable file. If a Meta link fails, download the .mp4 manually (e.g.
via the Ad Library's media, or a screen recording) and hand the skill the local
file instead.

## Quick check
```bash
for t in ffmpeg ffprobe whisper yt-dlp; do
  command -v "$t" >/dev/null && echo "$t ✓" || echo "$t ✗"
done
```
