#!/bin/bash
#===============================================================================
# FASE 4: IDENTITY FLEET - Process Knowledge
#===============================================================================
# Propósito: Procesar archivos de conocimiento (PDFs, Excel, Docs, Imágenes, URLs)
# Uso: ./process-knowledge.sh --agent-name "nombre"
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
readonly KNOWLEDGE_DIR="$OPENCLAW_DIR/knowledge"
readonly PENDING_FILE="$CONFIG_DIR/pending-knowledge.json"
readonly TEMP_DIR="$OPENCLAW_DIR/workspace/temp-upload"

# Estado
CLEANUP_NEEDED=false
PROCESSED_COUNT=0
ERROR_COUNT=0

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
        log_error "Falló el procesamiento. Limpiando..."
        rm -f "$CONFIG_DIR/.knowledge-status.json" 2>/dev/null || true
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
    echo "  --verbose               Mostrar más detalles"
    echo "  --dry-run               Simular procesamiento"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "Este script procesa archivos de pending-knowledge.json"
    echo "creado en FASE 1."
    exit 0
}

check_tool() {
    local tool="$1"
    local package="${2:-$1}"
    
    if ! command -v "$tool" &>/dev/null; then
        log_warning "Herramienta '$tool' no encontrada"
        log_info "Instalar con: sudo apt install $package"
        return 1
    fi
    return 0
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

process_pdf() {
    local input="$1"
    local output="$2"
    
    if check_tool pdftotext poppler-utils; then
        pdftotext "$input" "$output" 2>/dev/null || {
            log_warning "No se pudo extraer texto de: $input"
            return 1
        }
        return 0
    else
        log_warning "pdftotext no disponible, saltando PDF"
        return 1
    fi
}

process_excel() {
    local input="$1"
    local output="$2"
    
    if python3 -c "import openpyxl" 2>/dev/null; then
        python3 << PYEOF
import openpyxl
import json
import sys

try:
    wb = openpyxl.load_workbook('$input')
    data = {}
    for sheet in wb.sheetnames:
        ws = wb[sheet]
        rows = []
        for row in ws.iter_rows(values_only=True):
            rows.append(list(row))
        data[sheet] = rows
    with open('$output', 'w') as f:
        json.dump(data, f, indent=2, default=str)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
        return 0
    else
        log_warning "openpyxl no disponible, saltando Excel"
        return 1
    fi
}

process_doc() {
    local input="$1"
    local output="$2"
    
    if check_tool pandoc pandoc; then
        pandoc "$input" -o "$output" -t plain 2>/dev/null || {
            log_warning "No se pudo convertir: $input"
            return 1
        }
        return 0
    else
        log_warning "pandoc no disponible, saltando documento"
        return 1
    fi
}

process_url() {
    local url="$1"
    local output="$2"
    
    if check_tool curl curl; then
        curl -sL "$url" -o "$output" 2>/dev/null || {
            log_warning "No se pudo descargar: $url"
            return 1
        }
        return 0
    else
        log_warning "curl no disponible, saltando URL"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# PARÁMETROS
#-------------------------------------------------------------------------------

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

AGENT_NAME=""
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent-name)
            AGENT_NAME="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
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
readonly AGENT_NAME VERBOSE DRY_RUN

#===============================================================================
# ENCABEZADO
#===============================================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         FASE 4: IDENTITY FLEET - Process Knowledge            ║${NC}"
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

log_info "Verificando prerequisitos..."

# Verificar que existe skills
if [[ ! -f "$CONFIG_DIR/.skills-status.json" ]]; then
    log_error "Skills no configurados"
    log_warning "Ejecutar primero: ./setup-skills.sh"
    exit 1
fi

log_success "Skills verificados"

#===============================================================================
# VERIFICAR ARCHIVOS PENDIENTES
#===============================================================================

log_info "[1/6] Verificando archivos de conocimiento..."

# Crear directorios
if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía directorios de conocimiento"
else
    mkdir -p "$KNOWLEDGE_DIR"/{pdf,excel,docs,images,urls,processed,embeddings}
    mkdir -p "$TEMP_DIR"
fi

if [[ ! -f "$PENDING_FILE" ]]; then
    log_warning "No hay archivos pendientes de procesamiento"
    log_info "Creando archivo pending-knowledge.json vacío..."
    
    if [[ "$DRY_RUN" != "true" ]]; then
        cat > "$PENDING_FILE" << EOF
{
  "agent_name": "${AGENT_NAME}",
  "created_at": "$(date -Iseconds)",
  "files": []
}
EOF
    fi
    
    # Crear estado de finalización
    if [[ "$DRY_RUN" != "true" ]]; then
        cat > "$CONFIG_DIR/.knowledge-status.json" << EOF
{
  "status": "skipped",
  "agent_name": "${AGENT_NAME}",
  "reason": "No hay archivos pendientes",
  "processed_count": 0,
  "error_count": 0,
  "created_at": "$(date -Iseconds)",
  "version": "1.0.0"
}
EOF
    fi
    
    mark_success
    log_success "Procesamiento saltado (no hay archivos)"
    exit 0
fi

log_success "Archivo de pendientes encontrado"

#===============================================================================
# LEER ARCHIVOS PENDIENTES
#===============================================================================

log_info "[2/6] Leyendo lista de archivos..."

PENDINGS=""
if command -v jq &>/dev/null; then
    PENDINGS=$(jq -r '.files[] | @base64' "$PENDING_FILE" 2>/dev/null || true)
else
    log_warning "jq no disponible, usando método alternativo"
    PENDINGS=$(grep -o '"files"[^]]*' "$PENDING_FILE" 2>/dev/null || true)
fi

if [[ -z "$PENDINGS" ]]; then
    log_warning "No hay archivos en la lista"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        cat > "$CONFIG_DIR/.knowledge-status.json" << EOF
{
  "status": "skipped",
  "agent_name": "${AGENT_NAME}",
  "reason": "Lista vacía",
  "processed_count": 0,
  "error_count": 0,
  "created_at": "$(date -Iseconds)"
}
EOF
    fi
    
    mark_success
    exit 0
fi

FILE_COUNT=$(echo "$PENDINGS" | wc -l)
log_info "Encontrados $FILE_COUNT archivo(s) para procesar"

#===============================================================================
# VERIFICAR HERRAMIENTAS
#===============================================================================

log_info "[3/6] Verificando herramientas..."

TOOLS_OK=true

if ! check_tool pdftotext poppler-utils; then
    TOOLS_OK=false
fi

if ! python3 -c "import openpyxl" 2>/dev/null; then
    log_warning "openpyxl no disponible (pip install openpyxl)"
fi

if ! check_tool pandoc pandoc; then
    TOOLS_OK=false
fi

if ! check_tool curl curl; then
    TOOLS_OK=false
fi

if [[ "$TOOLS_OK" == "false" ]]; then
    log_warning "Algunas herramientas no están disponibles"
    log_info "Algunos archivos pueden no ser procesados"
fi

#===============================================================================
# PROCESAR ARCHIVOS
#===============================================================================

log_info "[4/6] Procesando archivos..."

INDEX_ENTRIES=()

while IFS= read -r encoded; do
    FILE_INFO=$(echo "$encoded" | base64 -d 2>/dev/null || echo "{}")
    
    FILE_PATH=$(echo "$FILE_INFO" | jq -r '.path // empty' 2>/dev/null || true)
    FILE_TYPE=$(echo "$FILE_INFO" | jq -r '.type // empty' 2>/dev/null || true)
    FILE_NAME=$(basename "$FILE_PATH" 2>/dev/null || echo "unknown")
    
    if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
        log_warning "Archivo no encontrado: $FILE_PATH"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi
    
    [[ "$VERBOSE" == "true" ]] && log_info "Procesando: $FILE_NAME ($FILE_TYPE)"
    
    OUTPUT_PATH=""
    PROCESS_OK=false
    
    case "$FILE_TYPE" in
        pdf)
            OUTPUT_PATH="$KNOWLEDGE_DIR/processed/${FILE_NAME%.pdf}.txt"
            if process_pdf "$FILE_PATH" "$OUTPUT_PATH"; then
                PROCESS_OK=true
            fi
            ;;
        excel|xlsx|xls)
            OUTPUT_PATH="$KNOWLEDGE_DIR/processed/${FILE_NAME%.xlsx}.json"
            if process_excel "$FILE_PATH" "$OUTPUT_PATH"; then
                PROCESS_OK=true
            fi
            ;;
        doc|docx)
            OUTPUT_PATH="$KNOWLEDGE_DIR/processed/${FILE_NAME%.docx}.txt"
            if process_doc "$FILE_PATH" "$OUTPUT_PATH"; then
                PROCESS_OK=true
            fi
            ;;
        url)
            OUTPUT_PATH="$KNOWLEDGE_DIR/urls/${FILE_NAME}.html"
            if process_url "$FILE_PATH" "$OUTPUT_PATH"; then
                PROCESS_OK=true
            fi
            ;;
        *)
            log_warning "Tipo no soportado: $FILE_TYPE"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            continue
            ;;
    esac
    
    if [[ "$PROCESS_OK" == "true" ]]; then
        PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
        INDEX_ENTRIES+=("{\"file\":\"$FILE_NAME\",\"type\":\"$FILE_TYPE\",\"output\":\"$OUTPUT_PATH\",\"processed_at\":\"$(date -Iseconds)\"}")
        log_success "Procesado: $FILE_NAME"
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        log_error "Error procesando: $FILE_NAME"
    fi
    
done <<< "$PENDINGS"

#===============================================================================
# CREAR ÍNDICE
#===============================================================================

log_info "[5/6] Creando índice de conocimiento..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $KNOWLEDGE_DIR/index.json"
else
    # Crear índice JSON
    echo "{" > "$KNOWLEDGE_DIR/index.json"
    echo "  \"agent_name\": \"${AGENT_NAME}\"," >> "$KNOWLEDGE_DIR/index.json"
    echo "  \"created_at\": \"$(date -Iseconds)\"," >> "$KNOWLEDGE_DIR/index.json"
    echo "  \"total_files\": ${FILE_COUNT}," >> "$KNOWLEDGE_DIR/index.json"
    echo "  \"processed\": ${PROCESSED_COUNT}," >> "$KNOWLEDGE_DIR/index.json"
    echo "  \"errors\": ${ERROR_COUNT}," >> "$KNOWLEDGE_DIR/index.json"
    echo "  \"files\": [" >> "$KNOWLEDGE_DIR/index.json"
    
    for i in "${!INDEX_ENTRIES[@]}"; do
        if [[ $i -lt $((${#INDEX_ENTRIES[@]} - 1)) ]]; then
            echo "    ${INDEX_ENTRIES[$i]}," >> "$KNOWLEDGE_DIR/index.json"
        else
            echo "    ${INDEX_ENTRIES[$i]}" >> "$KNOWLEDGE_DIR/index.json"
        fi
    done
    
    echo "  ]" >> "$KNOWLEDGE_DIR/index.json"
    echo "}" >> "$KNOWLEDGE_DIR/index.json"
    
    validate_json "$KNOWLEDGE_DIR/index.json" || true
    log_success "Índice creado con ${PROCESSED_COUNT} archivo(s)"
fi

#===============================================================================
# GENERAR EMBEDDINGS (OPCIONAL)
#===============================================================================

log_info "[6/6] Verificando embeddings..."

if [[ -f "$CONFIG_DIR/embeddings.json" ]]; then
    EMBEDDINGS_ENABLED=$(jq -r '.enabled // false' "$CONFIG_DIR/embeddings.json" 2>/dev/null || echo "false")
    
    if [[ "$EMBEDDINGS_ENABLED" == "true" ]]; then
        log_info "Embeddings habilitados - procesar con Ollama"
        log_warning "Embeddings se generan bajo demanda durante el uso"
    else
        log_info "Embeddings no habilitados"
    fi
else
    log_info "Configuración de embeddings no encontrada"
fi

#===============================================================================
# GUARDAR ESTADO
#===============================================================================

if [[ "$DRY_RUN" != "true" ]]; then
    log_info "Guardando estado..."
    
    STATUS="completed"
    [[ $ERROR_COUNT -gt 0 ]] && STATUS="completed_with_errors"
    [[ $PROCESSED_COUNT -eq 0 ]] && STATUS="skipped"
    
    cat > "$CONFIG_DIR/.knowledge-status.json" << EOF
{
  "status": "${STATUS}",
  "agent_name": "${AGENT_NAME}",
  "total_files": ${FILE_COUNT},
  "processed_count": ${PROCESSED_COUNT},
  "error_count": ${ERROR_COUNT},
  "index_file": "$KNOWLEDGE_DIR/index.json",
  "created_at": "$(date -Iseconds)",
  "version": "1.0.0"
}
EOF
    
    validate_json "$CONFIG_DIR/.knowledge-status.json" || true
fi

mark_success

#===============================================================================
# RESUMEN
#===============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              KNOWLEDGE PROCESSING COMPLETADO                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Archivos procesados:${NC} ${PROCESSED_COUNT}/${FILE_COUNT}"
echo -e "${BLUE}Errores:${NC} ${ERROR_COUNT}"
echo ""
echo -e "${BLUE}Directorio de conocimiento:${NC}"
echo -e "   ${GREEN}✓${NC} $KNOWLEDGE_DIR/processed/"
echo -e "   ${GREEN}✓${NC} $KNOWLEDGE_DIR/index.json"
echo ""

if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}Algunos archivos no pudieron ser procesados.${NC}"
    echo -e "${YELLOW}Verificar que las herramientas necesarias estén instaladas.${NC}"
    echo ""
fi

echo -e "${YELLOW}FASE 4 COMPLETADA${NC}"
echo ""

exit 0