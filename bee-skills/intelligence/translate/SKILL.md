---
name: translate
description: "Translate text between languages. Use when the user asks to translate content, convert to another language, or needs multilingual output. Uses DeepL API for high-quality translations or the built-in LLM as fallback."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: http
  - tool: memory
---

# translate

Translate text between any languages with high accuracy.

## Instructions

### Step 1: Detect source language
If not specified by user, auto-detect from the text content.

### Step 2: Translate using DeepL API (preferred)

```bash
curl -X POST "https://api-free.deepl.com/v2/translate" \
  -H "Authorization: DeepL-Auth-Key $DEEPL_API_KEY" \
  -d "text=Tu texto aquí" \
  -d "target_lang=EN" \
  -d "source_lang=ES"
```

**Supported languages**: DE, EN, ES, FR, IT, JA, KO, NL, PL, PT, RU, ZH, and many more.

### Fallback: LLM Translation
If DeepL is not configured, use the built-in LLM:
- Translate maintaining the original tone, formality, and style
- For technical content, preserve terminology
- For creative content, adapt idioms and expressions

### Step 3: Present the translation
```
🌐 Traducido (ES → EN):

"Your translated text here"
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DEEPL_API_KEY` | Optional | DeepL API key (500K chars free/month) |

## Usage Examples

### Example 1: Simple translation
**User**: "Traduce al inglés: 'Estamos encantados de trabajar con ustedes'"

**Response**: 🌐 Traducido (ES → EN): "We are delighted to work with you"

### Example 2: Document translation
**User**: "Traduce este email al francés"

**Response**: 🌐 Traducido (ES → FR):
"Cher Monsieur Dupont, nous avons le plaisir de vous confirmer..."

### Example 3: Multiple languages
**User**: "Traduce 'Bienvenido a nuestro restaurante' a inglés, francés y portugués"

**Response**: 🌐 Traducciones:
- 🇬🇧 EN: "Welcome to our restaurant"
- 🇫🇷 FR: "Bienvenue dans notre restaurant"
- 🇧🇷 PT: "Bem-vindo ao nosso restaurante"

## Error Handling

| Error | Action |
|---|---|
| DeepL key not set | Use LLM fallback (note: less accurate for rare pairs) |
| Unsupported language pair | Use LLM fallback |
| Text too long for DeepL (>50K chars) | Split into chunks |
| Language detection failed | Ask user to specify source language |
