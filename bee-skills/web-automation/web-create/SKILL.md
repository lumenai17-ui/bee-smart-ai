---
name: web-create
description: "Create web pages, landing pages, and simple websites from scratch. Use when the user needs an HTML page, a promotional landing page, a portfolio, or any web content. Generates responsive HTML/CSS/JS files."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: bash
---

# web-create

Create complete, responsive web pages with modern design.

## Instructions

### Step 1: Understand requirements
- **Type**: landing page, portfolio, menu, event page, info page
- **Content**: text, images, sections, contact form
- **Style**: modern, minimal, corporate, colorful, dark
- **Responsive**: Always — mobile-first design

### Step 2: Generate the HTML
Create a self-contained HTML file with embedded CSS and JS:
- Use modern CSS (Grid, Flexbox, custom properties)
- Add smooth animations and transitions
- Include responsive meta tag and proper SEO tags
- Use Google Fonts for typography
- Add a favicon and OpenGraph meta tags

### Step 3: Save and preview
- Save to `./web-output/{project-name}/index.html`
- Include any assets in the same directory
- Report the local file path and offer to publish

### Step 4: Offer to publish
Use the `cloudflare-tunnel` skill or `web-publish` capability:
- "¿Quieres publicarlo con un URL público?"
- "¿Quieres generar un QR para compartir?"

## Usage Examples

### Example 1: Restaurant landing page
**User**: "Crea una página web para mi restaurante 'La Trattoria'"

**Response**: 🌐 Página web creada: "La Trattoria"
- 📁 Ubicación: `./web-output/la-trattoria/index.html`
- 📱 Responsive: Sí
- Secciones: Hero, Menú, Ubicación, Contacto, Horario
¿Quieres que la publique?

### Example 2: Event page
**User**: "Hazme una página para el evento de lanzamiento del 15 de marzo"

**Response**: 🌐 Página de evento creada:
- Countdown timer al 15 de marzo
- Sección de detalles, speakers, registro
- Mapa de ubicación integrado

## Error Handling

| Error | Action |
|---|---|
| No content provided | Use placeholder content, ask user to fill |
| Images referenced but not available | Use placeholder with description |
| Complex requirement (e-commerce) | Suggest using a platform (Shopify, WooCommerce) |
