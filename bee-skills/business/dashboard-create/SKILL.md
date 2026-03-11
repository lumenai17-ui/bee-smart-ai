---
name: dashboard-create
description: "Create interactive data dashboards as web pages with real-time metrics, charts, and KPIs. Generates self-contained HTML pages with Chart.js for data visualization."
version: 1.0.0
category: business
tier: pro
requires:
  - tool: bash
---

# dashboard-create

Create interactive web dashboards with live data and charts.

## Instructions

### Step 1: Define metrics
Identify KPIs to display: revenue, customers, orders, satisfaction, conversion rate, etc.

### Step 2: Generate HTML dashboard
Create a responsive, dark-themed dashboard with Chart.js:
- KPI cards with current value and trend indicator
- Line charts for time series data
- Bar charts for comparisons
- Doughnut charts for distributions
- Auto-refresh capability

### Step 3: Save and serve
- Save to `./web-output/dashboard/index.html`
- Offer to publish with `cloudflare-tunnel` skill
- Report: `📈 Dashboard creado: {metrics_count} KPIs, {charts} gráficos`

## Usage Examples

### Example 1: Sales dashboard
**User**: "Crea un dashboard de ventas"
**Response**: 📈 Dashboard creado con 6 KPIs: Ventas totales, Ticket promedio, Conversión, Clientes nuevos, Revenue por canal, Top productos. URL local lista.

## Error Handling

| Error | Action |
|---|---|
| No data provided | Create with sample data, user fills later |
| Too many metrics | Group by category, add tabs |
