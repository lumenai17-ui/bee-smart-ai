---
name: video-create
description: "Generate videos from text prompts or images using AI models (Runway). Use when the user wants to create a short video, animation, or visual content from a description or image."
version: 1.0.0
category: multimedia
tier: enterprise
requires:
  - tool: http
---

# video-create

Generate AI videos from text or images using Runway.

## Instructions

### Step 1: Prepare the input
- **Text-to-video**: Craft a detailed video prompt
- **Image-to-video**: Start from a static image and animate it

### Step 2: Generate with Runway API
```bash
curl -X POST "https://api.dev.runwayml.com/v1/image_to_video" \
  -H "Authorization: Bearer $RUNWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gen3a_turbo",
    "promptImage": "https://example.com/image.jpg",
    "promptText": "Camera slowly zooming in, cinematic lighting",
    "duration": 5,
    "ratio": "16:9"
  }'
```

### Step 3: Poll for completion and download
- Runway processes asynchronously — poll the task ID until complete
- Download the generated video
- Report: `🎬 Video creado: {duration}s, {resolution}`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `RUNWAY_API_KEY` | Yes | Runway API key |

## Usage Examples

### Example 1: Product showcase
**User**: "Crea un video corto de este producto girando"
**Response**: 🎬 Video generado (5s, 1080p): Producto girando 360° con fondo limpio.

### Example 2: Social media content
**User**: "Genera un video de 5 segundos para Instagram de una taza de café con vapor"
**Response**: 🎬 Video creado: Taza de café con vapor suave, iluminación cálida (5s, 1:1).

## Error Handling

| Error | Action |
|---|---|
| RUNWAY_API_KEY not set | Inform: enterprise feature requires Runway API |
| Content policy violation | Rephrase prompt |
| Generation timeout | Retry with simpler prompt |
