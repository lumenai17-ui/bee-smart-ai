---
name: telegram-send
description: "Send messages via Telegram Bot API. Use when the user asks to send a message, photo, document, or notification via Telegram. Supports text with Markdown, photos, documents, and reply keyboards."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: http
---

# telegram-send

Send messages, photos, and documents via the Telegram Bot API.

## Instructions

### Step 1: Determine message type and parameters
- **Text**: Message with optional Markdown/HTML formatting
- **Photo**: Image with optional caption
- **Document**: File with optional caption
- **Location**: Latitude/longitude
- Requires a `chat_id` — this can be a user ID, group ID, or channel username

### Step 2: Send via Telegram Bot API

**Text message:**
```bash
curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "CHAT_ID",
    "text": "Tu mensaje aquí",
    "parse_mode": "Markdown"
  }'
```

**Photo:**
```bash
curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendPhoto" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "CHAT_ID",
    "photo": "https://example.com/image.jpg",
    "caption": "Descripción de la imagen"
  }'
```

**Document:**
```bash
curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "CHAT_ID",
    "document": "https://example.com/file.pdf",
    "caption": "Archivo adjunto"
  }'
```

### Step 3: Confirm delivery
- Parse response for `ok: true` and `message_id`
- Report: `💬 Mensaje de Telegram enviado`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Yes | Bot token from @BotFather |

## Usage Examples

### Example 1: Text message
**User**: "Envía por Telegram: 'La reunión se canceló'"

**Response**: 💬 Mensaje enviado por Telegram. Confirmación: ✓

### Example 2: Photo with caption
**User**: "Manda la foto del menú por Telegram al grupo"

**Response**: 📸 Foto enviada al grupo de Telegram con caption "Menú del día - Marzo 10".

## Error Handling

| Error | Action |
|---|---|
| Bot token not set | Tell user to configure `TELEGRAM_BOT_TOKEN` |
| Chat not found (403) | Bot needs to be added to the group first |
| Message too long (>4096 chars) | Split into multiple messages |
| File too large (>50MB) | Compress or use a link instead |
