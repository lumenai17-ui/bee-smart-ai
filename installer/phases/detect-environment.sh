#!/bin/bash
# =============================================================================
# detect-environment.sh - Detecta tipo de entorno (VPS vs Servidor Dedicado)
# TURNKEY v6 - FASE 1: PRE-FLIGHT
# =============================================================================
# 
# DESCRIPCIÓN:
#   Detecta si el servidor es un VPS (cloud) o un servidor dedicado/bare metal.
#   También identifica el provider cuando es posible.
#
# USO:
#   ./detect-environment.sh
#
# OUTPUT:
#   TIPO="vps"|"dedicado"
#   PROVIDER="aws"|"digitalocean"|"gcp"|"azure"|"other"|"unknown"
#   JSON a stdout con toda la información
#
# EXIT CODES:
#   0 - Éxito
#   1 - Error
#
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valores por defecto
TIPO="unknown"
PROVIDER="unknown"
DETECTION_METHOD=""

# -----------------------------------------------------------------------------
# FUNCIONES DE DETECCIÓN
# -----------------------------------------------------------------------------

# Detecta provider por metadata
detect_provider_metadata() {
    local provider=""
    
    # AWS metadata
    if curl -s -m 2 --connect-timeout 1 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null; then
        provider="aws"
        DETECTION_METHOD="metadata"
        return 0
    fi
    
    # DigitalOcean metadata
    if curl -s -m 2 --connect-timeout 1 http://169.254.169.254/metadata/v1/droplet_id &>/dev/null; then
        provider="digitalocean"
        DETECTION_METHOD="metadata"
        return 0
    fi
    
    # GCP metadata
    if curl -s -m 2 --connect-timeout 1 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id &>/dev/null; then
        provider="gcp"
        DETECTION_METHOD="metadata"
        return 0
    fi
    
    # Azure metadata
    if curl -s -m 2 --connect-timeout 1 -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2021-02-01 &>/dev/null; then
        provider="azure"
        DETECTION_METHOD="metadata"
        return 0
    fi
    
    return 1
}

# Detecta provider por hostname
detect_provider_hostname() {
    local hostname
    hostname=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")
    
    # AWS
    if [[ "$hostname" =~ ip-[0-9]+-[0-9]+-[0-9]+-[0-9]+ ]] || [[ "$hostname" =~ ec2 ]]; then
        PROVIDER="aws"
        DETECTION_METHOD="hostname"
        return 0
    fi
    
    # DigitalOcean
    if [[ "$hostname" =~ droplet ]] || [[ "$hostname" =~ do- ]]; then
        PROVIDER="digitalocean"
        DETECTION_METHOD="hostname"
        return 0
    fi
    
    # GCP
    if [[ "$hostname" =~ gke- ]] || [[ "$hostname" =~ google ]]; then
        PROVIDER="gcp"
        DETECTION_METHOD="hostname"
        return 0
    fi
    
    # Azure
    if [[ "$hostname" =~ azure ]] || [[ "$hostname" =~ vm[0-9]+ ]]; then
        PROVIDER="azure"
        DETECTION_METHOD="hostname"
        return 0
    fi
    
    return 1
}

# Detecta provider por DMI
detect_provider_dmi() {
    if [[ -f /sys/class/dmi/id/sys_vendor ]]; then
        local vendor
        vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
        
        case "$vendor" in
            "Amazon"*|"EC2"*)
                PROVIDER="aws"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "DigitalOcean")
                PROVIDER="digitalocean"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "Google"*)
                PROVIDER="gcp"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "Microsoft Corporation"*)
                PROVIDER="azure"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "Hetzner"*)
                PROVIDER="hetzner"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "Linode"*)
                PROVIDER="linode"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "Vultr"*)
                PROVIDER="vultr"
                DETECTION_METHOD="dmi"
                return 0
                ;;
            "OVH"*)
                PROVIDER="ovh"
                DETECTION_METHOD="dmi"
                return 0
                ;;
        esac
    fi
    return 1
}

# Detecta si es container virtualizado
detect_container() {
    # Docker
    if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        return 0
    fi
    return 1
}

# Detecta tipo de entorno (VPS vs Dedicado)
detect_type() {
    # Indicadores de VPS/cloud
    local is_vps=false
    
    # Verificar por DMI si es VM
    if [[ -f /sys/class/dmi/id/product_name ]]; then
        local product
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
        
        # Nombres típicos de VM
        case "$product" in
            *"Virtual"*|*"VM"*|*"KVM"*|*"Xen"*|*"QEMU"*|*"VirtualBox"*|*"Parallels"*|*"VMware"*|*"Hyper-V"*)
                is_vps=true
                ;;
        esac
    fi
    
    # Verificar por tipo de CPU (VPS suelen tener menos cores físicos)
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo 1)
    
    # Verificar por cantidad de RAM
    local ram_kb
    ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local ram_gb=$((ram_kb / 1024 / 1024))
    
    # Verificar por presencia de cloud-init
    if [[ -d /etc/cloud ]] || [[ -f /etc/cloud/cloud.cfg ]]; then
        is_vps=true
    fi
    
    # Verificar por nombre de producto DMI
    if [[ -f /sys/class/dmi/id/board_vendor ]]; then
        local board_vendor
        board_vendor=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null || echo "")
        case "$board_vendor" in
            "Amazon"*|"Google"*|"Microsoft"*|"DigitalOcean"*|"Hetzner"*|"Linode"*|"Vultr"*)
                is_vps=true
                ;;
        esac
    fi
    
    # Si tiene provider cloud identificado, es VPS
    if [[ "$PROVIDER" != "unknown" ]] && [[ "$PROVIDER" != "dedicated" ]]; then
        is_vps=true
    fi
    
    # Determinar tipo final
    if $is_vps; then
        TIPO="vps"
    else
        # Para dedicados, verificamos recursos típicos
        if [[ $cpu_cores -ge 4 ]] && [[ $ram_gb -ge 16 ]]; then
            TIPO="dedicado"
        elif [[ $cpu_cores -ge 8 ]] || [[ $ram_gb -ge 32 ]]; then
            TIPO="dedicado"
        else
            # Pequeño, probablemente VPS
            TIPO="vps"
        fi
    fi
}

# Obtiene información del OS
get_os_info() {
    local os_name="unknown"
    local os_version="unknown"
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        os_name="${NAME:-unknown}"
        os_version="${VERSION_ID:-unknown}"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        os_name="${DISTRIB_ID:-unknown}"
        os_version="${DISTRIB_RELEASE:-unknown}"
    fi
    
    OS_NAME="$os_name"
    OS_VERSION="$os_version"
}

# Obtiene información del kernel
get_kernel_info() {
    KERNEL=$(uname -r 2>/dev/null || echo "unknown")
}

# Verifica systemd
check_systemd() {
    if systemctl --version &>/dev/null; then
        SYSTEMD="true"
    else
        SYSTEMD="false"
    fi
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main() {
    echo -e "${BLUE}=== Detectando tipo de entorno ===${NC}"
    
    # Detectar provider (en orden de prioridad)
    detect_provider_metadata || detect_provider_hostname || detect_provider_dmi || PROVIDER="unknown"
    
    # Detectar tipo de entorno
    detect_type
    
    # Obtener info adicional
    get_os_info
    get_kernel_info
    check_systemd
    
    # Verificar si es container
    if detect_container; then
        CONTAINER="true"
        echo -e "${YELLOW}⚠ Container detectado (Docker/LXC)${NC}"
    else
        CONTAINER="false"
    fi
    
    # Mostrar resultado
    echo ""
    echo -e "${GREEN}✓ Entorno detectado:${NC}"
    echo -e "  Tipo:      ${GREEN}${TIPO}${NC}"
    echo -e "  Provider:  ${GREEN}${PROVIDER}${NC}"
    echo -e "  OS:        ${GREEN}${OS_NAME} ${OS_VERSION}${NC}"
    echo -e "  Kernel:    ${GREEN}${KERNEL}${NC}"
    echo -e "  Systemd:   ${GREEN}${SYSTEMD}${NC}"
    echo -e "  Container: ${GREEN}${CONTAINER}${NC}"
    echo -e "  Método:    ${GREEN}${DETECTION_METHOD}${NC}"
    
    # Generar JSON de salida
    cat <<EOF
{
  "type": "${TIPO}",
  "provider": "${PROVIDER}",
  "os": {
    "name": "${OS_NAME}",
    "version": "${OS_VERSION}"
  },
  "kernel": "${KERNEL}",
  "systemd": ${SYSTEMD},
  "container": ${CONTAINER},
  "detection_method": "${DETECTION_METHOD}"
}
EOF
    
    exit 0
}

# Ejecutar
main "$@"