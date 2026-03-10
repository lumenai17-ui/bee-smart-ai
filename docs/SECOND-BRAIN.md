# SECOND BRAIN - Sistema de Memoria Persistente

## Versión: 6.0.0
## Adaptado de LOCAL para TURNKEY v6

---

## 🧠 QUÉ ES SECOND BRAIN

Un **Second Brain** es un sistema de memoria persistente que permite al agente:

1. **Capturar** información de sesiones
2. **Organizar** por categorías y relevancia
3. **Destilar** lo esencial (consolidación)
4. **Recuperar** cuando se necesita

A diferencia de RAG tradicional, el Second Brain **evoluciona** con cada interacción.

---

## 📁 ESTRUCTURA DE DIRECTORIOS

```
~/.openclaw/workspace/second-brain/
│
├── 01_CAPTURE/           # Input sin procesar
│   ├── inbox.md         # Entrada rápida
│   ├── quick-notes.md   # Notas rápidas
│   └── voice-notes/     # Transcripciones de voz
│
├── 02_PROJECTS/          # Proyectos activos
│   ├── {project-id}/    # Un directorio por proyecto
│   │   ├── notes.md     # Notas del proyecto
│   │   ├── tasks.md     # Tareas
│   │   └── assets/      # Archivos relacionados
│   └── _index.md        # Índice de proyectos
│
├── 03_AREAS/            # Responsabilidades continuas
│   ├── health/          # Salud
│   ├── finance/         # Finanzas
│   ├── relationships/   # Relaciones
│   ├── work/            # Trabajo
│   └── learning/        # Aprendizaje
│
├── 04_RESOURCES/        # Conocimiento potencial
│   ├── articles/        # Artículos interesantes
│   ├── books/           # Notas de libros
│   ├── references/      # Referencias
│   └── tutorials/       # Tutoriales
│
├── 05_ARCHIVE/          # Completados
│   ├── completed-projects/
│   └── old-notes/
│
├── ZETTL/               # Sistema Zettelkasten
│   ├── {id}.md         # Notas atómicas
│   └── _index.md       # Índice de conexiones
│
├── MEMORY.md            # Consolidación principal
├── config.yaml          # Configuración
└── second-brain.db      # Base de datos SQLite
```

---

## 🔄 FLUJO DE INFORMACIÓN

```
CAPTURA → PROCESO → ORGANIZA → CONSOLIDA → RECUPERA

1. CAPTURA: Usuario dice algo importante
   └─→ Guardar en 01_CAPTURE/inbox.md

2. PROCESO: Agente extrae lo relevante
   └─→ Crear nota en ZETTL/

3. ORGANIZA: Clasificar por tipo
   └─→ Mover a PROJECTS/ o AREAS/ o RESOURCES/

4. CONSOLIDA: Fusionar en MEMORY.md
   └─→ Actualizar conocimiento central

5. RECUPERA: Cuando se necesita
   └─→ Buscar en second-brain.db
```

---

## 📊 TIPOS DE MEMORIA

| Tipo | Función | Ubicación |
|------|---------|-----------|
| **Working Memory** | Contexto activo | Memoria de sesión |
| **Semantic Memory** | Hechos y conocimiento | RESOURCES/ |
| **Episodic Memory** | Eventos y experiencias | AREAS/ |
| **Procedural Memory** | Workflows y procesos | ZETTL/ |

---

## ⚙️ CONFIGURACIÓN (config.yaml)

```yaml
second_brain:
  version: "6.0.0"
  
  # Scoring de importancia
  scoring:
    emotion_weight: 0.3      # Si fue emocional para el usuario
    reference_weight: 0.25   # Si fue referenciado después
    recency_weight: 0.2      # Qué tan reciente
    task_weight: 0.15        # Si relacionado con tarea
    connection_weight: 0.1   # Número de conexiones
  
  # Consolidación
  consolidation:
    frequency: "1h"          # Cada hora
    min_score: 5             # Score mínimo para consolidar
    max_age: "30d"           # Edad máxima para consolidar
    max_items: 100           # Máximo items por consolidación
  
  # Decay (decaimiento)
  decay:
    enabled: true
    rate: 0.1               # 10% por semana
    min_score: 1            # Score mínimo antes de eliminar
  
  # Búsqueda
  search:
    hybrid: true            # FTS + Semántica
    max_results: 10
    min_similarity: 0.5
  
  # Integración
  integration:
    knowledge_sync: true    # Sincronizar con KNOWLEDGE
    heart_sync: true        # Conectar con HEART
    dopamine_sync: true     # Conectar con DOPAMINE
```

---

## 🔌 API PRINCIPAL

```python
from second_brain import SecondBrain

# Inicializar
brain = SecondBrain()

# Crear nota
note = brain.create_note(
    title="Idea importante",
    content="El usuario quiere...",
    tags=["idea", "importante"],
    emotional_context={"emotion": "curiosity", "intensity": 0.8}
)

# Buscar
results = brain.search("idea importante")

# Conectar notas
brain.connect_notes(note1.id, note2.id, "relates", 0.7)

# Obtener nivel de dopamina
dopamine = brain.get_dopamine_level()

# Consolidar
brain.consolidate()

# Cerrar
brain.shutdown()
```

---

## 📈 MÉTRICAS

| Métrica | Descripción | Target |
|---------|-------------|--------|
| **Recall Rate** | % de búsquedas exitosas | >80% |
| **Consolidation Efficiency** | % consolidado vs capturado | >70% |
| **Connection Density** | Conexiones por nota | >2 |
| **Decay Rate** | Notas eliminadas por decay | <10%/mes |

---

## 🔗 INTEGRACIÓN CON HEART/DOPAMINE

### Memoria Emocional

Cada nota puede tener contexto emocional:

```yaml
emotional_context:
  emotion: "curiosity"     # happy, sad, angry, fear, surprise, curiosity
  intensity: 0.8           # 0.0 - 1.0
  triggers: ["idea", "innovación"]
```

### Preferencias Aprendidas

El Second Brain aprende preferencias del usuario:

```yaml
learned_preferences:
  communication_style: "direct"
  preferred_topics: ["tech", "business"]
  response_length: "concise"
  timezone: "America/Panama"
  language: "es"
```

### DOPAMINE Sync

- Las tareas completadas aumentan DOPAMINE
- Los aprendizajes nuevos aumentan DOPAMINE
- Los errores disminuyen DOPAMINE

---

## 🗄️ BASE DE DATOS (SQLite)

```sql
-- Tabla principal de notas
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    title TEXT,
    content TEXT,
    type TEXT,  -- note, project, area, resource
    tags TEXT,  -- JSON array
    score REAL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    emotional_context TEXT,  -- JSON
    metadata TEXT  -- JSON
);

-- Índice para búsqueda
CREATE VIRTUAL TABLE notes_fts USING fts5(
    title, content, tags
);

-- Conexiones entre notas
CREATE TABLE connections (
    id TEXT PRIMARY KEY,
    from_note TEXT,
    to_note TEXT,
    type TEXT,  -- relates, depends, references
    weight REAL,
    created_at TIMESTAMP
);

-- Historial de consolidación
CREATE TABLE consolidation_history (
    id TEXT PRIMARY KEY,
    timestamp TIMESTAMP,
    notes_processed INTEGER,
    notes_consolidated INTEGER
);
```

---

## 📝 ARCHIVOS DE REFERENCIA

| Archivo | Propósito |
|---------|-----------|
| `MEMORY.md` | Consolidación principal |
| `_index.md` | Índice por directorio |
| `config.yaml` | Configuración del sistema |
| `second-brain.db` | Base de datos SQLite |

---

## 🚀 IMPLEMENTACIÓN EN TURNKEY v6

### Para cada agente:

1. **Inicializar Second Brain** al crear el agente
2. **Capturar** información relevante de cada sesión
3. **Procesar** y organizar automáticamente
4. **Consolidar** cada hora
5. **Buscar** cuando necesite contexto

### Estructura por agente:

```
~/.openclaw/workspace/second-brain/
├── {agent-name}/           # Un directorio por agente
│   ├── 01_CAPTURE/
│   ├── 02_PROJECTS/
│   ├── 03_AREAS/
│   ├── 04_RESOURCES/
│   ├── 05_ARCHIVE/
│   ├── ZETTL/
│   ├── MEMORY.md
│   └── second-brain.db
```

---

*Second Brain copiado de LOCAL y adaptado para TURNKEY v6 - FASE 4 ÁREA 4*