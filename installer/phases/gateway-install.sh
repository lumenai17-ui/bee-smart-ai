#!/bin/bash
# =============================================================================
# gateway-install.sh - FASE 3: GATEWAY INSTALL - Instalar y configurar Gateway
# TURNKEY v6
# =============================================================================

set -euo pipefail

# =============================================================================
# CORRECCIONES APLICADAS:
# - Cambiado 'set -e; set +e' → 'set -euo pipefail' (manejo de errores robusto)
# - Agregado trap para cleanup en caso de falla
# - Agregada validación de FASE 1 y FASE 2
# - Agregada validación de puerto numérico
# - Agregada validación de binary antes de crear service
# - Enmascarada API key en logs
# =============================================================================

VERSION="6.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
PHASE1_STATUS="${HOME}/.openclaw/workspace/turnkey-v6/phases/01-pre-flight/status/turnkey-status.json"
PHASE2_STATUS="${HOME}/.openclaw/users-status.json"
WORK_DIR="${HOME}/.openclaw"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Valores por defecto (readonly después de parse)
GATEWAY_PORT="${GATEWAY_PORT:-18789}"
GATEWAY_HOST="${GATEWAY_HOST:-localhost}"
OLLAMA_API_KEY="${OLLAMA_API_KEY:-}"
SKIP_INSTALL=false
DRY_RUN=false
CONFIG_FILE=""

# Arrays para resultados
declare -a WARNINGS=()
declare -a ERRORS=()
declare -a CHECKS=()

# Variables para cleanup
CLEANUP_CONFIG=false
CLEANUP_SERVICE=false
CLEANUP_SUCCESS=false

# =============================================================================
# CLEANUP EN CASO DE FALLA
# =============================================================================

cleanup_on_failure() {
    # Solo limpiar si no fue exitoso
    if [[ "$CLEANUP_SUCCESS" == "true" ]]; then
        return 0
    fi
    
    log_warn "Ejecutando cleanup por falla..."
    
    if [[ "$CLEANUP_CONFIG" == "true" ]]; then
        local config_file="${HOME}/.openclaw/config/gateway.json"
        if [[ -f "$config_file" ]]; then
            log_warn "Eliminando configuración incompleta: $config_file"
            rm -f "$config_file" 2>/dev/null || true
        fi
    fi
    
    if [[ "$CLEANUP_SERVICE" == "true" ]]; then
        local service_file="${HOME}/.config/systemd/user/openclaw-gateway.service"
        if [[ -f "$service_file" ]]; then
            log_warn "Eliminando service incompleto: $service_file"
            rm -f "$service_file" 2>/dev/null || true
            systemctl --user daemon-reload 2>/dev/null || true
        fi
    fi
}

mark_success() {
    CLEANUP_SUCCESS=true
}

trap cleanup_on_failure EXIT ERR

# -----------------------------------------------------------------------------
# FUNCIONES DE LOGGING
# -----------------------------------------------------------------------------

log_info() { echo -e "${BLUE}$1${NC}"; }
log_ok() { echo -e "${GREEN}$1${NC}"; }
log_warn() { echo -e "${YELLOW}$1${NC}"; }
log_error() { echo -e "${RED}$1${NC}"; }

# -----------------------------------------------------------------------------
# MOSTRAR AYUDA
# -----------------------------------------------------------------------------

show_help() {
    echo -e "${CYAN}Uso: $0 [opciones]${NC}"
    echo ""
    echo "Opciones:"
    echo "  --api-key KEY     API key de Ollama Cloud"
    echo "  --port PORT        Puerto del gateway (default: 18789)"
    echo "  --host HOST        Host del gateway (default: localhost)"
    echo "  --config FILE      Archivo de configuración JSON"
    echo "  --skip-install     Solo configurar, no instalar"
    echo "  --dry-run          Simular sin hacer cambios"
    echo "  --help             Mostrar esta ayuda"
    echo ""
    echo "Variables de entorno:"
    echo "  OLLAMA_API_KEY     API key de Ollama Cloud"
    echo "  GATEWAY_PORT       Puerto del gateway"
    echo "  GATEWAY_HOST       Host del gateway"
    echo ""
    echo "Ejemplos:"
    echo "  $0 --api-key os_xxx"
    echo "  $0 --config gateway-config.json"
    echo "  $0 --dry-run"
    exit 0
}

# -----------------------------------------------------------------------------
# PARSEAR ARGUMENTOS
# -----------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --api-key) OLLAMA_API_KEY="$2"; shift 2 ;;
            --port) GATEWAY_PORT="$2"; shift 2 ;;
            --host) GATEWAY_HOST="$2"; shift 2 ;;
            --config) CONFIG_FILE="$2"; shift 2 ;;
            --skip-install) SKIP_INSTALL=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) show_help ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
    
    # Validar puerto como número
    if ! [[ "$GATEWAY_PORT" =~ ^[0-9]+$ ]]; then
        log_error "Puerto debe ser numérico: $GATEWAY_PORT"
        exit 1
    fi
    if [[ "$GATEWAY_PORT" -lt 1024 ]] || [[ "$GATEWAY_PORT" -gt 65535 ]]; then
        log_error "Puerto fuera de rango válido (1024-65535): $GATEWAY_PORT"
        exit 1
    fi
    
    # Cargar config desde archivo si existe
    if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
        log_info "Cargando configuración desde: $CONFIG_FILE"
        # TODO: Parsear JSON
    fi
    
    # Hacer variables readonly después de parsear
    readonly GATEWAY_PORT GATEWAY_HOST SKIP_INSTALL DRY_RUN
}

# -----------------------------------------------------------------------------
# VALIDAR FASES PREVIAS
# -----------------------------------------------------------------------------

validate_phase1() {
    log_info "=== VALIDANDO FASE 1 (PRE-FLIGHT) ==="
    
    if [[ ! -f "$PHASE1_STATUS" ]]; then
        log_warn "FASE 1 no detectada (turnkey-status.json no encontrado)"
        log_warn "Se recomienda ejecutar FASE 1 antes de continuar"
        # No es fatal, permitir continuar
        return 0
    fi
    
    if command -v jq &>/dev/null; then
        local status
        status=$(jq -r '.status // "unknown"' "$PHASE1_STATUS" 2>/dev/null || echo "unknown")
        
        if [[ "$status" != "passed" ]] && [[ "$status" != "completed" ]]; then
            log_warn "FASE 1 tiene estado: $status"
            log_warn "Se recomienda completar FASE 1"
        else
            log_ok "FASE 1 validada: $status"
        fi
    else
        log_warn "jq no disponible, no se puede validar FASE 1"
    fi
}

validate_phase2() {
    log_info "=== VALIDANDO Fase 2 (SETUP USERS) ==="
    
    local required_dirs=(
        "${WORK_DIR}"
        "${WORK_DIR}/config"
        "${WORK_DIR}/logs"
        "${WORK_DIR}/data"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        log_error "Directorios de FASE 2 faltantes:"
        for dir in "${missing_dirs[@]}"; do
            log_error "  - $dir"
        done
        log_error ""
        log_error "Ejecute primero: FASE 2 (setup-users)"
        log_error "O use: mkdir -p ${missing_dirs[*]}"
        exit 1
    fi
    
    # Verificar users-status.json
    if [[ -f "$PHASE2_STATUS" ]]; then
        log_ok "FASE 2 detectada"
    else
        log_warn "users-status.json no encontrado (FASE 2 puede no haberse ejecutado)"
    fi
    
    log_ok "Directorios de FASE 2 validados"
}

# -----------------------------------------------------------------------------
# VERIFICAR REQUISITOS
# -----------------------------------------------------------------------------

check_requirements() {
    log_info "=== VERIFICANDO REQUISITOS ==="
    
    # Node.js (CRÍTICO)
    if command -v node &>/dev/null; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//')
        local node_major=$(echo "$node_version" | cut -d. -f1)
        
        if [[ $node_major -ge 18 ]]; then
            log_ok "Node.js: v${node_version}"
            CHECKS+=("{\"name\": \"node_version\", \"status\": \"passed\", \"value\": \"v${node_version}\"}")
        else
            log_error "Node.js versión antigua: v${node_version} (requiere >= 18)"
            ERRORS+=("Node.js versión antigua")
            CHECKS+=("{\"name\": \"node_version\", \"status\": \"error\", \"value\": \"v${node_version}\"}")
        fi
    else
        log_error "Node.js no instalado"
        ERRORS+=("Node.js no instalado")
        CHECKS+=("{\"name\": \"node_version\", \"status\": \"error\", \"value\": \"not_installed\"}")
    fi
    
    # npm
    if command -v npm &>/dev/null; then
        local npm_version
        npm_version=$(npm --version 2>/dev/null)
        local npm_major=$(echo "$npm_version" | cut -d. -f1)
        
        if [[ $npm_major -ge 9 ]]; then
            log_ok "npm: ${npm_version}"
            CHECKS+=("{\"name\": \"npm_version\", \"status\": \"passed\", \"value\": \"${npm_version}\"}")
        else
            log_warn "npm versión antigua: ${npm_version} (requiere >= 9)"
            WARNINGS+=("npm versión antigua")
            CHECKS+=("{\"name\": \"npm_version\", \"status\": \"warning\", \"value\": \"${npm_version}\"}")
        fi
    else
        log_error "npm no instalado"
        ERRORS+=("npm no instalado")
        CHECKS+=("{\"name\": \"npm_version\", \"status\": \"error\", \"value\": \"not_installed\"}")
    fi
    
    # Puerto
    if ss -tuln 2>/dev/null | grep -q ":${GATEWAY_PORT} "; then
        log_warn "Puerto ${GATEWAY_PORT} está en uso"
        WARNINGS+=("Puerto ${GATEWAY_PORT} en uso")
        CHECKS+=("{\"name\": \"port_available\", \"status\": \"warning\", \"value\": \"${GATEWAY_PORT}\"}")
    else
        log_ok "Puerto ${GATEWAY_PORT} disponible"
        CHECKS+=("{\"name\": \"port_available\", \"status\": \"passed\", \"value\": \"${GATEWAY_PORT}\"}")
    fi
    
    # API key
    if [[ -n "$OLLAMA_API_KEY" ]]; then
        log_ok "API key proporcionada (${OLLAMA_API_KEY:0:10}...)"
        CHECKS+=("{\"name\": \"api_key\", \"status\": \"provided\"}")
    else
        log_warn "API key no proporcionada - Se solicitará más adelante"
        WARNINGS+=("API key no proporcionada")
        CHECKS+=("{\"name\": \"api_key\", \"status\": \"missing\"}")
    fi
    
    echo ""
}

# -----------------------------------------------------------------------------
# DETECTAR GATEWAY EXISTENTE
# -----------------------------------------------------------------------------

detect_gateway() {
    log_info "=== DETECTANDO GATEWAY EXISTENTE ==="
    
    local gateway_path
    gateway_path=$(which openclaw-gateway 2>/dev/null || echo "")
    
    if [[ -n "$gateway_path" ]]; then
        log_ok "Gateway encontrado: $gateway_path"
        
        # Verificar si está corriendo
        if pgrep -f "openclaw-gateway" &>/dev/null; then
            log_ok "Gateway está corriendo"
            CHECKS+=("{\"name\": \"gateway_installed\", \"status\": \"existing\", \"running\": true}")
        else
            log_warn "Gateway instalado pero no corriendo"
            WARNINGS+=("Gateway no está corriendo")
            CHECKS+=("{\"name\": \"gateway_installed\", \"status\": \"existing\", \"running\": false}")
        fi
        
        return 0
    else
        log_info "Gateway no instalado"
        CHECKS+=("{\"name\": \"gateway_installed\", \"status\": \"not_installed\"}")
        return 1
    fi
    
    echo ""
}

# -----------------------------------------------------------------------------
# VALIDAR API KEY
# -----------------------------------------------------------------------------

validate_api_key() {
    log_info "=== VALIDANDO API KEY ==="
    
    if [[ -z "$OLLAMA_API_KEY" ]]; then
        log_warn "API key no proporcionada"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warn "[DRY-RUN] Se solicitaría API key interactivamente"
            return 0
        fi
        
        # Solicitar interactivamente
        echo -n "Ingrese su API key de Ollama Cloud: "
        read -s OLLAMA_API_KEY
        echo ""
        
        if [[ -z "$OLLAMA_API_KEY" ]]; then
            log_error "API key es obligatoria"
            ERRORS+=("API key es obligatoria")
            return 1
        fi
    fi
    
    # Validar formato
    if [[ ! "$OLLAMA_API_KEY" =~ ^os_ ]]; then
        log_error "API key inválida (debe empezar con 'os_')"
        ERRORS+=("API key con formato inválido")
        return 1
    fi
    
    log_ok "API key válida (formato correcto)"
    
    # TODO: Validar contra API de Ollama
    # Por ahora solo validamos formato
    
    CHECKS+=("{\"name\": \"api_key_valid\", \"status\": \"passed\", \"key_prefix\": \"${OLLAMA_API_KEY:0:10}\"}")
    
    echo ""
}

# -----------------------------------------------------------------------------
# CONFIGURAR GATEWAY
# -----------------------------------------------------------------------------

configure_gateway() {
    log_info "=== CONFIGURANDO GATEWAY ==="
    
    local config_dir="${HOME}/.openclaw/config"
    local config_file="${config_dir}/gateway.json"
    
    # Crear directorio si no existe
    if [[ ! -d "$config_dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warn "[DRY-RUN] Se crearían: $config_dir"
        else
            mkdir -p "$config_dir"
            chmod 700 "$config_dir"
            log_ok "Creado: $config_dir (permisos 700)"
        fi
    fi
    
    # Marcar para cleanup en caso de falla
    CLEANUP_CONFIG=true
    
    # Crear configuración
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "[DRY-RUN] Se crearía: $config_file"
    else
        cat > "$config_file" <<EOF
{
  "gateway": {
    "name": "openclaw-gateway",
    "version": "${VERSION}",
    "host": "${GATEWAY_HOST}",
    "port": ${GATEWAY_PORT},
    "logLevel": "info"
  },
  "api": {
    "ollama": {
      "enabled": true,
      "apiKey": "${OLLAMA_API_KEY}",
      "baseUrl": "https://api.ollama.cloud/v1"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": ""
    },
    "whatsapp": {
      "enabled": true,
      "sessionId": "default"
    },
    "discord": {
      "enabled": true,
      "token": ""
    }
  },
  "memory": {
    "enabled": true,
    "path": "${HOME}/.openclaw/data/memory"
  },
  "logging": {
    "path": "${HOME}/.openclaw/logs",
    "level": "info",
    "maxSize": "10M",
    "maxFiles": 5
  }
}
EOF
        # Permisos restrictivos para proteger API key
        chmod 600 "$config_file"
        log_ok "Creado: $config_file (permisos 600)"
        CHECKS+=("{\"name\": \"gateway_config\", \"status\": \"created\"}")
    fi
    
    echo ""
}

# -----------------------------------------------------------------------------
# CREAR SYSTEMD SERVICE
# -----------------------------------------------------------------------------

create_systemd_service() {
    log_info "=== CREANDO SYSTEMD SERVICE ==="
    
    local service_dir="${HOME}/.config/systemd/user"
    local service_file="${service_dir}/openclaw-gateway.service"
    
    # Marcar para cleanup
    CLEANUP_SERVICE=true
    
    # Verificar que systemd está disponible
    if ! command -v systemctl &>/dev/null; then
        log_warn "systemd no disponible - El service se creará pero no se habilitará"
        WARNINGS+=("systemd no disponible")
    fi
    
    # Verificar que el binary existe
    local binary_path="/usr/local/bin/openclaw-gateway"
    if [[ ! -x "$binary_path" ]]; then
        log_warn "Binary no encontrado: $binary_path"
        log_warn "El service se creará pero no podrá iniciar hasta que se instale el binary"
        WARNINGS+=("Binary no encontrado")
    fi
    
    # Crear directorio si no existe
    if [[ ! -d "$service_dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warn "[DRY-RUN] Se crearían: $service_dir"
        else
            mkdir -p "$service_dir"
            log_ok "Creado: $service_dir"
        fi
    fi
    
    # Crear service
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "[DRY-RUN] Se crearía: $service_file"
    else
        cat > "$service_file" <<EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/openclaw-gateway --config ${HOME}/.openclaw/config/gateway.json
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
        log_ok "Creado: $service_file"
        CHECKS+=("{\"name\": \"systemd_service\", \"status\": \"created\"}")
        
        # Recargar systemd
        systemctl --user daemon-reload 2>/dev/null || true
    fi
    
    echo ""
}

# -----------------------------------------------------------------------------
# GENERAR REPORTE
# -----------------------------------------------------------------------------

generate_report() {
    log_info "=== GENERANDO REPORTE ==="
    
    local timestamp
    timestamp=$(date -Iseconds)
    
    # gateway-status.json
    cat > "${HOME}/.openclaw/gateway-status.json" <<EOF
{
  "generated_at": "${timestamp}",
  "version": "${VERSION}",
  "gateway": {
    "host": "${GATEWAY_HOST}",
    "port": ${GATEWAY_PORT},
    "url": "http://${GATEWAY_HOST}:${GATEWAY_PORT}"
  },
  "api_key": {
    "provider": "ollama",
    "configured": $([ -n "$OLLAMA_API_KEY" ] && echo "true" || echo "false")
  },
  "checks": [$(IFS=,; echo "${CHECKS[*]}")],
  "warnings": $(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]"),
  "errors": $(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
}
EOF
    
    log_ok "Generado: ${HOME}/.openclaw/gateway-status.json"
    
    # Resumen final
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          GATEWAY INSTALL CONFIGURADO                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        log_error "ERRORES:"
        for err in "${ERRORS[@]}"; do
            log_error "  ✗ $err"
        done
        exit 1
    elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
        log_warn "WARNINGS:"
        for warn in "${WARNINGS[@]}"; do
            log_warn "  ⚠ $warn"
        done
    else
        log_ok "Todo configurado correctamente"
    fi
    
    echo ""
    log_info "Gateway URL: ${CYAN}http://${GATEWAY_HOST}:${GATEWAY_PORT}${NC}"
    log_info "Config: ${CYAN}${HOME}/.openclaw/config/gateway.json${NC}"
    echo ""
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Para iniciar el gateway:"
        echo -e "  ${CYAN}systemctl --user start openclaw-gateway${NC}"
        echo -e "  ${CYAN}systemctl --user enable openclaw-gateway${NC}"
        echo ""
    fi
    
    exit 0
}

# -----------------------------------------------------------------------------
# ENCABEZADO
# -----------------------------------------------------------------------------

show_header() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          TURNKEY v6 - FASE 3: GATEWAY INSTALL                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main() {
    parse_args "$@"
    show_header
    
    log_info "Puerto: ${GATEWAY_PORT}"
    log_info "Host: ${GATEWAY_HOST}"
    [[ "$DRY_RUN" == "true" ]] && log_warn "MODO DRY-RUN - No se harán cambios"
    echo ""
    
    # Validar fases previas (CRÍTICO - agregado en corrección)
    validate_phase1
    validate_phase2
    
    # Validar requisitos del sistema
    check_requirements
    
    # Abortar si hay errores críticos
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        log_error "Se encontraron errores críticos. Corríjalos antes de continuar."
        for error in "${ERRORS[@]}"; do
            log_error "  - $error"
        done
        exit 1
    fi
    
    # Detectar gateway existente
    detect_gateway || true
    
    # Validar API key
    validate_api_key
    
    # Configurar gateway
    configure_gateway
    create_systemd_service
    generate_report
    
    # Marcar como exitoso para evitar cleanup
    mark_success
    
    log_ok "FASE 3 completada exitosamente"
}

main "$@"