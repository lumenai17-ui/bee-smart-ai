---
name: whatsapp-unified-context
description: Maintains persistent context for WhatsApp conversations across all operator channels. Ensures that when an operator manages WhatsApp from Dashboard, Telegram, or any other platform, the full conversation history and customer context is always available.
version: 1.0.0
category: communication
requires:
  - tool: memory
  - tool: database
  - plugin: bee-unified-context
---

# WhatsApp Unified Context

This skill ensures **zero context loss** when managing WhatsApp conversations from any platform.

## Problem

When an operator manages a WhatsApp customer from Dashboard or Telegram, the agent loses context about:
- What the customer asked previously
- Customer preferences and history
- Ongoing topics and unresolved issues

## Solution

This skill connects to the **Unified Context Plugin** to:

1. **Resolve** the customer identity from their WhatsApp phone number
2. **Load** their full conversation history across all channels
3. **Inject** a context summary into every LLM prompt
4. **Record** every interaction, regardless of which channel the operator uses
5. **Summarize** old conversations to keep the context window efficient

## How to Use

### When receiving a WhatsApp message:
1. The plugin automatically resolves the contact by phone number
2. Full context is injected into your prompt
3. You can reference previous conversations naturally

### When an operator responds from another channel:
1. The operator requests the customer's context: `Show me chat for +521234567890`
2. The plugin provides:
   - Customer name and profile
   - Conversation summary
   - Recent messages with timestamps
   - Tags and satisfaction score
3. The operator's response is recorded with `role: operator` and `channel: dashboard`
4. The customer receives the response on WhatsApp

### When handing off to a human operator:
1. Generate a handoff summary: `Handoff summary for +521234567890`
2. The summary includes: current topic, context, recent messages, satisfaction score
3. The operator continues the conversation with full context

## Context Injection Format

The following is automatically added to your system prompt for each incoming message:

```
## Contact Context: Juan Pérez
- Phone: +521234567890
- Total interactions: 23
- Tags: vip, frecuente
- Current topic: reservación
- Summary: Cliente frecuente, prefiere mesas cerca de ventana, alérgico a mariscos

### Recent messages:
[customer/whatsapp] Quiero reservar para 4
[agent/whatsapp] ¡Claro! ¿Para qué fecha?
[customer/whatsapp] Este sábado a las 8pm
[operator/dashboard] Tenemos mesa disponible a las 8pm
```

## Configuration

Configure via the Unified Context plugin in `openclaw.json`:

```json
{
  "plugins": {
    "load": ["./bee-plugins/unified-context"]
  }
}
```

Plugin settings in `openclaw.plugin.json`:
- `database.engine`: `sqlite` (default) or `redis`
- `contextWindow.maxMessages`: Max recent messages to include (default: 50)
- `contextWindow.summaryAfter`: Compress history after N messages (default: 100)
