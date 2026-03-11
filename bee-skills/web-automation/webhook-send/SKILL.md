---
name: webhook-send
description: "Send HTTP webhooks to external services and APIs. Use when the user needs to trigger an external action, notify another system, or send data to a third-party service via HTTP POST/PUT/PATCH."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: http
---

# webhook-send

Send HTTP requests (webhooks) to external services and APIs.

## Instructions

### Step 1: Prepare the request
- **URL**: Target endpoint
- **Method**: POST (default), PUT, PATCH, DELETE
- **Headers**: Content-Type, Authorization, custom headers
- **Body**: JSON payload with the data to send

### Step 2: Send the webhook
```bash
curl -X POST "https://hooks.example.com/webhook" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"event": "order_completed", "data": {"order_id": "12345", "amount": 150}}'
```

### Step 3: Confirm delivery
- Report HTTP status code and response body
- Report: `🔗 Webhook enviado: {status} — {endpoint}`

## Usage Examples

### Example 1: Zapier trigger
**User**: "Envía un webhook a Zapier cuando se complete el pedido"
**Response**: 🔗 Webhook enviado a Zapier: 200 OK. Trigger "order_completed" activado.

### Example 2: Slack notification
**User**: "Notifica al canal de Slack que el reporte está listo"
**Response**: 🔗 Mensaje enviado a Slack #general: "📊 Reporte mensual listo"

## Error Handling

| Error | Action |
|---|---|
| 401/403 Unauthorized | Check authorization header/token |
| 404 Not Found | Verify the webhook URL |
| Timeout | Retry once with longer timeout |
| 5xx Server Error | Retry with exponential backoff |
