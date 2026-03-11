---
name: pdf-edit
description: "Edit existing PDF files: merge, split, add watermarks, encrypt, rotate pages, or add annotations. Use when the user needs to manipulate existing PDFs."
version: 1.0.0
category: documents
tier: pro
requires:
  - tool: bash
  - tool: http
---

# pdf-edit

Edit, merge, split, watermark, and secure PDF documents.

## Instructions

### Supported operations

#### 1. Merge multiple PDFs
```bash
curl -X POST "https://api.pdf.co/v1/pdf/merge2" \
  -H "x-api-key: $PDF_CO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "urls": ["url1.pdf", "url2.pdf"], "name": "merged.pdf" }'
```

#### 2. Split a PDF
```bash
curl -X POST "https://api.pdf.co/v1/pdf/split" \
  -H "x-api-key: $PDF_CO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "url": "input.pdf", "pages": "1-3, 5, 7-10", "name": "split.pdf" }'
```

#### 3. Add watermark
```bash
curl -X POST "https://api.pdf.co/v1/pdf/edit/add" \
  -H "x-api-key: $PDF_CO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "input.pdf",
    "name": "watermarked.pdf",
    "annotations": [{
      "text": "CONFIDENCIAL",
      "x": 200, "y": 400,
      "size": 60, "color": "FF0000",
      "opacity": 30, "pages": "0-"
    }]
  }'
```

#### 4. Password protect
```bash
curl -X POST "https://api.pdf.co/v1/pdf/security/add" \
  -H "x-api-key: $PDF_CO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "url": "input.pdf", "userPassword": "secret123", "name": "protected.pdf" }'
```

#### Local fallback with qpdf/pdftk:
```bash
# Merge
qpdf --empty --pages file1.pdf file2.pdf -- merged.pdf
# Split
qpdf input.pdf --pages . 1-5 -- first5.pdf
# Encrypt
qpdf --encrypt userpass ownerpass 256 -- input.pdf protected.pdf
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `PDF_CO_API_KEY` | Optional | pdf.co API key |

## Usage Examples

### Example 1: Merge
**User**: "Junta estos 3 PDFs en uno solo"
**Response**: 📄 PDF combinado: "Documento-Completo.pdf" (15 páginas total).

### Example 2: Watermark
**User**: "Ponle marca de agua 'BORRADOR' al contrato"
**Response**: 📄 Marca de agua aplicada: "BORRADOR" en todas las páginas.

## Error Handling

| Error | Action |
|---|---|
| pdf.co not configured | Fall back to local qpdf/pdftk tools |
| Protected PDF (can't edit) | Ask for owner password |
| File too large | Process in smaller batches |
