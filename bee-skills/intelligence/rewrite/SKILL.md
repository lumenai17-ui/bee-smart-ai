---
name: rewrite
description: "Rewrite text in a different tone, style, or format. Use when the user wants to make text more formal, casual, concise, expanded, or adapted for a specific audience. Handles tone shifting, simplification, and format conversion."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
---

# rewrite

Rewrite text in any desired tone, style, or format.

## Instructions

### Step 1: Understand the transformation
Determine what the user wants:
- **Tone change**: formal ↔ casual, friendly ↔ professional
- **Length**: expand (add detail) or condense (shorten)
- **Audience**: simplify for general public, or add technical depth
- **Format**: convert prose to bullet points, email to social post, etc.
- **Language level**: basic → advanced or vice versa

### Step 2: Rewrite preserving meaning
- Keep the core message intact
- Apply the requested transformation
- Maintain factual accuracy — never invent information
- Match the target audience's vocabulary

### Step 3: Present both versions
Show original and rewritten side by side when helpful.

## Usage Examples

### Example 1: Formal to casual
**User**: "Reescribe más casual: 'Estimado cliente, por medio de la presente le informamos que su pedido ha sido procesado satisfactoriamente'"

**Response**: ✏️ Reescrito (casual):
"¡Hola! 👋 Tu pedido ya fue procesado y todo está en orden. ¡Pronto lo recibirás!"

### Example 2: Expand for detail
**User**: "Expande este texto para un post de blog: 'La IA mejora la atención al cliente'"

**Response**: ✏️ Expandido (post de blog, 300 palabras):
"## Cómo la Inteligencia Artificial está Revolucionando la Atención al Cliente

En un mundo donde los consumidores esperan respuestas inmediatas, la IA se ha convertido en el aliado perfecto..."

### Example 3: Simplify
**User**: "Simplifica esto para que lo entienda alguien sin conocimientos técnicos"

**Response**: ✏️ Simplificado: "En lugar de guardar archivos en tu computadora, se guardan en internet para que puedas acceder desde cualquier lugar. Es como tener un USB que funciona desde cualquier dispositivo."

## Error Handling

| Error | Action |
|---|---|
| No text provided | Ask what text to rewrite |
| Unclear target style | Offer options: formal, casual, concise, expanded |
| Very long text (>5000 words) | Rewrite in sections |
