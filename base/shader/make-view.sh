#!/bin/bash

# Usage: ./to_gif.sh input.mp4 output.gif 30

INPUT="$1"
OUTPUT="$2"
FPS="$3"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ] || [ -z "$FPS" ]; then
  echo "Usage: $0 input.mp4 output.gif <fps>"
  exit 1
fi

mkdir -p tmp
PALETTE="tmp/palette.png"

# Step 1: Generate palette
ffmpeg -y -i "$INPUT" -vf "fps=$FPS,scale=1024:-1:flags=lanczos,palettegen" "$PALETTE"

# Step 2: Create gif with correct delay handling
ffmpeg -y -i "$INPUT" -i "$PALETTE" \
  -filter_complex "[0:v]fps=$FPS,scale=1024:-1:flags=lanczos[video];[video][1:v]paletteuse" \
  -gifflags -offsetting -plays 0 "$OUTPUT"

# Cleanup
rm "$PALETTE"
