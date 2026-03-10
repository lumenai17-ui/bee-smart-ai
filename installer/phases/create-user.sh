#!/bin/bash
# ==============================================================================
# TURNKEY v6 - FASE 2: Creación de Usuarios
# ==============================================================================
# Este script crea usuarios del sistema con el prefijo "bee-" para agentes
# de OpenClaw. Cada usuario se crea con:
# - Home directory propio
# - Shell configurada
# - Sin grupos adicionales (máximo aislamiento)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================
readonly SCRIPT_NAME="create-user"
readonly SCRIPT_VERSION="6.0.0"
readonly USER_PREFIX="bee-"
readonly DEFAULT_SHELL="/bin/bash"

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

Crea un usuario del sistema con prefijo bee- para agentes OpenClaw.

Opciones:
    -n, --name NOMBRE    Nombre del agente (sin prefijo bee-)
    -p, --password PASS  Contraseña (si no se especifica, se genera)
    -s, --shell SHELL    Shell del usuario (default: /bin/bash)
    -d, --dry-run         Simular sin hacer cambios
    -j, --json            Salida en formato JSON
    -h, --help            Mostrar esta ayuda

Ejemplos:
    $(basename "$0") --name restaurante
    $(basename "$0") --name hotel --dry-run
    $(basename "$0") --name tienda --password 'MiPass123!'

EOF
}

# ==============================================================================
# VALIDACIONES
# ==============================================================================

# Nombres reservados que no se pueden usar
readonly RESERVED_NAMES=(
    "root"
    "admin"
    "administrator"
    "user"
    "bee"
    "daemon"
    "bin"
    "sys"
    "sync"
    "games"
    "man"
    "lp"
    "mail"
    "news"
    "uucp"
    "proxy"
    "www-data"
    "backup"
    "list"
    "irc"
    "gnats"
    "nobody"
    "systemd-network"
    "systemd-resolve"
    "messagebus"
    "syslog"
)

# Validar nombre del agente
# Argumentos:
#   $1 - Nombre a validar
# Retorna:
#   0 si es válido, 1 si no
validate_name() {
    local name="$1"
    
    # Verificar que no está vacío
    if [[ -z "$name" ]]; then
        log_error "El nombre no puede estar vacío"
        return 1
    fi
    
    # Verificar longitud (máximo 32 caracteres)
    if [[ ${#name} -gt 32 ]]; then
        log_error "El nombre no puede tener más de 32 caracteres (actual: ${#name})"
        return 1
    fi
    
    # Verificar longitud mínima
    if [[ ${#name} -lt 2 ]]; then
        log_error "El nombre debe tener al menos 2 caracteres"
        return 1
    fi
    
    # Verificar formato (solo alfanumérico y guiones)
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_error "El nombre debe comenzar con letra minúscula y contener solo letras, números y guiones"
        return 1
    fi
    
    # Verificar que no termina con guión
    if [[ "$name" == *- ]]; then
        log_error "El nombre no puede terminar con guión"
        return 1
    fi
    
    # Verificar que no tiene guiones consecutivos
    if [[ "$name" == *--* ]]; then
        log_error "El nombre no puede tener guiones consecutivos"
        return 1
    fi
    
    # Verificar que no es un nombre reservado
    local lower_name
    lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    for reserved in "${RESERVED_NAMES[@]}"; do
        if [[ "$lower_name" == "$reserved" ]]; then
            log_error "El nombre '$name' está reservado y no puede usarse"
            return 1
        fi
    done
    
    return 0
}

# Verificar permisos de root
check_root_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script requiere permisos de root/sudo"
        log_info "Ejecuta con: sudo $0 $*"
        return 1
    fi
    return 0
}

# ==============================================================================
# FUNCIONES DE USUARIO
# ==============================================================================

# Verificar si existe un usuario
# Argumentos:
#   $1 - Nombre del usuario
# Retorna:
#   0 si existe, 1 si no
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# Obtener el path del script generate-password.sh
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Generar contraseña segura
generate_password() {
    local script_dir
    script_dir=$(get_script_dir)
    local gen_script="${script_dir}/generate-password.sh"
    
    # Verificar que existe el script
    if [[ ! -x "$gen_script" ]]; then
        log_error "No se encuentra el script: $gen_script"
        return 1
    fi
    
    # Ejecutar script y obtener contraseña
    "$gen_script" --json
}

# Crear usuario del sistema
# Argumentos:
#   $1 - Nombre del agente (sin prefijo)
#   $2 - Contraseña
#   $3 - Shell (opcional)
#   $4 - Dry run (opcional: true/false)
# Retorna:
#   0 si exitoso, 1 si error
create_user() {
    local agent_name="$1"
    local password="$2"
    local shell="${3:-$DEFAULT_SHELL}"
    local dry_run="${4:-false}"
    
    local username="${USER_PREFIX}${agent_name}"
    local home_dir="/home/${username}"
    
    log_info "Creando usuario: $username"
    
    # Verificar que no existe
    if user_exists "$username"; then
        log_error "El usuario '$username' ya existe"
        return 1
    fi
    
    # Verificar que el home no existe
    if [[ -d "$home_dir" ]]; then
        log_error "El directorio home '$home_dir' ya existe"
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "[DRY-RUN] Se crearía el usuario: $username"
        log_warn "[DRY-RUN] Home: $home_dir"
        log_warn "[DRY-RUN] Shell: $shell"
        return 0
    fi
    
    # Crear usuario con useradd
    # Opciones:
    #   -m: crear home directory
    #   -s: shell
    #   -N: no crear grupo con el mismo nombre (usamos -g principal)
    #   -U: crear grupo con el mismo nombre del usuario
    #   -r: sistema (no es necesario para usuarios de agentes)
    if ! useradd -m -s "$shell" -U "$username" 2>&1; then
        log_error "Error al crear usuario '$username'"
        return 1
    fi
    
    # Asignar contraseña
    if ! echo "$username:$password" | chpasswd 2>&1; then
        log_error "Error al asignar contraseña para '$username'"
        # Intentar revertir
        userdel -r "$username" 2>/dev/null || true
        return 1
    fi
    
    # Forzar cambio de contraseña en primer login (opcional, comentado)
    # chage -d 0 "$username"
    
    # Bloquear cuenta hasta que sea necesario (opcional, comentado)
    # passwd -l "$username"
    
    log_info "Usuario '$username' creado exitosamente"
    return 0
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    local agent_name=""
    local password=""
    local shell="$DEFAULT_SHELL"
    local dry_run=false
    local output_json=false
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                agent_name="$2"
                shift 2
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            -s|--shell)
                shell="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -j|--json)
                output_json=true
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
                # Argumento posicional: nombre del agente
                if [[ -z "$agent_name" ]]; then
                    agent_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Modo interactivo si no se especificó nombre
    if [[ -z "$agent_name" ]]; then
        echo -e "${CYAN}?${NC} Introduce el nombre del agente: "
        read -r agent_name
        if [[ -z "$agent_name" ]]; then
            log_error "El nombre del agente es obligatorio"
            exit 1
        fi
    fi
    
    # Validar nombre
    if ! validate_name "$agent_name"; then
        exit 1
    fi
    
    local username="${USER_PREFIX}${agent_name}"
    
    # Verificar permisos (excepto en dry-run)
    if [[ "$dry_run" == "false" ]]; then
        if ! check_root_permissions "$@"; then
            exit 1
        fi
    fi
    
    # Generar contraseña si no se especificó
    local password_data
    if [[ -z "$password" ]]; then
        log_info "Generando contraseña segura..."
        password_data=$(generate_password)
        if [[ $? -ne 0 ]]; then
            log_error "Error al generar contraseña"
            exit 1
        fi
        password=$(echo "$password_data" | grep -o '"password": "[^"]*"' | cut -d'"' -f4)
    fi
    
    # Crear usuario
    if ! create_user "$agent_name" "$password" "$shell" "$dry_run"; then
        exit 1
    fi
    
    # Output
    if [[ "$output_json" == "true" ]]; then
        local home_dir="/home/${username}"
        cat << EOF
{
    "success": true,
    "agent_name": "${agent_name}",
    "username": "${username}",
    "home_directory": "${home_dir}",
    "shell": "${shell}",
    "password_generated": $([ -z "${2:-}" ] && echo 'true' || echo 'false'),
    "dry_run": ${dry_run},
    "created_at": "$(date -Iseconds)",
    "created_by": "${SCRIPT_NAME}",
    "version": "${SCRIPT_VERSION}"
}
EOF
    else
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  Usuario creado exitosamente                               ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  Usuario:    ${CYAN}$username${NC}"
        echo -e "${GREEN}║  Home:       ${home_dir}-${NC}"
        echo -e "${GREEN}║  Shell:      ${shell}${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║  ${YELLOW}[IMPORTANTE]${NC} Guarda esta contraseña de forma segura${NC}"
        echo -e "${GREEN}║  Contraseña: ${CYAN}$password${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
    
    exit 0
}

# ==============================================================================
# EJECUCIÓN
# ==============================================================================

main "$@"