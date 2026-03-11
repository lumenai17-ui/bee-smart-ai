---
name: summarize
description: "Summarize text, documents, conversations, or web pages into concise key points. Use when the user asks for a summary, TL;DR, key takeaways, or a shorter version of any content. This skill uses the LLM itself — no external API needed."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
---

# summarize

Generate concise summaries from any text using built-in LLM capabilities.

## Instructions

### Step 1: Identify the content to summarize
- **Direct text**: User pastes or provides text
- **Document**: Use pdf-read or excel-read first, then summarize
- **Conversation**: Summarize the current or past conversation
- **URL**: Use web-scraping first, then summarize the content

### Step 2: Choose summary style
- **Executive summary**: 2-3 paragraphs with key decisions and numbers
- **Bullet points**: Key items in a scannable list
- **One-liner**: Single sentence capturing the essence
- **Structured**: Summary with sections (Context, Key Points, Action Items, Conclusions)

### Step 3: Generate the summary
Structure your prompt internally:
- Identify the main topic and purpose
- Extract the most important facts, numbers, and decisions
- Note any action items or deadlines
- Preserve the original tone and context

### Step 4: Present the result
Format: `📋 Resumen ({original_words} palabras → {summary_words})`

## Usage Examples

### Example 1: Text summary
**User**: "Resume este artículo de 2000 palabras"

**Response**: 📋 Resumen (2,000 → 150 palabras):

El artículo analiza las tendencias de IA para 2026. **Puntos clave**:
- Los modelos open-source superaron a los privados en benchmarks generales
- El mercado de agentes IA creció 340% vs 2025
- La regulación europea entró en vigor, afectando a 15,000 empresas

**Conclusión**: Las empresas que no adopten IA en 2026 perderán competitividad.

### Example 2: Meeting summary
**User**: "Resume la conversación de hoy"

**Response**: 📋 Resumen de la conversación:
- **Tema**: Configuración del proyecto BEE Smart AI
- **Decisiones**: Se aprobó el plan de implementación con 58 skills
- **Pendientes**: Falta configurar WhatsApp Business API
- **Próximos pasos**: Completar skills de comunicación esta semana

## Error Handling

| Error | Action |
|---|---|
| Content too short (<50 words) | Inform: "El texto ya es bastante corto" |
| Content too long (>50K words) | Summarize in chunks, then meta-summarize |
| No clear content provided | Ask user what they want summarized |
