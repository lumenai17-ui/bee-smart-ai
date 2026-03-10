#!/bin/bash
# ==============================================================================
# TURNKEY v6 - FASE 2: Generador de Contraseñas Seguras
# ==============================================================================
# Genera contraseñas seguras de 16 caracteres con:
# - Mayúsculas (A-Z)
# - Minúsculas (a-z)
# - Números (0-9)
# - Símbolos (!@#$%^&*()_+-=)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================
readonly SCRIPT_NAME="generate-password"
readonly SCRIPT_VERSION="6.0.0"
readonly PASSWORD_LENGTH=16

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# ==============================================================================
# FUNCIONES
# ==============================================================================

log_info() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*" >&2; }

show_usage() {
    cat << EOF
Uso: $(basename "$0") [OPCIONES]

Genera una contraseña segura de 16 caracteres.

Opciones:
    -j, --json           Salida en formato JSON
    -l, --length N       Longitud de contraseña (default: 16)
    -n, --no-symbols     Excluir símbolos
    -h, --help           Mostrar esta ayuda

Ejemplos:
    $(basename "$0")
    $(basename "$0") --json
    $(basename "$0") --length 20
EOF
}

# Generar número aleatorio criptográficamente seguro usando /dev/urandom
# NOTA: $RANDOM no es criptográficamente seguro, usamos /dev/urandom
crypto_random() {
    local max="$1"
    local bytes=$(( (max < 256) ? 1 : 2 ))
    local num
    num=$(od -An -N$bytes -tu$bytes /dev/urandom | tr -d ' ')
    echo $(( num % max ))
}

# Generar contraseña segura garantizando todos los tipos de caracteres
# Usa /dev/urandom para máxima seguridad (no $RANDOM)
generate_password() {
    local length="${1:-$PASSWORD_LENGTH}"
    local include_symbols="${2:-true}"
    
    # Caracteres disponibles
    local upper="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local lower="abcdefghijklmnopqrstuvwxyz"
    local numbers="0123456789"
    local symbols='!@#$%^&*()_+-='
    
    local password=""
    
    # Asegurar al menos un carácter de cada tipo requerido
    # Usamos /dev/urandom para selección aleatoria criptográficamente segura
    # 1 mayúscula
    password="${password}${upper:$(crypto_random 26):1}"
    # 1 minúscula
    password="${password}${lower:$(crypto_random 26):1}"
    # 1 número
    password="${password}${numbers:$(crypto_random 10):1}"
    # 1 símbolo (si aplica)
    if [[ "$include_symbols" == "true" ]]; then
        password="${password}${symbols:$(crypto_random 15):1}"
    fi
    
    # Pool para el resto
    local pool="${upper}${lower}${numbers}"
    if [[ "$include_symbols" == "true" ]]; then
        pool="${pool}${symbols}"
    fi
    
    # Completar hasta la longitud deseada
    local remaining=$((length - ${#password}))
    local pool_len=${#pool}
    local i
    for ((i = 0; i < remaining; i++)); do
        password="${password}${pool:$(crypto_random $pool_len):1}"
    done
    
    # Mezclar los caracteres (shuffle criptográficamente seguro)
    local shuffled=""
    while [[ -n "$password" ]]; do
        local idx=$(crypto_random ${#password})
        shuffled="${shuffled}${password:idx:1}"
        password="${password:0:idx}${password:idx+1}"
    done
    
    echo "$shuffled"
}

# Validar contraseña
validate_password() {
    local password="$1"
    local include_symbols="${2:-true}"
    
    # Longitud mínima
    [[ ${#password} -ge 16 ]] || return 1
    # Al menos una mayúscula
    [[ "$password" =~ [A-Z] ]] || return 1
    # Al menos una minúscula
    [[ "$password" =~ [a-z] ]] || return 1
    # Al menos un número
    [[ "$password" =~ [0-9] ]] || return 1
    # Al menos un símbolo si aplica
    if [[ "$include_symbols" == "true" ]]; then
        [[ "$password" =~ [^a-zA-Z0-9] ]] || return 1
    fi
    
    return 0
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    local output_json=false
    local length="$PASSWORD_LENGTH"
    local include_symbols="true"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j|--json) output_json=true; shift ;;
            -l|--length) length="$2"; shift 2 ;;
            -n|--no-symbols) include_symbols="false"; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
    
    # Generar contraseña
    local password
    password=$(generate_password "$length" "$include_symbols")
    
    # Validar
    if ! validate_password "$password" "$include_symbols"; then
        log_error "Error al generar contraseña válida"
        exit 1
    fi
    
    # Output
    if [[ "$output_json" == "true" ]]; then
        cat << EOF
{
    "password": "${password}",
    "length": ${#password},
    "include_symbols": ${include_symbols},
    "generated_at": "$(date -Iseconds)",
    "generator": "${SCRIPT_NAME}",
    "version": "${SCRIPT_VERSION}"
}
EOF
    else
        echo "$password"
    fi
    
    exit 0
}

main "$@"