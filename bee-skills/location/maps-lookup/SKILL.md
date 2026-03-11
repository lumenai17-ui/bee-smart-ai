---
name: maps-lookup
description: "Search for places, get business info, and find locations using Google Maps Platform. Use when the user asks about a place, needs an address, wants business hours, or is looking for nearby services."
version: 1.0.0
category: location
tier: pro
requires:
  - tool: http
---

# maps-lookup

Search for places and get detailed location information.

## Instructions

### Search for a place:
```bash
curl "https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurantes+cerca+de+Polanco+CDMX&key=$GOOGLE_MAPS_KEY&language=es"
```

### Get place details:
```bash
curl "https://maps.googleapis.com/maps/api/place/details/json?place_id=PLACE_ID&fields=name,formatted_address,formatted_phone_number,opening_hours,rating,reviews&key=$GOOGLE_MAPS_KEY"
```

### Geocode an address:
```bash
curl "https://maps.googleapis.com/maps/api/geocode/json?address=Av+Reforma+505+CDMX&key=$GOOGLE_MAPS_KEY"
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_MAPS_KEY` | Yes | Google Maps API key ($200 free/month) |

## Usage Examples

### Example 1: Find nearby
**User**: "¿Dónde hay una farmacia cerca de Condesa?"
**Response**: 📍 3 farmacias cerca de Condesa:
1. **Farmacia San Pablo** — Av. Michoacán 120 (350m) ⭐ 4.3
2. **Farmacia del Ahorro** — Tamaulipas 78 (500m) ⭐ 4.1
3. **Farmacias Similares** — Ozuluama 45 (600m) ⭐ 3.8

### Example 2: Business info
**User**: "¿A qué hora abre La Trattoria?"
**Response**: 📍 La Trattoria — Polanco, CDMX
- 🕐 Horario: Lun-Sáb 13:00-23:00, Dom 13:00-18:00
- ⭐ Rating: 4.5/5 (342 reseñas)
- 📞 +52 55 1234 5678

## Error Handling

| Error | Action |
|---|---|
| GOOGLE_MAPS_KEY not set | Inform user to configure |
| No results | Suggest broader search terms |
| Quota exceeded | Inform about $200/mo free quota |
