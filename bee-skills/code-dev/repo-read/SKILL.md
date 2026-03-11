---
name: repo-read
description: "Read and analyze repository structure, code files, and documentation. Use when the user asks about a project's structure, wants to understand a codebase, or needs file contents from a repository."
version: 1.0.0
category: code-dev
tier: basic
requires:
  - tool: bash
---

# repo-read

Read and analyze codebases and repositories.

## Instructions

### Step 1: Explore the structure
```bash
# Tree view
find . -type f -not -path './node_modules/*' -not -path './.git/*' | head -50

# File count by type
find . -not -path './node_modules/*' -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

### Step 2: Read specific files
```bash
cat path/to/file.ts
```

### Step 3: Analyze and summarize
- Identify the tech stack (package.json, requirements.txt, etc.)
- Map the architecture (entry points, modules, configs)
- Report dependencies and versions
- Identify patterns and conventions

## Usage Examples

### Example 1: Project overview
**User**: "Dame un resumen de este proyecto"
**Response**: 📁 Proyecto: BEE Smart AI
- **Stack**: TypeScript, Node.js
- **Módulos**: 24 archivos TS, 58 skills, 20 automations
- **Dependencias**: better-sqlite3, TypeScript 5.4
- **Configuración**: openclaw.json (301 líneas)

### Example 2: Find specific code
**User**: "¿Dónde se manejan los pagos?"
**Response**: 📁 Archivos relacionados con pagos:
1. `bee-automations/ecommerce/A-19-Payment-Links/` — Generación de links
2. `bee-skills/business/invoice-generate/` — Facturación

## Error Handling

| Error | Action |
|---|---|
| Repo too large | Show top-level structure only |
| Binary files | Skip, report as binary |
| Permission denied | Report restricted files |
