---
name: git-commit
description: "Perform Git operations: commit changes, push to remote, create branches, and manage repositories. Use when the user asks to save changes, deploy code, or manage version control."
version: 1.0.0
category: code-dev
tier: basic
requires:
  - tool: bash
---

# git-commit

Manage Git version control: commit, push, branch, and more.

## Instructions

### Common operations:

**Commit changes:**
```bash
git add -A
git commit -m "feat: add new feature"
```

**Push to remote:**
```bash
git push origin main
```

**Create branch:**
```bash
git checkout -b feature/new-feature
```

**View status:**
```bash
git status
git log --oneline -5
```

### Commit message convention:
- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation
- `chore:` — Maintenance
- `refactor:` — Code refactoring

## Usage Examples

### Example 1: Quick commit
**User**: "Guarda los cambios con el mensaje 'actualización de skills'"
**Response**: 📦 Git commit: "docs: actualización de skills" (12 archivos). ¿Push al repositorio?

### Example 2: Deploy
**User**: "Sube los cambios a GitHub"
**Response**: 📦 Push a origin/main: 3 commits, 15 archivos. Deploy completo.

## Error Handling

| Error | Action |
|---|---|
| Not a git repo | Suggest `git init` |
| Merge conflicts | Show conflicts and guide resolution |
| Auth failed | Check SSH key or token |
