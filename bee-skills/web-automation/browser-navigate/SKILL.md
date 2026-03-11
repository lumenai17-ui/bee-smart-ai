---
name: browser-navigate
description: "Navigate and interact with web pages using a headless browser. Use when the user needs to visit a URL, fill forms, click buttons, take screenshots, or interact with any web interface. Uses Puppeteer for browser automation."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: bash
  - tool: browser
---

# browser-navigate

Navigate web pages, take screenshots, fill forms, and extract content.

## Instructions

### Step 1: Launch browser and navigate
```bash
node -e "
const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  await page.goto('https://example.com', { waitUntil: 'networkidle2', timeout: 30000 });
  // ... actions
})();
"
```

### Step 2: Perform requested actions
- **Screenshot**: `await page.screenshot({ path: '/tmp/screenshot.png', fullPage: true });`
- **Extract text**: `const text = await page.evaluate(() => document.body.innerText);`
- **Fill form**: `await page.type('#email', 'user@example.com');`
- **Click**: `await page.click('button[type=submit]');`
- **Wait**: `await page.waitForSelector('.result', { timeout: 10000 });`
- **Get links**: `const links = await page.$$eval('a', els => els.map(e => e.href));`

### Step 3: Report results
- Show extracted content or confirmation of actions
- Attach screenshots when relevant
- Report: `🌐 Navegación completada: {actions} acciones ejecutadas`

## Usage Examples

### Example 1: Visit and screenshot
**User**: "Toma una captura de pantalla de google.com"
**Response**: 🌐 Screenshot tomado de google.com (1280x800).

### Example 2: Fill a form
**User**: "Ve a mi formulario de contacto y prueba que funciona"
**Response**: 🌐 Formulario probado: campos llenados y enviados exitosamente. Respuesta del servidor: 200 OK.

## Error Handling

| Error | Action |
|---|---|
| Page timeout | Retry with longer timeout, report if still fails |
| SSL error | Try with `ignoreHTTPSErrors: true` |
| Element not found | Try alternative selectors, report |
| Page blocks automation | Try with stealth plugin |
