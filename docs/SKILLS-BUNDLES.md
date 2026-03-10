# Skills Bundles - TURNKEY v6

**Versión:** 1.0.0
**Fecha:** 2026-03-05
**Área:** FASE 4 - ÁREA 6 - SKILLS BUNDLES

---

## 📋 RESUMEN

| Concepto | Definición |
|-----------|------------|
| **Skills Bundles** | Conjuntos preconfigurados de habilidades específicas por tipo de negocio |
| **Habilidades Natas** | 14 habilidades básicas que TODO agente debe tener |
| **Habilidades CORE** | 25 habilidades que funcionan SIEMPRE (proveemos API) |
| **Habilidades OPCIONALES** | 14 habilidades que requieren API key del cliente |

---

## 1️⃣ QUÉ SON LOS SKILLS BUNDLES

### Definición

Un **Skill Bundle** es un paquete preconfigurado de capacidades específicas diseñadas para un tipo de negocio particular. Cada bundle incluye:

1. **Skills específicas del negocio** - Funcionalidades que el negocio necesita
2. **Intents predefinidos** - Frases que activan cada skill
3. **Responses personalizadas** - Respuestas adaptadas al negocio
4. **Configuración de flujos** - Workflows automatizados

### Estructura de un Bundle

```json
{
  "bundle": "restaurante",
  "skills": ["menu", "reservas", "pedidos", "horarios", "delivery"],
  "custom_prompts": {
    "menu": "Puedo leer el menú y responder preguntas sobre platos...",
    "reservas": "Puedo gestionar reservaciones para el restaurante...",
    "pedidos": "Puedo tomar pedidos y enviarlos a cocina...",
    "horarios": "Puedo informar sobre horarios de atención..."
  },
  "intents": {
    "menu": ["¿quétienen?", "menú", "carta", "platos", "comida"],
    "reservas": ["reservar", "mesa", "reservación", "disponibilidad"],
    "pedidos": ["pedir", "ordenar", "orden", "delivery", "llevar"]
  }
}
```

---

## 2️⃣ DIFERENCIA: SKILLS BUNDLES vs HABILIDADES NATAS

### Comparación Detallada

| Aspecto | Skills Bundles | Habilidades Natas |
|---------|----------------|-------------------|
| **Propósito** | Capacidades específicas de negocio | Capacidades básicas comunes |
| **Configuración** | Pre-configurado por tipo de negocio | Siempre presentes |
| **Personalización** | Custom prompts + intents | Genéricas, sin personalización |
| **Dependencias** | Requieren skills base | Independientes |
| **Cantidad** | Variables según negocio | 14 fijas, obligatorias |
| **Ejemplos** | menu_parse, reservations, orders | email_send, pdf_generate |

### Habilidades Natas (14 Obligatorias)

| # | Habilidad | Función | Estado |
|---|-----------|---------|--------|
| 1 | email_send | Enviar emails | ✅ Siempre |
| 2 | email_read | Leer emails | ✅ Siempre |
| 3 | voice_send | Enviar voice notes | 🔧 API key |
| 4 | voice_receive | Recibir voice notes | 🔧 API key |
| 5 | audio_process | Procesar audio | 🔧 API key |
| 6 | image_generate | Crear imágenes | 🔧 API key |
| 7 | image_receive | Analizar imágenes | ✅ Siempre |
| 8 | pdf_generate | Crear PDFs | ✅ Siempre |
| 9 | pdf_read | Leer PDFs | ✅ Siempre |
| 10 | video_process | Procesar video | ✅ Siempre |
| 11 | location | Ubicación/maps | 🔧 API key |
| 12 | calendar | Google Calendar | 🔧 OAuth |
| 13 | sheets | Google Sheets | 🔧 OAuth |
| 14 | translate | Traducción | 🔧 API key |

### Habilidades CORE (25 que SIEMPRE funcionan)

Son habilidades que nosotros proveemos con nuestras APIs compartidas:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HABILIDADES CORE (25)                             │
│                  Funcionan SIEMPRE - Proveemos API                   │
├─────────────────────────────────────────────────────────────────────┤
│ DOCUMENTOS (7)                                                      │
│   • pdf_generate    • pdf_read      • pdf_edit                       │
│   • doc_generate    • excel_generate • excel_read                    │
│   • presentation_create                                              │
├─────────────────────────────────────────────────────────────────────┤
│ EMAIL (2)                                                            │
│   • email_send     • email_read                                      │
├─────────────────────────────────────────────────────────────────────┤
│ VIDEO (2)                                                            │
│   • video_process  • video_edit                                      │
├─────────────────────────────────────────────────────────────────────┤
│ AUTOMATIZACIÓN (5)                                                   │
│   • browser         • scraping      • forms                          │
│   • cron            • webhook                                        │
├─────────────────────────────────────────────────────────────────────┤
│ COMUNICACIÓN (4)                                                     │
│   • sms_send        • whatsapp_send • telegram_send                  │
│   • discord_send                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ NEGOCIO (3)                                                          │
│   • invoice_generate • report_generate • qrcode_generate             │
├─────────────────────────────────────────────────────────────────────┤
│ PRODUCTIVIDAD (4)                                                    │
│   • summarize       • extract_data   • sentiment                     │
│   • ocr                                                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3️⃣ SKILLS BUNDLES POR TIPO DE NEGOCIO

### 3.1 Bundle: RESTAURANTE

```json
{
  "bundle": "restaurante",
  "version": "1.0.0",
  "skills": [
    {
      "id": "menu_parse",
      "name": "Menú Digital",
      "description": "Mostrar menú, precios, recomendar platos",
      "intents": ["menú", "carta", "platos", "comida", "¿qué tienen?", "precios"],
      "responses": {
        "default": "Nuestro menú incluye: {menu_items}. ¿Te gustaría que te recomiende algo?",
        "price": "{item} cuesta {price}. ¿Deseas agregarlo a tu orden?"
      },
      "requires": ["pdf_read", "extract_data", "summarize"]
    },
    {
      "id": "reservations",
      "name": "Reservaciones",
      "description": "Gestionar reservaciones de mesas",
      "intents": ["reservar", "mesa", "reservación", "disponibilidad", "para cuántos"],
      "responses": {
        "available": "¡Perfecto! Tenemos disponibilidad para {people} personas el {date} a las {time}.",
        "unavailable": "Lo siento, no tenemos disponibilidad para esa fecha. ¿Te gustaría probar otro día?"
      },
      "requires": ["calendar", "forms"]
    },
    {
      "id": "orders",
      "name": "Pedidos",
      "description": "Tomar pedidos y enviar a cocina",
      "intents": ["pedir", "ordenar", "orden", "quiero", "me trae", "para llevar"],
      "responses": {
        "confirm": "Tu orden incluye: {items}. Total: {total}. ¿Confirmas?",
        "sent": "¡Orden confirmada! Tiempo estimado: {estimated_time} minutos."
      },
      "requires": ["forms", "pdf_generate"]
    },
    {
      "id": "hours",
      "name": "Horarios",
      "description": "Informar horarios de atención",
      "intents": ["horarios", "horario", "¿a qué hora?", "¿cuándo abren?", "¿cuándo cierran?"],
      "responses": {
        "default": "Nuestros horarios son: {hours}. ¿Necesitas algo más?"
      },
      "requires": []
    },
    {
      "id": "delivery",
      "name": "Delivery",
      "description": "Gestionar órdenes de delivery",
      "intents": ["delivery", "domicilio", "llevar", "a domicilio", "envío", "dirección"],
      "responses": {
        "zones": "Hacemos delivery a: {zones}. Costo de envío: {delivery_cost}.",
        "eta": "Tiempo estimado de entrega: {eta} minutos."
      },
      "requires": ["location", "forms"]
    },
    {
      "id": "faq",
      "name": "Preguntas Frecuentes",
      "description": "Responder preguntas comunes",
      "intents": ["¿tienen?", "¿aceptan?", "¿puedo?", "estacionamiento", "niños", "mascotas"],
      "requires": ["extract_data"]
    },
    {
      "id": "contact",
      "name": "Contacto",
      "description": "Información de contacto",
      "intents": ["teléfono", "dirección", "ubicación", "contacto", "¿dónde están?"],
      "requires": ["location"]
    }
  ],
  "total_skills": 7,
  "dependencies_natas": ["email_send", "pdf_generate", "calendar", "forms", "location"]
}
```

### 3.2 Bundle: HOTEL

```json
{
  "bundle": "hotel",
  "version": "1.0.0",
  "skills": [
    {
      "id": "reservations",
      "name": "Reservaciones",
      "description": "Gestionar reservaciones de habitaciones",
      "intents": ["reservar", "habitación", "reservación", "disponibilidad", "noches"],
      "responses": {
        "available": "Tenemos disponibilidad para {nights} noches en {room_type}. Precio: {price}/noche.",
        "unavailable": "Lo siento, no tenemos disponibilidad para esas fechas."
      },
      "requires": ["calendar", "forms"]
    },
    {
      "id": "availability",
      "name": "Disponibilidad",
      "description": "Consultar disponibilidad en tiempo real",
      "intents": ["¿hay disponibilidad?", "¿cuánto cuesta?", "¿tienen habitaciones?"],
      "requires": ["calendar"]
    },
    {
      "id": "rooms",
      "name": "Habitaciones",
      "description": "Describir habitaciones y servicios",
      "intents": ["habitaciones", "tipos", "suites", "servicios", "¿qué incluyen?"],
      "responses": {
        "describe": "Nuestras habitaciones {room_type} incluyen: {amenities}.",
        "amenities": "Servicios del hotel: {services_list}."
      },
      "requires": ["pdf_read", "summarize"]
    },
    {
      "id": "faq",
      "name": "Preguntas Frecuentes",
      "description": "Responder preguntas comunes de huéspedes",
      "intents": ["check-in", "check-out", "wifi", "estacionamiento", "desayuno", "piscina"],
      "requires": ["extract_data"]
    },
    {
      "id": "contact",
      "name": "Contacto",
      "description": "Información del hotel",
      "intents": ["teléfono", "dirección", "ubicación", "contacto"],
      "requires": ["location"]
    },
    {
      "id": "hours",
      "name": "Horarios",
      "description": "Horarios de servicios",
      "intents": ["horarios", "¿a qué hora?", "recepción", "spa", "restaurante"],
      "requires": []
    }
  ],
  "total_skills": 6,
  "dependencies_natas": ["email_send", "calendar", "forms", "location", "pdf_generate"]
}
```

### 3.3 Bundle: TIENDA/RETAIL

```json
{
  "bundle": "tienda",
  "version": "1.0.0",
  "skills": [
    {
      "id": "inventory",
      "name": "Inventario",
      "description": "Consultar disponibilidad de productos",
      "intents": ["¿tienen?", "stock", "disponibilidad", "¿hay?"],
      "responses": {
        "available": "Sí, tenemos {product} en stock. Cantidad: {quantity}.",
        "unavailable": "Lo siento, {product} está agotado. ¿Te gustaría que te avisemos cuando vuelva?"
      },
      "requires": ["excel_read", "extract_data"]
    },
    {
      "id": "products",
      "name": "Productos",
      "description": "Buscar y recomendar productos",
      "intents": ["productos", "¿qué tienen?", "catálogo", "buscar", "recomendación"],
      "responses": {
        "search": "Encontré {count} productos: {products_list}.",
        "recommend": "Te recomiendo {product} por {reason}."
      },
      "requires": ["summarize", "sentiment"]
    },
    {
      "id": "orders",
      "name": "Pedidos",
      "description": "Gestionar carrito y checkout",
      "intents": ["pedir", "comprar", "checkout", "carrito", "agregar"],
      "responses": {
        "cart": "Tu carrito tiene {items}. Total: {total}.",
        "checkout": "Pedido confirmado. Número de orden: {order_number}."
      },
      "requires": ["forms", "pdf_generate"]
    },
    {
      "id": "payments",
      "name": "Pagos",
      "description": "Métodos de pago y facturación",
      "intents": ["pagar", "métodos de pago", "tarjeta", "efectivo", "factura"],
      "responses": {
        "methods": "Aceptamos: {payment_methods}.",
        "invoice": "Tu factura está lista. Enviando a {email}."
      },
      "requires": ["invoice_generate", "email_send"]
    },
    {
      "id": "promotions",
      "name": "Promociones",
      "description": "Descuentos y ofertas activas",
      "intents": ["promociones", "descuentos", "ofertas", "cupones"],
      "requires": ["pdf_read"]
    },
    {
      "id": "faq",
      "name": "Preguntas Frecuentes",
      "description": "FAQ de la tienda",
      "intents": ["devoluciones", "garantía", "envíos", " horario"],
      "requires": ["extract_data"]
    },
    {
      "id": "contact",
      "name": "Contacto",
      "description": "Información de contacto",
      "intents": ["teléfono", "dirección", "ubicación", "whatsapp"],
      "requires": ["location"]
    }
  ],
  "total_skills": 7,
  "dependencies_natas": ["email_send", "pdf_generate", "excel_read", "forms", "location"]
}
```

### 3.4 Bundle: SERVICIOS PROFESIONALES

```json
{
  "bundle": "servicios",
  "version": "1.0.0",
  "skills": [
    {
      "id": "appointments",
      "name": "Citas",
      "description": "Agendar y gestionar citas",
      "intents": ["cita", "agendar", "reservar", "consulta", "disponibilidad"],
      "responses": {
        "available": "Tenemos disponibilidad el {date} a las {time}. ¿Confirmas?",
        "confirm": "Cita confirmada para {date} a las {time} con {professional}."
      },
      "requires": ["calendar", "forms"]
    },
    {
      "id": "calendar",
      "name": "Calendario",
      "description": "Consultar disponibilidad del profesional",
      "intents": ["calendario", "horarios", "¿cuándo puedes?", "disponibilidad"],
      "requires": ["calendar"]
    },
    {
      "id": "reminders",
      "name": "Recordatorios",
      "description": "Enviar recordatorios de citas",
      "intents": ["recordar", "recordatorio", "avisame", "no olvides"],
      "responses": {
        "set": "Recordatorio configurado para {date}. Te avisaré {hours_before} horas antes."
      },
      "requires": ["cron", "sms_send", "email_send"]
    },
    {
      "id": "followup",
      "name": "Seguimiento",
      "description": "Seguimiento post-servicio",
      "intents": ["seguimiento", "¿cómo quedó?", "resultado"],
      "requires": ["email_send", "forms"]
    },
    {
      "id": "faq",
      "name": "Preguntas Frecuentes",
      "description": "FAQ del servicio",
      "intents": ["precios", "duración", "proceso", "requisitos"],
      "requires": ["extract_data"]
    },
    {
      "id": "contact",
      "name": "Contacto",
      "description": "Información de contacto",
      "intents": ["teléfono", "email", "ubicación", "whatsapp"],
      "requires": ["location"]
    }
  ],
  "total_skills": 6,
  "dependencies_natas": ["email_send", "calendar", "forms", "cron", "sms_send"]
}
```

### 3.5 Bundle: GENÉRICO

```json
{
  "bundle": "generico",
  "version": "1.0.0",
  "skills": [
    {
      "id": "faq",
      "name": "Preguntas Frecuentes",
      "description": "Responder preguntas frecuentes del negocio",
      "intents": ["¿qué?", "¿cómo?", "¿cuándo?", "¿dónde?", "¿por qué?"],
      "requires": ["extract_data", "pdf_read"]
    },
    {
      "id": "contact",
      "name": "Contacto",
      "description": "Proporcionar información de contacto",
      "intents": ["contacto", "teléfono", "email", "whatsapp", "ubicación", "dirección"],
      "requires": ["location"]
    },
    {
      "id": "hours",
      "name": "Horarios",
      "description": "Informar horarios de atención",
      "intents": ["horarios", "horario", "¿a qué hora?", "¿cuándo abren?", "¿cuándo cierran?"],
      "requires": []
    },
    {
      "id": "location",
      "name": "Ubicación",
      "description": "Mostrar ubicación y mapa",
      "intents": ["ubicación", "¿dónde están?", "dirección", "mapa", "llegar"],
      "requires": ["location"]
    },
    {
      "id": "general",
      "name": "Consultas Generales",
      "description": "Responder consultas generales",
      "intents": ["hola", "buenos días", "información", "ayuda", "necesito"],
      "requires": ["summarize"]
    }
  ],
  "total_skills": 5,
  "dependencies_natas": ["location", "pdf_read", "extract_data"]
}
```

---

## 4️⃣ ORGANIZACIÓN EN OPENCLAW

### Estructura de Archivos

```
~/.openclaw/
├── config/
│   ├── skills-core.json        # 25 habilidades CORE (siempre funcionan)
│   ├── skills-optional.json     # 14 habilidades opcionales (requieren API)
│   ├── skills-bundle.json       # Bundle seleccionado según negocio
│   └── SKILLS.md                # Documentación completa
│
├── knowledge/
│   ├── menu/                    # Menú (para restaurantes)
│   │   └── menu.pdf
│   ├── products/                # Productos (para tiendas)
│   │   └── catalog.xlsx
│   ├── services/                # Servicios (para profesionales)
│   │   └── services.pdf
│   └── faq/                     # FAQ común
│       └── faq.json
│
└── prompts/
    ├── restaurante/
    │   ├── menu_parse.txt
    │   ├── reservations.txt
    │   └── orders.txt
    ├── hotel/
    │   ├── reservations.txt
    │   └── rooms.txt
    ├── tienda/
    │   ├── inventory.txt
    │   └── orders.txt
    ├── servicios/
    │   ├── appointments.txt
    │   └── reminders.txt
    └── generico/
        ├── faq.txt
        └── contact.txt
```

### Configuración en openclaw.json

```json
{
  "skills": {
    "core": {
      "enabled": true,
      "source": "config/skills-core.json",
      "total": 25
    },
    "optional": {
      "enabled": "partial",
      "source": "config/skills-optional.json",
      "configured": ["image_receive", "voice_receive"],
      "pending": ["calendar", "sheets", "location"]
    },
    "bundle": {
      "type": "restaurante",
      "source": "config/skills-bundle.json",
      "skills": ["menu", "reservas", "pedidos", "horarios", "delivery"]
    },
    "nativeSkills": "auto"
  }
}
```

### Flujo de Activación

```
┌─────────────────────────────────────────────────────────────────────┐
│                  FLUJO DE SKILLS BUNDLE                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. SETUP INICIAL                                                    │
│     └── ./setup-skills.sh --agent-name "nombre" --business-type "X" │
│         └── Carga bundle según tipo de negocio                       │
│             └── Carga skills CORE (25)                               │
│                 └── Carga skills OPCIONALES (14)                     │
│                                                                       │
│  2. KNOWLEDGE PROCESSING                                             │
│     └── Carga documentos del negocio                                 │
│         └── Menu (restaurantes)                                      │
│         └── Productos (tiendas)                                      │
│         └── Servicios (profesionales)                                │
│         └── FAQ genérico                                             │
│                                                                       │
│  3. ACTIVACIÓN                                                       │
│     └── Skills habilitadas según configuración                        │
│         └── CORE: Siempre activas                                    │
│         └── OPCIONALES: Activas si hay API key                       │
│         └── BUNDLE: Activas según tipo de negocio                    │
│                                                                       │
│  4. EJECUCIÓN                                                        │
│     └── Usuario pregunta → Intent detection                          │
│         └── Skill seleccionada → Response generada                  │
│             └── Acción ejecutada si aplica                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5️⃣ RESUMEN FINAL

### Tabla Comparativa

| Tipo | Cantidad | Configuración | Ejemplos |
|------|----------|---------------|----------|
| **Habilidades Natas** | 14 | Siempre presentes | email, voice, images, translate |
| **Habilidades CORE** | 25 | Proveemos API | pdf, video, sms, browser |
| **Habilidades OPCIONALES** | 14 | Cliente configura | DALL-E, Suno, DeepL |
| **Skills Bundle** | 5-7/negocio | Por tipo de negocio | menu, reservations, orders |

### Costo de APIs Compartidas

| API | Límite/mes | Costo | Habilidades |
|-----|------------|-------|-------------|
| Resend | 3,000 emails | ~$10 | email_send |
| PDF.co | 5,000 pág | ~$15 | pdf/doc/excel |
| Mathpix | 1,000 pág | ~$10 | pdf_read |
| Mux | 100 videos | ~$20 | video_hosting |
| Twilio | 500 SMS | ~$10 | sms_send |
| Oxylabs | 1,000 req | ~$30 | scraping |
| Gamma | 50 presentaciones | ~$10 | presentation_create |
| **Total** | - | **~$105/mes** | - |

### Diferenciador de Mercado

| Nosotros | Competencia |
|----------|-------------|
| **25+14 = 39 habilidades** | 5-10 básicas |
| **Documentos completos** | Solo texto |
| **Email enviar + recibir** | Solo enviar |
| **Video processing** | No disponible |
| **SMS** | No disponible |
| **Web scraping** | No disponible |
| **Automatización** | Limitada |
| **Bundles por negocio** | No disponible |

---

## 📎 ARCHIVOS RELACIONADOS

| Archivo | Propósito |
|---------|-----------|
| `skills-core.json` | 25 habilidades CORE |
| `skills-optional.json` | 14 habilidades opcionales |
| `skills-bundle.json` | Bundle según tipo de negocio |
| `SKILLS.md` | Documentación de usuario |
| `setup-skills.sh` | Script de configuración |

---

*Documento creado para FASE 4 ÁREA 6 - TURNKEY v6*
*Autor: Sub-agente de análisis*
*Fecha: 2026-03-05*