---
name: voice-receive
description: "Receive and transcribe incoming voice notes and audio messages. Use when a voice message arrives and needs to be understood, transcribed, or acted upon. Uses OpenAI Whisper for transcription."
version: 1.0.0
category: communication
tier: pro
requires:
  - tool: http
  - tool: bash
---

# voice-receive

Transcribe incoming voice notes from any channel using Whisper API.

## Instructions

### Step 1: Receive the audio file
When a voice note arrives from WhatsApp, Telegram, or Discord:
- Download the audio file to a temporary location
- Identify the format (ogg, mp3, m4a, wav, webm)
- Note the duration and source channel

### Step 2: Transcribe with Whisper API

```bash
curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=whisper-1" \
  -F "file=@/tmp/voice_note.ogg" \
  -F "language=es" \
  -F "response_format=verbose_json"
```

### Step 3: Process the transcription
- Extract the text from the API response
- Detect the language if not specified
- Calculate confidence score from `segments`
- Present: `🎙️ Mensaje de voz ({duration}s): "{transcription}"`

### Step 4: Act on the content
After transcribing, treat the text as if the user typed it:
- If it's a command, execute it
- If it's a question, answer it
- If it's unclear, ask for clarification showing the transcription

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | OpenAI API key (for Whisper) |

## Usage Examples

### Example 1: WhatsApp voice note
**Incoming**: Voice note from +521234567890 (15 seconds)

**Response**: 🎙️ Mensaje de voz (15s): "Oye necesito que me mandes la factura del mes pasado por favor"
→ Procesando solicitud de factura...

### Example 2: Long voice memo
**Incoming**: Audio message (2 min, 30 sec)

**Response**: 🎙️ Transcripción (2:30):
"Buenas tardes. Quiero confirmar mi reservación para el sábado. Somos 6 personas, llegaremos a las 8pm. También quería preguntar si tienen menú vegetariano..."

¿Quieres que confirme la reservación con estos datos?

## Error Handling

| Error | Action |
|---|---|
| OPENAI_API_KEY not set | Inform user: "⚠️ Para voz necesito OPENAI_API_KEY" |
| Audio too long (>25MB) | Compress with FFmpeg, split if needed |
| Unsupported format | Convert to mp3 with FFmpeg first |
| Low quality audio | Warn about possible transcription errors |
