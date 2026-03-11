---
name: task-manage
description: "Create, update, and manage task lists and to-do items. Use when the user asks to add a task, check pending items, mark things as done, or organize their work."
version: 1.0.0
category: productivity
tier: basic
requires:
  - tool: bash
  - tool: memory
---

# task-manage

Manage to-do lists and task tracking.

## Instructions

### Step 1: Store tasks as JSON
```json
{
  "tasks": [
    { "id": 1, "title": "Enviar factura", "status": "pending", "priority": "high", "due": "2026-03-11" },
    { "id": 2, "title": "Revisar contrato", "status": "done", "priority": "medium", "due": "2026-03-10" }
  ]
}
```

### Step 2: Support CRUD operations
- **Add**: Create new task with title, priority, due date
- **List**: Show all tasks grouped by status
- **Update**: Mark as done, change priority, update due date
- **Delete**: Remove completed or cancelled tasks

### Step 3: Present tasks
```
📋 Tus tareas (3 pendientes, 2 completadas):

🔴 Alta prioridad
  □ Enviar factura al cliente — vence mañana
  □ Llamar al proveedor — vence hoy ⚠️

🟡 Media prioridad
  □ Revisar propuesta — vence viernes

✅ Completadas hoy
  ☑ Enviar reporte mensual
  ☑ Actualizar inventario
```

## Usage Examples

### Example 1: Add task
**User**: "Agrega tarea: llamar a Pedro mañana, prioridad alta"
**Response**: ✅ Tarea agregada: "Llamar a Pedro" — Prioridad alta, vence: 11 marzo.

### Example 2: Check tasks
**User**: "¿Qué tengo pendiente?"
**Response**: 📋 3 tareas pendientes. 1 vence hoy (⚠️). ¿Quieres los detalles?

## Error Handling

| Error | Action |
|---|---|
| No tasks file | Create empty task list |
| Duplicate task | Warn and ask to confirm |
| Past due date | Flag as overdue |
