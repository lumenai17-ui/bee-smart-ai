---
name: whatsapp-send
description: "Send WhatsApp messages via the WhatsApp Business API (Cloud API). Use when the user asks to send a WhatsApp message, share images/documents via WhatsApp, or needs to reach a contact on WhatsApp. Supports text, images, documents, templates, and interactive messages."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: http
---

# whatsapp-send

Send messages, media, and templates via WhatsApp Business API.

## Instructions

### Step 1: Determine message type
- **Text**: Plain text message
- **Image**: Image with optional caption
- **Document**: PDF, Word, Excel with filename
- **Template**: Pre-approved template message (required for first contact)
- **Interactive**: Buttons or list messages

### Step 2: Resolve recipient
- Get the phone number in international format (e.g., +521234567890)
- Remove the leading + for the API (use `521234567890`)
- If this is a **first-time contact**, you MUST use a template message (WhatsApp policy)

### Step 3: Send via Cloud API

**Text message:**
```bash
curl -X POST "https://graph.facebook.com/v18.0/$WHATSAPP_PHONE_ID/messages" \
  -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messaging_product": "whatsapp",
    "to": "521234567890",
    "type": "text",
    "text": { "body": "Hola! Tu pedido está listo." }
  }'
```

**Image message:**
```bash
curl -X POST "https://graph.facebook.com/v18.0/$WHATSAPP_PHONE_ID/messages" \
  -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messaging_product": "whatsapp",
    "to": "521234567890",
    "type": "image",
    "image": { "link": "https://example.com/image.jpg", "caption": "Tu imagen" }
  }'
```

**Document message:**
```bash
curl -X POST "https://graph.facebook.com/v18.0/$WHATSAPP_PHONE_ID/messages" \
  -H "Authorization: Bearer $WHATSAPP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messaging_product": "whatsapp",
    "to": "521234567890",
    "type": "document",
    "document": { "link": "https://example.com/file.pdf", "filename": "Factura.pdf" }
  }'
```

### Step 4: Confirm delivery
- Parse response for message `id`
- Report: `💬 Mensaje de WhatsApp enviado a {contact}`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `WHATSAPP_PHONE_ID` | Yes | WhatsApp Business phone number ID |
| `WHATSAPP_ACCESS_TOKEN` | Yes | Permanent or temporary access token |
| `WHATSAPP_VERIFY_TOKEN` | For webhooks | Webhook verification token |

## Usage Examples

### Example 1: Text message
**User**: "Mándale un WhatsApp a +52 55 1234 5678 diciendo que el pedido ya salió"

**Response**: 💬 WhatsApp enviado a +5215512345678: "¡Hola! Te confirmamos que tu pedido ya salió y está en camino. 📦"

### Example 2: Send a document
**User**: "Envíale la factura por WhatsApp al cliente"

**Response**: 💬 Documento enviado por WhatsApp: "Factura-2026-0341.pdf" a +5215512345678.

### Example 3: Template message (first contact)
**User**: "Contacta a este nuevo cliente: +52 33 9876 5432"

**Response**: 💬 Mensaje de plantilla enviado a +523398765432. Nota: al ser primer contacto, se usó la plantilla aprobada "bienvenida_cliente".

## Error Handling

| Error | Action |
|---|---|
| WhatsApp not configured | Tell user to set up WhatsApp Business API credentials |
| 24h window expired | Use a template message instead of free-form |
| Invalid phone number | Verify number format with country code |
| Media too large (>16MB images, >100MB docs) | Compress or split |
| Rate limited | Queue and retry with exponential backoff |
