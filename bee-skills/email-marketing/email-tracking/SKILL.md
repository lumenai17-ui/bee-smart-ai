---
name: email-tracking
description: "Track email campaign metrics: opens, clicks, bounces, and unsubscribes. Uses Resend webhooks and analytics to monitor campaign performance."
version: 1.0.0
category: email-marketing
tier: pro
requires:
  - tool: http
---

# email-tracking

Track and analyze email campaign performance metrics.

## Instructions

### Step 1: Query Resend analytics
```bash
curl "https://api.resend.com/emails/$EMAIL_ID" \
  -H "Authorization: Bearer $RESEND_API_KEY"
```

### Step 2: Process webhook events from Resend
Register webhook at `https://{gateway}/api/webhooks/resend`:
- `email.delivered` — Successfully delivered
- `email.opened` — Recipient opened the email
- `email.clicked` — Recipient clicked a link
- `email.bounced` — Email bounced
- `email.complained` — Marked as spam

### Step 3: Generate report
```
📊 Métricas de campaña: {campaign_name}
- Enviados: 250
- Entregados: 245 (98%)
- Abiertos: 112 (45.7%)
- Clicks: 34 (13.9%)
- Rebotados: 5 (2%)
- Spam reports: 0
```

## Usage Examples

### Example 1: Campaign metrics
**User**: "¿Cómo fue el newsletter de la semana pasada?"
**Response**: 📊 Newsletter "Ofertas Marzo": 250 enviados, 45% apertura, 14% clicks. Mejor link: "50% OFF" (22 clicks).

## Error Handling

| Error | Action |
|---|---|
| No tracking data | Campaign too recent, check back later |
| Webhook not configured | Guide setup |
