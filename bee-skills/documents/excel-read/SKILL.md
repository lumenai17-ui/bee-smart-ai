---
name: excel-read
description: "Read and parse Excel spreadsheets (.xlsx, .xls, .csv). Use when the user provides a spreadsheet and needs to understand the data, search for values, summarize contents, or convert to another format."
version: 1.0.0
category: documents
tier: basic
requires:
  - tool: bash
---

# excel-read

Read, parse, and analyze Excel and CSV files.

## Instructions

### Step 1: Load the file

```bash
node -e "
const ExcelJS = require('exceljs');
const workbook = new ExcelJS.Workbook();
await workbook.xlsx.readFile('/tmp/input.xlsx');

workbook.eachSheet((sheet, id) => {
  console.log('Sheet:', sheet.name, '- Rows:', sheet.rowCount, '- Cols:', sheet.columnCount);
  // Read headers
  const headers = [];
  sheet.getRow(1).eachCell((cell, colNum) => headers.push(cell.value));
  console.log('Headers:', headers.join(', '));
  // Read first 5 data rows
  for (let r = 2; r <= Math.min(6, sheet.rowCount); r++) {
    const row = [];
    sheet.getRow(r).eachCell((cell) => row.push(cell.value));
    console.log('Row', r, ':', row.join(' | '));
  }
});
"
```

### Step 2: Present data to user
- Show sheet count, row count, column headers
- Display first few rows as a preview table
- Provide data type summary (numbers, dates, text)
- Calculate basic stats for numeric columns (sum, avg, min, max)

### Step 3: Offer follow-up actions
- "¿Quieres filtrar por alguna columna?"
- "¿Quieres un resumen estadístico?"
- "¿Quieres convertirlo a otro formato?"

## Usage Examples

### Example 1: Read an inventory file
**User**: "Lee este Excel de inventario"

**Response**: 📊 Excel analizado: "inventario.xlsx"
- **Hojas**: 1 (Productos)
- **Filas**: 245 productos
- **Columnas**: SKU, Nombre, Stock, Precio, Categoría

Estadísticas rápidas:
- Stock total: 12,450 unidades
- Precio promedio: $45.80
- 3 productos con stock = 0 ⚠️

### Example 2: Search data
**User**: "¿Cuántos pedidos hay de más de $500?"

**Response**: 📊 Encontré 23 pedidos mayores a $500. Total: $18,750. ¿Quieres ver el detalle?

## Error Handling

| Error | Action |
|---|---|
| File format not recognized | Try CSV parser as fallback |
| Password-protected | Ask for password |
| Very large file (>50K rows) | Read in streaming mode, show preview |
| Corrupted cells | Skip and report which cells failed |
