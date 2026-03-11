---
name: report-generate
description: "Generate business reports with data, charts, and insights. Combines data from various sources into a formatted PDF or HTML report with executive summary, charts, and recommendations."
version: 1.0.0
category: business
tier: basic
requires:
  - tool: bash
  - tool: http
  - tool: memory
---

# report-generate

Generate comprehensive business reports with data visualization.

## Instructions

### Step 1: Collect data
Gather data from available sources:
- Conversation history (Unified Context)
- User-provided data (spreadsheets, numbers)
- External APIs (sales, analytics, reviews)

### Step 2: Structure the report
Standard sections:
1. **Executive Summary** — Key findings in 3-5 bullet points
2. **Metrics Overview** — KPIs with comparison to previous period
3. **Detailed Analysis** — Charts, tables, trends
4. **Recommendations** — Action items based on data
5. **Appendix** — Raw data tables

### Step 3: Generate the document
Use the `pdf-generate` skill to create the final PDF, or output as HTML with embedded Chart.js:
```html
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<canvas id="salesChart"></canvas>
<script>
new Chart(document.getElementById('salesChart'), {
  type: 'bar',
  data: { labels: ['Ene','Feb','Mar'], datasets: [{label:'Ventas', data: [12,19,15]}] }
});
</script>
```

### Step 4: Deliver
Report: `📊 Reporte generado: {title} ({pages} páginas, {charts} gráficos)`

## Usage Examples

### Example 1: Monthly report
**User**: "Genera el reporte mensual de ventas"
**Response**: 📊 Reporte generado: "Ventas Marzo 2026" (5 páginas, 3 gráficos). Resumen: ventas +15% vs febrero, 45 clientes nuevos.

### Example 2: Dashboard report
**User**: "Dame un resumen ejecutivo de cómo va el negocio"
**Response**: 📊 Resumen ejecutivo:
- 💰 Ingresos: $125,000 (+12%)
- 👥 Clientes activos: 156 (+8)
- ⭐ Satisfacción: 4.5/5
- ⚠️ Atención: 3 clientes en riesgo de churn

## Error Handling

| Error | Action |
|---|---|
| No data available | Ask user for the data source |
| Incomplete data | Generate with available data, note gaps |
| Chart library unavailable | Use ASCII/table format |
