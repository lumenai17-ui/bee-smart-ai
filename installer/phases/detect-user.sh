#!/bin/bash
# =============================================================================
# detect-user.sh - Detecta el usuario actual y sus permisos
# TURNKEY v6 - FASE 2: SETUP USERS
# =============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# DETECTAR USUARIO ACTUAL
# -----------------------------------------------------------------------------

detect_current_user() {
    local current_user
    current_user=$(whoami 2>/dev/null || echo "unknown")
    
    local uid
    uid=$(id -u 2>/dev/null || echo "unknown")
    
    local gid
    gid=$(id -g 2>/dev/null || echo "unknown")
    
    local groups
    groups=$(id -Gn 2>/dev/null | tr ' ' ',' || echo "")
    
    local is_root="false"
    [[ "$uid" == "0" ]] && is_root="true"
    
    # Verificar sudo
    local has_sudo="false"
    local sudo_nopasswd="false"
    
    if command -v sudo &>/dev/null; then
        if sudo -n true 2>/dev/null; then
            has_sudo="true"
            sudo_nopasswd="true"
        elif groups "$current_user" 2>/dev/null | grep -q sudo; then
            has_sudo="true"
            sudo_nopasswd="false"
        elif groups "$current_user" 2>/dev/null | grep -q wheel; then
            has_sudo="true"
            sudo_nopasswd="false"
        fi
    fi
    
    # Output JSON
    cat <<EOF
{
  "current_user": "$current_user",
  "uid": $uid,
  "gid": $gid,
  "groups": "$(echo "$groups" | sed 's/,$//g')",
  "is_root": $is_root,
  "has_sudo": $has_sudo,
  "sudo_nopasswd": $sudo_nopasswd,
  "home": "${HOME:-unknown}",
  "shell": "${SHELL:-unknown}"
}
EOF
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

detect_current_user