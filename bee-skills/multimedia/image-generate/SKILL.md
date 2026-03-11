---
name: image-generate
description: "Generate images from text descriptions using AI models (DALL-E, Stable Diffusion). Use when the user asks to create, draw, design, or generate any visual content from a text prompt."
version: 1.0.0
category: multimedia
tier: pro
requires:
  - tool: http
---

# image-generate

Generate images from text prompts using DALL-E or Stable Diffusion.

## Instructions

### Step 1: Craft the prompt
Enhance the user's description into an effective image generation prompt:
- Add style details (photorealistic, illustration, vector, watercolor)
- Specify composition, lighting, and perspective
- Include resolution and aspect ratio

### Step 2: Generate with DALL-E 3
```bash
curl -X POST "https://api.openai.com/v1/images/generations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "dall-e-3",
    "prompt": "Enhanced prompt here",
    "n": 1,
    "size": "1024x1024",
    "quality": "standard"
  }'
```

### Alternative: Stable Diffusion (local/API)
```bash
curl -X POST "http://localhost:7860/sdapi/v1/txt2img" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Your prompt",
    "negative_prompt": "blurry, low quality",
    "steps": 30,
    "width": 1024,
    "height": 1024
  }'
```

### Step 3: Deliver
- Save the generated image
- Show the image to the user
- Report: `🎨 Imagen generada: {description}`
- Offer variations or edits

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | For DALL-E | OpenAI API key |
| `SD_API_URL` | For SD | Stable Diffusion API URL |

## Usage Examples

### Example 1: Logo
**User**: "Genera un logo para una cafetería llamada 'Bean Dreams'"
**Response**: 🎨 Logo generado: Un grano de café estilizado con ojos soñadores, colores cálidos. ¿Quieres variaciones?

### Example 2: Social media post
**User**: "Crea una imagen para promocionar nuestro 50% de descuento"
**Response**: 🎨 Imagen promocional creada (1080x1080). Diseño vibrante con "50% OFF" prominente.

## Error Handling

| Error | Action |
|---|---|
| OPENAI_API_KEY not set | Try Stable Diffusion, if unavailable inform user |
| Content policy rejection | Rephrase prompt removing flagged content |
| Rate limited | Queue and retry after delay |
