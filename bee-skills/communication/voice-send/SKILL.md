---
name: voice-send
description: "Generate and send voice messages using text-to-speech (OpenAI TTS). Use when the user asks to respond with audio, send a voice note, or when voice output would be more appropriate than text."
version: 1.0.0
category: communication
tier: pro
requires:
  - tool: http
  - tool: bash
---

# voice-send

Generate voice messages from text using OpenAI TTS and send to any channel.

## Instructions

### Step 1: Prepare the text
- Take the text to convert to speech
- Keep it concise — voice messages work best under 1 minute
- Apply the business tone (formal/casual) from branding config

### Step 2: Generate audio with TTS API

```bash
curl -X POST "https://api.openai.com/v1/audio/speech" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1",
    "voice": "nova",
    "input": "Tu texto aquí",
    "response_format": "opus",
    "speed": 1.0
  }' --output /tmp/voice_response.opus
```

### Step 3: Send the audio
- Use the appropriate channel's send skill (whatsapp-send, telegram-send, etc.)
- Send as audio/voice note attachment
- Include a text fallback for accessibility

### Available voices
| Voice | Style | Best for |
|---|---|---|
| `nova` | Femenina, clara | Atención al cliente |
| `alloy` | Neutral | General purpose |
| `echo` | Masculina | Formal/corporativo |
| `shimmer` | Suave, cálida | Servicios personales |
| `fable` | Narrativa | Cuentos, tutoriales |
| `onyx` | Profunda | Autoridad, seriedad |

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | OpenAI API key (for TTS) |

## Usage Examples

### Example 1: Voice response
**User**: "Respóndele con un audio diciendo que ya tiene su reservación confirmada"

**Response**: 🔊 Audio generado (8s, voz: nova) y enviado por WhatsApp.

### Example 2: Custom voice
**User**: "Manda un audio con voz masculina formal confirmando la cotización"

**Response**: 🔊 Audio generado con voz "echo" (12s) y enviado.

## Error Handling

| Error | Action |
|---|---|
| OPENAI_API_KEY not set | Inform: "⚠️ Para generar voz necesito OPENAI_API_KEY" |
| Text too long (>4096 chars) | Split into multiple audio segments |
| Generation failed | Retry once, then send text-only fallback |
