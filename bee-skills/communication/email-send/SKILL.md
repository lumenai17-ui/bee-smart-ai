---
name: email-send
description: "Send emails via Resend API or SMTP. Use when the user asks to send an email, contact someone by email, or deliver any document/report/notification via email. Supports HTML body, attachments, CC/BCC, and reply-to."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: http
  - tool: bash
  - tool: email
---

# email-send

Send professional emails with full formatting, attachments, and tracking.

## Instructions

### Step 1: Gather information
Ask the user for or extract from context:
- **To**: Email address of the recipient (required)
- **Subject**: Email subject line (required)
- **Body**: Email content (required — can be plain text or you'll format as HTML)
- **CC/BCC**: Additional recipients (optional)
- **Attachments**: File paths to attach (optional)
- **Reply-To**: Reply address if different from sender (optional)

### Step 2: Format the email body
- If the user gives plain text, wrap it in a clean HTML template with the business branding
- Use the business name and tone from the branding config when available
- Keep formatting professional: proper paragraphs, line spacing, signature block

### Step 3: Send via Resend API
Use the `http` tool to call the Resend API:

```bash
curl -X POST "https://api.resend.com/emails" \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "'"$SMTP_FROM"'",
    "to": ["recipient@example.com"],
    "subject": "Your Subject",
    "html": "<p>Your HTML body</p>"
  }'
```

### Step 4: Confirm delivery
- Parse the API response for the email `id`
- Report success to the user: `✉️ Email enviado correctamente a {recipient}`
- If there's an error, explain clearly and offer to retry

### Fallback: SMTP
If Resend is not configured, use the SMTP settings from `.env`:
```bash
# Use the email tool directly with SMTP_HOST, SMTP_USER, SMTP_PASSWORD
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `RESEND_API_KEY` | Yes (primary) | Resend API key |
| `SMTP_FROM` | Yes | Sender email address |
| `SMTP_HOST` | Fallback | SMTP server hostname |
| `SMTP_USER` | Fallback | SMTP username |
| `SMTP_PASSWORD` | Fallback | SMTP password |

## Usage Examples

### Example 1: Simple email
**User**: "Envía un email a juan@empresa.com diciéndole que la reunión es mañana a las 3pm"

**Agent action**: Send email with subject "Recordatorio: Reunión mañana" and formatted body.

**Response**: ✉️ Email enviado correctamente a juan@empresa.com. ¿Necesitas algo más?

### Example 2: Email with attachment
**User**: "Mándale la factura que acabamos de generar a cliente@gmail.com"

**Agent action**: Attach the generated PDF, compose professional email with invoice details.

**Response**: ✉️ Email enviado a cliente@gmail.com con la factura #1234 adjunta.

### Example 3: Email to multiple recipients
**User**: "Envía el reporte mensual a todo el equipo: ana@co.com, pedro@co.com, luis@co.com"

**Agent action**: Send to all three with CC, attach report.

**Response**: ✉️ Email enviado a 3 destinatarios. Asunto: "Reporte Mensual - Marzo 2026".

## Error Handling

| Error | Action |
|---|---|
| Invalid email address | Ask user to verify the address |
| RESEND_API_KEY not set | Check for SMTP fallback, if unavailable tell user to configure |
| Rate limit (429) | Wait and retry once, then inform user |
| Attachment too large (>25MB) | Suggest compressing or using a file sharing link |
| Network error | Retry once, then report the error |
