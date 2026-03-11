---
name: qr-generate
description: "Generate QR codes for URLs, text, WiFi credentials, contact cards (vCard), events, or any data. Creates high-quality PNG/SVG QR codes with optional logo and branding."
version: 1.0.0
category: business
tier: basic
requires:
  - tool: bash
---

# qr-generate

Generate branded QR codes for any purpose.

## Instructions

### Generate QR code with Node.js:
```bash
node -e "
const QRCode = require('qrcode');
// PNG
await QRCode.toFile('/tmp/qr.png', 'https://example.com', {
  width: 400, margin: 2,
  color: { dark: '#1a1a2e', light: '#ffffff' }
});
// SVG
const svg = await QRCode.toString('https://example.com', { type: 'svg' });
require('fs').writeFileSync('/tmp/qr.svg', svg);
"
```

### QR Types:
- **URL**: `https://example.com`
- **WiFi**: `WIFI:T:WPA;S:NetworkName;P:password;;`
- **vCard**: `BEGIN:VCARD\nVERSION:3.0\nFN:Juan\nTEL:+521234567890\nEND:VCARD`
- **Event**: `BEGIN:VEVENT\nSUMMARY:Reunión\nDTSTART:20260315T100000\nEND:VEVENT`
- **Text/SMS/Email**: Formatted strings

## Usage Examples

### Example 1: URL QR
**User**: "Crea un QR para mi sitio web"
**Response**: 📱 QR generado para https://miempresa.com (400x400px). ¿Quieres que lo ponga en el menú/tarjeta?

### Example 2: WiFi QR
**User**: "Genera un QR para el WiFi del restaurante: red 'LaTrattoria', password 'bienvenidos2026'"
**Response**: 📱 QR WiFi generado. Los clientes solo escanean y se conectan automáticamente.

## Error Handling

| Error | Action |
|---|---|
| Data too long for QR | Suggest URL shortener or plain URL |
| qrcode library not available | Use online API as fallback |
