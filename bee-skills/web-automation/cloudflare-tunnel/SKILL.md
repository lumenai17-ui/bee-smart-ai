---
name: cloudflare-tunnel
description: "Publish local web content to the internet via Cloudflare Tunnel. Use when the user wants to make a local website accessible publicly with a custom URL, SSL certificate, and DDoS protection — all with zero server configuration."
version: 1.0.0
category: web-automation
tier: pro
requires:
  - tool: bash
---

# cloudflare-tunnel

Publish local sites instantly via Cloudflare Tunnel.

## Instructions

### Step 1: Ensure cloudflared is installed
```bash
# Check if installed
cloudflared --version

# If not: install
# macOS: brew install cloudflare/cloudflare/cloudflared
# Linux: curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared
# Windows: winget install Cloudflare.cloudflared
```

### Step 2: Start a quick tunnel (anonymous)
For quick demos/shares (temporary URL):
```bash
# Serve a local directory
npx serve ./web-output/my-site -l 3000 &
cloudflared tunnel --url http://localhost:3000
```
This gives a temporary URL like `https://random-name.trycloudflare.com`

### Step 3: Named tunnel (persistent)
For permanent deployments:
```bash
# Login first
cloudflared tunnel login
# Create tunnel
cloudflared tunnel create my-site
# Configure DNS
cloudflared tunnel route dns my-site mysite.example.com
# Run
cloudflared tunnel run my-site
```

### Step 4: Report
- Report: `🚀 Web publicada: {url}`
- The URL has automatic SSL and DDoS protection
- Offer to generate QR code for sharing

## Usage Examples

### Example 1: Quick publish
**User**: "Publica la landing page que acabamos de crear"

**Response**: 🚀 Web publicada:
- 🌐 URL: `https://blue-river-abc123.trycloudflare.com`
- 🔒 SSL: Activado automáticamente
- ⏱️ Tiempo: 8 segundos
¿Quieres un QR para compartir?

### Example 2: Custom domain
**User**: "Publica en mi dominio mirestaurante.com"

**Response**: 🚀 Sitio desplegado:
- 🌐 URL: `https://mirestaurante.com`
- 🔒 SSL: Certificado de Cloudflare activo
- 🛡️ Protección DDoS: Activada

## Error Handling

| Error | Action |
|---|---|
| cloudflared not installed | Guide installation |
| Port already in use | Try next available port |
| DNS configuration needed | Guide user through DNS setup |
| Login required | Prompt `cloudflared tunnel login` |
