---
name: reminder-set
description: "Set time-based reminders that notify the user at a specified future time. Use when the user says 'remind me', 'don't let me forget', or sets a deadline for any task."
version: 1.0.0
category: productivity
tier: basic
requires:
  - tool: bash
  - tool: memory
---

# reminder-set

Create and manage time-based reminders.

## Instructions

### Step 1: Parse the time information
- "En 30 minutos" → now + 30 min
- "Mañana a las 9am" → next day 09:00
- "El viernes" → next Friday 09:00
- "En 2 horas" → now + 2h

### Step 2: Create the reminder
```bash
# Store in memory + schedule notification
echo '{"reminder":"Llamar al cliente","time":"2026-03-11T09:00:00","channel":"whatsapp"}' >> /data/reminders.json
```

### Step 3: Use cron for triggering
Integrate with the `cron-schedule` skill for recurring reminders.

### Step 4: Notify when due
When the time arrives, send via the most appropriate channel:
- In-chat: Show the reminder in the conversation
- WhatsApp/Telegram: Send a message
- Email: Send a reminder email

## Usage Examples

### Example 1: Simple reminder
**User**: "Recuérdame llamar a Juan mañana a las 10am"
**Response**: ⏰ Recordatorio programado: "Llamar a Juan" — mañana 10:00am. Te avisaré por este chat.

### Example 2: Recurring
**User**: "Recuérdame revisar las reseñas cada lunes"
**Response**: ⏰ Recordatorio recurrente: "Revisar reseñas" — cada lunes a las 9:00am.

## Error Handling

| Error | Action |
|---|---|
| Ambiguous time | Ask to clarify (¿AM o PM? ¿Qué día?) |
| Past time | Inform and suggest correct time |
| Timezone unclear | Use configured timezone from .env |
