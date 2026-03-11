---
name: sms-send
description: "Send SMS text messages via Twilio API. Use when the user asks to send a text message, SMS, or needs to reach someone by phone number with a short message. Supports international numbers."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: http
---

# sms-send

Send SMS text messages to any phone number worldwide via Twilio.

## Instructions

### Step 1: Gather information
- **Phone number**: Must include country code (e.g., +52 for Mexico, +1 for US)
- **Message**: SMS body — max 160 chars for single SMS, up to 1600 for long SMS
- Auto-detect country code from context if the user omits it

### Step 2: Normalize the phone number
```bash
# Remove spaces, dashes, parentheses
# Ensure starts with +
# Mexican numbers: +52 + 10 digits
# US/Canada: +1 + 10 digits
```

### Step 3: Send via Twilio API

```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
  -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
  -d "From=$TWILIO_PHONE_NUMBER" \
  -d "To=+521234567890" \
  -d "Body=Tu mensaje aquí"
```

### Step 4: Confirm delivery
- Parse response for `sid` and `status`
- Report: `📱 SMS enviado a {phone}. Estado: {status}`
- Twilio statuses: `queued` → `sent` → `delivered`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `TWILIO_ACCOUNT_SID` | Yes | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | Yes | Twilio auth token |
| `TWILIO_PHONE_NUMBER` | Yes | Sender phone number (Twilio) |

## Usage Examples

### Example 1: Simple SMS
**User**: "Envía un SMS al 55 1234 5678 diciendo que ya está listo su pedido"

**Response**: 📱 SMS enviado a +5215512345678. Entregado en 2s.

### Example 2: Reminder SMS
**User**: "Mándale un mensaje de texto a María (+1 555 123 4567) recordándole la cita de mañana"

**Response**: 📱 SMS enviado a +15551234567: "Hola María, te recordamos tu cita mañana a las 10:00am. ¡Te esperamos!"

## Error Handling

| Error | Action |
|---|---|
| Invalid phone number | Ask user to verify the number with country code |
| Twilio not configured | Inform user to add Twilio credentials to `.env` |
| Undeliverable (landline) | Inform user the number may be a landline |
| Rate limited | Wait 1 second and retry |
| Message too long (>1600 chars) | Suggest shortening or splitting into multiple SMS |
