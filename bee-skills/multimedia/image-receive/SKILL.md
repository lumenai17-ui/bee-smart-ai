---
name: image-receive
description: "Analyze and describe received images using vision models. Use when the user sends an image and wants to know what's in it, asks questions about visual content, or needs image-based data extraction. Uses Qwen3-VL or similar vision models."
version: 1.0.0
category: multimedia
tier: basic
requires:
  - tool: memory
---

# image-receive

Analyze images using vision LLM models and describe/extract content.

## Instructions

### Step 1: Receive the image
- Accept from any channel (WhatsApp, Telegram, Discord, email)
- Supported formats: JPEG, PNG, WebP, GIF
- The vision model receives the image directly through the LLM context

### Step 2: Analyze with vision model
The agent has access to the `vision` sub-agent (Qwen3-VL) for image analysis. Delegate image analysis to this sub-agent when:
- User asks "¿Qué hay en esta imagen?"
- Need to extract text from a photo (for OCR use the `ocr` skill)
- Need to describe a product, scene, document, or chart

### Step 3: Present findings
Describe what the image contains clearly and relevantly:
- For products: name, brand, condition, approximate price
- For documents: content type, key text, layout
- For scenes: context, objects, people, text
- For charts/graphs: data points, trends, labels

## Usage Examples

### Example 1: Product photo
**User**: Sends photo of a laptop
**Response**: 📸 Imagen analizada: Laptop Dell XPS 15 (modelo 2025), color plateado, pantalla 15.6", teclado retroiluminado. Parece en buen estado. ¿Necesitas más detalles o quieres agregar al catálogo?

### Example 2: Restaurant receipt
**User**: Sends photo of a receipt
**Response**: 📸 Recibo detectado:
- Restaurante: La Trattoria
- Fecha: 10/03/2026
- Total: $450 MXN
- Propina: $90 MXN
¿Quieres que lo registre como gasto?

## Error Handling

| Error | Action |
|---|---|
| Image too blurry | Ask for a clearer photo |
| Vision model unavailable | Inform that image analysis requires vision model |
| Very large image (>20MB) | Resize before processing |
