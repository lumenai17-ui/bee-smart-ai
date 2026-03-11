---
name: discord-send
description: "Send messages to Discord channels or users via the Discord Bot API. Use when the user asks to post in Discord, send a notification to a Discord channel, or share content via Discord. Supports text, embeds, and file uploads."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: http
---

# discord-send

Send messages, rich embeds, and files to Discord channels.

## Instructions

### Step 1: Determine target and message type
- **Channel message**: Post to a specific channel by ID
- **Embed**: Rich formatted message with title, description, color, fields
- **File upload**: Attach files to a message
- You need a `channel_id` — get it from the configuration or context

### Step 2: Send via Discord API

**Text message:**
```bash
curl -X POST "https://discord.com/api/v10/channels/CHANNEL_ID/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "content": "Tu mensaje aquí" }'
```

**Rich embed:**
```bash
curl -X POST "https://discord.com/api/v10/channels/CHANNEL_ID/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "embeds": [{
      "title": "📊 Reporte Diario",
      "description": "Métricas del día",
      "color": 16750848,
      "fields": [
        { "name": "Ventas", "value": "$1,200", "inline": true },
        { "name": "Clientes", "value": "15", "inline": true }
      ],
      "footer": { "text": "BEE Smart AI" }
    }]
  }'
```

### Step 3: Confirm delivery
- Parse response for `id` field
- Report: `💬 Mensaje enviado al canal de Discord`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DISCORD_BOT_TOKEN` | Yes | Discord bot token |
| `DISCORD_GUILD_ID` | Optional | Default server (guild) ID |

## Usage Examples

### Example 1: Channel notification
**User**: "Avisa en Discord que el servidor está actualizado"

**Response**: 💬 Mensaje enviado al canal #announcements: "✅ Servidor actualizado a v2.1.0"

### Example 2: Rich embed report
**User**: "Publica el resumen de ventas en Discord"

**Response**: 💬 Embed enviado al canal de Discord con las métricas del día.

## Error Handling

| Error | Action |
|---|---|
| Bot token not set | Tell user to configure `DISCORD_BOT_TOKEN` |
| Missing permissions (403) | Bot needs "Send Messages" permission in channel |
| Channel not found | Verify channel ID is correct |
| Message > 2000 chars | Split into multiple messages or use embed |
