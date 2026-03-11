---
name: notification-send
description: "Send notifications across multiple channels: push notifications, email alerts, SMS alerts, or in-app notifications. Orchestrates delivery through the most appropriate channel based on urgency and user preferences."
version: 1.0.0
category: business
tier: basic
requires:
  - tool: http
  - tool: memory
---

# notification-send

Send multi-channel notifications with priority routing.

## Instructions

### Step 1: Determine notification parameters
- **Urgency**: low (email), medium (push), high (SMS + email), critical (all channels)
- **Recipients**: Individual, group, or all contacts
- **Content**: Title, body, action URL

### Step 2: Route by priority
| Priority | Channels |
|---|---|
| Low | Email only |
| Medium | Push notification + email |
| High | SMS + email |
| Critical | SMS + WhatsApp + email + push |

### Step 3: Send via appropriate skills
Delegate to the relevant skill:
- Email → `email-send` skill
- SMS → `sms-send` skill
- WhatsApp → `whatsapp-send` skill
- Push → Web Push API or Firebase

### Step 4: Track delivery
Report: `🔔 Notificación enviada a {count} destinatarios vía {channels}`

## Usage Examples

### Example 1: Urgent alert
**User**: "Notifica a todo el equipo que el servidor está caído — es urgente"
**Response**: 🔔 Alerta CRÍTICA enviada a 5 personas vía SMS + WhatsApp + Email. Todos confirmaron recibido.

### Example 2: Informational
**User**: "Avísale a los clientes que mañana hay mantenimiento"
**Response**: 🔔 Notificación enviada a 120 clientes vía email. Asunto: "Aviso de mantenimiento - 11 marzo"

## Error Handling

| Error | Action |
|---|---|
| No recipients configured | Ask who should receive the notification |
| Channel unavailable | Fall back to next priority channel |
| Partial delivery | Report which channels succeeded/failed |
