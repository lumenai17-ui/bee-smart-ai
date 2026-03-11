---
name: image-edit
description: "Edit existing images: resize, crop, filter, remove background, add text overlay, or transform with AI. Uses Sharp for basic edits and DALL-E/SD for AI-powered editing."
version: 1.0.0
category: multimedia
tier: pro
requires:
  - tool: bash
  - tool: http
---

# image-edit

Edit and transform images with basic tools and AI.

## Instructions

### Basic edits with Sharp:
```bash
node -e "
const sharp = require('sharp');
await sharp('/tmp/input.jpg')
  .resize(800, 600)           // Resize
  .rotate(90)                  // Rotate
  .blur(5)                     // Blur
  .grayscale()                 // B&W
  .toFile('/tmp/output.jpg');
"
```

### Remove background:
```bash
curl -X POST "https://api.remove.bg/v1.0/removebg" \
  -H "X-Api-Key: $REMOVEBG_API_KEY" \
  -F "image_file=@/tmp/input.jpg" \
  -o /tmp/no-bg.png
```

### AI edit with DALL-E:
```bash
curl -X POST "https://api.openai.com/v1/images/edits" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "image=@/tmp/input.png" \
  -F "mask=@/tmp/mask.png" \
  -F "prompt=Add a sunset in the background" \
  -F "size=1024x1024"
```

## Usage Examples

### Example 1: Resize for social media
**User**: "Redimensiona esta imagen a 1080x1080 para Instagram"
**Response**: 🖼️ Imagen redimensionada a 1080x1080px. Lista para Instagram.

### Example 2: Remove background
**User**: "Quítale el fondo a la foto del producto"
**Response**: 🖼️ Fondo removido. Imagen con transparencia guardada como PNG.

## Error Handling

| Error | Action |
|---|---|
| Unsupported format | Convert to PNG/JPG first |
| Image too large | Resize before editing |
| API unavailable | Fall back to basic Sharp operations |
