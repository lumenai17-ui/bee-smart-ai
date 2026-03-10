#!/bin/bash
#===============================================================================
# FASE 4: IDENTITY FLEET - Script Maestro
#===============================================================================
# Propósito: Orquestar la configuración completa de Identity y Fleet
# Uso: ./setup-fase4.sh --agent-name "nombre" --business-type "tipo" --business-name "nombre"
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
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Directorios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPENCLAW_DIR="$HOME/.openclaw"
readonly CONFIG_DIR="$OPENCLAW_DIR/config"
readonly DATA_DIR="$OPENCLAW_DIR/data"
readonly PHASES_DIR="$(dirname "$SCRIPT_DIR")"

# Estado
STEP=0
TOTAL_STEPS=4
CLEANUP_NEEDED=false
DRY_RUN=false

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
        log_error "Falló en paso $STEP. Limpiando..."
        
        # Remover archivos de estado parciales
        rm -f "$CONFIG_DIR/.identity-status.json" 2>/dev/null || true
        rm -f "$CONFIG_DIR/.fleet-status.json" 2>/dev/null || true
        rm -f "$CONFIG_DIR/.skills-status.json" 2>/dev/null || true
        
        log_warning "Archivos de estado parciales removidos"
        log_warning "Re-ejecutar este script después de corregir el error"
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
    echo "  --business-type TIPO    Tipo: restaurante, hotel, tienda, servicios, generico"
    echo "  --business-name NOMBRE  Nombre del negocio (requerido)"
    echo "  --email EMAIL           Email de contacto"
    echo "  --dry-run               Simular ejecución sin crear archivos"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --agent-name 'casamahana' --business-type 'restaurante' \\"
    echo "     --business-name 'Casa Mahana' --email 'info@casamahana.com'"
    exit 0
}

#-------------------------------------------------------------------------------
# VALIDACIONES
#-------------------------------------------------------------------------------

validate_phase1() {
    log_info "Validando FASE 1 (Pre-Flight)..."
    
    # FASE 1 genera: turnkey-status.json o turnkey-env.json
    local phase1_files=(
        "$CONFIG_DIR/turnkey-status.json"
        "$OPENCLAW_DIR/workspace/turnkey/turnkey-status.json"
        "$CONFIG_DIR/.pre-flight-status.json"
    )
    
    for file in "${phase1_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 1 validada: $file"
            return 0
        fi
    done
    
    log_error "FASE 1 no completada"
    log_warning "No se encontró ninguno de:"
    for file in "${phase1_files[@]}"; do
        log_warning "  - $file"
    done
    return 1
}

validate_phase2() {
    log_info "Validando FASE 2 (Setup Users)..."
    
    # FASE 2 crea directorios y usuario bee-*
    local phase2_files=(
        "$CONFIG_DIR/users-status.json"
        "$OPENCLAW_DIR/users-status.json"
        "$CONFIG_DIR/.users-status.json"
    )
    
    local found=false
    for file in "${phase2_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 2 validada: $file"
            found=true
            break
        fi
    done
    
    # También verificar que existen directorios
    if [[ -d "$CONFIG_DIR" && -d "$DATA_DIR" ]]; then
        log_success "Directorios de FASE 2 existen"
        return 0
    elif [[ "$found" == "true" ]]; then
        log_warning "Directorios no encontrados, creando..."
        mkdir -p "$CONFIG_DIR" "$DATA_DIR"
        return 0
    fi
    
    log_error "FASE 2 no completada"
    log_warning "Directorios esperados: $CONFIG_DIR, $DATA_DIR"
    return 1
}

validate_phase3() {
    log_info "Validando FASE 3 (Gateway Install)..."
    
    # FASE 3 genera gateway.json y gateway-status.json
    local phase3_files=(
        "$CONFIG_DIR/gateway.json"
        "$CONFIG_DIR/gateway-status.json"
        "$OPENCLAW_DIR/gateway-status.json"
    )
    
    for file in "${phase3_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 3 validada: $file"
            return 0
        fi
    done
    
    log_warning "FASE 3 no detectada (Gateway puede no estar instalado)"
    log_warning "Continuando sin validación de Gateway..."
    return 0  # No es crítico para FASE 4
}

validate_tools() {
    log_info "Validando herramientas requeridas..."
    
    local tools=("jq" "curl" "sed" "grep")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Faltan herramientas: ${missing[*]}"
        log_warning "Instalar con: sudo apt install ${missing[*]}"
        return 1
    fi
    
    log_success "Todas las herramientas están disponibles"
    return 0
}

#-------------------------------------------------------------------------------
# EJECUCIÓN
#-------------------------------------------------------------------------------

run_step() {
    local step_name="$1"
    local script="$2"
    shift 2
    local args=("$@")
    
    STEP=$((STEP + 1))
    CLEANUP_NEEDED=true
    
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  Paso ${STEP}/${TOTAL_STEPS}: ${step_name}${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Ejecutaría: ${SCRIPT_DIR}/${script} ${args[*]}"
        log_success "[DRY-RUN] ${step_name} simulado"
        mark_success
        return 0
    fi
    
    if "${SCRIPT_DIR}/${script}" "${args[@]}"; then
        log_success "${step_name} completado"
        mark_success
        return 0
    else
        log_error "Error en ${step_name}"
        log_warning "Revisar logs arriba para detalles"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

# Parsear argumentos
AGENT_NAME=""
BUSINESS_TYPE=""
BUSINESS_NAME=""
CONTACT_EMAIL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent-name)
            AGENT_NAME="$2"
            shift 2
            ;;
        --business-type)
            BUSINESS_TYPE="$2"
            shift 2
            ;;
        --business-name)
            BUSINESS_NAME="$2"
            shift 2
            ;;
        --email)
            CONTACT_EMAIL="$2"
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

# Encabezado
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${CYAN}${BOLD}              TURNKEY v6 - FASE 4: IDENTITY FLEET                ${NC}${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Este script configura:${NC}"
echo -e "   ${CYAN}•${NC} Identity (SOUL, USER, MEMORY, HEART, DOPAMINE)"
echo -e "   ${CYAN}•${NC} Fleet (13 modelos AI)"
echo -e "   ${CYAN}•${NC} Skills (39 habilidades)"
echo -e "   ${CYAN}•${NC} Knowledge (archivos del negocio)"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}[MODO DRY-RUN]${NC} Solo simulación, no se crearán archivos"
    echo ""
fi

#-------------------------------------------------------------------------------
# VALIDACIONES PREVIAS
#-------------------------------------------------------------------------------

echo -e "${YELLOW}Verificando prerequisitos...${NC}"
echo ""

# Validar herramientas
if ! validate_tools; then
    exit 1
fi

# Validar fases previas
if ! validate_phase1; then
    log_error "Ejecutar primero: phases/01-pre-flight/pre-flight.sh"
    exit 1
fi

if ! validate_phase2; then
    log_error "Ejecutar primero: phases/02-setup-users/setup-users.sh"
    exit 1
fi

# FASE 3 es opcional (warning)
validate_phase3 || true

echo ""
log_success "Dependencias verificadas"
echo ""

# Validar parámetros requeridos
if [[ -z "$AGENT_NAME" ]]; then
    log_error "--agent-name es requerido"
    usage
fi

if [[ -z "$BUSINESS_NAME" ]]; then
    log_error "--business-name es requerido"
    usage
fi

# Normalizar business-type
BUSINESS_TYPE="${BUSINESS_TYPE:-generico}"
case "$BUSINESS_TYPE" in
    restaurante|hotel|tienda|servicios|generico)
        ;;
    *)
        log_warning "business-type '$BUSINESS_TYPE' no reconocido, usando 'generico'"
        BUSINESS_TYPE="generico"
        ;;
esac

#-------------------------------------------------------------------------------
# EJECUTAR PASOS
#-------------------------------------------------------------------------------

# Construir argumentos comunes
ARGS=()
[[ -n "$AGENT_NAME" ]] && ARGS+=(--agent-name "$AGENT_NAME")
[[ -n "$BUSINESS_TYPE" ]] && ARGS+=(--business-type "$BUSINESS_TYPE")
[[ -n "$BUSINESS_NAME" ]] && ARGS+=(--business-name "$BUSINESS_NAME")
[[ -n "$CONTACT_EMAIL" ]] && ARGS+=(--email "$CONTACT_EMAIL")
[[ "$DRY_RUN" == "true" ]] && ARGS+=(--dry-run)

# Ejecutar cada paso
run_step "Setup Identity" "setup-identity.sh" "${ARGS[@]}" || exit 1
run_step "Setup Fleet" "setup-fleet.sh" "${ARGS[@]}" || exit 1
run_step "Setup Skills" "setup-skills.sh" "${ARGS[@]}" || exit 1
run_step "Process Knowledge" "process-knowledge.sh" "${ARGS[@]}" || exit 1

#-------------------------------------------------------------------------------
# RESUMEN FINAL
#-------------------------------------------------------------------------------

echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              ✓ FASE 4 COMPLETADA EXITOSAMENTE                 ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Resumen de archivos creados:${NC}"
echo ""
echo -e "${CYAN}Identity:${NC}"
echo -e "   ✓ SOUL.md - Personalidad del agente"
echo -e "   ✓ USER.md - Información del cliente"
echo -e "   ✓ MEMORY.md - Memoria inicial"
echo -e "   ✓ HEART.md - Sistema emocional"
echo -e "   ✓ DOPAMINE.md - Sistema de satisfacción"
echo ""
echo -e "${CYAN}Fleet:${NC}"
echo -e "   ✓ fleet.json - 13 modelos configurados"
echo -e "   ✓ openclaw.json - Configuración de OpenClaw"
echo -e "   ✓ embeddings.json - Configuración de embeddings"
echo ""
echo -e "${CYAN}Skills (39 habilidades):${NC}"
echo -e "   ✓ skills-core.json - 25 habilidades CORE"
echo -e "   ✓ skills-optional.json - 14 habilidades OPCIONALES"
echo -e "   ✓ skills-bundle.json - Bundle por tipo de negocio"
echo -e "   ✓ SKILLS.md - Documentación completa"
echo ""
echo -e "${CYAN}Knowledge:${NC}"
echo -e "   ✓ Directorio ~/.openclaw/knowledge/"
echo -e "   ✓ index.json - Índice de archivos"
echo ""
echo -e "${YELLOW}Próximo paso:${NC} FASE 5 - Bot Config"
echo -e "${YELLOW}Ejecutar:${NC} ./phases/05-bot-config/setup-fase5.sh"
echo ""

# Guardar estado maestro
if [[ "$DRY_RUN" != "true" ]]; then
    cat > "$CONFIG_DIR/.fase4-status.json" << EOF
{
  "status": "completed",
  "completed_at": "$(date -Iseconds)",
  "agent_name": "$AGENT_NAME",
  "business_type": "$BUSINESS_TYPE",
  "business_name": "$BUSINESS_NAME",
  "steps_completed": [
    "setup-identity",
    "setup-fleet",
    "setup-skills",
    "process-knowledge"
  ],
  "total_files_created": 13,
  "next_phase": "05-bot-config"
}
EOF
    log_success "Estado guardado en $CONFIG_DIR/.fase4-status.json"
fi

exit 0