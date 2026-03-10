# Changelog

All notable changes to BEE Smart AI will be documented in this file.

## [2.1.0] - 2026-03-10

### 🔀 Fusion with Turnkey v6

**Integrated real content from turnkey-v6 deployment system:**

- **50 real skills** with intents, templated responses, and API mappings (`config/skills-bundles.json`)
- **11 LLM models** from Ollama Cloud (GLM-5, Kimi K2.5, DeepSeek V3, Qwen3, etc.)
- **4 specialized agents** — main, thinking (DeepSeek), vision (Qwen3-VL), coding (Qwen3-Coder)
- **32KB email templates** with dynamic variables (`config/email-templates.json`)
- **17+ deployment scripts** for pre-flight, user setup, gateway install, identity fleet, bot config, activation (`installer/phases/`)
- **5 skill documentation files** — detailed skill bundles, habilidades profundas, second brain (`docs/`)
- **Channel policies** — WhatsApp pairing, Telegram streaming, Discord allowlist
- **Internal hooks** — boot-md, session-memory, command-logger
- **Business-type context mapping** — consultoria, ecommerce, agencia, inmobiliaria, etc.
- **Gateway** — TLS auto-generation, control UI, deny dangerous commands

### 🔒 Security Fixes (v2.0.1)

- `.gitignore` — vaults/, .env, SQLite excluded from git
- SQL injection prevention — whitelist for `orderBy`, column validation, LIKE escaping
- Auth middleware — Bearer token on all 11 Provider Manager endpoints
- `crypto.randomBytes()` replaces insecure `Math.random()` tokens
- Vault passphrase min 16 chars + `exportPlain` warning

## [2.0.0] - 2026-03-10

### 🎉 Initial Release — Full Framework

**Repository Structure**
- 129 files, ~294 KB total code
- OpenClaw upstream via git submodules
- 58 skills in 10 categories (stubs with SKILL.md)
- 20 automations in 4 categories (stubs with automation.json)
- Complete config, security, and vault directory structure

**Provider Manager Plugin** (6 modules, ~46KB)
- AES-256-GCM encrypted vault storage (PBKDF2, 100K iterations)
- Auto-rotation on HTTP 429 rate-limit errors
- Fallback chains (e.g., Ollama → OpenAI → Anthropic)
- Health monitoring with auto-fallback after 3 failures
- 11 REST API endpoints
- Tier-gated provider access
- JSONL audit logging with key sanitization

**Unified Context Plugin** (8 modules, ~63KB)
- SQLite database with WAL mode (contacts + messages)
- Contact identity resolution (phone/email/username → contact_id)
- Rich context injection into every LLM prompt
- Operator handoff (agent ↔ operator ↔ hybrid)
- Dual-mode summarizer (LLM-powered + rule-based fallback)
- Background cron for history compression
- 14 REST API endpoints

**BEE CLI** (5 modules, ~61KB)
- 10-step interactive onboarding wizard
- Config generator (produces .env, system-prompt.md, allowlist, theme, etc.)
- Deploy with pre-flight checks and plugin builds
- Key management (list/rotate/add with masking)
- Operator CRUD, allow/block management
- Skill and automation scaffolding commands

**BEE Overlay Engine** (5 modules, ~39KB)
- 7-step boot orchestrator (zero-config awakening)
- Branding engine (CSS vars, channel messages, tone)
- Tier enforcement ($25/$40/$100 plan gates)
- Automation scheduler with cron and tier limits
- System prompt builder (assembles from all sources)

**Security**
- RBAC with 4 roles (admin, manager, operator, viewer)
- Allowlist/blocklist per channel
- Rate limiting per tier
- Encrypted vault for API keys
- Audit logging for all management operations
