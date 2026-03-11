---
name: email-template
description: "Create responsive email templates using MJML framework. Templates can be reused for newsletters, notifications, invoices, and marketing campaigns. Outputs both MJML source and compiled HTML."
version: 1.0.0
category: email-marketing
tier: basic
requires:
  - tool: bash
---

# email-template

Create professional, responsive email templates with MJML.

## Instructions

### Step 1: Choose template type
- **Transactional**: Order confirmation, password reset, welcome
- **Marketing**: Promotion, announcement, product launch
- **Newsletter**: Multi-section editorial emails
- **Notification**: Alerts, reminders, status updates

### Step 2: Generate MJML template
Build with proper responsive components:
- `mj-section` for layout rows
- `mj-column` for grid columns
- `mj-text` for content
- `mj-button` for CTAs
- `mj-image` for visuals
- `mj-social` for social links

### Step 3: Compile and save
```bash
node -e "
const mjml = require('mjml');
const template = require('fs').readFileSync('/tmp/template.mjml', 'utf-8');
const { html, errors } = mjml(template);
require('fs').writeFileSync('/tmp/template.html', html);
console.log('Compiled:', errors.length === 0 ? 'OK' : errors);
"
```

## Usage Examples

### Example 1: Welcome email
**User**: "Crea una plantilla de email de bienvenida para nuevos clientes"
**Response**: 🎨 Plantilla creada: "bienvenida.mjml" — Header con logo, mensaje de bienvenida personalizado, 3 pasos para empezar, footer con redes sociales. Responsive para móvil y desktop.

## Error Handling

| Error | Action |
|---|---|
| MJML syntax error | Auto-fix common issues, report remaining ones |
| Images not loading | Use absolute URLs |
