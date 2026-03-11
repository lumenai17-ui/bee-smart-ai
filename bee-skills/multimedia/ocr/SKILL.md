---
name: ocr
description: "Extract text from images and scanned documents using OCR (Optical Character Recognition). Uses Mathpix for complex documents with math/tables, or Tesseract for simple text extraction."
version: 1.0.0
category: multimedia
tier: basic
requires:
  - tool: bash
  - tool: http
---

# ocr

Extract text from images and scanned documents.

## Instructions

### Step 1: For complex documents (tables, math), use Mathpix:
```bash
curl -X POST "https://api.mathpix.com/v3/text" \
  -H "app_id: $MATHPIX_APP_ID" \
  -H "app_key: $MATHPIX_APP_KEY" \
  -F "file=@/tmp/image.jpg" \
  -F 'options_json={"math_inline_delimiters": ["$", "$"], "rm_spaces": true}'
```

### Step 2: For simple text, use Tesseract:
```bash
tesseract /tmp/image.jpg /tmp/output -l spa+eng
cat /tmp/output.txt
```

### Step 3: Present extracted text
- Show the full text or a summary
- Format tables if detected
- Note confidence level and any unclear sections
- Report: `📝 Texto extraído: {chars} caracteres ({language})`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `MATHPIX_APP_ID` | Optional | Mathpix app ID |
| `MATHPIX_APP_KEY` | Optional | Mathpix app key |

## Usage Examples

### Example 1: Business card
**User**: Sends photo of a business card
**Response**: 📝 Datos extraídos:
- Nombre: Dr. Roberto Sánchez
- Cargo: Director General
- Tel: +52 55 9876 5432
- Email: r.sanchez@empresa.mx
¿Quieres que lo guarde como contacto?

### Example 2: Document scan
**User**: "Lee el texto de esta foto del menú"
**Response**: 📝 Menú extraído (español):
- Entrada: Sopa Azteca — $85
- Plato fuerte: Arrachera — $220
- Postre: Flan napolitano — $65

## Error Handling

| Error | Action |
|---|---|
| Blurry image | Ask for better photo or apply sharpening |
| Handwriting | Warn about lower accuracy |
| Mathpix unavailable | Fall back to Tesseract |
| Tesseract not installed | Use vision model as fallback OCR |
