---
name: drip-campaign
description: "Set up automated email sequences (drip campaigns) that send a series of pre-written emails at scheduled intervals. Ideal for onboarding, nurturing leads, and post-purchase follow-ups."
version: 1.0.0
category: email-marketing
tier: pro
requires:
  - tool: bash
  - tool: http
---

# drip-campaign

Create automated email sequences triggered by events or time.

## Instructions

### Step 1: Define the sequence
Example drip campaign:
```
Day 0: Welcome email (immediate)
Day 2: Getting started guide
Day 5: Tips & best practices
Day 10: Case study / testimonial
Day 15: Special offer (10% discount)
Day 30: Feedback survey
```

### Step 2: Store campaign config
Save as JSON in the automations directory:
```json
{
  "name": "Onboarding Sequence",
  "trigger": "new_subscriber",
  "emails": [
    { "delay_days": 0, "template": "welcome", "subject": "¡Bienvenido!" },
    { "delay_days": 2, "template": "getting_started", "subject": "Cómo empezar" },
    { "delay_days": 5, "template": "tips", "subject": "5 tips para aprovechar al máximo" }
  ]
}
```

### Step 3: Schedule via cron
Use the `cron-schedule` skill to check daily for pending emails:
- Check subscriber join dates against campaign delays
- Send matching emails via `email-send` skill
- Track which emails have been sent per subscriber

## Usage Examples

### Example 1: Create onboarding drip
**User**: "Crea una secuencia de 5 emails para nuevos clientes"
**Response**: ⏰ Drip campaign "Onboarding" creada con 5 emails:
1. Día 0: Bienvenida
2. Día 3: Guía de inicio
3. Día 7: Tips avanzados
4. Día 14: Caso de éxito
5. Día 21: Oferta especial

## Error Handling

| Error | Action |
|---|---|
| Templates not created | Generate basic templates |
| Contact already in sequence | Skip or restart from current position |
| Email delivery failed | Retry next day, then skip |
