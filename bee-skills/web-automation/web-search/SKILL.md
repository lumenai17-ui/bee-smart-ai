---
name: web-search
description: "Search the web and return relevant results. Use when the user asks to look something up online, research a topic, find current information, or verify facts. Uses SerpAPI or DuckDuckGo as search backends."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: http
---

# web-search

Search the web and return structured results with snippets.

## Instructions

### Step 1: Formulate the search query
- Clean and optimize the user's query for search
- Add relevant context (location, language, date range)

### Step 2: Search via SerpAPI or DuckDuckGo

**SerpAPI (Google results):**
```bash
curl "https://serpapi.com/search.json?q=mejores+restaurantes+CDMX&api_key=$SERPAPI_KEY&hl=es&gl=mx"
```

**DuckDuckGo (free, no API key):**
```bash
curl "https://api.duckduckgo.com/?q=mejores+restaurantes+CDMX&format=json&no_html=1"
```

### Step 3: Present results
Show top 5 results with title, snippet, and URL:
```
🔍 Resultados para "mejores restaurantes CDMX":

1. **Los 10 Mejores Restaurantes en CDMX 2026** — timeout.com
   "Descubre los restaurantes más aclamados de la ciudad..."

2. **Guía Gastronómica CDMX** — eater.com
   "Nuestra selección de restaurantes imperdibles..."
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SERPAPI_KEY` | Optional | SerpAPI key for Google results |

## Usage Examples

### Example 1: Quick search
**User**: "Busca cuál es el tipo de cambio dólar-peso hoy"

**Response**: 🔍 Tipo de cambio USD/MXN hoy: $17.85 (fuente: XE.com, actualizado hace 10 min)

### Example 2: Research
**User**: "Investiga qué CRM es mejor para restaurantes"

**Response**: 🔍 Top 3 CRMs para restaurantes:
1. **Toast** — Integración POS completa ($69/mes)
2. **SevenRooms** — Gestión de reservas y CRM ($299/mes)
3. **Eat App** — Específico para restaurantes ($129/mes)

## Error Handling

| Error | Action |
|---|---|
| SerpAPI key not set | Fall back to DuckDuckGo |
| No results found | Suggest alternate search terms |
| Rate limited | Queue and retry |
