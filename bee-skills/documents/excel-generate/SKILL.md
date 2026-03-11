---
name: excel-generate
description: "Generate Excel spreadsheets (.xlsx) with data, formulas, charts, and formatting. Use when the user needs a spreadsheet for data, financial reports, inventories, or any tabular data."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
---

# excel-generate

Create Excel spreadsheets with data, formatting, formulas, and charts.

## Instructions

### Step 1: Determine the structure
- Identify column headers and data types
- Plan formatting (number formats, dates, currencies)
- Determine if formulas, charts, or conditional formatting are needed

### Step 2: Generate with ExcelJS

```bash
node -e "
const ExcelJS = require('exceljs');
const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet('Datos');

// Headers with styling
const headerRow = sheet.addRow(['Producto', 'Cantidad', 'Precio', 'Total']);
headerRow.font = { bold: true, color: { argb: 'FFFFFF' } };
headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1a1a2e' } };

// Data rows
sheet.addRow(['Licencia Basic', 50, 25, { formula: 'B2*C2' }]);
sheet.addRow(['Licencia Pro', 30, 40, { formula: 'B3*C3' }]);

// Column widths
sheet.columns.forEach(col => col.width = 18);

// Currency format
sheet.getColumn(3).numFmt = '\"$\"#,##0.00';
sheet.getColumn(4).numFmt = '\"$\"#,##0.00';

await workbook.xlsx.writeFile('/tmp/output.xlsx');
"
```

### Step 3: Deliver
- Save the .xlsx file
- Report: `📊 Excel creado: {filename} ({rows} filas, {cols} columnas)`

## Usage Examples

### Example 1: Sales data
**User**: "Crea un Excel con los datos de ventas de esta semana"

**Response**: 📊 Excel creado: "Ventas-Semana-10.xlsx" (45 filas, 6 columnas). Incluye totales y fórmulas de suma.

### Example 2: Inventory
**User**: "Genera una hoja de inventario con estos productos..."

**Response**: 📊 Excel creado: "Inventario-Marzo.xlsx" (120 productos, columnas: SKU, Nombre, Stock, Precio, Valor Total). Fórmulas de total incluidas.

## Error Handling

| Error | Action |
|---|---|
| ExcelJS not available | Generate CSV as fallback |
| Too much data (>100K rows) | Stream write in batches |
| Invalid formula | Warn and use static value |
