---
name: webm-to-gif
description: Converts .webm video files into optimized .gif files using ffmpeg and gifsicle. Use whenever the user says "turn webm into gif", "screen recording to gif", "how do I make a gif on Linux", or asks to convert/share a screencast or video recording as an animated gif. Works on any .webm file.
tools: Bash, Read, Glob
---

# webm-to-gif

Convert `.webm` files into shareable `.gif` files using `ffmpeg` (pre-installed on this system) and optionally `gifsicle` for compression.

## Why two-pass ffmpeg

A single `ffmpeg -i in.webm out.gif` produces washed-out colors because ffmpeg picks a generic 256-color palette. The two-pass approach generates an *optimal* palette from the actual video frames first, then uses it when encoding — dramatically better color fidelity at the same file size.

## Dependency check

```bash
which gifsicle || echo "not installed"
```

If gifsicle is missing and the user wants smaller files:
```bash
sudo apt install gifsicle
```
gifsicle is open-source (GPL), widely used, and in the Ubuntu main repo. Optional — skip if the user doesn't want to install anything extra.

## Defaults

| Parameter | Default | Rationale |
|-----------|---------|-----------|
| fps | 10 | Smooth enough for screencasts; keeps file size reasonable |
| width | 800 | Good for sharing; preserves aspect ratio |
| dither | bayer:bayer_scale=5 | Reduces banding without large size cost |
| output dir | same as input | Predictable; no hidden files elsewhere |

Adjust based on user request. Higher fps (15–20) for fast cursor movement; wider (1024+) when screencasts show code.

## Conversion commands

### Single file, standard quality

```bash
# Wrap in subshell so the EXIT trap is scoped here, not the parent shell
(
  INPUT="$HOME/Videos/Screencasts/recording.webm"
  OUTPUT="${INPUT%.webm}.gif"
  PALETTE=$(mktemp --suffix=.png)
  FPS=10
  WIDTH=800

  trap 'rm -f "$PALETTE"' EXIT

  ffmpeg -y -i "$INPUT" \
    -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=diff" \
    "$PALETTE"

  ffmpeg -y -i "$INPUT" -i "$PALETTE" \
    -filter_complex "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    "$OUTPUT"

  echo "Created: $OUTPUT ($(du -h --apparent-size "$OUTPUT" | cut -f1))"
)
```

### With gifsicle optimization (smaller file)

Append inside the subshell above, after the last ffmpeg line:
```bash
  gifsicle -O3 --lossy=80 "$OUTPUT" -o "$OUTPUT"
  echo "Optimized: $OUTPUT ($(du -h --apparent-size "$OUTPUT" | cut -f1))"
```

### Trim a time range

Add `-ss START -t DURATION` before `-i "$INPUT"` on both ffmpeg lines:
```bash
# Example: start at 5s, take 30s
ffmpeg -y -ss 5 -t 30 -i "$INPUT" \
  -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$PALETTE"

ffmpeg -y -ss 5 -t 30 -i "$INPUT" -i "$PALETTE" \
  -filter_complex "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  "$OUTPUT"
```

### Speed up / slow down playback

Use `setpts=(1/SPEED)*PTS` in the filter chain. Examples: `2x = 0.5*PTS`,
`3x = 0.333*PTS`, `0.5x = 2.0*PTS`. GIFs have no audio track — no `atempo`
or `-an` needed. For webm-to-webm conversion that keeps audio, use the
audio variant below.

Insert `setpts` between `fps` and `scale` on the second ffmpeg pass only
(palette pass uses original timing — drop the `setpts` there or palette
generation will skip frames). With trim, `-ss/-t` reflect SOURCE time, so
output duration = `DURATION / SPEED`.

```bash
# 2x speed of trimmed range — example: first 52s source → 26s gif
SPEED=2.0
PTS=$(awk -v s="$SPEED" 'BEGIN{printf "%.6f", 1/s}')

ffmpeg -y -ss 0 -t 52 -i "$INPUT" \
  -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$PALETTE"

ffmpeg -y -ss 0 -t 52 -i "$INPUT" -i "$PALETTE" \
  -filter_complex "setpts=${PTS}*PTS,fps=${FPS},scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  "$OUTPUT"
```

For webm-to-webm with audio synced to new speed:
```bash
# 2x: video setpts=0.5, audio atempo=2.0 (atempo range is 0.5–2.0 per filter; chain for >2x)
ffmpeg -y -i "$INPUT" -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]" out.webm
```

### Batch: all webm files in a directory

```bash
SCREENCAST_DIR="$HOME/Videos/Screencasts"
FPS=10
WIDTH=800
CURRENT_PALETTE=""

trap 'rm -f "$CURRENT_PALETTE"' EXIT INT TERM

shopt -s nullglob
webm_files=("$SCREENCAST_DIR"/*.webm)
shopt -u nullglob

if [[ ${#webm_files[@]} -eq 0 ]]; then
  echo "No .webm files found in $SCREENCAST_DIR"
  exit 0
fi

for INPUT in "${webm_files[@]}"; do
  OUTPUT="${INPUT%.webm}.gif"
  CURRENT_PALETTE=$(mktemp --suffix=.png)

  err=$(ffmpeg -y -i "$INPUT" \
    -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen=stats_mode=diff" \
    "$CURRENT_PALETTE" 2>&1) || { echo "Palette failed for: $INPUT"; echo "$err"; rm -f "$CURRENT_PALETTE"; continue; }

  err=$(ffmpeg -y -i "$INPUT" -i "$CURRENT_PALETTE" \
    -filter_complex "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    "$OUTPUT" 2>&1) || { echo "Encode failed for: $INPUT"; echo "$err"; rm -f "$CURRENT_PALETTE"; continue; }

  rm -f "$CURRENT_PALETTE"
  echo "Done: $OUTPUT ($(du -h --apparent-size "$OUTPUT" | cut -f1))"
done
```

## Moving source files after conversion

After a successful conversion, move the source `.webm` into a `completed/` subdirectory alongside it. This keeps the source directory clean and makes it easy to see what's been processed without deleting originals.

```bash
# Single file — run after successful gif creation
COMPLETED_DIR="$(dirname "$INPUT")/completed"
mkdir -p "$COMPLETED_DIR"
mv "$INPUT" "$COMPLETED_DIR/"
echo "Moved source: $COMPLETED_DIR/$(basename "$INPUT")"
```

For batch, add the same block inside the loop after the `echo "Done: ..."` line:
```bash
  COMPLETED_DIR="$(dirname "$INPUT")/completed"
  mkdir -p "$COMPLETED_DIR"
  mv "$INPUT" "$COMPLETED_DIR/"
```

Only move on success — the `continue` on ffmpeg failure already skips this block in the batch loop.

## Workflow

1. Find the webm file(s):
   ```bash
   ls -lh "$HOME/Videos/Screencasts/"*.webm 2>/dev/null
   ls -lh ./*.webm 2>/dev/null
   ```
   If neither location has webm files, ask the user for the path.
2. Confirm: single file or batch? Any time range? Different fps or width?
3. Run the appropriate command block above.
4. Move source `.webm` to `completed/` subdirectory (see above).
5. Report output path and file size.
6. If file is large (>10 MB), suggest gifsicle or lowering fps/width.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Colors look washed out | Palette pass ran but wasn't used — check filter_complex syntax |
| Output too large | Lower `FPS` to 8, `WIDTH` to 600, or run gifsicle |
| `ffmpeg: command not found` | `sudo apt install ffmpeg` |
| `mktemp: failed` | Use `PALETTE=/tmp/palette_$$.png` as fallback |
