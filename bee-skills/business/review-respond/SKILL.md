---
name: review-respond
description: "Auto-respond to business reviews on Google, Yelp, and other platforms. Generates contextual, professional responses that match the business tone and address the reviewer's specific feedback."
version: 1.0.0
category: business
tier: pro
requires:
  - tool: http
  - tool: memory
---

# review-respond

Generate and post professional responses to customer reviews.

## Instructions

### Step 1: Analyze the review
- Extract: rating, key points (positive/negative), reviewer name
- Determine tone needed: grateful (positive), empathetic (negative), neutral

### Step 2: Generate response
Follow these guidelines:
- **5 stars**: Thank warmly, mention specifics they liked, invite back
- **4 stars**: Thank, acknowledge their experience, ask how to improve
- **3 stars**: Thank, address concerns, offer to make it right
- **1-2 stars**: Apologize sincerely, address specific issues, offer resolution privately

Always: Use the business name and tone from branding config. Keep under 300 chars for Google.

### Step 3: Post the response
```bash
curl -X POST "https://mybusinessbusinessinformation.googleapis.com/v1/{reviewName}/reply" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "comment": "Your response here" }'
```

## Usage Examples

### Example 1: Positive review
**Review**: ⭐⭐⭐⭐⭐ "Increíble experiencia, la comida estaba deliciosa"
**Response**: "¡Muchas gracias por tu visita! 🙏 Nos alegra que hayas disfrutado la comida. Tu opinión nos motiva a seguir mejorando. ¡Te esperamos pronto en La Trattoria!"

### Example 2: Negative review
**Review**: ⭐⭐ "Tardaron 45 minutos en servir, inaceptable"
**Response**: "Lamentamos sinceramente la espera. Esto no refleja nuestro estándar de servicio. Nos gustaría compensarte — ¿podrías contactarnos por WhatsApp al +52 55 1234 5678? Queremos asegurarnos de que tu próxima visita sea perfecta."

## Error Handling

| Error | Action |
|---|---|
| Google OAuth expired | Prompt to re-authenticate |
| Response too long | Shorten while keeping key points |
| Already responded | Inform and show existing response |
