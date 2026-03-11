---
name: voice-transcribe
description: "Transcribe audio files (recordings, meetings, podcasts) to text using Whisper API. Use when the user provides an audio file and wants the text content extracted, summarized, or translated. Supports multiple languages and audio formats."
version: 1.0.0
category: communication
tier: pro
requires:
  - tool: http
  - tool: bash
---

# voice-transcribe

Transcribe audio files to text with language detection and speaker identification.

## Instructions

### Step 1: Receive and validate the audio file
- Accept formats: mp3, mp4, mpeg, mpga, m4a, wav, webm, ogg, flac
- Check file size (max 25MB for Whisper API)
- If > 25MB, compress with FFmpeg:
```bash
ffmpeg -i input.wav -b:a 64k -map a /tmp/compressed.mp3
```

### Step 2: Transcribe with Whisper

```bash
curl -X POST "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=whisper-1" \
  -F "file=@/tmp/audio_file.mp3" \
  -F "response_format=verbose_json" \
  -F "timestamp_granularities[]=segment"
```

For **translation** (any language → English):
```bash
curl -X POST "https://api.openai.com/v1/audio/translations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "model=whisper-1" \
  -F "file=@/tmp/audio_file.mp3"
```

### Step 3: Format the output
Present the transcription clearly:
- Short audio (<1 min): Show full text inline
- Medium audio (1-10 min): Show with timestamps per segment
- Long audio (>10 min): Provide summary + key points, full text as attachment

### Step 4: Offer follow-up actions
- "¿Quieres que resuma lo más importante?"
- "¿Quieres que traduzca la transcripción?"
- "¿Quieres que la guarde como documento?"

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | OpenAI API key (for Whisper) |

## Usage Examples

### Example 1: Meeting recording
**User**: "Transcribe la grabación de la reunión de hoy"

**Response**: 📝 Transcripción completada (45 min, idioma: español):

**Resumen**: Reunión de equipo sobre lanzamiento Q2. Se acordaron 3 puntos principales...

**Puntos clave**:
1. Fecha de lanzamiento: 15 de abril
2. Presupuesto aprobado: $12,000
3. Responsable: Ana López

Transcripción completa: 3,240 palabras. ¿La guardo como documento?

### Example 2: Quick audio
**User**: "¿Qué dice este audio?" (sends 30s recording)

**Response**: 🎙️ Transcripción (30s): "Buenos días, le llamo del banco para confirmar su cita del viernes a las 2pm. Por favor confirme respondiendo a este mensaje."

## Error Handling

| Error | Action |
|---|---|
| OPENAI_API_KEY not set | Inform user to configure API key |
| File too large (>25MB) | Auto-compress with FFmpeg and retry |
| Unsupported format | Convert with FFmpeg to mp3 |
| Multiple speakers (unclear) | Note possible speaker changes, suggest verification |
| Poor audio quality | Warn about accuracy and show confidence % |
