#!/usr/bin/env bash
#
# Cut the ad's music bed from the full track.
#
# "Glass Circuit" is 2:42; the ad is 25.07s. The cut is not arbitrary - the
# track's hardest entry is at 144.000s (it jumps ~15 dB in one 20ms frame), and
# that transient is placed on the ad's turn: the cut from "you will never scroll
# far enough to find it" into "what if you only got twelve a day?" at 8.333s.
#
# Everything else follows from that anchor:
#
#   ad 0.00-8.33s   track 135.67-144.00   sparse, unresolved - the buried roll
#   ad 8.33s        track 144.00          THE HIT - Tumble arrives
#   ad 10.80s       track 146.47          beat 3 after the hit - the shake starts
#   ad 14.40-20.0s  track 150.07-155.67   full band under the drawer of prints
#   ad 20.0-25.07s  track 155.67-160.74   resolve, decaying under the ask
#
# The track runs at ~73.2 BPM (0.820s a beat), so the shake landing on beat 3 is
# exact rather than lucky. Re-run this if the ad's timing changes.
#
#   ./scripts/build-ad-audio.sh [path-to-source.wav]
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$HOME/Downloads/Glass Circuit.wav}"
OUT="$ROOT/video/public/glass-circuit-ad.wav"

# The ad is 752 frames at 30fps.
# 144.017 is the measured transient; the extra ~40ms accounts for encoder delay
# in the finished mp4, which is where sync actually has to be right. Verified by
# measuring the transient's position in the rendered file, not the source.
readonly START=135.724
readonly DURATION=25.0667
readonly FADE_OUT_AT=24.27

[ -f "$SRC" ] || { echo "source not found: $SRC" >&2; exit 1; }

# Two passes, and the bed lands as WAV rather than AAC. Both are about keeping
# the transient exactly where it was measured: single-pass loudnorm is dynamic
# and reshapes the envelope, and AAC priming shifts playback by a frame or two.
# A linear gain into PCM moves nothing.
echo "measuring…"
# The JSON prints at info level, so -v error would swallow it.
MEASURED="$(ffmpeg -v info -hide_banner -nostats -ss "$START" -t "$DURATION" -i "$SRC" \
  -af "loudnorm=I=-15:TP=-1.5:LRA=11:print_format=json" -f null - 2>&1 | tr -d '\n' \
  | sed 's/.*{/{/;s/}.*/}/')"

get() { echo "$MEASURED" | sed -n "s/.*\"$1\"[^\"]*\"\([^\"]*\)\".*/\1/p"; }
I="$(get input_i)"; TP="$(get input_tp)"; LRA="$(get input_lra)"; THRESH="$(get input_thresh)"
echo "  measured I=$I TP=$TP LRA=$LRA thresh=$THRESH"

ffmpeg -v error -y -ss "$START" -t "$DURATION" -i "$SRC" \
  -af "loudnorm=I=-15:TP=-1.5:LRA=11:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true,afade=t=in:st=0:d=0.18,afade=t=out:st=${FADE_OUT_AT}:d=0.8" \
  -c:a pcm_s16le -ar 48000 -ac 2 \
  "$OUT"

echo "wrote $OUT"
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT"
