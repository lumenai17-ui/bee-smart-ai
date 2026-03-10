#!/bin/bash
# =============================================================================
# validate-user.sh - Valida que el usuario tiene los permisos necesarios
# TURNKEY v6 - FASE 2: SETUP USERS
# =============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Valores por defecto
AGENT_USER="$(whoami)"

# Inicializar arrays (evita error si no se ejecuta validate_user)
declare -a ISSUES=()
declare -a WARNINGS=()

# -----------------------------------------------------------------------------
# PARSEAR ARGUMENTOS
# -----------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user) AGENT_USER="$2"; shift 2 ;;
            --help)
                echo "Uso: $0 [--user USER]"
                exit 0
                ;;
            *) shift ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# VALIDAR USUARIO
# -----------------------------------------------------------------------------

validate_user() {
    local user="$AGENT_USER"
    local valid=true
    
    # Verificar que el usuario existe
    if ! id "$user" &>/dev/null; then
        ISSUES+=("Usuario $user no existe")
        valid=false
    fi
    
    # Verificar UID
    local uid
    uid=$(id -u "$user" 2>/dev/null || echo "unknown")
    
    if [[ "$uid" == "0" ]]; then
        WARNINGS+=("Usuario root no recomendado")
    fi
    
    # Verificar HOME
    local home
    home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
    
    if [[ -z "$home" ]]; then
        ISSUES+=("Usuario sin directorio HOME")
        valid=false
    elif [[ ! -d "$home" ]]; then
        ISSUES+=("Directorio HOME no existe: $home")
        valid=false
    fi
    
    # Verificar SHELL
    local shell
    shell=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)
    
    if [[ -z "$shell" ]] || [[ "$shell" == "/usr/sbin/nologin" ]] || [[ "$shell" == "/bin/false" ]]; then
        ISSUES+=("Usuario sin shell válido")
        valid=false
    fi
    
    # Verificar grupos necesarios
    local groups
    groups=$(id -Gn "$user" 2>/null || echo "")
    
    # Verificar sudo
    if echo "$groups" | grep -qE "sudo|wheel"; then
        : # OK
    else
        WARNINGS+=("Usuario sin grupo sudo/wheel")
    fi
    
    # Output JSON
    local status="passed"
    [[ ${#ISSUES[@]} -gt 0 ]] && status="failed"
    [[ ${#WARNINGS[@]} -gt 0 ]] && status="warning"
    
    cat <<EOF
{
  "user": "$user",
  "uid": $uid,
  "home": "${home:-unknown}",
  "shell": "${shell:-unknown}",
  "groups": "$(echo "$groups" | tr ' ' ',')",
  "valid": $valid,
  "status": "$status",
  "issues": $(printf '%s\n' "${ISSUES[@]}" 2>/dev/null | jq -R . | jq -s . 2>/dev/null || echo "[]"),
  "warnings": $(printf '%s\n' "${WARNINGS[@]}" 2>/dev/null | jq -R . | jq -s . 2>/dev/null || echo "[]")
}
EOF
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

parse_args "$@"
validate_user