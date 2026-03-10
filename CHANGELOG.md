# Changelog

All notable changes to BEE Smart AI will be documented in this file.

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
