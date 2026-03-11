---
name: classify
description: "Classify text into predefined or custom categories. Use when the user needs to sort, label, or categorize messages, tickets, documents, or any text into groups. Works with zero-shot classification using the built-in LLM."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
---

# classify

Classify text into categories using zero-shot LLM classification.

## Instructions

### Step 1: Determine categories
- **User-defined**: The user provides the categories
- **Auto-detect**: Suggest categories based on the content type:
  - Support tickets: bug, feature request, question, billing, complaint
  - Emails: urgent, informational, promotional, personal, spam
  - Reviews: product, service, price, ambiance, staff

### Step 2: Classify the content
For each piece of text, determine:
- **Primary category** with confidence score
- **Secondary category** if applicable
- **Priority/urgency** level (low, medium, high, critical)

### Step 3: Present results

For single classification:
```
🏷️ Clasificación: SOPORTE TÉCNICO (92% confianza)
Subcategoría: Bug report
Prioridad: Alta
```

For batch classification:
```
🏷️ 50 mensajes clasificados:
- Soporte: 20 (40%)
- Ventas: 15 (30%)
- General: 10 (20%)
- Spam: 5 (10%)
```

## Usage Examples

### Example 1: Classify a message
**User**: "Clasifica: 'No puedo iniciar sesión desde ayer, ya intenté cambiar la contraseña'"

**Response**: 🏷️ **Soporte Técnico** (95%) — Bug/Login — Prioridad: Alta

### Example 2: Batch classify support tickets
**User**: "Clasifica estos 20 tickets de soporte por tipo y prioridad"

**Response**: 🏷️ 20 tickets clasificados:

| Categoría | Cantidad | Prioridad |
|---|---|---|
| Bug | 8 | 3 críticos, 5 medios |
| Feature request | 6 | Todos bajos |
| Billing | 4 | 2 altos, 2 medios |
| Question | 2 | Bajos |

## Error Handling

| Error | Action |
|---|---|
| No categories specified | Suggest common categories based on content |
| Content doesn't fit any category | Label as "Other" with explanation |
| Low confidence (<60%) | Present top 2-3 candidates with scores |
