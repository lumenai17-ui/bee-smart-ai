---
name: calendar-manage
description: "Manage calendar events via Google Calendar API. Create, read, update, and delete events. Check availability, schedule meetings, and send invitations."
version: 1.0.0
category: productivity
tier: pro
requires:
  - tool: http
---

# calendar-manage

Manage Google Calendar events and scheduling.

## Instructions

### Step 1: Authenticate with Google
Uses OAuth2 with `$GOOGLE_OAUTH_TOKEN`.

### Step 2: Common operations

**List events:**
```bash
curl "https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=$(date -u +%Y-%m-%dT00:00:00Z)&maxResults=10&orderBy=startTime&singleEvents=true" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN"
```

**Create event:**
```bash
curl -X POST "https://www.googleapis.com/calendar/v3/calendars/primary/events" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Reunión con cliente",
    "start": { "dateTime": "2026-03-15T10:00:00-05:00" },
    "end": { "dateTime": "2026-03-15T11:00:00-05:00" },
    "attendees": [{ "email": "cliente@example.com" }],
    "reminders": { "useDefault": false, "overrides": [{ "method": "popup", "minutes": 15 }] }
  }'
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_OAUTH_TOKEN` | Yes | Google OAuth2 access token |

## Usage Examples

### Example 1: Check agenda
**User**: "¿Qué tengo para hoy?"
**Response**: 📅 Hoy (10 marzo):
1. 09:00 — Standup diario (30 min)
2. 11:00 — Reunión con Ana López (1h)
3. 15:00 — Demo al cliente (2h)

### Example 2: Schedule meeting
**User**: "Agenda una reunión con carlos@empresa.com el viernes a las 3pm"
**Response**: 📅 Evento creado: "Reunión" — Viernes 14 de marzo, 3:00pm. Invitación enviada a carlos@empresa.com.

## Error Handling

| Error | Action |
|---|---|
| OAuth not configured | Guide: "🔐 Configura Google Auth en Configuración" |
| Time conflict | Show conflicts and suggest alternatives |
| Token expired | Prompt to re-authenticate |
