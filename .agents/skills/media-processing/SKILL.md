---
name: media-processing
description: Use when converting, transcoding, or optimizing video and audio files (WMV, MKV, AVI, etc. to MP4) for smooth playback and preview inside Kodbox.
metadata:
  category: multimedia
  triggers: ffmpeg, transcode, video-convert, wmv, mp4, h264, web-streaming
---

# Media Processing & Transcoding for Remote Explorer

Use this skill when processing video or audio files stored in Remote Explorer to ensure compatibility with Kodbox's built-in web media players.

## Target Video Standard for Web Browsers & Kodbox

Kodbox's web player relies on HTML5 video (`<video>`). The most universally supported format across browsers (Chrome, Firefox, Safari, Edge, Mobile) is:
- **Container**: MP4 (`.mp4`)
- **Video Codec**: H.264 (AVC)
- **Audio Codec**: AAC (Stereo, 44.1 kHz or 48 kHz)
- **Pixel Format**: `yuv420p`

## FFmpeg Transcoding Recipes

### 1. Fast Transcode (Standard Quality)
Converts any container (WMV, MKV, AVI, FLV) to web-optimized MP4:
```bash
ffmpeg -i input.wmv -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k -movflags +faststart output.mp4
```
*Note: `-movflags +faststart` moves the index to the beginning of the file, allowing instant streaming in Kodbox without waiting for full download.*

### 2. High Compatibility Profile (Apple TV, iOS, Safari)
Ensures strict profile levels and audio sample rates:
```bash
ffmpeg -i input.wmv \
  -c:v libx264 -crf 23 -profile:v high -level 4.0 -r 30 -pix_fmt yuv420p \
  -c:a aac -b:a 160k -ar 48000 \
  -movflags +faststart output.mp4
```

### 3. Quick Remux (Zero Re-encoding)
If the video is already H.264 and audio is AAC, but trapped inside an MKV or AVI container:
```bash
ffmpeg -i input.mkv -c copy -movflags +faststart output.mp4
```
*Executes in seconds with zero loss of quality.*

### 4. Batch Processing Directories
Convert all `.wmv` files in the current folder:
```bash
for file in *.wmv; do
  [ -e "$file" ] || continue
  out="${file%.*}.mp4"
  echo "Transcoding $file -> $out"
  ffmpeg -y -i "$file" \
    -c:v libx264 -crf 23 -preset faster -c:a aac -q:a 100 \
    -movflags +faststart "$out"
done
```

Recursive conversion for subfolders:
```bash
find . -type f -name "*.wmv" | while read -r file; do
  out="${file%.*}.mp4"
  if [ ! -f "$out" ]; then
    echo "Processing: $file"
    ffmpeg -y -i "$file" -c:v libx264 -crf 23 -c:a aac -q:a 100 -movflags +faststart "$out"
  fi
done
```

### 5. Generating Video Poster / Thumbnail
Create a 1280x720 JPEG thumbnail taken at 5 seconds:
```bash
ffmpeg -ss 00:00:05 -i input.mp4 -vframes 1 -q:v 2 thumbnail.jpg
```
