---
name: email-read
description: "Read, search and summarize emails from the inbox via IMAP. Use when the user asks to check their email, find a specific message, count unread emails, or get a summary of recent correspondence."
version: 1.0.0
category: communication
tier: basic
requires:
  - tool: bash
  - tool: http
  - tool: email
---

# email-read

Check inbox, search emails, read content, and provide summaries.

## Instructions

### Step 1: Connect to IMAP
Use the configured IMAP credentials to connect to the mailbox:

```bash
# Node.js script using imapflow
node -e "
const { ImapFlow } = require('imapflow');
const client = new ImapFlow({
  host: process.env.IMAP_HOST,
  port: 993,
  secure: true,
  auth: { user: process.env.IMAP_USER, pass: process.env.IMAP_PASSWORD }
});
// ... operations
"
```

### Step 2: Determine the operation
- **Check unread**: Fetch count and subjects of unseen messages
- **Search**: Search by sender, subject, date range, or body content
- **Read specific**: Fetch full content of a specific email
- **Summarize**: Read recent emails and provide an AI summary

### Step 3: Fetch and format results
- For unread count: `📬 Tienes {count} emails nuevos`
- For search: List matching emails with date, sender, subject
- For full read: Present subject, from, date, and body content
- For summary: Generate a concise summary of the email batch

### Step 4: Offer follow-up actions
After showing results, suggest:
- "¿Quieres que responda a alguno?"
- "¿Quieres que resuma los más importantes?"
- "¿Quieres marcar alguno como leído?"

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `IMAP_HOST` | Yes | IMAP server hostname |
| `IMAP_USER` | Yes | IMAP username/email |
| `IMAP_PASSWORD` | Yes | IMAP password or app password |

## Usage Examples

### Example 1: Check inbox
**User**: "¿Tengo emails nuevos?"

**Response**: 📬 Tienes 5 emails nuevos:
1. **Carlos Mendoza** — "Propuesta de colaboración" (hace 2h)
2. **Notificación Stripe** — "Pago recibido #4521" (hace 3h)
3. **Ana López** — "Re: Presupuesto Q2" (hace 5h)
...
¿Quieres que los resuma?

### Example 2: Search emails
**User**: "Busca emails de ana@empresa.com sobre el presupuesto"

**Response**: 📧 Encontré 3 emails de ana@empresa.com sobre "presupuesto":
1. "Presupuesto Q2 - Aprobado" (5 mar)
2. "Re: Revisión de presupuesto" (28 feb)
3. "Presupuesto Q1 - Final" (15 ene)

### Example 3: Read and summarize
**User**: "Revisa mi correo y dame un resumen de lo importante"

**Response**: 📋 Resumen de tus últimos 10 emails:
- **Urgente**: Carlos necesita aprobación del contrato antes del viernes
- **Financiero**: 2 pagos recibidos ($1,200 y $850)
- **Reuniones**: Confirmación de reunión el jueves a las 10am
- **Marketing**: Newsletter report — 45% open rate

## Error Handling

| Error | Action |
|---|---|
| IMAP credentials not set | Inform user to configure email in `.env` |
| Connection timeout | Retry once, suggest checking server settings |
| No emails found | Confirm search criteria and suggest broadening |
| Large inbox (>1000 unread) | Show most recent 20 and offer pagination |
