---
name: sheets-manage
description: "Read and write Google Sheets spreadsheets via the Google Sheets API. Use for data storage, collaborative editing, real-time dashboards, and data import/export."
version: 1.0.0
category: productivity
tier: pro
requires:
  - tool: http
---

# sheets-manage

Read and write Google Sheets for data management.

## Instructions

### Read data from a sheet:
```bash
curl "https://sheets.googleapis.com/v4/spreadsheets/$SHEET_ID/values/Sheet1!A1:Z100" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN"
```

### Write data to a sheet:
```bash
curl -X PUT "https://sheets.googleapis.com/v4/spreadsheets/$SHEET_ID/values/Sheet1!A1:D5?valueInputOption=USER_ENTERED" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "values": [["Producto","Cantidad","Precio","Total"],["Widget A",10,25,"=B2*C2"]] }'
```

### Append a row:
```bash
curl -X POST "https://sheets.googleapis.com/v4/spreadsheets/$SHEET_ID/values/Sheet1!A:D:append?valueInputOption=USER_ENTERED" \
  -H "Authorization: Bearer $GOOGLE_OAUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "values": [["New Item",5,30,"=B*C"]] }'
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_OAUTH_TOKEN` | Yes | Google OAuth2 access token |

## Usage Examples

### Example 1: Read inventory
**User**: "Lee la hoja de inventario"
**Response**: 📊 Google Sheet "Inventario" (45 filas):
| SKU | Producto | Stock | Precio |
|---|---|---|---|
| A001 | Widget A | 150 | $25 |
| A002 | Widget B | 0 ⚠️ | $30 |

### Example 2: Add data
**User**: "Agrega estas ventas al Sheet: Widget A x10, Widget B x5"
**Response**: 📊 2 filas agregadas al Sheet "Ventas". Total ahora: 47 filas.

## Error Handling

| Error | Action |
|---|---|
| Google OAuth not set | Guide authentication setup |
| Sheet not found | Ask for spreadsheet URL/ID |
| Permission denied | Need editor access to the sheet |
