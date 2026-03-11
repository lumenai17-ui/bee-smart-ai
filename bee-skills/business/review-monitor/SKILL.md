---
name: review-monitor
description: "Monitor business reviews from Google Business, Yelp, TripAdvisor, and other platforms. Fetches new reviews, analyzes sentiment, and alerts on negative feedback."
version: 1.0.0
category: business
tier: pro
requires:
  - tool: http
  - tool: bash
---

# review-monitor

Monitor and analyze business reviews across platforms.

## Instructions

### Step 1: Fetch reviews via Google Business Profile API
```bash
curl "https://mybusinessbusinessinformation.googleapis.com/v1/accounts/{accountId}/locations/{locationId}/reviews" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN"
```

### Alternative: Scrape review sites
Use the `web-scraping` skill to extract reviews from public pages.

### Step 2: Analyze each review
For each new review:
- Extract rating, text, date, reviewer name
- Run sentiment analysis (use `sentiment-analysis` skill)
- Classify: product, service, price, ambiance, staff

### Step 3: Generate summary
```
⭐ Resumen de reseñas (últimos 7 días):
- Promedio: 4.3/5 (12 reseñas)
- Positivas: 9 (75%)
- Negativas: 2 (17%)
- Neutras: 1 (8%)

⚠️ Alertas: 2 reseñas negativas sobre tiempo de espera
```

### Step 4: Alert on negative reviews
If rating ≤ 2 or negative sentiment detected → immediate notification to operator.

## Usage Examples

### Example 1: Weekly check
**User**: "¿Cómo están las reseñas de esta semana?"
**Response**: ⭐ 12 reseñas nuevas esta semana. Promedio: 4.3/5. Tendencia: ↑ (vs 4.1 la semana pasada). 2 requieren atención.

## Error Handling

| Error | Action |
|---|---|
| Google OAuth not configured | Use web scraping fallback |
| No new reviews | Report "Todo tranquilo" |
| API rate limited | Schedule check for later |
