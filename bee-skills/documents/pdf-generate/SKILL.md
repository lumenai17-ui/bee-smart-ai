---
name: pdf-generate
description: "Generate PDF documents from HTML content, templates, or data. Use when the user asks to create a PDF report, document, letter, or any formatted output. Uses Puppeteer for HTML-to-PDF or pdf.co API for template-based generation."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
  - tool: http
---

# pdf-generate

Generate professional PDF documents from HTML, data, or templates.

## Instructions

### Step 1: Determine the PDF type
- **From HTML**: Create an HTML page, then convert to PDF with Puppeteer
- **From template**: Use a pre-built template and fill with data
- **Report**: Generate structured content with headings, tables, charts

### Step 2: Create the HTML content
Build a well-formatted HTML document with inline CSS:
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; color: #333; }
    h1 { color: #1a1a2e; border-bottom: 2px solid #e94560; padding-bottom: 8px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1a1a2e; color: white; }
    .footer { margin-top: 40px; font-size: 0.8em; color: #666; }
  </style>
</head>
<body>
  <!-- Content here -->
</body>
</html>
```

### Step 3: Convert to PDF with Puppeteer

```bash
node -e "
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setContent(htmlContent);
  await page.pdf({
    path: '/tmp/output.pdf',
    format: 'Letter',
    margin: { top: '20mm', bottom: '20mm', left: '15mm', right: '15mm' },
    printBackground: true
  });
  await browser.close();
})();
"
```

### Alternative: pdf.co API
```bash
curl -X POST "https://api.pdf.co/v1/pdf/convert/from/html" \
  -H "x-api-key: $PDF_CO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "html": "<html>...</html>", "name": "output.pdf", "margins": "20px" }'
```

### Step 4: Deliver the PDF
- Save to a known location
- Offer to send via email, WhatsApp, or download
- Report: `📄 PDF creado: {filename} ({pages} páginas)`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `PDF_CO_API_KEY` | Optional | pdf.co API key (alternative to Puppeteer) |

## Usage Examples

### Example 1: Simple report
**User**: "Genera un PDF con el resumen de ventas del mes"

**Response**: 📄 PDF creado: "Reporte-Ventas-Marzo-2026.pdf" (3 páginas). ¿Te lo envío por email?

### Example 2: Letter/document
**User**: "Crea un documento PDF con una carta de presentación para el cliente Acme Corp"

**Response**: 📄 PDF creado: "Carta-Presentacion-AcmeCorp.pdf". Incluye membrete, cuerpo y firma.

## Error Handling

| Error | Action |
|---|---|
| Puppeteer not available | Fall back to pdf.co API |
| pdf.co not configured | Use basic HTML-to-file conversion |
| Content too large | Paginate automatically |
| Missing data fields | Ask user for the missing information |
