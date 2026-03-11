---
name: cron-schedule
description: "Schedule recurring tasks using cron expressions. Use when the user wants to automate repetitive activities: daily reports, weekly backups, hourly checks, or any time-based task. Integrates with the BEE Automation Scheduler."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: bash
---

# cron-schedule

Create and manage scheduled recurring tasks.

## Instructions

### Step 1: Understand the schedule
Translate user request to cron expression:

| Request | Cron | Description |
|---|---|---|
| "Cada día a las 9am" | `0 9 * * *` | Daily at 9:00 |
| "Cada hora" | `0 * * * *` | Every hour |
| "Lunes a viernes 8am" | `0 8 * * 1-5` | Weekdays 8:00 |
| "Cada 15 minutos" | `*/15 * * * *` | Every 15 min |
| "Primer día del mes" | `0 9 1 * *` | 1st of month 9:00 |
| "Domingos a las 6pm" | `0 18 * * 0` | Sundays 18:00 |

### Step 2: Register the task
Use the Automation Scheduler API:
```bash
curl -X POST "http://localhost:18789/api/automations/schedule" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Reporte diario",
    "expression": "0 9 * * *",
    "action": "generate-daily-report",
    "enabled": true
  }'
```

### Step 3: Confirm
Report: `⏰ Tarea programada: "{name}" cada {frequency}. Próxima ejecución: {next_run}`

## Usage Examples

### Example 1: Daily report
**User**: "Programa un reporte diario a las 9am"
**Response**: ⏰ Tarea programada: "Reporte Diario" cada día a las 9:00am. Próxima ejecución: mañana 9:00am.

### Example 2: List scheduled tasks
**User**: "¿Qué tareas tengo programadas?"
**Response**: 📋 3 tareas activas:
1. ⏰ "Reporte Diario" — cada día 9:00am (próx: mañana)
2. ⏰ "Backup DB" — cada domingo 2:00am (próx: domingo)
3. ⏰ "Check Reviews" — cada 6 horas (próx: en 4h)

## Error Handling

| Error | Action |
|---|---|
| Invalid cron expression | Help user formulate correctly |
| Tier limit reached | Inform about plan upgrade |
| Task overlap | Warn and ask for confirmation |
