# 🐝 BEE Smart AI v2.0.0

**Agente de IA Autónomo para Negocios** — Basado en [OpenClaw](https://github.com/openclaw-ai/openclaw)

BEE Smart AI es un fork comercial de OpenClaw que transforma un agente de IA genérico en un **empleado digital listo para usar**. El agente "despierta" con memoria completa del negocio, 58 skills activas, 20 automatizaciones y canales de comunicación conectados.

---

## ⚡ Quick Start

```bash
# 1. Clonar con submodules
git clone --recurse-submodules https://github.com/your-org/bee-smart-ai.git
cd bee-smart-ai

# 2. Instalar CLI
cd bee-overlay/cli && npm install && npm run build && cd ../..
npm link bee-overlay/cli  # Hace 'bee' disponible globalmente

# 3. Onboarding (wizard de 10 pasos → genera todos los configs)
bee onboard

# 4. Deploy
bee deploy

# ★ El agente ya está despierto y funcionando ★
```

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────┐
│               🐝 BEE Overlay Layer               │
│   Branding │ Onboarding │ Tiers │ BEE CLI        │
│   Boot Orchestrator │ Prompt Builder │ Scheduler  │
├──────────────────────────────────────────────────┤
│               🔌 BEE Plugins                     │
│   Provider Manager (6 mod) │ Unified Context (8)  │
├──────────────────────────────────────────────────┤
│               📦 OpenClaw Core (upstream)         │
│   Gateway │ Agents │ Channels │ Tools │ Skills    │
└──────────────────────────────────────────────────┘
```

### Componentes Principales

| Componente | Módulos | Descripción |
|---|---|---|
| **Provider Manager** | 6 (~46KB) | Rotación de API keys, fallback chains, vault encriptado AES-256-GCM, health monitoring |
| **Unified Context** | 8 (~63KB) | Memoria cross-channel SQLite, resolución de contactos, handoff operador, summarizer con LLM |
| **BEE CLI** | 5 (~61KB) | Wizard de 10 pasos, deploy, keys, operadores, scaffolding |
| **BEE Overlay** | 5 (~39KB) | Boot orchestrator, branding, tier enforcement, scheduler, prompt builder |

---

## 📁 Estructura del Proyecto

```
bee-smart-ai/
├── openclaw/                    ← Git submodule (NO MODIFICAR)
│
├── config/                      ← Configuración del agente
│   ├── openclaw.json            ← Config principal del gateway
│   ├── system-prompt.md         ← Template del system prompt
│   └── .env.template            ← Template de credenciales
│
├── security/                    ← Control de acceso
│   ├── allowlist.json           ← Números/usuarios permitidos
│   ├── blocklist.json           ← Contactos bloqueados
│   ├── operator-roles.json      ← RBAC (admin/manager/operator/viewer)
│   └── rate-limits.json         ← Límites por tier
│
├── bee-plugins/                 ← Plugins nativos
│   ├── provider-manager/        ← Gestión de providers y API keys
│   │   └── src/
│   │       ├── index.ts         ← Orquestador central
│   │       ├── types.ts         ← Definiciones de tipos
│   │       ├── vault.ts         ← Vault AES-256-GCM
│   │       ├── audit.ts         ← Logger JSONL
│   │       ├── health.ts        ← Health checks periódicos
│   │       └── api.ts           ← 11 endpoints REST
│   └── unified-context/         ← Memoria cross-channel
│       └── src/
│           ├── index.ts         ← Orquestador central
│           ├── types.ts         ← Definiciones de tipos
│           ├── database.ts      ← SQLite WAL mode
│           ├── resolver.ts      ← Resolución de identidad
│           ├── injector.ts      ← Inyección de contexto al LLM
│           ├── handoff.ts       ← Transición agent ↔ operator
│           ├── summarizer.ts    ← Compresión con LLM/reglas
│           └── api.ts           ← 14 endpoints REST
│
├── bee-overlay/                 ← Capa de personalización BEE
│   ├── cli/                     ← BEE CLI
│   │   ├── bee-cli.ts           ← Entry point
│   │   └── src/
│   │       ├── ui.ts            ← ANSI colors, prompts, spinner
│   │       ├── onboarding.ts    ← Wizard de 10 pasos
│   │       ├── config-generator.ts ← Genera .env, prompt, configs
│   │       └── commands.ts      ← Deploy, keys, allow, operator, test
│   ├── engine/                  ← Motor del overlay
│   │   ├── boot.ts              ← Zero-config awakening (7 pasos)
│   │   ├── branding.ts          ← CSS vars, mensajes por canal
│   │   ├── tier-enforcer.ts     ← Gates por plan $25/$40/$100
│   │   ├── scheduler.ts         ← Cron de automatizaciones
│   │   └── prompt-builder.ts    ← Ensamblador de system prompt
│   ├── branding/theme.json      ← Tema del cliente
│   ├── tiers/tier-config.json   ← Definición de planes
│   └── onboarding/              ← Wizard configs
│       ├── form-steps.json      ← 10 pasos del wizard
│       └── context-mapping.json ← Mapeo negocio → automaciones
│
├── bee-skills/                  ← 58 skills en 10 categorías
│   ├── 01-communication/        ← WhatsApp, Telegram, SMS, etc.
│   ├── 02-multimedia/           ← Audio, imagen, video
│   ├── 03-documents/            ← PDF, Excel, Google Docs
│   ├── 04-web-automation/       ← Web scraping, WordPress
│   ├── 05-intelligence/         ← Sentiment, translation, QA
│   ├── 06-business/             ← Calendar, CRM, invoicing
│   ├── 07-email-marketing/      ← Campaigns, newsletters
│   ├── 08-code/                 ← Code gen, deploy, git
│   ├── 09-productivity/         ← Tasks, reminders, notes
│   └── 10-location/             ← Maps, directions, geofencing
│
├── bee-automations/             ← 20 automatizaciones
│   ├── marketing/               ← Social media, promos
│   ├── web/                     ← SEO, blog, analytics
│   ├── operations/              ← Daily reports, backup
│   └── e-commerce/              ← Inventory, orders
│
├── vaults/                      ← Credenciales encriptadas (gitignored)
├── installer/                   ← Scripts de despliegue
│   └── turnkey-deploy.sh
└── scripts/                     ← Scripts de utilidad
```

---

## 🐝 BEE CLI — Comandos

### Core
```bash
bee onboard              # Wizard interactivo de 10 pasos
bee deploy               # Deploy con pre-flight checks
bee update               # Actualiza OpenClaw upstream
bee status               # Estado del agente (skills, canales, providers)
bee test                 # Suite de tests de integridad
```

### Gestión de API Keys
```bash
bee keys list            # Lista keys con masking
bee keys rotate <prov>   # Rota key activa
bee keys add <prov> <k>  # Agrega key al pool
bee provider list        # Lista providers
bee provider swap <t> <p># Cambia provider por tipo
```

### Seguridad
```bash
bee allow                # Muestra allowlist
bee allow +521234567890  # Agrega a allowlist (auto-detecta canal)
bee block @spammer       # Bloquea contacto
bee operator list        # Lista operadores
bee operator add <n> <r> # Agrega operador con rol
bee operator remove <n>  # Remueve operador
```

### Scaffolding
```bash
bee add-skill <name> [category]       # Crea nuevo skill desde template
bee add-automation <name> [category]  # Crea nueva automatización
```

---

## 🔌 Provider Manager

El Provider Manager gestiona todas las API keys y providers del sistema.

### Características
- **Auto-rotación** de keys en errores HTTP 429
- **Fallback chains**: Ollama Cloud → OpenAI → Anthropic
- **Vault encriptado** con AES-256-GCM + PBKDF2 (100K iteraciones)
- **Health monitoring** con auto-fallback después de 3 fallos
- **Tier gates**: providers bloqueados por plan ($25/$40/$100)
- **Audit trail** con keys automáticamente enmascaradas en logs

### API Endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/providers` | Lista todos los providers |
| GET | `/api/providers/:name` | Detalle de un provider |
| POST | `/api/providers` | Agrega provider |
| DELETE | `/api/providers/:name` | Elimina provider |
| PUT | `/api/providers/:name/toggle` | Habilita/deshabilita |
| POST | `/api/providers/:name/rotate` | Rota key activa |
| POST | `/api/providers/:name/keys` | Agrega key |
| DELETE | `/api/providers/:name/keys/:idx` | Elimina key |
| POST | `/api/providers/swap` | Intercambia providers |
| GET | `/api/providers/health` | Health de todos los providers |
| GET | `/api/providers/audit` | Log de auditoría |

---

## 👤 Unified Context — Memoria Cross-Channel

El Unified Context asegura que el agente **nunca pierde contexto**, sin importar desde qué canal se comunique el cliente.

### Flujo
```
📱 WhatsApp ─┐
✈️ Telegram ──┤──→ Contact Resolver ──→ SQLite DB ──→ Context Injector ──→ LLM
💬 Discord ──┤     (phone/email/user     (messages    (markdown block
📧 Email ────┘      → contact_id)         + context)   en cada prompt)
```

### Características
- **Resolución de identidad**: phone/email/username → único `contact_id`
- **Zero context loss**: Cada mensaje de cualquier canal se almacena en SQLite
- **Inyección rica**: Bloque markdown con historial, tags, tema, resumen se inyecta al prompt
- **Handoff operador**: agent → operator → hybrid con resumen formateado
- **Summarizer dual**: LLM-powered o fallback rule-based con detección de intenciones
- **Background cron**: Compresión automática de historial viejo

### API Endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/contacts` | Lista contactos con paginación |
| GET | `/api/contacts/search` | Busca por nombre/teléfono |
| GET | `/api/contacts/:id` | Record completo del contacto |
| GET | `/api/contacts/:id/context` | Inyección de contexto |
| GET | `/api/contacts/:id/messages` | Historial de mensajes |
| POST | `/api/contacts/:id/messages` | Agrega mensaje |
| POST | `/api/contacts/resolve` | Resuelve identifier → contact_id |
| POST | `/api/contacts/:id/handoff` | Inicia handoff a operador |
| DELETE | `/api/contacts/:id/handoff` | Finaliza handoff |
| GET | `/api/contacts/:id/handoff` | Estado del handoff |
| PUT | `/api/contacts/:id/tags` | Actualiza tags |
| PUT | `/api/contacts/:id/topic` | Actualiza tema |
| POST | `/api/contacts/summarize` | Ejecuta summarización |
| GET | `/api/contacts/search/messages` | Busca en historial |

---

## 💰 Planes y Tiers

| Feature | Basic ($25) | Pro ($40) | Max ($100) |
|---|---|---|---|
| Skills | 58 | 58 | 58 |
| LLM | Ollama Cloud | Ollama + OpenAI | Multi-provider |
| Multimedia | ❌ | ✅ (Deepgram, SD) | ✅ (Todo) |
| Google APIs | ❌ | ✅ | ✅ |
| Automaciones | 3 | 10 | 20 |
| Rate limit | Moderate | Generous | Unlimited |
| Infra | Shared | Dedicated | Premium |

---

## 🔒 Seguridad

- **Vault encriptado**: API keys almacenadas con AES-256-GCM
- **RBAC**: 4 roles (admin, manager, operator, viewer)
- **Allowlist/Blocklist**: Control fino por canal
- **Rate limiting**: Por tier y por contacto
- **Audit log**: Cada operación de gestión registrada en JSONL
- **Secrets en `.env`**: Nunca en el repo (gitignored)

---

## 🔄 Actualizar OpenClaw

```bash
bee update
# Ejecuta: git submodule update --remote openclaw + reinstala deps
```

Las actualizaciones de OpenClaw core no afectan la capa BEE ya que están en directorios separados.

---

## 🚀 Boot Sequence (Zero-Config Awakening)

Cuando ejecutas `bee deploy`, el boot orchestrator ejecuta 7 pasos:

```
[1/7] Validate config     → Verifica .env, openclaw.json, system-prompt.md
[2/7] Load branding       → Aplica theme.json (colores, tono, nombre)
[3/7] Init tier enforcer  → Activa gates por plan
[4/7] Build system prompt  → Ensambla: template + tone + 58 skills + automations + tier
[5/7] Scan skills          → Carga todas las skills del directorio
[6/7] Start automations    → Activa cron jobs dentro del límite del tier
[7/7] Detect channels      → Lee canales habilitados de openclaw.json
```

Después del boot, el agente está **completamente despierto** con conocimiento del negocio, habilidades cargadas, y canales conectados.

---

## 📋 Skills (58)

| Categoría | Cant. | Ejemplos |
|---|---|---|
| Communication | 8 | WhatsApp, Telegram, Discord, SMS |
| Multimedia | 6 | Text-to-Speech, Image Generation, Video |
| Documents | 5 | PDF, Excel, Google Docs, Slides |
| Web Automation | 8 | Scraping, WordPress, SEO, Social Media |
| Intelligence | 5 | Sentiment, Translation, QA, Data Analysis |
| Business | 7 | Calendar, CRM, Invoicing, Payments |
| Email Marketing | 4 | Campaigns, Newsletters, Templates |
| Code | 5 | Code Gen, Deploy, Git, Debug |
| Productivity | 6 | Tasks, Reminders, Notes, Templates |
| Location | 4 | Maps, Directions, Geofencing |

---

## 🤖 Automatizaciones (20)

| Categoría | Cant. | Ejemplos |
|---|---|---|
| Marketing | 5 | Social media posts, promos, lead nurture |
| Web | 5 | SEO audits, blog automation, analytics |
| Operations | 5 | Daily reports, backups, health checks |
| E-commerce | 5 | Inventory alerts, order tracking, reviews |

---

## 🛠️ Desarrollo

```bash
# Build de plugins
cd bee-plugins/provider-manager && npm install && npm run build
cd bee-plugins/unified-context && npm install && npm run build

# Build de CLI
cd bee-overlay/cli && npm install && npm run build

# Watch mode (desarrollo)
cd bee-plugins/provider-manager && npm run dev
```

---

## Licencia

MIT (fork de OpenClaw, MIT License)
