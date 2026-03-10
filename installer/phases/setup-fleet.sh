#!/bin/bash
#===============================================================================
# FASE 4: IDENTITY FLEET - Setup Fleet
#===============================================================================
# Propósito: Configurar fleet de modelos (13 modelos)
# Uso: ./setup-fleet.sh --agent-name "nombre" [--ollama-key "key"]
# Corregido: 2026-03-06 - Auditoría Multigente
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# CONFIGURACIÓN
#-------------------------------------------------------------------------------

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Directorios
readonly OPENCLAW_DIR="$HOME/.openclaw"
readonly CONFIG_DIR="$OPENCLAW_DIR/config"
readonly DATA_DIR="$OPENCLAW_DIR/data"
readonly SECRETS_DIR="$OPENCLAW_DIR/workspace/secrets"

# Estado
CLEANUP_NEEDED=false
CREATED_FILES=()

#-------------------------------------------------------------------------------
# FUNCIONES
#-------------------------------------------------------------------------------

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup_on_failure() {
    local exit_code=$?
    
    if [[ "$CLEANUP_NEEDED" == "true" && $exit_code -ne 0 ]]; then
        log_error "Falló la configuración. Limpiando archivos parciales..."
        
        for file in "${CREATED_FILES[@]}"; do
            if [[ -f "$file" ]]; then
                rm -f "$file"
                log_warning "Removido: $file"
            fi
        done
        
        rm -f "$CONFIG_DIR/.fleet-status.json" 2>/dev/null || true
    fi
    
    exit $exit_code
}

mark_success() {
    CLEANUP_NEEDED=false
}

usage() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  --agent-name NOMBRE     Nombre del agente (requerido)"
    echo "  --ollama-key KEY        API key de Ollama Cloud"
    echo "  --dry-run               Simular ejecución"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "La API key se busca en este orden:"
    echo "  1. Parámetro --ollama-key"
    echo "  2. Variable de entorno OLLAMA_API_KEY"
    echo "  3. Archivo \$CONFIG_DIR/.ollama-key"
    echo "  4. Archivo \$SECRETS_DIR/API_KEYS.json"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --agent-name 'casamahana'"
    exit 0
}

validate_json() {
    local file="$1"
    if command -v jq &>/dev/null; then
        if ! jq . "$file" > /dev/null 2>&1; then
            log_error "JSON inválido: $file"
            return 1
        fi
    fi
    return 0
}

mask_api_key() {
    local key="$1"
    if [[ -n "$key" && ${#key} -gt 8 ]]; then
        echo "${key:0:4}...${key: -4}"
    else
        echo "****"
    fi
}

#-------------------------------------------------------------------------------
# PARÁMETROS
#-------------------------------------------------------------------------------

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

AGENT_NAME=""
OLLAMA_KEY=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent-name)
            AGENT_NAME="$2"
            shift 2
            ;;
        --ollama-key)
            OLLAMA_KEY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Parámetro desconocido: $1"
            usage
            ;;
    esac
done

# Validar parámetros
if [[ -z "$AGENT_NAME" ]]; then
    log_error "--agent-name es obligatorio"
    usage
fi

# Hacer variables readonly
readonly AGENT_NAME OLLAMA_KEY DRY_RUN

#===============================================================================
# ENCABEZADO
#===============================================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         FASE 4: IDENTITY FLEET - Setup Fleet                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}[MODO DRY-RUN]${NC} Solo simulación"
    echo ""
fi

#===============================================================================
# VALIDAR PREREQUISITOS
#===============================================================================

CLEANUP_NEEDED=true

# Verificar que existe identity
log_info "Verificando prerequisitos..."

if [[ ! -f "$CONFIG_DIR/.identity-status.json" ]]; then
    log_error "Identity no configurado"
    log_warning "Ejecutar primero: ./setup-identity.sh"
    exit 1
fi

log_success "Identity verificado"

#===============================================================================
# BUSCAR API KEY
#===============================================================================

log_info "[1/4] Buscando API key de Ollama..."

# Buscar API key en varios lugares (en orden de prioridad)
if [[ -z "$OLLAMA_KEY" ]]; then
    # 1. Variable de entorno
    OLLAMA_KEY="${OLLAMA_API_KEY:-}"
    
    # 2. Archivo .ollama-key
    if [[ -z "$OLLAMA_KEY" ]] && [[ -f "$CONFIG_DIR/.ollama-key" ]]; then
        OLLAMA_KEY=$(cat "$CONFIG_DIR/.ollama-key" 2>/dev/null || true)
    fi
    
    # 3. Secrets API_KEYS.json
    if [[ -z "$OLLAMA_KEY" ]] && [[ -f "$SECRETS_DIR/API_KEYS.json" ]]; then
        OLLAMA_KEY=$(jq -r '.ollamacloud.apiKey // empty' "$SECRETS_DIR/API_KEYS.json" 2>/dev/null || true)
    fi
    
    # 4. Config openclaw.json
    if [[ -z "$OLLAMA_KEY" ]] && [[ -f "$CONFIG_DIR/openclaw.json" ]]; then
        OLLAMA_KEY=$(jq -r '.models.providers.ollamacloud.apiKey // empty' "$CONFIG_DIR/openclaw.json" 2>/dev/null || true)
    fi
fi

if [[ -z "$OLLAMA_KEY" ]]; then
    log_error "No se encontró API key de Ollama Cloud"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  1. Variable de entorno: export OLLAMA_API_KEY='tu-key'"
    echo "  2. Parámetro: --ollama-key 'tu-key'"
    echo "  3. Archivo: echo 'tu-key' > $CONFIG_DIR/.ollama-key"
    echo "  4. Secrets: configurar en $SECRETS_DIR/API_KEYS.json"
    exit 1
fi

# Validar formato de API key (debe empezar con os_ o sk-)
if [[ ! "$OLLAMA_KEY" =~ ^(os_|sk-) ]]; then
    log_warning "API key no tiene formato esperado (os_* o sk-*)"
fi

log_success "API key encontrada: $(mask_api_key "$OLLAMA_KEY")"

#===============================================================================
# CREAR FLEET.JSON
#===============================================================================

log_info "[2/4] Configurando Fleet de modelos..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/fleet.json"
else
    cat > "$CONFIG_DIR/fleet.json" << 'FLEET_EOF'
{
  "version": "2.0.0",
  "description": "Fleet de modelos LUMEN v2 - 13 modelos",
  "providers": {
    "ollamacloud": {
      "baseUrl": "https://ollama.com/v1",
      "apiKey": "OLLAMA_API_KEY_PLACEHOLDER",
      "api": "openai-completions"
    }
  },
  "models": [
    {
      "id": "glm-5",
      "name": "GLM-5",
      "provider": "ollamacloud",
      "role": "primary",
      "reasoning": true,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Modelo principal - rápido, general, con razonamiento"
    },
    {
      "id": "kimi-k2.5",
      "name": "Kimi K2.5",
      "provider": "ollamacloud",
      "role": "fallback",
      "reasoning": false,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Alternativo - más capacidad de contexto"
    },
    {
      "id": "kimi-k2-thinking",
      "name": "Kimi K2 Thinking",
      "provider": "ollamacloud",
      "role": "thinking",
      "reasoning": true,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Thinking - para razonamiento profundo"
    },
    {
      "id": "deepseek-v3.1:671b",
      "name": "DeepSeek V3.1 671B",
      "provider": "ollamacloud",
      "role": "thinking",
      "reasoning": true,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Thinking - modelo de razonamiento potente"
    },
    {
      "id": "deepseek-v3.2",
      "name": "DeepSeek V3.2",
      "provider": "ollamacloud",
      "role": "fallback",
      "reasoning": true,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Alternativo - nueva versión DeepSeek"
    },
    {
      "id": "qwen3-coder-next",
      "name": "Qwen3 Coder Next",
      "provider": "ollamacloud",
      "role": "coding",
      "reasoning": false,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Coding - especializado en código"
    },
    {
      "id": "qwen3.5:397b",
      "name": "Qwen3.5 397B",
      "provider": "ollamacloud",
      "role": "fallback",
      "reasoning": false,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Alternativo - modelo grande"
    },
    {
      "id": "qwen3-vl:235b",
      "name": "Qwen3-VL 235B",
      "provider": "ollamacloud",
      "role": "vision",
      "reasoning": false,
      "input": ["text", "image"],
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Vision - análisis de imágenes"
    },
    {
      "id": "minimax-m2.5",
      "name": "MiniMax M2.5",
      "provider": "ollamacloud",
      "role": "fallback",
      "reasoning": false,
      "contextWindow": 131072,
      "maxTokens": 16384,
      "description": "Alternativo - multilingüe"
    },
    {
      "id": "gemma3:27b",
      "name": "Gemma3 27B",
      "provider": "ollamacloud",
      "role": "light",
      "reasoning": false,
      "contextWindow": 8192,
      "maxTokens": 4096,
      "description": "Light - tareas simples"
    },
    {
      "id": "gemma3:12b",
      "name": "Gemma3 12B",
      "provider": "ollamacloud",
      "role": "light",
      "reasoning": false,
      "contextWindow": 8192,
      "maxTokens": 4096,
      "description": "Light - muy ligero"
    },
    {
      "id": "fingpt",
      "name": "FinGPT",
      "provider": "ollamacloud",
      "role": "specialized",
      "reasoning": false,
      "contextWindow": 8192,
      "maxTokens": 4096,
      "description": "Specialized - finanzas"
    },
    {
      "id": "medical",
      "name": "Medical",
      "provider": "ollamacloud",
      "role": "specialized",
      "reasoning": false,
      "contextWindow": 8192,
      "maxTokens": 4096,
      "description": "Specialized - medicina"
    }
  ],
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollamacloud/glm-5",
        "fallbacks": ["ollamacloud/kimi-k2.5", "ollamacloud/qwen3.5:397b"]
      },
      "workspace": "~/.openclaw/workspace",
      "compaction": {"mode": "safeguard"},
      "maxConcurrent": 4,
      "subagents": {"maxConcurrent": 8}
    },
    "list": [
      {"id": "main", "model": {"primary": "ollamacloud/glm-5"}, "subagents": {"allowAgents": ["main", "thinking", "vision", "coding"]}},
      {"id": "thinking", "model": {"primary": "ollamacloud/deepseek-v3.1:671b"}},
      {"id": "vision", "model": {"primary": "ollamacloud/qwen3-vl:235b"}},
      {"id": "coding", "model": {"primary": "ollamacloud/qwen3-coder-next"}}
    ]
  }
}
FLEET_EOF

    # Reemplazar placeholder con la key (escapando caracteres especiales)
    sed -i "s|OLLAMA_API_KEY_PLACEHOLDER|${OLLAMA_KEY}|g" "$CONFIG_DIR/fleet.json"
    
    # Permisos restrictivos (contiene API key)
    chmod 600 "$CONFIG_DIR/fleet.json"
    
    # Validar JSON
    if validate_json "$CONFIG_DIR/fleet.json"; then
        CREATED_FILES+=("$CONFIG_DIR/fleet.json")
        log_success "Fleet configurado con 13 modelos"
    else
        log_error "Error creando fleet.json"
        exit 1
    fi
fi

#===============================================================================
# CREAR OPENCLAW.JSON
#===============================================================================

log_info "[3/4] Configurando openclaw.json..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/openclaw.json"
else
    # Backup del existente
    if [[ -f "$CONFIG_DIR/openclaw.json" ]]; then
        cp "$CONFIG_DIR/openclaw.json" "$CONFIG_DIR/openclaw.json.bak"
        log_info "Backup creado: openclaw.json.bak"
    fi

    cat > "$CONFIG_DIR/openclaw.json" << OPENCLAW_EOF
{
  "meta": {
    "agentName": "${AGENT_NAME}",
    "createdAt": "$(date -Iseconds)",
    "version": "2026.3.5"
  },
  "models": {
    "providers": {
      "ollamacloud": {
        "baseUrl": "https://ollama.com/v1",
        "apiKey": "${OLLAMA_KEY}",
        "api": "openai-completions",
        "models": [
          {"id": "glm-5", "name": "GLM-5", "reasoning": true, "input": ["text"], "contextWindow": 131072, "maxTokens": 16384},
          {"id": "kimi-k2.5", "name": "Kimi K2.5", "reasoning": false, "input": ["text"], "contextWindow": 131072, "maxTokens": 16384},
          {"id": "deepseek-v3.1:671b", "name": "DeepSeek V3.1", "reasoning": true, "input": ["text"], "contextWindow": 131072, "maxTokens": 16384},
          {"id": "qwen3-vl:235b", "name": "Qwen3-VL", "reasoning": false, "input": ["text", "image"], "contextWindow": 131072, "maxTokens": 16384},
          {"id": "qwen3-coder-next", "name": "Qwen3 Coder", "reasoning": false, "input": ["text"], "contextWindow": 131072, "maxTokens": 16384}
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollamacloud/glm-5",
        "fallbacks": ["ollamacloud/kimi-k2.5", "ollamacloud/qwen3.5:397b"]
      },
      "workspace": "~/.openclaw/workspace",
      "compaction": {"mode": "safeguard"},
      "maxConcurrent": 4,
      "subagents": {"maxConcurrent": 8}
    },
    "list": [
      {"id": "main", "model": {"primary": "ollamacloud/glm-5"}, "subagents": {"allowAgents": ["main", "thinking", "vision", "coding"]}},
      {"id": "thinking", "model": {"primary": "ollamacloud/deepseek-v3.1:671b"}},
      {"id": "vision", "model": {"primary": "ollamacloud/qwen3-vl:235b"}},
      {"id": "coding", "model": {"primary": "ollamacloud/qwen3-coder-next"}}
    ]
  },
  "memory": {
    "enabled": true,
    "embeddings": {
      "enabled": true,
      "provider": "ollamacloud",
      "model": "nomic-embed-text"
    }
  },
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "boot-md": {"enabled": true},
        "session-memory": {"enabled": true}
      }
    }
  }
}
OPENCLAW_EOF

    chmod 600 "$CONFIG_DIR/openclaw.json"
    
    if validate_json "$CONFIG_DIR/openclaw.json"; then
        CREATED_FILES+=("$CONFIG_DIR/openclaw.json")
        log_success "openclaw.json configurado"
    else
        log_error "Error creando openclaw.json"
        exit 1
    fi
fi

#===============================================================================
# CREAR EMBEDDINGS.JSON
#===============================================================================

log_info "[4/4] Configurando embeddings..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/embeddings.json"
else
    mkdir -p "$DATA_DIR/embeddings"

    cat > "$CONFIG_DIR/embeddings.json" << EOF
{
  "enabled": true,
  "provider": "ollamacloud",
  "model": "nomic-embed-text",
  "chunkSize": 512,
  "overlap": 50,
  "indexDir": "$DATA_DIR/embeddings"
}
EOF

    if validate_json "$CONFIG_DIR/embeddings.json"; then
        CREATED_FILES+=("$CONFIG_DIR/embeddings.json")
        log_success "Embeddings configurados"
    else
        log_error "Error creando embeddings.json"
        exit 1
    fi
fi

#===============================================================================
# GUARDAR ESTADO
#===============================================================================

if [[ "$DRY_RUN" != "true" ]]; then
    log_info "Guardando estado..."
    
    cat > "$CONFIG_DIR/.fleet-status.json" << EOF
{
  "status": "completed",
  "agent_name": "${AGENT_NAME}",
  "total_models": 13,
  "primary_model": "glm-5",
  "thinking_model": "deepseek-v3.1:671b",
  "vision_model": "qwen3-vl:235b",
  "coding_model": "qwen3-coder-next",
  "embeddings_enabled": true,
  "created_at": "$(date -Iseconds)",
  "version": "1.0.0"
}
EOF

    validate_json "$CONFIG_DIR/.fleet-status.json" || true
fi

mark_success

#===============================================================================
# RESUMEN
#===============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              FLEET SETUP COMPLETADO                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Modelos configurados:${NC}"
echo -e "   ${GREEN}✓${NC} Primary: glm-5"
echo -e "   ${GREEN}✓${NC} Thinking: deepseek-v3.1:671b"
echo -e "   ${GREEN}✓${NC} Vision: qwen3-vl:235b"
echo -e "   ${GREEN}✓${NC} Coding: qwen3-coder-next"
echo -e "   ${GREEN}✓${NC} + 9 modelos de fallback/especializados"
echo ""
echo -e "${BLUE}Total modelos en fleet:${NC} 13"
echo ""
echo -e "${BLUE}Archivos creados:${NC}"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/fleet.json"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/openclaw.json"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/embeddings.json"
echo ""
echo -e "${YELLOW}Siguiente paso:${NC} ./setup-skills.sh --agent-name '${AGENT_NAME}'"
echo ""

exit 0