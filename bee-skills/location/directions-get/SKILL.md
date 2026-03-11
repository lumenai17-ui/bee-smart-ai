---
name: directions-get
description: "Get driving, walking, or transit directions between two locations using Google Maps Directions API. Provides step-by-step routes, estimated time, distance, and traffic conditions."
version: 1.0.0
category: location
tier: pro
requires:
  - tool: http
---

# directions-get

Get directions and routes between locations.

## Instructions

### Get directions:
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Polanco+CDMX&destination=Aeropuerto+CDMX&mode=driving&language=es&key=$GOOGLE_MAPS_KEY"
```

### Travel modes: `driving`, `walking`, `bicycling`, `transit`

### Step 2: Present the route
```
🗺️ Ruta: Polanco → Aeropuerto CDMX

🚗 En auto: 35 min (18.5 km)
Ruta: Periférico → Viaducto → Terminal 1

📍 Pasos:
1. Dirígete al sur por Av. Masaryk (400m)
2. Toma Periférico rumbo sur (8km)
3. Sal en Viaducto Miguel Alemán (5km)
4. Sigue hasta Terminal 1 (5km)

⚠️ Tráfico actual: Moderado (+10 min estimado)
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_MAPS_KEY` | Yes | Google Maps API key |

## Usage Examples

### Example 1: Driving directions
**User**: "¿Cómo llego al aeropuerto desde Polanco?"
**Response**: 🗺️ Polanco → Aeropuerto: 35 min en auto (18.5 km) por Periférico-Viaducto. Tráfico actual: moderado.

### Example 2: Walking
**User**: "¿Puedo caminar de aquí al restaurante?"
**Response**: 🚶 Caminando: 12 min (850m). Ruta directa por Av. Presidente Masaryk.

## Error Handling

| Error | Action |
|---|---|
| Origin/destination unclear | Ask for specific addresses |
| Route not found | Try alternative modes |
| API key not set | Inform user to configure |
