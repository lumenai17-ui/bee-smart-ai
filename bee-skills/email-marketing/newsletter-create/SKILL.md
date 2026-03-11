---
name: newsletter-create
description: "Create and send email newsletters to subscriber lists via Resend API. Supports HTML templates, audience segmentation, and scheduled delivery."
version: 1.0.0
category: email-marketing
tier: basic
requires:
  - tool: http
  - tool: bash
---

# newsletter-create

Create professional newsletters and send to subscriber lists.

## Instructions

### Step 1: Build the newsletter content
- Curate content sections: header, articles, highlights, CTA
- Apply the business branding (colors, logo, tone)
- Use MJML for responsive email templates

### Step 2: Render HTML from MJML template
```bash
node -e "
const mjml = require('mjml');
const result = mjml(\`<mjml><mj-body>
  <mj-section background-color='#1a1a2e'>
    <mj-column><mj-text color='white' font-size='24px'>{{business_name}} Newsletter</mj-text></mj-column>
  </mj-section>
  <mj-section><mj-column>
    <mj-text font-size='16px'>{{content}}</mj-text>
    <mj-button background-color='#e94560' href='{{cta_url}}'>{{cta_text}}</mj-button>
  </mj-column></mj-section>
</mj-body></mjml>\`);
console.log(result.html);
"
```

### Step 3: Send via Resend batch API
```bash
curl -X POST "https://api.resend.com/emails/batch" \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "emails": [
    {"from":"news@empresa.com","to":"sub1@example.com","subject":"Newsletter Marzo","html":"..."},
    {"from":"news@empresa.com","to":"sub2@example.com","subject":"Newsletter Marzo","html":"..."}
  ]}'
```

### Step 4: Report
Report: `📧 Newsletter enviado a {count} suscriptores. Asunto: "{subject}"`

## Usage Examples

### Example 1: Monthly newsletter
**User**: "Envía el newsletter del mes a todos los suscriptores"
**Response**: 📧 Newsletter "Novedades Marzo 2026" enviado a 250 suscriptores.

## Error Handling

| Error | Action |
|---|---|
| No subscriber list | Ask user to provide email list |
| Resend API key not set | Inform user to configure |
| Bounce rate high | Warn and suggest cleaning subscriber list |
