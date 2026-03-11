---
name: code-execute
description: "Execute code snippets in Node.js, Python, or Bash. Use when the user needs to run calculations, scripts, data processing, or any computational task. Runs in a sandboxed environment."
version: 1.0.0
category: code-dev
tier: basic
requires:
  - tool: bash
---

# code-execute

Execute code in Node.js, Python, or Bash.

## Instructions

### Step 1: Determine language
- **Node.js**: `node -e "..."` or `node script.js`
- **Python**: `python3 -c "..."` or `python3 script.py`
- **Bash**: Direct shell commands

### Step 2: Execute safely
```bash
# Node.js
node -e "console.log(2 + 2)"

# Python
python3 -c "print(2 + 2)"

# Bash
echo $((2 + 2))
```

### Step 3: Present output
```
💻 Código ejecutado:
⏱️ Tiempo: 45ms
📤 Output:
4

✅ Completado sin errores.
```

### Security rules
- Never execute code that deletes system files
- Never execute code that accesses credentials outside of .env
- Timeout: 30 seconds max
- Memory: 256MB max

## Usage Examples

### Example 1: Math calculation
**User**: "Calcula el 16% de IVA de $15,800"
**Response**: 💻 $15,800 × 16% = **$2,528.00** IVA. Total: **$18,328.00**

### Example 2: Data processing
**User**: "Ordena estos números de mayor a menor: 45, 12, 78, 23, 56"
**Response**: 💻 Resultado: 78, 56, 45, 23, 12

## Error Handling

| Error | Action |
|---|---|
| Syntax error | Show error and suggest fix |
| Timeout (>30s) | Kill process and inform user |
| Module not found | Suggest installing with npm/pip |
