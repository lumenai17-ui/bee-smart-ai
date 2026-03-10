# FASE 4: HABILIDADES NATAS - REVISIÓN COMPLETA

**Versión:** 2.0.0
**Fecha:** 2026-03-05
**Prioridad:** 🔴 CRÍTICA - Todo procesamiento por APIs
**Principio:** NADA LOCAL - Todo vía APIs

---

## 🎯 PRINCIPIO FUNDAMENTAL

**TODO el procesamiento se hace vía APIs, NADA localmente.**

| ❌ No usar | ✅ Usar |
|-----------|--------|
| ffmpeg local | API de video (Mux, Cloudflare) |
| espeak local | API de TTS (OpenAI, ElevenLabs) |
| puppeteer local | API de PDF (PDF.co, CloudConvert) |
| pdftotext local | API de extract (Mathpix, PDF.co) |
| Whisper local | Whisper API |
| Stable Diffusion local | DALL-E API, Flux API |

**Razón:** ffmpeg, espeak, puppeteer consumen recursos del cliente. Debemos proveer APIs funcionando.

---

## 📋 REVISIÓN HABILIDAD POR HABILIDAD

### 1. VOICE_RECEIVE - Escuchar Voenotes

**Función:** Convertir voz a texto

| Aspecto | Detalle |
|---------|---------|
| **API** | OpenAI Whisper API |
| **Endpoint** | `POST https://api.openai.com/v1/audio/transcriptions` |
| **Costo** | $0.006/minuto |
| **Key** | OPENAI_API_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |
| **Fallback local** | ❌ NO - Solo API |

**Procesamiento multi-agente:**
```
Usuario envía voicenote
    │
    ▼
Agente recibe archivo de audio
    │
    ▼
Agente 1: VALIDADOR
    ├─► Verificar formato (mp3, wav, ogg)
    ├─► Verificar tamaño (< 25MB)
    └─► Verificar duración (< 2 horas)
    │
    ▼
Agente 2: TRANSCRIBER
    ├─► Llamar Whisper API
    ├─► Obtener texto
    └─► Obtener idioma detectado
    │
    ▼
Agente 3: FORMATTER
    ├─► Formatear texto
    ├─► Agregar metadata
    └─► Entregar al agente principal
```

**Sin API key:**
```json
{
  "voice_receive": {
    "enabled": false,
    "reason": "OPENAI_API_KEY no configurada",
    "message": "Para escuchar audios, necesito que configures tu API key de OpenAI en la FASE 1.",
    "setup_instructions": "Ve a FASE 1 y agrega: OPENAI_API_KEY=sk-..."
  }
}
```

---

### 2. VOICE_SEND - Enviar Voenotes

**Función:** Convertir texto a voz

| Aspecto | Detalle |
|---------|---------|
| **API** | OpenAI TTS API o ElevenLabs |
| **Endpoint** | `POST https://api.openai.com/v1/audio/speech` |
| **Costo** | OpenAI: $15/1M chars, ElevenLabs: $5/1M chars |
| **Key** | OPENAI_API_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |
| **Fallback local** | ❌ NO - Solo API |

**Procesamiento multi-agente:**
```
Agente quiere enviar voicenote
    │
    ▼
Agente 1: GENERATOR
    ├─► Generar texto a convertir
    ├─► Seleccionar voz (alloy, echo, fable...)
    └─► Seleccionar velocidad
    │
    ▼
Agente 2: CONVERTER
    ├─► Llamar TTS API
    ├─► Obtener archivo de audio
    └─► Formato: mp3, opus, aac
    │
    ▼
Agente 3: SENDER
    ├─► Enviar archivo a Telegram/WhatsApp
    └─► Confirmar envío
```

---

### 3. IMAGE_GENERATE - Crear Imágenes

**Función:** Generar imágenes desde texto

| Aspecto | Detalle |
|---------|---------|
| **API** | OpenAI DALL-E 3 |
| **Endpoint** | `POST https://api.openai.com/v1/images/generations` |
| **Costo** | $0.04-0.12 por imagen |
| **Key** | OPENAI_API_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |
| **Fallback local** | ❌ NO - Solo API |

**Procesamiento multi-agente:**
```
Usuario pide crear imagen
    │
    ▼
Agente 1: PROMPT BUILDER
    ├─► Recibir descripción del usuario
    ├─► Mejorar prompt para DALL-E
    └─► Seleccionar tamaño y calidad
    │
    ▼
Agente 2: GENERATOR
    ├─► Llamar DALL-E API
    ├─► Obtener URL de imagen
    └─► Descargar imagen
    │
    ▼
Agente 3: OPTIMIZER
    ├─► Redimensionar si necesario
    ├─► Optimizar tamaño
    └─► Entregar al usuario
```

---

### 4. IMAGE_RECEIVE - Analizar Imágenes

**Función:** Analizar y describir imágenes

| Aspecto | Detalle |
|---------|---------|
| **API** | Ollama Vision (qwen3-vl) ✅ |
| **Endpoint** | `POST https://ollama.com/v1/chat/completions` |
| **Costo** | Incluido en plan Ollama |
| **Key** | OLLAMA_API_KEY (FASE 1) ✅ YA CONFIGURADA |
| **Proveedor** | Servicio compartido (bee.ai) |
| **Fallback local** | ❌ NO - Solo API |

**✅ ESTA FUNCIÓN YA FUNCIONA**

---

### 5. EMAIL_SEND - Enviar Emails

**Función:** Enviar emails

| Aspecto | Detalle |
|---------|---------|
| **API** | Resend API |
| **Endpoint** | `POST https://api.resend.com/emails` |
| **Costo** | Gratis 3,000 emails/mes |
| **Key** | RESEND_API_KEY (FASE 1) |
| **Dominio** | bee.ai (configurado por nosotros) |
| **Proveedor** | Nosotros proveemos el dominio + key compartida |

**IMPORTANTE:** Para emails, nosotros proveemos:
1. Dominio bee.ai verificado
2. API key de Resend compartida
3. El cliente NO configura nada

**Procesamiento multi-agente:**
```
Agente quiere enviar email
    │
    ▼
Agente 1: COMPOSER
    ├─► Generar contenido del email
    ├─► Formatear HTML
    └─► Preparar adjuntos
    │
    ▼
Agente 2: VALIDATOR
    ├─► Verificar destinatario
    ├─► Verificar subject
    └─► Verificar adjuntos < 25MB
    │
    ▼
Agente 3: SENDER
    ├─► Llamar Resend API
    ├─► Obtener ID de mensaje
    └─► Confirmar envío
```

---

### 6. EMAIL_READ - Leer Emails

**Función:** Leer y recibir emails

| Aspecto | Detalle |
|---------|---------|
| **API** | IMAP/POP3 ✅ |
| **Servidor** | imap.bee.ai |
| **Costo** | GRATIS |
| **Key** | No necesita API key |
| **Configuración** | Nosotros proveemos el servidor IMAP |

**IMPORTANTE:** Para emails, nosotros proveemos:
1. Servidor IMAP bee.ai
2. Buzón para cada agente
3. El cliente NO configura nada

---

### 7. PDF_GENERATE - Crear PDFs

**Función:** Generar PDFs desde HTML/Markdown

| Aspecto | Detalle |
|---------|---------|
| **API** | PDF.co API o CloudConvert |
| **Endpoint** | `POST https://api.pdf.co/v1/pdf/convert` |
| **Costo** | PDF.co: Gratis 5,000 páginas/mes |
| **Key** | No necesita - API compartida |
| **Proveedor** | Nosotros proveemos API compartida |

**IMPORTANTE:** Para PDFs, nosotros proveemos:
1. API key de PDF.co compartida
2. El cliente NO configura nada

**Procesamiento multi-agente:**
```
Agente quiere crear PDF
    │
    ▼
Agente 1: CONTENT GENERATOR
    ├─► Generar contenido HTML/Markdown
    ├─► Agregar estilos
    └─► Preparar estructura
    │
    ▼
Agente 2: PDF CONVERTER
    ├─► Llamar PDF.co API
    ├─► Obtener PDF
    └─► Optimizar tamaño
    │
    ▼
Agente 3: DELIVERER
    ├─► Guardar en ~/.openclaw/data/pdfs/
    └─► Entregar URL al usuario
```

---

### 8. PDF_READ - Leer PDFs

**Función:** Extraer texto de PDFs

| Aspecto | Detalle |
|---------|---------|
| **API** | Mathpix API o PDF.co |
| **Endpoint** | `POST https://api.mathpix.com/v3/text` |
| **Costo** | Mathpix: Gratis 1,000 páginas/mes |
| **Key** | No necesita - API compartida |
| **Proveedor** | Nosotros proveemos API compartida |

**IMPORTANTE:** Para leer PDFs, nosotros proveemos:
1. API key de Mathpix compartida
2. El cliente NO configura nada

---

### 9. VIDEO_PROCESS - Procesar Videos

**Función:** Analizar y procesar videos

| Aspecto | Detalle |
|---------|---------|
| **API** | Ollama Vision + Mux API |
| **Endpoint** | Vision: Ollama, Video: Mux |
| **Costo** | Ollama: incluido, Mux: gratis para agentes |
| **Key** | OLLAMA_API_KEY + MUX_API_KEY |
| **Proveedor** | Ollama: ya configurado, Mux: nosotros proveemos |

**IMPORTANTE:**
- Vision: Ollama ya configurado ✅
- Video hosting: Mux API compartida

---

### 10. LOCATION - Manejar Ubicaciones

**Función:** Manejar ubicaciones y maps

| Aspecto | Detalle |
|---------|---------|
| **API** | Google Maps Geocoding API |
| **Endpoint** | `GET https://maps.googleapis.com/maps/api/geocode/json` |
| **Costo** | $200 crédito gratis/mes, luego $0.005/request |
| **Key** | GOOGLE_MAPS_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |

---

### 11. CALENDAR - Google Calendar

**Función:** Manejar eventos de calendario

| Aspecto | Detalle |
|---------|---------|
| **API** | Google Calendar API |
| **Costo** | GRATIS |
| **Key** | GOOGLE_OAUTH (FASE 5) |
| **Proveedor** | Cliente configura OAuth en FASE 5 |

---

### 12. SHEETS - Google Sheets

**Función:** Leer y escribir hojas de cálculo

| Aspecto | Detalle |
|---------|---------|
| **API** | Google Sheets API |
| **Costo** | GRATIS |
| **Key** | GOOGLE_OAUTH (FASE 5) |
| **Proveedor** | Cliente configura OAuth en FASE 5 |

---

### 13. TRANSLATE - Traducción

**Función:** Traducir texto

| Aspecto | Detalle |
|---------|---------|
| **API** | DeepL API |
| **Endpoint** | `POST https://api-free.deepl.com/v2/translate` |
| **Costo** | Gratis 500,000 caracteres/mes |
| **Key** | DEEPL_API_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |

---

### 14. AUDIO_PROCESS - Procesar Audio

**Función:** Procesar archivos de audio

| Aspecto | Detalle |
|---------|---------|
| **API** | OpenAI Whisper API (igual que voice_receive) |
| **Costo** | $0.006/minuto |
| **Key** | OPENAI_API_KEY (FASE 1) |
| **Proveedor** | Cliente configura su key en FASE 1 |

---

## 3️⃣ RESUMEN DE APIs NECESARIAS

### APIs que el CLIENTE configura (FASE 1)

| API | Habilidades | Costo |
|-----|-------------|-------|
| `OLLAMA_API_KEY` | image_receive, video_process | Plan Ollama |
| `OPENAI_API_KEY` | voice_receive, voice_send, image_generate, audio_process | Pay per use |
| `DEEPL_API_KEY` | translate | Gratis 500K chars/mes |
| `GOOGLE_MAPS_KEY` | location | Gratis $200 crédito/mes |

### APIs que NOSOTROS proveemos (SERVICIO COMPARTIDO)

| API | Habilidades | Nuestra Key | Dominio |
|-----|-------------|-------------|---------|
| Resend | email_send | Compartida | bee.ai |
| IMAP | email_read | Compartida | bee.ai |
| PDF.co | pdf_generate, pdf_read | Compartida | - |
| Mux | video_hosting | Compartida | - |

### APIs que requieren OAuth (FASE 5)

| API | Habilidades | Configuración |
|-----|-------------|--------------|
| Google OAuth | calendar, sheets | Cliente configura en FASE 5 |

---

## 4️⃣ SISTEMA DE APIs COMPARTIDAS (NUEVO)

### APIs que proveemos como servicio

```json
{
  "shared_apis": {
    "resend": {
      "enabled": true,
      "api_key": "re_xxxx_shared",
      "domain": "bee.ai",
      "limit_per_agent": 3000,
      "note": "Nosotros proveemos, cliente no configura"
    },
    "pdf_co": {
      "enabled": true,
      "api_key": "pdf_xxxx_shared",
      "limit_per_agent": 5000,
      "note": "Nosotros proveemos, cliente no configura"
    },
    "mathpix": {
      "enabled": true,
      "api_key": "math_xxxx_shared",
      "limit_per_agent": 1000,
      "note": "Nosotros proveemos, cliente no configura"
    },
    "mux": {
      "enabled": true,
      "api_key": "mux_xxxx_shared",
      "limit_per_agent": 100,
      "note": "Nosotros proveemos, cliente no configura"
    }
  }
}
```

### Keys que el cliente configura en FASE 1

```json
{
  "client_apis": {
    "OLLAMA_API_KEY": {
      "required": true,
      "habilidades": ["image_receive", "video_process"],
      "note": "OBLIGATORIA"
    },
    "OPENAI_API_KEY": {
      "required": false,
      "habilidades": ["voice_receive", "voice_send", "image_generate", "audio_process"],
      "note": "Opcional pero recomendada"
    },
    "DEEPL_API_KEY": {
      "required": false,
      "habilidades": ["translate"],
      "note": "Opcional"
    },
    "GOOGLE_MAPS_KEY": {
      "required": false,
      "habilidades": ["location"],
      "note": "Opcional"
    }
  }
}
```

---

## 5️⃣ HABILIDADES SIN API KEY (SIEMPRE FUNCIONAN)

| Habilidad | Estado | Nota |
|-----------|--------|------|
| **email_send** | ✅ Siempre | Nosotros proveemos Resend |
| **email_read** | ✅ Siempre | Nosotros proveemos IMAP |
| **pdf_generate** | ✅ Siempre | Nosotros proveemos PDF.co |
| **pdf_read** | ✅ Siempre | Nosotros proveemos Mathpix |
| **image_receive** | ✅ Siempre | Ollama (OBLIGATORIA en FASE 1) |

---

## 6️⃣ HABILIDADES QUE REQUIEREN API KEY DEL CLIENTE

| Habilidad | API | Configura en |
|-----------|-----|--------------|
| voice_receive | OPENAI_API_KEY | FASE 1 |
| voice_send | OPENAI_API_KEY | FASE 1 |
| image_generate | OPENAI_API_KEY | FASE 1 |
| audio_process | OPENAI_API_KEY | FASE 1 |
| translate | DEEPL_API_KEY | FASE 1 |
| location | GOOGLE_MAPS_KEY | FASE 1 |
| calendar | GOOGLE_OAUTH | FASE 5 |
| sheets | GOOGLE_OAUTH | FASE 5 |

---

## 7️⃣ MENSAJES CUANDO FALTA API KEY

### Sin OPENAI_API_KEY

```json
{
  "habilidad": "voice_receive",
  "enabled": false,
  "reason": "OPENAI_API_KEY no configurada",
  "message": "Para escuchar audios, necesito una API key de OpenAI.",
  "setup": {
    "step1": "Ve a https://platform.openai.com/api-keys",
    "step2": "Crea una API key",
    "step3": "Agrégala en FASE 1 como OPENAI_API_KEY"
  }
}
```

### Sin DEEPL_API_KEY

```json
{
  "habilidad": "translate",
  "enabled": false,
  "reason": "DEEPL_API_KEY no configurada",
  "message": "Para traducir, necesito una API key de DeepL.",
  "setup": {
    "step1": "Ve a https://www.deepl.com/pro-api",
    "step2": "Crea una cuenta gratuita",
    "step3": "Agrégala en FASE 1 como DEEPL_API_KEY"
  }
}
```

---

## 8️⃣ VALIDACIÓN FINAL

### Habilidades que funcionan SIEMPRE (sin configuración del cliente)

| Habilidad | API | Proveedor |
|-----------|-----|-----------|
| image_receive | Ollama | Configurada en FASE 1 (OBLIGATORIA) |
| email_send | Resend | Nosotros proveemos |
| email_read | IMAP | Nosotros proveemos |
| pdf_generate | PDF.co | Nosotros proveemos |
| pdf_read | Mathpix | Nosotros proveemos |

### Habilidades que funcionan con API key del cliente

| Habilidad | API | Estado si falta key |
|-----------|-----|---------------------|
| voice_receive | OPENAI | Mensaje explicativo |
| voice_send | OPENAI | Mensaje explicativo |
| image_generate | OPENAI | Mensaje explicativo |
| audio_process | OPENAI | Mensaje explicativo |
| translate | DEEPL | Mensaje explicativo |
| location | GOOGLE_MAPS | Mensaje explicativo |
| calendar | GOOGLE_OAUTH | Mensaje explicativo |
| sheets | GOOGLE_OAUTH | Mensaje explicativo |

---

*Revisión completada - Sistema de APIs actualizado*

---

## 2️⃣ DETALLE DE CADA HABILIDAD

### 2.1 👂 VOICE_RECEIVE - Escuchar Voenotes

**Qué hace:** Convierte voz a texto

**API necesaria:** OpenAI Whisper API o similar

**Endpoint:**
```
POST https://api.openai.com/v1/audio/transcriptions
Authorization: Bearer {OPENAI_API_KEY}
```

**Costo:** ~$0.006 por minuto de audio

**Sin API key:**
- ❌ **No funciona**
- El agente no puede escuchar voicenotes
- Mensaje: "Para escuchar audios, configura tu API key de Whisper"

**Archivo de configuración:**
```json
{
  "voice_receive": {
    "enabled": true,
    "provider": "openai",
    "model": "whisper-1",
    "api_key": "${OPENAI_API_KEY}",
    "languages": ["es", "en", "pt"],
    "fallback_message": "Para escuchar audios, necesito una API key de Whisper. Contacta al administrador."
  }
}
```

---

### 2.2 🗣️ VOICE_SEND - Enviar Voenotes

**Qué hace:** Convierte texto a voz

**API necesaria:** TTS (Text-to-Speech)

**Opciones:**
| Provider | Costo | Calidad |
|----------|-------|---------|
| OpenAI TTS | $15/1M chars | Alta |
| ElevenLabs | $5/1M chars | Muy alta |
| Local TTS | Gratis | Media |

**Sin API key:**
- ❌ No funciona con APIs pagas
- ✅ Funciona con TTS local (calidad media)
- Mensaje: "Para voz de alta calidad, configura API key de TTS"

**Archivo de configuración:**
```json
{
  "voice_send": {
    "enabled": true,
    "provider": "openai",
    "model": "tts-1",
    "api_key": "${OPENAI_API_KEY}",
    "voice": "alloy",
    "local_fallback": {
      "enabled": true,
      "provider": "espeak",
      "quality": "media"
    }
  }
}
```

---

### 2.3 🖼️ IMAGE_GENERATE - Crear Imágenes

**Qué hace:** Genera imágenes desde texto

**API necesaria:** DALL-E, Flux, o Stable Diffusion

**Opciones:**
| Provider | Costo | Calidad |
|----------|-------|---------|
| DALL-E 3 | $0.04-0.12/img | Alta |
| Flux | Variable | Alta |
| SD Local | Gratis | Media |

**Endpoint DALL-E:**
```
POST https://api.openai.com/v1/images/generations
Authorization: Bearer {OPENAI_API_KEY}
```

**Sin API key:**
- ❌ No funciona con APIs pagas
- ⚠️ Funciona con Stable Diffusion local (requiere GPU)
- Mensaje: "Para crear imágenes, necesito una API key de DALL-E o Flux"

**Archivo de configuración:**
```json
{
  "image_generate": {
    "enabled": true,
    "provider": "openai",
    "model": "dall-e-3",
    "api_key": "${OPENAI_API_KEY}",
    "size": "1024x1024",
    "quality": "standard",
    "fallback_message": "Para crear imágenes, necesito una API key de DALL-E o Flux."
  }
}
```

---

### 2.4 👁️ IMAGE_RECEIVE - Analizar Imágenes

**Qué hace:** Describe y analiza imágenes

**API necesaria:** Vision API (incluida en Ollama)

**Opción incluida:**
- ✅ **Ollama qwen3-vl:235b** - Ya disponible con la API key de Ollama
- No requiere API adicional

**Endpoint:**
```
POST https://ollama.com/v1/chat/completions
Authorization: Bearer {OLLAMA_API_KEY}
Model: qwen3-vl:235b-instruct
```

**Costo:** Incluido en plan Ollama

**Sin API key:**
- ❌ No funciona
- La API key de Ollama ya se configuró en FASE 1

**Archivo de configuración:**
```json
{
  "image_receive": {
    "enabled": true,
    "provider": "ollama",
    "model": "qwen3-vl:235b-instruct",
    "api_key": "${OLLAMA_API_KEY}",
    "features": ["describe", "ocr", "analyze"]
  }
}
```

---

### 2.5 📧 EMAIL_SEND - Enviar Emails

**Qué hace:** Envía emails

**API necesaria:** Resend, SendGrid, o SMTP

**Opciones:**
| Provider | Costo | Límite |
|----------|-------|--------|
| Resend | Gratis 3K/mes | 100/día |
| SendGrid | Gratis 100/día | 100/día |
| SMTP | Depende | Sin límite |

**Dominio bee.ai:**
- Email: `{agente}@bee.ai`
- Provider: Resend
- Verificado en FASE 7 (Registry)

**Endpoint Resend:**
```
POST https://api.resend.com/emails
Authorization: Bearer {RESEND_API_KEY}
```

**Sin API key:**
- ❌ No funciona
- Mensaje: "Para enviar emails, necesito configurar el dominio bee.ai"

**Archivo de configuración:**
```json
{
  "email_send": {
    "enabled": true,
    "provider": "resend",
    "api_key": "${RESEND_API_KEY}",
    "domain": "bee.ai",
    "from": "{agent_name}@bee.ai",
    "features": {
      "templates": true,
      "attachments": true,
      "tracking": true
    },
    "fallback_message": "Para enviar emails, necesito configurar el dominio bee.ai."
  }
}
```

---

### 2.6 📨 EMAIL_READ - Leer Emails

**Qué hace:** Lee y recibe emails

**API necesaria:** IMAP/POP3 (¡GRATIS!)

**Proveedor:** Cualquier servidor de email

**Configuración IMAP:**
```json
{
  "email_read": {
    "enabled": true,
    "provider": "imap",
    "server": "imap.bee.ai",
    "port": 993,
    "security": "ssl",
    "username": "{agent_name}@bee.ai",
    "password": "${EMAIL_PASSWORD}",
    "features": {
      "attachments": true,
      "html": true,
      "folders": ["INBOX", "Sent"]
    }
  }
}
```

**Sin configuración:**
- ❌ No funciona sin servidor IMAP
- Pero es GRATIS (no requiere API key paga)

---

### 2.7 📄 PDF_GENERATE - Crear PDFs

**Qué hace:** Genera PDFs desde HTML/Markdown

**API necesaria:** Puppeteer (¡GRATIS!)

**Proveedor:** Local, ningún costo

**Instalación:**
```bash
npm install puppeteer
```

**Funcionamiento:**
1. Agente genera HTML
2. Puppeteer convierte a PDF
3. PDF guardado en `~/.openclaw/data/pdfs/`

**Sin instalación:**
- ❌ No funciona
- Mensaje: "PDF generator no instalado. Ejecuta: npm install puppeteer"

**Archivo de configuración:**
```json
{
  "pdf_generate": {
    "enabled": true,
    "provider": "puppeteer",
    "cost": "free",
    "features": {
      "templates": true,
      "headers": true,
      "footers": true,
      "watermark": false
    }
  }
}
```

---

### 2.8 📑 PDF_READ - Leer PDFs

**Qué hace:** Extrae texto de PDFs

**API necesaria:** pdftotext (¡GRATIS!)

**Instalación:**
```bash
sudo apt install poppler-utils
```

**Estado actual:** ✅ Ya instalado en LOCAL

**Sin instalación:**
- ❌ No funciona
- Mensaje: "PDF reader no instalado. Ejecuta: sudo apt install poppler-utils"

---

### 2.9 🎬 VIDEO_PROCESS - Procesar Videos

**Qué hace:** Analiza videos cortos

**API necesaria:** Vision API (Ollama) + Frame extraction

**Proveedor:** Ollama Cloud

**Requisitos:**
- API key Ollama (ya configurada)
- ffmpeg para extracción de frames

**Sin API key:**
- ❌ No funciona
- Pero Ollama ya está configurado

---

### 2.10 📍 LOCATION - Manejar Ubicaciones

**Qué hace:** Maneja ubicaciones y maps

**API necesaria:** Google Maps API

**Endpoint:**
```
GET https://maps.googleapis.com/maps/api/geocode/json
?key={GOOGLE_MAPS_API_KEY}
```

**Costo:** $200 crédito gratis/mes, luego $0.005/request

**Sin API key:**
- ⚠️ Funcionalidad limitada
- Mensaje: "Para ubicaciones precisas, necesito API key de Google Maps"

---

### 2.11 📅 CALENDAR - Google Calendar

**Qué hace:** Maneja eventos de calendario

**API necesaria:** Google Calendar API + OAuth

**Requisitos:**
- Google Cloud Project
- OAuth configurado
- API key

**Sin configuración:**
- ❌ No funciona
- Requiere configuración manual por el usuario

---

### 2.12 📊 SHEETS - Google Sheets

**Qué hace:** Lee y escribe hojas de cálculo

**API necesaria:** Google Sheets API + OAuth

**Requisitos:** Igual que Calendar

---

### 2.13 🌐 TRANSLATE - Traducción

**Qué hace:** Traduce texto

**API necesaria:** DeepL o Google Translate API

**Opciones:**
| Provider | Costo | Calidad |
|----------|-------|---------|
| DeepL | Gratis 500K chars/mes | Muy alta |
| Google | $20/1M chars | Alta |

**Sin API key:**
- ❌ No funciona
- Mensaje: "Para traducir, necesito API key de DeepL o Google"

---

### 2.14 🎵 AUDIO_PROCESS - Procesar Audio

**Qué hace:** Procesa archivos de audio

**API necesaria:** Whisper API

**Igual que voice_receive**

---

## 3️⃣ RESUMEN DE DEPENDENCIAS

### Habilidades GRATIS (siempre funcionan)

| Habilidad | Dependencia | Estado |
|-----------|-------------|--------|
| pdf_read | pdftotext | ✅ Instalado |
| pdf_generate | Puppeteer | ⚠️ Instalar npm |

### Habilidades con API Key de Ollama (ya configurada)

| Habilidad | Usa | Estado |
|-----------|-----|--------|
| image_receive | qwen3-vl | ✅ Funciona |
| video_process | qwen3-vl | ✅ Funciona |

### Habilidades que requieren API adicional

| Habilidad | API | Costo |
|-----------|-----|-------|
| voice_receive | Whisper | $0.006/min |
| voice_send | TTS | Gratis local |
| image_generate | DALL-E | $0.04-0.12/img |
| email_send | Resend | Gratis 3K/mes |
| email_read | IMAP | Gratis |
| location | Google Maps | Gratis $200/mes |
| calendar | Google OAuth | Gratis |
| sheets | Google OAuth | Gratis |
| translate | DeepL | Gratis 500K/mes |

---

## 4️⃣ CONFIGURACIÓN POR DEFECTO

### Todas las API Keys necesarias

| API Key | FASE donde se configura | Usada por |
|---------|------------------------|-----------|
| OLLAMA_API_KEY | FASE 1 | image_receive, video_process |
| OPENAI_API_KEY | FASE 1 | voice_receive, voice_send, image_generate |
| RESEND_API_KEY | FASE 1 | email_send |
| DEEPL_API_KEY | FASE 1 | translate |
| GOOGLE_MAPS_KEY | FASE 1 | location |
| GOOGLE_OAUTH | FASE 5 | calendar, sheets |

### Archivo de configuración final

```json
{
  "native_skills": {
    "voice_receive": {
      "enabled": true,
      "requires_api_key": "OPENAI_API_KEY",
      "fallback_message": "Para escuchar audios, necesito API key de Whisper."
    },
    "voice_send": {
      "enabled": true,
      "provider": "local",
      "fallback_provider": "espeak"
    },
    "image_generate": {
      "enabled": true,
      "requires_api_key": "OPENAI_API_KEY",
      "fallback_message": "Para crear imágenes, necesito API key de DALL-E."
    },
    "image_receive": {
      "enabled": true,
      "uses_api_key": "OLLAMA_API_KEY"
    },
    "email_send": {
      "enabled": true,
      "requires_api_key": "RESEND_API_KEY",
      "requires_domain": "bee.ai"
    },
    "email_read": {
      "enabled": true,
      "requires_imap": true
    },
    "pdf_generate": {
      "enabled": true,
      "requires_install": "npm install puppeteer"
    },
    "pdf_read": {
      "enabled": true,
      "requires_install": "sudo apt install poppler-utils"
    },
    "video_process": {
      "enabled": true,
      "uses_api_key": "OLLAMA_API_KEY"
    },
    "location": {
      "enabled": true,
      "requires_api_key": "GOOGLE_MAPS_KEY"
    },
    "calendar": {
      "enabled": true,
      "requires_oauth": "google"
    },
    "sheets": {
      "enabled": true,
      "requires_oauth": "google"
    },
    "translate": {
      "enabled": true,
      "requires_api_key": "DEEPL_API_KEY"
    },
    "audio_process": {
      "enabled": true,
      "requires_api_key": "OPENAI_API_KEY"
    }
  }
}
```

---

## 5️⃣ VALIDACIÓN EN LOCAL

### Resultados de Validación (2026-03-05)

| Habilidad | Dependencia | Verificación |
|-----------|-------------|--------------|
| **image_receive** | Ollama API | ✅ Funciona |
| **video_process** | Ollama API + ffmpeg | ✅ Funciona (ffmpeg instalado) |
| **pdf_read** | pdftotext | ✅ Instalado |

### Habilidades que FALTA instalar/configurar

| Habilidad | Acción |
|-----------|--------|
| pdf_generate | `npm install puppeteer` |
| voice_send | `sudo apt install espeak` |

### Habilidades que FALTA API key

| Habilidad | API necesaria | Estado |
|-----------|--------------|--------|
| voice_receive | OPENAI_API_KEY | ❌ NO configurada |
| voice_send (calidad alta) | OPENAI_API_KEY | ❌ NO configurada |
| image_generate | OPENAI_API_KEY | ❌ NO configurada |
| email_send | RESEND_API_KEY | ❌ NO configurada |
| translate | DEEPL_API_KEY | ❌ NO configurada |
| location | GOOGLE_MAPS_KEY | ❌ NO configurada |
| calendar | GOOGLE_OAUTH | ❌ NO configurada |
| sheets | GOOGLE_OAUTH | ❌ NO configurada |

### Habilidades que funcionan SIN configuración adicional

| Habilidad | Estado | Nota |
|-----------|--------|------|
| **image_receive** | ✅ Funciona | Usa Ollama API (ya configurada) |
| **video_process** | ✅ Funciona | Usa Ollama + ffmpeg (instalado) |
| **pdf_read** | ✅ Funciona | pdftotext instalado |
| **email_read** | ⚠️ Parcial | IMAP gratis pero requiere configuración |

### Habilidades con fallback local

| Habilidad | Fallback | Calidad |
|-----------|----------|---------|
| voice_send | espeak (local) | Media |
| pdf_generate | puppeteer (local) | Alta |

---

## 6️⃣ PREGUNTAS DE VALIDACIÓN

| # | Pregunta | Resultado | Acción |
|---|----------|-----------|--------|
| 1 | ¿Ollama API key funciona? | ✅ Sí | Ninguna |
| 2 | ¿Ollama tiene modelo vision? | ✅ qwen3-vl | Ninguna |
| 3 | ¿pdftotext está instalado? | ✅ Sí | Ninguna |
| 4 | ¿puppeteer está instalado? | ❌ No | Instalar en FASE 4 |
| 5 | ¿espeak está instalado? | ❌ No | Instalar en FASE 4 |
| 6 | ¿ffmpeg está instalado? | ✅ Sí | Ninguna |
| 7 | ¿OPENAI_API_KEY configurada? | ❌ No | Agregar a FASE 1 |
| 8 | ¿RESEND_API_KEY configurada? | ❌ No | Agregar a FASE 1 |
| 9 | ¿DEEPL_API_KEY configurada? | ❌ No | Agregar a FASE 1 |
| 10 | ¿GOOGLE_MAPS_KEY configurada? | ❌ No | Agregar a FASE 1 |
| 11 | ¿GOOGLE_OAUTH configurado? | ❌ No | Agregar a FASE 5 |

---

## 7️⃣ CONCLUSIONES FINALES

### ✅ Habilidades que funcionan AHORA (sin configuración)

| Habilidad | Estado | Nota |
|-----------|--------|------|
| image_receive | ✅ Funciona | Ollama + qwen3-vl |
| video_process | ✅ Funciona | Ollama + ffmpeg |
| pdf_read | ✅ Funciona | pdftotext |

### ⚠️ Habilidades que funcionan con instalación LOCAL

| Habilidad | Acción | Gratis? |
|-----------|--------|---------|
| pdf_generate | `npm install puppeteer` | ✅ Sí |
| voice_send | `sudo apt install espeak` | ✅ Sí |

### ❌ Habilidades que necesitan API key

| Habilidad | API | Dónde configurar |
|-----------|-----|-----------------|
| voice_receive | OPENAI_API_KEY | FASE 1 INPUTS.md |
| image_generate | OPENAI_API_KEY | FASE 1 INPUTS.md |
| email_send | RESEND_API_KEY | FASE 1 INPUTS.md |
| translate | DEEPL_API_KEY | FASE 1 INPUTS.md |
| location | GOOGLE_MAPS_KEY | FASE 1 INPUTS.md |
| calendar | GOOGLE_OAUTH | FASE 5 |
| sheets | GOOGLE_OAUTH | FASE 5 |
| email_read | IMAP config | FASE 4 |

### 📋 ACCIONES PENDIENTES

1. **FASE 1 INPUTS.md** - Agregar sección de API keys adicionales:
   - OPENAI_API_KEY
   - RESEND_API_KEY
   - DEEPL_API_KEY
   - GOOGLE_MAPS_KEY

2. **FASE 4 CODING** - Instalar dependencias locales:
   - `npm install puppeteer`
   - `sudo apt install espeak`

3. **FASE 5** - Configurar Google OAuth para:
   - calendar
   - sheets

---

*Profundización completada - Pendiente de validación en LOCAL*