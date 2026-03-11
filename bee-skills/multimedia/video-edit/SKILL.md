---
name: video-edit
description: "Edit existing videos: trim, merge, add text overlays, add music, change speed, and apply effects. Uses FFmpeg for processing and Mux for cloud-based editing."
version: 1.0.0
category: multimedia
tier: pro
requires:
  - tool: bash
---

# video-edit

Edit videos with trimming, merging, overlays, and effects.

## Instructions

### Common operations with FFmpeg:

**Trim:**
```bash
ffmpeg -i input.mp4 -ss 00:00:30 -to 00:01:30 -c copy trimmed.mp4
```

**Merge multiple videos:**
```bash
# Create file list
echo "file 'clip1.mp4'" > /tmp/list.txt
echo "file 'clip2.mp4'" >> /tmp/list.txt
ffmpeg -f concat -safe 0 -i /tmp/list.txt -c copy merged.mp4
```

**Add text overlay:**
```bash
ffmpeg -i input.mp4 -vf "drawtext=text='50%% OFF':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" output.mp4
```

**Add background music:**
```bash
ffmpeg -i video.mp4 -i music.mp3 -c:v copy -c:a aac -shortest output.mp4
```

**Speed up/slow down:**
```bash
# 2x speed
ffmpeg -i input.mp4 -filter:v "setpts=0.5*PTS" -filter:a "atempo=2.0" fast.mp4
# Slow motion (0.5x)
ffmpeg -i input.mp4 -filter:v "setpts=2*PTS" -filter:a "atempo=0.5" slow.mp4
```

## Usage Examples

### Example 1: Create social reel
**User**: "Recorta los primeros 30 segundos y ponle el logo"
**Response**: 🎬 Video editado: 30s, logo en esquina inferior derecha. ¿Lo exporto para Instagram?

### Example 2: Merge clips
**User**: "Junta estos 3 clips en un solo video"
**Response**: 🎬 3 clips combinados: duración total 2:45. Transiciones suaves aplicadas.

## Error Handling

| Error | Action |
|---|---|
| FFmpeg error | Check codec compatibility, try re-encoding |
| Files different resolution | Normalize to largest resolution |
| Audio sync issues | Re-encode with `-async 1` |
