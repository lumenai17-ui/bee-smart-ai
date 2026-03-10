#!/bin/bash
#===============================================================================
# FASE 5: BOT CONFIG - Script Maestro
#===============================================================================
# Propósito: Orquestar configuración de canales de comunicación
# Uso: ./bot-config.sh [opciones]
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
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"
readonly OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
readonly CONFIG_DIR="$OPENCLAW_DIR/config"
readonly SECRETS_DIR="$OPENCLAW_DIR/secrets"
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
log_step() { echo -e "${CYAN}==>${NC} $1"; }

cleanup_on_failure() {
    local exit_code=$?
    
    if [[ "$CLEANUP_NEEDED" == "true" && $exit_code -ne 0 ]]; then
        log_error "Falló en paso $STEP. Limpiando..."
        
        # Remover archivos de estado parciales
        rm -f "$CONFIG_DIR/.email-status.json" 2>/dev/null || true
        rm -f "$CONFIG_DIR/.telegram-status.json" 2>/dev/null || true
        rm -f "$CONFIG_DIR/.bot-config-status.json" 2>/dev/null || true
        
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
    echo "FASE 5: Configurar canales de comunicación (Telegram, Email, APIs)"
    echo ""
    echo "Opciones:"
    echo "  --telegram           Configurar solo Telegram"
    echo "  --email              Configurar solo Email"
    echo "  --api-keys           Configurar solo APIs opcionales"
    echo "  --all                Configurar todos (default)"
    echo "  --dry-run            Simular sin escribir archivos"
    echo "  --skip-validation    Saltar validación de canales"
    echo "  --help               Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --all                    # Configurar todo"
    echo "  $0 --telegram --email       # Solo Telegram y Email"
    echo "  $0 --dry-run --all          # Simular configuración"
    echo ""
    echo "Prerequisitos:"
    echo "  - FASE 4 completada (identity y fleet configurados)"
    echo "  - Gateway corriendo en puerto 18789"
    echo "  - Credenciales del cliente disponibles"
    exit 0
}

#-------------------------------------------------------------------------------
# VALIDACIONES
#-------------------------------------------------------------------------------

validate_phase4() {
    log_step "Validando FASE 4..."
    
    # Buscar archivos de estado de FASE 4
    local phase4_files=(
        "$CONFIG_DIR/.fase4-status.json"
        "$CONFIG_DIR/.identity-status.json"
        "$CONFIG_DIR/.fleet-status.json"
        "$OPENCLAW_DIR/openclaw.json"
    )
    
    local found=false
    for file in "${phase4_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 4 validada: $file"
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        log_error "FASE 4 no completada"
        log_warning "Ejecutar primero: phases/04-identity-fleet/setup-fase4.sh"
        return 1
    fi
    
    # Verificar gateway corriendo
    if command -v systemctl &>/dev/null; then
        if systemctl is-active --quiet openclaw-gateway 2>/dev/null; then
            log_success "Gateway está corriendo"
        else
            log_warning "Gateway no detectado (puede que no esté instalado)"
        fi
    fi
    
    return 0
}

validate_phase1() {
    log_step "Validando FASE 1..."
    
    # Buscar config de FASE 1
    local phase1_files=(
        "$OPENCLAW_DIR/workspace/turnkey-config.json"
        "$CONFIG_DIR/turnkey-config.json"
        "$OPENCLAW_DIR/turnkey-config.json"
    )
    
    for file in "${phase1_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 1 validada: $file"
            export TURNKEY_CONFIG="$file"
            return 0
        fi
    done
    
    log_warning "FASE 1 config no encontrada (se solicitarán datos interactivamente)"
    return 0  # No es error crítico
}

validate_tools() {
    log_step "Validando herramientas..."
    
    local tools=("curl" "jq")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Faltan herramientas: ${missing[*]}"
        log_info "Instalar con: sudo apt install ${missing[*]}"
        return 1
    fi
    
    log_success "Todas las herramientas disponibles"
    return 0
}

load_phase1_config() {
    # Intentar cargar config de FASE 1
    if [[ -n "${TURNKEY_CONFIG:-}" ]] && [[ -f "$TURNKEY_CONFIG" ]]; then
        log_info "Cargando config de FASE 1..."
        
        # Extraer valores con jq
        if command -v jq &>/dev/null; then
            export AGENT_NAME="${AGENT_NAME:-$(jq -r '.agent_name // empty' "$TURNKEY_CONFIG" 2>/dev/null || true)}"
            export BUSINESS_NAME="${BUSINESS_NAME:-$(jq -r '.business_name // empty' "$TURNKEY_CONFIG" 2>/dev/null || true)}"
            export CONTACT_EMAIL="${CONTACT_EMAIL:-$(jq -r '.contact_email // empty' "$TURNKEY_CONFIG" 2>/dev/null || true)}"
            
            if [[ -n "$AGENT_NAME" ]]; then
                log_success "Config de FASE 1 cargada: agente=$AGENT_NAME"
            fi
        fi
    fi
}

update_openclaw_json() {
    local openclaw_file="$OPENCLAW_DIR/openclaw.json"
    
    if [[ ! -f "$openclaw_file" ]]; then
        log_warning "openclaw.json no encontrado, saltando actualización"
        return 0
    fi
    
    log_step "Actualizando openclaw.json..."
    
    # Backup
    cp "$openclaw_file" "${openclaw_file}.bak.$(date +%s)" 2>/dev/null || true
    
    # Leer canales configurados
    local telegram_enabled=false
    local email_enabled=false
    
    [[ -f "$SECRETS_DIR/telegram-secrets.yaml" ]] && telegram_enabled=true
    [[ -f "$SECRETS_DIR/email-secrets.yaml" ]] && email_enabled=true
    
    # Actualizar con jq si está disponible
    if command -v jq &>/dev/null; then
        local tmp_file="${openclaw_file}.tmp"
        
        jq --argjson telegram "$telegram_enabled" \
           --argjson email "$email_enabled" \
           '.channels.telegram.enabled = $telegram |
            .channels.email.enabled = $email' \
           "$openclaw_file" > "$tmp_file" 2>/dev/null && \
        mv "$tmp_file" "$openclaw_file" || \
        rm -f "$tmp_file"
        
        log_success "openclaw.json actualizado"
    fi
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
        log_warning "[DRY-RUN] Ejecutaría: ${script} ${args[*]}"
        mark_success
        return 0
    fi
    
    if [[ ! -f "$script" ]]; then
        log_error "Script no encontrado: $script"
        return 1
    fi
    
    if bash "$script" "${args[@]}"; then
        log_success "${step_name} completado"
        mark_success
        return 0
    else
        log_error "Error en ${step_name}"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

# Parsear argumentos
CONFIGURE_ALL=true
CONFIGURE_TELEGRAM=false
CONFIGURE_EMAIL=false
CONFIGURE_API_KEYS=false
SKIP_VALIDATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --telegram)
            CONFIGURE_ALL=false
            CONFIGURE_TELEGRAM=true
            shift
            ;;
        --email)
            CONFIGURE_ALL=false
            CONFIGURE_EMAIL=true
            shift
            ;;
        --api-keys)
            CONFIGURE_ALL=false
            CONFIGURE_API_KEYS=true
            shift
            ;;
        --all)
            CONFIGURE_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
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

# Hacer variables readonly
readonly CONFIGURE_ALL CONFIGURE_TELEGRAM CONFIGURE_EMAIL CONFIGURE_API_KEYS SKIP_VALIDATION DRY_RUN

# Encabezado
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${CYAN}${BOLD}              TURNKEY v6 - FASE 5: BOT CONFIG                   ${NC}${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}[MODO DRY-RUN]${NC} Solo simulación, no se escribirán archivos"
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

# Validar FASE 4
if ! validate_phase4; then
    exit 1
fi

# Validar FASE 1
validate_phase1 || true

# Cargar config de FASE 1
load_phase1_config

# Crear directorios necesarios
mkdir -p "$CONFIG_DIR"
mkdir -p "$SECRETS_DIR"

log_success "Prerequisitos verificados"
echo ""

#-------------------------------------------------------------------------------
# EJECUTAR PASOS
#-------------------------------------------------------------------------------

# Calcular pasos según configuración
STEPS_TO_RUN=()
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_EMAIL" == "true" ]] && STEPS_TO_RUN+=("email")
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_TELEGRAM" == "true" ]] && STEPS_TO_RUN+=("telegram")
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_API_KEYS" == "true" ]] && STEPS_TO_RUN+=("api-keys")
[[ "$SKIP_VALIDATION" == "false" ]] && STEPS_TO_RUN+=("validate")

TOTAL_STEPS=${#STEPS_TO_RUN[@]}

if [[ $TOTAL_STEPS -eq 0 ]]; then
    log_warning "No hay pasos a ejecutar"
    exit 0
fi

# Ejecutar cada paso
for step in "${STEPS_TO_RUN[@]}"; do
    case $step in
        email)
            run_step "Configurar Email" "$SCRIPT_DIR/setup-email.sh" || exit 1
            ;;
        telegram)
            run_step "Configurar Telegram" "$SCRIPT_DIR/setup-telegram.sh" || exit 1
            ;;
        api-keys)
            run_step "Configurar APIs" "$SCRIPT_DIR/setup-api-keys.sh" || exit 1
            ;;
        validate)
            run_step "Validar Canales" "$SCRIPT_DIR/validate-channels.sh" || exit 1
            ;;
    esac
done

#-------------------------------------------------------------------------------
# ACTUALIZAR OPENCLAW.JSON
#-------------------------------------------------------------------------------

if [[ "$DRY_RUN" != "true" ]]; then
    update_openclaw_json
fi

#-------------------------------------------------------------------------------
# GUARDAR ESTADO
#-------------------------------------------------------------------------------

if [[ "$DRY_RUN" != "true" ]]; then
    cat > "$CONFIG_DIR/.bot-config-status.json" << EOF
{
  "status": "completed",
  "completed_at": "$(date -Iseconds)",
  "channels": {
    "telegram": $([[ -f "$SECRETS_DIR/telegram-secrets.yaml" ]] && echo "true" || echo "false"),
    "email": $([[ -f "$SECRETS_DIR/email-secrets.yaml" ]] && echo "true" || echo "false")
  },
  "validated": $([[ "$SKIP_VALIDATION" == "false" ]] && echo "true" || echo "false"),
  "version": "1.0.0"
}
EOF
fi

#-------------------------------------------------------------------------------
# RESUMEN FINAL
#-------------------------------------------------------------------------------

echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              ✓ FASE 5 COMPLETADA EXITOSAMENTE                ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Canales configurados:${NC}"
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_EMAIL" == "true" ]] && echo -e "   ${GREEN}✓${NC} Email"
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_TELEGRAM" == "true" ]] && echo -e "   ${GREEN}✓${NC} Telegram"
[[ "$CONFIGURE_ALL" == "true" || "$CONFIGURE_API_KEYS" == "true" ]] && echo -e "   ${GREEN}✓${NC} APIs opcionales"

echo ""
echo -e "${BLUE}Archivos generados:${NC}"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/telegram.yaml"
echo -e "   ${GREEN}✓${NC} $SECRETS_DIR/telegram-secrets.yaml"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/email.yaml"
echo -e "   ${GREEN}✓${NC} $SECRETS_DIR/email-secrets.yaml"
echo -e "   ${GREEN}✓${NC} $OPENCLAW_DIR/openclaw.json (actualizado)"

echo ""
echo -e "${YELLOW}Próximo paso:${NC} FASE 6 - Activation"
echo -e "${YELLOW}Ejecutar:${NC} ./phases/06-activation/setup-fase6.sh"
echo ""

exit 0