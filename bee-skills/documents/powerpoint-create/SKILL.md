---
name: powerpoint-create
description: "Create PowerPoint presentations (.pptx) with slides, text, images, and layouts. Use when the user needs a presentation for meetings, pitches, reports, or training. Uses the Gamma API for AI-generated presentations or PptxGenJS for programmatic creation."
version: 1.0.0
category: documents
tier: pro
requires:
  - tool: bash
  - tool: http
---

# powerpoint-create

Create professional presentations with themed slides, content, and visuals.

## Instructions

### Step 1: Plan the presentation
- Determine topic, audience, and number of slides
- Create an outline with slide titles and key points
- Choose a theme/style (corporate, creative, minimal)

### Step 2: Generate with Gamma API (AI-powered)
```bash
curl -X POST "https://api.gamma.app/v1/generate" \
  -H "Authorization: Bearer $GAMMA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "Presentación de ventas Q1 2026",
    "num_slides": 10,
    "style": "corporate",
    "language": "es",
    "include_images": true
  }'
```

### Alternative: PptxGenJS (programmatic)
```bash
node -e "
const pptxgen = require('pptxgenjs');
const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE';

// Title slide
let slide = pres.addSlide();
slide.addText('Presentación de Ventas Q1', {
  x: 1, y: 1, w: '80%', h: 1.5,
  fontSize: 36, bold: true, color: '1a1a2e', align: 'center'
});

// Content slide
slide = pres.addSlide();
slide.addText('Métricas Clave', { x: 0.5, y: 0.3, fontSize: 28, bold: true });
slide.addText([
  { text: '• Ingresos: ', options: { bold: true } },
  { text: '\$125,000 (+15%)', options: { color: '2ecc71' } }
], { x: 0.5, y: 1.5, w: '90%', fontSize: 18 });

await pres.writeFile({ fileName: '/tmp/presentacion.pptx' });
"
```

### Step 3: Deliver
- Save the .pptx file
- Report: `🖼️ Presentación creada: {filename} ({slides} slides)`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GAMMA_API_KEY` | Optional | Gamma.app API key for AI generation |

## Usage Examples

### Example 1: Sales presentation
**User**: "Haz una presentación de 10 slides sobre las ventas del trimestre"

**Response**: 🖼️ Presentación creada: "Ventas-Q1-2026.pptx" (10 slides). Incluye gráficos de tendencias, comparativas y resumen ejecutivo.

### Example 2: Training deck
**User**: "Crea una presentación para capacitación de nuevos empleados"

**Response**: 🖼️ Presentación creada: "Onboarding-2026.pptx" (15 slides). Secciones: Bienvenida, Cultura, Procesos, Herramientas, FAQ.

## Error Handling

| Error | Action |
|---|---|
| Gamma API not available | Fall back to PptxGenJS |
| PptxGenJS not installed | Create HTML slides as fallback |
| Images not loading | Use placeholder with description |
