---
name: invoice-generate
description: "Generate professional invoices in PDF format. Use when the user needs to create a bill, factura, or receipt for a client. Supports multiple currencies, tax calculation, itemized details, and business branding."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
  - tool: http
---

# invoice-generate

Generate branded, professional invoices as PDF documents.

## Instructions

### Step 1: Gather invoice details
- **Client**: Name, address, tax ID (RFC in Mexico)
- **Items**: Description, quantity, unit price
- **Invoice number**: Auto-generate sequential or use provided
- **Date**: Issue date and due date
- **Tax**: IVA (16% Mexico), ITBMS, or as configured
- **Currency**: MXN, USD, EUR, etc.

### Step 2: Build the invoice HTML
Use a professional template with the business branding:
```html
<div class="invoice">
  <header>
    <div class="company">{{business_name}}</div>
    <div class="invoice-meta">
      <p>Factura #{{number}}</p>
      <p>Fecha: {{date}}</p>
      <p>Vence: {{due_date}}</p>
    </div>
  </header>
  <section class="client">
    <h3>Facturar a:</h3>
    <p>{{client_name}}</p>
    <p>RFC: {{client_rfc}}</p>
  </section>
  <table class="items">
    <thead><tr><th>Descripción</th><th>Cant.</th><th>Precio</th><th>Total</th></tr></thead>
    <tbody>{{items}}</tbody>
  </table>
  <section class="totals">
    <p>Subtotal: {{subtotal}}</p>
    <p>IVA (16%): {{tax}}</p>
    <p class="total">Total: {{total}}</p>
  </section>
</div>
```

### Step 3: Generate PDF
Use the `pdf-generate` skill to convert the invoice HTML to PDF.

### Step 4: Deliver
- Report: `🧾 Factura #{number} generada: {amount} {currency}`
- Offer to send by email or WhatsApp

## Usage Examples

### Example 1: Simple invoice
**User**: "Genera una factura a Juan Pérez por $5,000 de servicios de consultoría"

**Response**: 🧾 Factura #2026-0042 generada:
- Cliente: Juan Pérez
- Concepto: Servicios de consultoría
- Subtotal: $5,000.00
- IVA (16%): $800.00
- **Total: $5,800.00 MXN**

PDF listo. ¿Lo envío por email?

### Example 2: Multi-item invoice
**User**: "Hazle factura al Hotel Paraíso: 3 licencias basic ($25 c/u) y 1 pro ($40)"

**Response**: 🧾 Factura #2026-0043:

| Concepto | Cant. | Precio | Total |
|---|---|---|---|
| Licencia Basic | 3 | $25.00 | $75.00 |
| Licencia Pro | 1 | $40.00 | $40.00 |
| | | Subtotal | $115.00 |
| | | IVA 16% | $18.40 |
| | | **Total** | **$133.40** |

## Error Handling

| Error | Action |
|---|---|
| Missing client info | Ask for required fields |
| Invalid tax rate | Default to 16% (Mexico IVA), warn user |
| PDF generation fails | Save as HTML fallback |
