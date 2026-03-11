---
name: pdf-read
description: "Read, parse, and extract content from PDF files. Use when the user provides a PDF and wants to understand its contents, extract specific data, search for information, or get a summary. Uses Mathpix for complex PDFs (tables, math) or pdf-parse for simple text extraction."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
  - tool: http
---

# pdf-read

Extract text, tables, and data from PDF documents.

## Instructions

### Step 1: Receive the PDF file
- Accept the PDF from the user (file path or URL)
- Check file size and page count
- Determine complexity (text-only vs tables/images/math)

### Step 2: Extract content

**Simple text extraction (pdf-parse):**
```bash
node -e "
const fs = require('fs');
const pdfParse = require('pdf-parse');
const buffer = fs.readFileSync('/tmp/input.pdf');
pdfParse(buffer).then(data => {
  console.log('Pages:', data.numpages);
  console.log('Text:', data.text);
});
"
```

**Complex extraction (Mathpix — tables, math, images):**
```bash
curl -X POST "https://api.mathpix.com/v3/pdf" \
  -H "app_id: $MATHPIX_APP_ID" \
  -H "app_key: $MATHPIX_APP_KEY" \
  -F "file=@/tmp/input.pdf" \
  -F "options_json='{\"conversion_formats\": {\"md\": true}}'"
```

### Step 3: Present the content
- Show page count and document summary
- For short docs (<5 pages): Present full text
- For long docs: Provide summary + key information
- For tables: Format as markdown tables
- For forms: Extract field names and values

### Step 4: Offer follow-up
- "¿Quieres que extraiga datos específicos?"
- "¿Quieres un resumen ejecutivo?"
- "¿Quieres que busque algo en particular?"

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `MATHPIX_APP_ID` | Optional | Mathpix application ID |
| `MATHPIX_APP_KEY` | Optional | Mathpix application key |

## Usage Examples

### Example 1: Read a PDF
**User**: "Lee este PDF" (sends contract.pdf)

**Response**: 📖 PDF analizado: "Contrato de Servicios" (12 páginas)

**Resumen**: Contrato entre Empresa A y Empresa B para servicios de consultoría. Vigencia: 1 año. Valor: $24,000. Cláusulas principales: confidencialidad, penalización por cancelación (30 días).

¿Quieres que extraiga alguna sección específica?

### Example 2: Extract table data
**User**: "Extrae la tabla de precios de este PDF"

**Response**: 📊 Tabla extraída:

| Producto | Precio Unitario | Cantidad Min |
|---|---|---|
| Licencia Basic | $25/mes | 1 |
| Licencia Pro | $40/mes | 1 |
| Licencia Enterprise | $100/mes | 5 |

## Error Handling

| Error | Action |
|---|---|
| Password-protected PDF | Ask user for the password |
| Scanned/image PDF | Use OCR skill first, then extract text |
| Corrupted file | Inform user the file may be damaged |
| Very large PDF (>100 pages) | Process in batches, summarize by section |
