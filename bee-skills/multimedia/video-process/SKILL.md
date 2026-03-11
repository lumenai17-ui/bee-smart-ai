---
name: video-process
description: "Process videos: extract audio, convert formats, compress, extract frames, get metadata, and add subtitles. Uses FFmpeg for all video processing operations."
version: 1.0.0
category: multimedia
tier: pro
requires:
  - tool: bash
---

# video-process

Process, convert, and analyze video files with FFmpeg.

## Instructions

### Common FFmpeg operations:

**Convert format:**
```bash
ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4
```

**Compress (reduce size):**
```bash
ffmpeg -i input.mp4 -crf 28 -preset fast -c:a aac -b:a 128k output_compressed.mp4
```

**Extract audio:**
```bash
ffmpeg -i input.mp4 -vn -acodec mp3 audio.mp3
```

**Extract frames/thumbnail:**
```bash
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.jpg
```

**Add subtitles:**
```bash
ffmpeg -i input.mp4 -vf "subtitles=subs.srt" output_subtitled.mp4
```

**Get metadata:**
```bash
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```

**Trim video:**
```bash
ffmpeg -i input.mp4 -ss 00:01:00 -to 00:02:30 -c copy trimmed.mp4
```

## Usage Examples

### Example 1: Compress for WhatsApp
**User**: "Comprime este video para enviarlo por WhatsApp (max 16MB)"
**Response**: 🎬 Video comprimido: 45MB → 14MB. Calidad: buena. Duración: 2:30. Listo para WhatsApp.

### Example 2: Extract audio
**User**: "Extrae el audio de este video"
**Response**: 🎬 Audio extraído: "audio.mp3" (3:45, 128kbps). ¿Quieres que lo transcriba?

## Error Handling

| Error | Action |
|---|---|
| FFmpeg not installed | Inform user it's required |
| Unsupported codec | Try with software decoding |
| File too large (>1GB) | Process in segments |
| Corrupted video | Try to repair with `ffmpeg -err_detect ignore_err` |
