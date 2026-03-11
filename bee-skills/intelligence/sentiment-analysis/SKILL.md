---
name: sentiment-analysis
description: "Analyze the emotional tone and sentiment of text, reviews, messages, or social media posts. Use when the user wants to understand how customers feel, evaluate feedback, or monitor brand perception."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
---

# sentiment-analysis

Analyze emotional tone, sentiment polarity, and emotions in text.

## Instructions

### Step 1: Receive the text to analyze
Accept text from any source: reviews, messages, emails, social posts, survey responses.

### Step 2: Perform multi-dimensional analysis
Analyze across these dimensions:
- **Polarity**: Positive / Negative / Neutral / Mixed
- **Confidence**: 0-100% strength of the sentiment
- **Emotions**: Joy, anger, fear, sadness, surprise, trust, disgust
- **Intent**: complaint, praise, question, suggestion, urgency
- **Tone**: formal, casual, sarcastic, frustrated, enthusiastic

### Step 3: Present results
```
😊 Sentimiento: POSITIVO (87% confianza)

Emociones detectadas: alegría (72%), confianza (65%)
Tono: entusiasta, casual
Intención: elogio / recomendación
```

## Usage Examples

### Example 1: Single review
**User**: "Analiza el sentimiento de esta reseña: 'La comida estuvo increíble pero tardaron mucho en servir'"

**Response**: 😐 Sentimiento: **MIXTO** (75% confianza)
- 😊 Positivo: "comida increíble" (comida: 9/10)
- 😤 Negativo: "tardaron mucho" (servicio: 4/10)
- **Recomendación**: Mejorar tiempos de servicio, la calidad del producto es un fortaleza

### Example 2: Batch analysis
**User**: "Analiza el sentimiento de estas 5 reseñas de Google"

**Response**: 📊 Análisis de 5 reseñas:
- ⭐ Promedio: 4.2/5
- 😊 Positivas: 3 (60%)
- 😐 Neutras: 1 (20%)
- 😤 Negativas: 1 (20%)

**Temas positivos**: calidad del producto, atención amable
**Temas negativos**: tiempos de espera, estacionamiento

## Error Handling

| Error | Action |
|---|---|
| Text too short | Provide analysis but note low confidence |
| Multiple languages | Analyze each language segment separately |
| Sarcasm detected | Flag as potentially sarcastic, lower confidence |
| No clear sentiment | Report as "Neutral" with explanation |
