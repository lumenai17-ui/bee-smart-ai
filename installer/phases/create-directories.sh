#!/bin/bash
# ==============================================================================
# TURNKEY v6 - FASE 2: Creación de Estructura de Directorios
# ==============================================================================
# Este script crea la estructura de directorios para agentes OpenClaw:
# 
# /home/bee-{nombre}/.openclaw/
# ├── config/      (700) - API keys y configuración sensible
# ├── workspace/   (755) - Archivos de trabajo del agente
# ├── logs/        (755) - Logs del agente
# └── data/        (755) - Datos persistentes
#
# Permisos:
# - config/ : 700 (solo el propietario puede acceder)
# - resto   : 755 (acceso de lectura/ejecución para otros)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# VALIDACIÓN DE DEPENDENCIAS (al inicio, antes de procesar)
# ==============================================================================

# Verificar que jq está disponible para output JSON
if [[ "$*" == *"--json"* ]]; then
    if ! command -v jq &>/dev/null; then
        echo "Error: jq no está instalado. Instala con: sudo apt install jq"
        exit 1
    fi
fi

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================
readonly SCRIPT_NAME="create-directories"
readonly SCRIPT_VERSION="6.0.0"
readonly USER_PREFIX="bee-"

# Permisos
readonly PERM_CONFIG=700
readonly PERM_STANDARD=755

# Directorios a crear
readonly OPENCLAW_DIR=".openclaw"
readonly -a SUBDIRECTORIES=(
    "config"
    "workspace"
    "logs"
    "data"
)

# Archivos README para cada directorio
declare -A DIR_DESCRIPTIONS=(
    ["config"]="API keys y configuración sensible (protegido 700)"
    ["workspace"]="Archivos de trabajo del agente"
    ["logs"]="Logs y archivos de registro"
    ["data"]="Datos persistentes del agente"
)

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Archivo de log
readonly LOG_FILE="/var/log/turnkey/setup-users.log"

# ==============================================================================
# FUNCIONES DE UTILIDAD
# ==============================================================================

# Log con timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Crear directorio de log si no existe
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
    fi
    
    # Escribir a archivo
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    
    # Output a consola según nivel
    case "$level" in
        INFO)
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[!]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[✗]${NC} $message" >&2
            ;;
        DEBUG)
            echo -e "${CYAN}[?]${NC} $message"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

log_info() { log "INFO" "$*"; }
log_warn() { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }
log_debug() { log "DEBUG" "$*"; }

# Mostrar uso del script
show_usage() {
    cat << EOF
Uso: $(basename "$0") [OPCIONES]

Crea la estructura de directorios para un agente OpenClaw.

Opciones:
    -n, --name NOMBRE    Nombre del agente (sin prefijo bee-)
    -u, --username USER  Nombre de usuario completo (con prefijo bee-)
    -v, --verbose        Mostrar información detallada
    -d, --dry-run        Simular sin hacer cambios
    -j, --json           Salida en formato JSON
    -h, --help           Mostrar esta ayuda

Ejemplos:
    $(basename "$0") --name restaurante
    $(basename "$0") --username bee-hotel --verbose
    $(basename "$0") --name tienda --dry-run

EOF
}

# ==============================================================================
# VALIDACIONES
# ==============================================================================

# Verificar permisos de root
check_root_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script requiere permisos de root/sudo"
        log_info "Ejecuta con: sudo $0 $*"
        return 1
    fi
    return 0
}

# Verificar que existe el usuario
# Argumentos:
#   $1 - Nombre del usuario
# Retorna:
#   0 si existe, 1 si no
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# ==============================================================================
# FUNCIONES DE DIRECTORIOS
# ==============================================================================

# Crear estructura de directorios
# Argumentos:
#   $1 - Nombre del agente (sin prefijo)
#   $2 - Dry run (opcional: true/false)
#   $3 - Verbose (opcional: true/false)
# Retorna:
#   0 si exitoso, 1 si error
create_directories() {
    local agent_name="$1"
    local dry_run="${2:-false}"
    local verbose="${3:-false}"
    
    local username="${USER_PREFIX}${agent_name}"
    local home_dir="/home/${username}"
    local openclaw_dir="${home_dir}/${OPENCLAW_DIR}"
    
    # Verificar que el usuario existe
    if [[ "$dry_run" == "false" ]]; then
        if ! user_exists "$username"; then
            log_error "El usuario '$username' no existe. Crea primero el usuario."
            return 1
        fi
    fi
    
    log_info "Creando estructura de directorios para: $username"
    log_debug "Directorio base: $openclaw_dir"
    
    # Verificar si ya existe la estructura
    if [[ -d "$openclaw_dir" ]]; then
        log_warn "El directorio '$openclaw_dir' ya existe"
        if [[ "$dry_run" == "false" ]]; then
            log_warn "Verificando permisos y propietario..."
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "[DRY-RUN] Se crearía la siguiente estructura:"
        echo "  $openclaw_dir/ (755)"
        for subdir in "${SUBDIRECTORIES[@]}"; do
            local perm=$PERM_STANDARD
            if [[ "$subdir" == "config" ]]; then
                perm=$PERM_CONFIG
            fi
            echo "  ├── $subdir/ ($perm)"
        done
        return 0
    fi
    
    # Crear directorio base .openclaw
    if [[ ! -d "$openclaw_dir" ]]; then
        if ! mkdir -p "$openclaw_dir"; then
            log_error "Error al crear directorio: $openclaw_dir"
            return 1
        fi
        log_info "Creado: $openclaw_dir"
    fi
    
    # Crear subdirectorios
    local count=0
    for subdir in "${SUBDIRECTORIES[@]}"; do
        local full_path="${openclaw_dir}/${subdir}"
        local perm=$PERM_STANDARD
        
        # config/ tiene permisos restrictivos
        if [[ "$subdir" == "config" ]]; then
            perm=$PERM_CONFIG
        fi
        
        # Crear directorio si no existe
        if [[ ! -d "$full_path" ]]; then
            if ! mkdir -p "$full_path"; then
                log_error "Error al crear directorio: $full_path"
                return 1
            fi
        fi
        
        # Configurar permisos
        if ! chmod "$perm" "$full_path"; then
            log_error "Error al establecer permisos $perm en: $full_path"
            return 1
        fi
        
        log_info "Creado: $subdir/ ($perm)"
        ((count++)) || true
    done
    
    # Configurar propietario
    if ! chown -R "${username}:${username}" "$openclaw_dir"; then
        log_error "Error al cambiar propietario de: $openclaw_dir"
        return 1
    fi
    
    # Crear archivos README.md en cada directorio
    if [[ "$verbose" == "true" ]]; then
        for subdir in "${SUBDIRECTORIES[@]}"; do
            local full_path="${openclaw_dir}/${subdir}"
            local readme_path="${full_path}/README.md"
            
            if [[ ! -f "$readme_path" ]]; then
                cat > "$readme_path" << EOF
# OpenClaw Agent Directory: $subdir

${DIR_DESCRIPTIONS[$subdir]}

## Información

- **Agente:** $agent_name
- **Usuario:** $username
- **Permisos:** $(ls -ld "$full_path" | cut -c1-10)
- **Creado:** $(date '+%Y-%m-%d %H:%M:%S')

---
*Generado por TURNKEY v6 - FASE 2*
EOF
                chown "${username}:${username}" "$readme_path"
                log_debug "Creado: $subdir/README.md"
            fi
        done
    fi
    
    # Crear archivo .gitkeep para asegurar que los directorios se rastrean
    for subdir in "${SUBDIRECTORIES[@]}"; do
        local full_path="${openclaw_dir}/${subdir}"
        local gitkeep="${full_path}/.gitkeep"
        
        if [[ ! -f "$gitkeep" ]]; then
            touch "$gitkeep"
            chown "${username}:${username}" "$gitkeep"
        fi
    done
    
    log_info "Estructura creada: $count directorios"
    return 0
}

# Verificar estructura existente
# Argumentos:
#   $1 - Nombre del agente (sin prefijo)
# Retorna:
#   0 si la estructura es correcta, 1 si hay problemas
verify_directories() {
    local agent_name="$1"
    local username="${USER_PREFIX}${agent_name}"
    local home_dir="/home/${username}"
    local openclaw_dir="${home_dir}/${OPENCLAW_DIR}"
    
    local issues=0
    
    echo -e "\n${CYAN}Verificando estructura para: $username${NC}\n"
    
    # Verificar directorio base
    if [[ ! -d "$openclaw_dir" ]]; then
        log_error "No existe: $openclaw_dir"
        ((issues++)) || true
    else
        # Verificar propietario
        local owner
        owner=$(stat -c '%U' "$openclaw_dir")
        if [[ "$owner" != "$username" ]]; then
            log_error "Propietario incorrecto en $openclaw_dir: $owner (esperado: $username)"
            ((issues++)) || true
        else
            log_info "OK: Propietario de .openclaw/ - $username"
        fi
    fi
    
    # Verificar subdirectorios
    for subdir in "${SUBDIRECTORIES[@]}"; do
        local full_path="${openclaw_dir}/${subdir}"
        local expected_perm=$PERM_STANDARD
        if [[ "$subdir" == "config" ]]; then
            expected_perm=$PERM_CONFIG
        fi
        
        if [[ ! -d "$full_path" ]]; then
            log_error "No existe: $subdir/"
            ((issues++)) || true
            continue
        fi
        
        # Verificar permisos
        local actual_perm
        actual_perm=$(stat -c '%a' "$full_path")
        if [[ "$actual_perm" != "$expected_perm" ]]; then
            log_warn "Permisos incorrectos en $subdir/: $actual_perm (esperado: $expected_perm)"
        else
            log_info "OK: $subdir/ ($actual_perm)"
        fi
        
        # Verificar propietario
        local owner
        owner=$(stat -c '%U' "$full_path")
        if [[ "$owner" != "$username" ]]; then
            log_error "Propietario incorrecto en $subdir/: $owner (esperado: $username)"
            ((issues++)) || true
        fi
    done
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        log_info "Verificación exitosa: sin problemas detectados"
        return 0
    else
        log_error "Verificación fallida: $issues problema(s) detectado(s)"
        return 1
    fi
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    local agent_name=""
    local username=""
    local verbose=false
    local dry_run=false
    local output_json=false
    local verify_only=false
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                agent_name="$2"
                shift 2
                ;;
            -u|--username)
                username="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -j|--json)
                output_json=true
                shift
                ;;
            --verify)
                verify_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Opción desconocida: $1"
                show_usage
                exit 1
                ;;
            *)
                # Argumento posicional
                if [[ -z "$agent_name" && -z "$username" ]]; then
                    # Si empieza con "bee-", es un username
                    if [[ "$1" == bee-* ]]; then
                        username="$1"
                    else
                        agent_name="$1"
                    fi
                fi
                shift
                ;;
        esac
    done
    
    # Si se especificó username, extraer agent_name
    if [[ -n "$username" ]]; then
        if [[ "$username" == bee-* ]]; then
            agent_name="${username#bee-}"
        else
            log_error "El username debe comenzar con 'bee-'"
            exit 1
        fi
    fi
    
    # Modo interactivo si no se especificó nombre
    if [[ -z "$agent_name" ]]; then
        echo -e "${CYAN}?${NC} Introduce el nombre del agente: "
        read -r agent_name
        if [[ -z "$agent_name" ]]; then
            log_error "El nombre del agente es obligatorio"
            exit 1
        fi
    fi
    
    username="${USER_PREFIX}${agent_name}"
    
    # Verificar permisos (excepto en dry-run)
    if [[ "$dry_run" == "false" ]]; then
        if ! check_root_permissions "$@"; then
            exit 1
        fi
    fi
    
    # Modo verificación
    if [[ "$verify_only" == "true" ]]; then
        if verify_directories "$agent_name"; then
            exit 0
        else
            exit 1
        fi
    fi
    
    # Crear directorios
    if ! create_directories "$agent_name" "$dry_run" "$verbose"; then
        exit 1
    fi
    
    # Output
    if [[ "$output_json" == "true" ]]; then
        local home_dir="/home/${username}"
        local openclaw_dir="${home_dir}/${OPENCLAW_DIR}"
        
        cat << EOF
{
    "success": true,
    "agent_name": "${agent_name}",
    "username": "${username}",
    "home_directory": "${home_dir}",
    "openclaw_directory": "${openclaw_dir}",
    "subdirectories": $(printf '%s\n' "${SUBDIRECTORIES[@]}" | jq -R . | jq -s .),
    "permissions": {
        "config": "${PERM_CONFIG}",
        "standard": "${PERM_STANDARD}"
    },
    "dry_run": ${dry_run},
    "verbose": ${verbose},
    "created_at": "$(date -Iseconds)",
    "created_by": "${SCRIPT_NAME}",
    "version": "${SCRIPT_VERSION}"
}
EOF
    fi
    
    exit 0
}

# ==============================================================================
# EJECUCIÓN
# ==============================================================================

main "$@"