---
name: word-generate
description: "Generate Microsoft Word (.docx) documents from content and templates. Use when the user needs a Word document for letters, reports, proposals, or any editable document format."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
---

# word-generate

Generate professional Word documents (.docx) with formatting and structure.

## Instructions

### Step 1: Gather content and structure
- Determine document type: letter, report, proposal, memo, etc.
- Collect the content from the user
- Apply appropriate formatting for the document type

### Step 2: Generate using docx library

```bash
node -e "
const { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell } = require('docx');

const doc = new Document({
  sections: [{
    properties: {},
    children: [
      new Paragraph({
        children: [new TextRun({ text: 'Título del Documento', bold: true, size: 32 })],
        heading: HeadingLevel.HEADING_1
      }),
      new Paragraph({
        children: [new TextRun('Contenido del documento aquí...')]
      })
    ]
  }]
});

const buffer = await Packer.toBuffer(doc);
require('fs').writeFileSync('/tmp/output.docx', buffer);
"
```

### Step 3: Deliver
- Save the .docx file
- Report: `📝 Documento Word generado: {filename}`
- Offer to send via email or convert to PDF

## Usage Examples

### Example 1: Business letter
**User**: "Crea una carta dirigida a Sr. García agradeciendo la colaboración"

**Response**: 📝 Documento Word generado: "Carta-Agradecimiento-Garcia.docx". Incluye membrete, fecha, saludo formal, cuerpo y firma.

### Example 2: Report
**User**: "Genera un documento Word con el informe trimestral"

**Response**: 📝 Documento Word generado: "Informe-Q1-2026.docx" (8 páginas, 3 tablas, 2 gráficos).

## Error Handling

| Error | Action |
|---|---|
| docx library not available | Generate HTML and suggest converting to docx online |
| Content too large | Split into sections, create table of contents |
| Missing template | Use default professional formatting |
