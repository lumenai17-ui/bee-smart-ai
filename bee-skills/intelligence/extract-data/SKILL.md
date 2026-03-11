---
name: extract-data
description: "Extract structured data from unstructured text, documents, or images. Use when the user needs to pull specific information (names, dates, amounts, addresses, phone numbers, products) from text, emails, invoices, or any document."
version: 1.0.0
category: intelligence
tier: basic
requires:
  - tool: memory
---

# extract-data

Extract structured data fields from unstructured content using LLM.

## Instructions

### Step 1: Identify what to extract
Common extraction targets:
- **Contact info**: names, emails, phones, addresses
- **Financial**: amounts, currencies, invoice numbers, dates
- **Products**: names, SKUs, prices, quantities
- **Events**: dates, times, locations, participants
- **Custom fields**: whatever the user specifies

### Step 2: Analyze the content
Read the provided text/document and identify the requested data points. Structure internally:
- Identify all mentions of the requested field type
- Handle variations (e.g., "Tel:", "Phone:", "Teléfono:", "+52...")
- Resolve ambiguities by context
- Note confidence level for each extraction

### Step 3: Present structured results
Format as a clean table or JSON:
```
📊 Datos extraídos (5 campos, 92% confianza):

| Campo | Valor |
|---|---|
| Nombre | Juan Pérez García |
| Email | juan@empresa.com |
| Teléfono | +52 55 1234 5678 |
| Empresa | Acme Corp |
| RFC | PEGJ860101ABC |
```

## Usage Examples

### Example 1: Extract from email
**User**: "Extrae los datos de contacto de este email"

**Response**: 📊 Datos extraídos:
- **Nombre**: Lic. Carlos Mendoza
- **Email**: carlos.mendoza@bufete.mx
- **Tel**: +52 33 9876 5432
- **Empresa**: Bufete Mendoza & Asociados
- **Cargo**: Socio Director

### Example 2: Invoice data
**User**: "Extrae los datos de esta factura"

**Response**: 📊 Datos de factura:
- **Número**: FE-2026-0341
- **Fecha**: 10/03/2026
- **Emisor**: Tech Solutions SA de CV
- **RFC Emisor**: TSO200115XY9
- **Total**: $15,800.00 MXN (IVA incluido)
- **Concepto**: Servicios de desarrollo de software

### Example 3: Extract products from text
**User**: "Extrae los productos y precios de esta cotización"

**Response**: 📊 3 productos encontrados:

| Producto | Cantidad | Precio Unit. | Total |
|---|---|---|---|
| Laptop Dell XPS 15 | 2 | $24,500 | $49,000 |
| Monitor 27" 4K | 4 | $8,900 | $35,600 |
| Teclado mecánico | 6 | $2,100 | $12,600 |
| | | **Gran Total** | **$97,200** |

## Error Handling

| Error | Action |
|---|---|
| No data found | Inform user and ask to clarify what to extract |
| Low confidence (<70%) | Show results with warning markers |
| Ambiguous data | Present options and ask user to confirm |
| Content is an image | Use OCR skill first, then extract |
