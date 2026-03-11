---
name: memory-search
description: "Search across all stored conversation history and contact context using the Unified Context Plugin. Use when the user asks to find past conversations, recall what was discussed with a contact, or search for specific information across all interactions."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
  - tool: http
  - plugin: bee-unified-context
---

# memory-search

Search across all conversation history stored in the Unified Context database.

## Instructions

### Step 1: Understand the search query
- **By contact**: "¿Qué hablamos con Juan?"
- **By topic**: "¿Cuándo discutimos el presupuesto?"
- **By date**: "¿Qué pasó la semana pasada?"
- **By keyword**: "Busca menciones de 'factura'"
- **Cross-channel**: Search across WhatsApp, Telegram, email, etc.

### Step 2: Query the Unified Context API

```bash
# Search messages
curl "http://localhost:18789/api/contacts/search/messages?q=factura"

# Get contact history
curl "http://localhost:18789/api/contacts/{contactId}/messages?limit=50"

# Search contacts
curl "http://localhost:18789/api/contacts/search?q=Juan"
```

### Step 3: Present results
Format results chronologically with channel indicator:
```
🔍 Encontré 8 menciones de "factura":

1. [WhatsApp/Juan] 8 mar: "¿Me pueden enviar la factura?"
2. [Email/Ana] 5 mar: "Adjunto la factura #2026-0033"
3. [Telegram/Pedro] 1 mar: "La factura tiene un error en el IVA"
...
```

### Step 4: Offer context
- Show the surrounding conversation for each match
- Offer to show the full conversation thread
- Suggest related searches

## Usage Examples

### Example 1: Find past discussion
**User**: "¿Qué acordamos con el cliente del Hotel Paraíso?"

**Response**: 🔍 Historial con Hotel Paraíso (12 interacciones):

**Último contacto**: 8 mar 2026 (WhatsApp)
**Resumen**: Cliente VIP, plan Pro ($40/mes). Solicitó integración con su sistema de reservas. Se acordó reunión para el 15 de marzo.

**Mensajes recientes**:
1. [8 mar] "Confirmo reunión del viernes 15"
2. [5 mar] "Necesitamos conectar con nuestro PMS"
3. [1 mar] "¿Cuánto cuesta el plan Enterprise?"

### Example 2: Search by keyword
**User**: "Busca todas las menciones de 'descuento'"

**Response**: 🔍 7 menciones de "descuento" en los últimos 30 días:
- 3 clientes pidieron descuento → 2 se otorgaron (10%), 1 pendiente
- Descuento promedio otorgado: 12%

## Error Handling

| Error | Action |
|---|---|
| Unified Context not running | Inform user the plugin needs to be active |
| No results found | Suggest broader search or different keywords |
| Too many results (>100) | Filter by date range or contact |
