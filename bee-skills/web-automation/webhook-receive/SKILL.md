---
name: webhook-receive
description: "Listen for and process incoming webhooks from external services. Use when the user needs to receive notifications from payment processors, form submissions, social media events, or any external trigger."
version: 1.0.0
category: web-automation
tier: pro
requires:
  - tool: http
  - tool: bash
---

# webhook-receive

Listen for incoming webhooks and trigger actions based on the payload.

## Instructions

### Step 1: Register a webhook endpoint
The OpenClaw Gateway exposes webhook endpoints at:
```
https://{gateway-host}:18789/api/webhooks/{webhook-name}
```

### Step 2: Configure the handler
Define what action to take when a webhook arrives:
- Parse the incoming JSON payload
- Validate the signature/secret (if configured)
- Extract relevant data
- Trigger the appropriate skill or workflow

### Step 3: Common webhook sources

**Stripe (payment received):**
```json
{ "type": "payment_intent.succeeded", "data": { "amount": 5000, "currency": "mxn" } }
```
→ Action: Send confirmation email, update order status

**GitHub (push event):**
```json
{ "ref": "refs/heads/main", "commits": [{ "message": "fix: login bug" }] }
```
→ Action: Deploy, notify team on Discord

**Form submission:**
```json
{ "name": "Juan", "email": "juan@example.com", "message": "Quiero información" }
```
→ Action: Save lead, send auto-reply, notify operator

### Step 4: Report
- Log the webhook event
- Report: `🔔 Webhook recibido: {source} — ejecutando acción configurada...`

## Usage Examples

### Example 1: Payment notification
**Incoming**: Stripe webhook `payment_intent.succeeded`
**Response**: 🔔 Pago recibido: $500 MXN de juan@example.com → Email de confirmación enviado.

### Example 2: Form submission
**Incoming**: Contact form webhook
**Response**: 🔔 Nuevo lead capturado: Ana López (ana@empresa.com) → Guardado y auto-reply enviado.

## Error Handling

| Error | Action |
|---|---|
| Invalid signature | Reject with 401, log security event |
| Unknown webhook source | Log payload, notify admin |
| Handler error | Respond 500, retry processing |
