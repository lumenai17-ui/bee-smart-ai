#!/bin/bash
# =============================================================================
# validate-resources.sh - Valida recursos del sistema según tipo de entorno
# TURNKEY v6 - FASE 1: PRE-FLIGHT
# =============================================================================
#
# DESCRIPCIÓN:
#   Valida que los recursos del sistema cumplan con los mínimos requeridos
#   según el tipo de entorno (VPS o Dedicado).
#
# USO:
#   ./validate-resources.sh [TIPO]
#   TIPO: "vps" o "dedicado" (por defecto auto-detecta)
#
# OUTPUT:
#   JSON con estado de validación
#
# EXIT CODES:
#   0 - Recursos OK
#   1 - Recursos insuficientes (crítico)
#   2 - Recursos con warnings
#
# =============================================================================

set -e

# Pero ignorar errores en comandos específicos
set +e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Argumento de tipo
TIPO="${1:-auto}"

# Defaults de recursos
declare -A RESOURCES_VPS=(
    ["ram_min"]=2
    ["ram_recommended"]=4
    ["cpu_min"]=1
    ["cpu_recommended"]=2
    ["disk_min"]=20
    ["disk_recommended"]=50
)

declare -A RESOURCES_DEDICADO=(
    ["ram_min"]=16
    ["ram_recommended"]=32
    ["cpu_min"]=4
    ["cpu_recommended"]=8
    ["disk_min"]=100
    ["disk_recommended"]=500
)

# Arrays para results
declare -a WARNINGS=()
declare -a ERRORS=()
declare -a CHECKS=()

# Valores detectados
RAM_TOTAL_GB=0
RAM_AVAIL_GB=0
CPU_CORES=0
DISK_TOTAL_GB=0
DISK_AVAIL_GB=0

# -----------------------------------------------------------------------------
# FUNCIONES
# -----------------------------------------------------------------------------

# Detectar tipo si es auto
detect_type() {
    if [[ "$TIPO" == "auto" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -x "$script_dir/detect-environment.sh" ]]; then
            local result
            result=$("$script_dir/detect-environment.sh" | grep '"type"' | cut -d'"' -f4)
            TIPO="${result:-vps}"
        else
            TIPO="vps"
        fi
    fi
}

# Obtener recursos actuales
get_resources() {
    # RAM total en GB
    RAM_TOTAL_GB=$(free -g | awk '/^Mem:/{print $2}')
    [[ -z "$RAM_TOTAL_GB" || "$RAM_TOTAL_GB" == "0" ]] && RAM_TOTAL_GB=1
    
    # RAM disponible en GB
    RAM_AVAIL_GB=$(free -g | awk '/^Mem:/{print $7}')
    [[ -z "$RAM_AVAIL_GB" ]] && RAM_AVAIL_GB=0
    
    # CPU cores
    CPU_CORES=$(nproc 2>/dev/null || echo 1)
    
    # Disco disponible en GB (raíz)
    DISK_AVAIL_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4}')
    [[ -z "$DISK_AVAIL_GB" ]] && DISK_AVAIL_GB=10
    
    # Disco total en GB
    DISK_TOTAL_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub(/G/,""); print $2}')
    [[ -z "$DISK_TOTAL_GB" ]] && DISK_TOTAL_GB=20
}

# Validar RAM
validate_ram() {
    local min
    local recommended
    
    if [[ "$TIPO" == "vps" ]]; then
        min=${RESOURCES_VPS["ram_min"]}
        recommended=${RESOURCES_VPS["ram_recommended"]}
    else
        min=${RESOURCES_DEDICADO["ram_min"]}
        recommended=${RESOURCES_DEDICADO["ram_recommended"]}
    fi
    
    local status="passed"
    local details="RAM ${RAM_TOTAL_GB}GB"
    
    if [[ $RAM_TOTAL_GB -lt $min ]]; then
        status="error"
        details="RAM ${RAM_TOTAL_GB}GB es menor al mínimo ${min}GB"
        ERRORS+=("RAM insuficiente: ${RAM_TOTAL_GB}GB < ${min}GB mínimo")
    elif [[ $RAM_TOTAL_GB -lt $recommended ]]; then
        status="warning"
        details="RAM ${RAM_TOTAL_GB}GB (recomendado: ${recommended}GB)"
        WARNINGS+=("RAM por debajo de recomendado: ${RAM_TOTAL_GB}GB < ${recommended}GB")
    fi
    
    CHECKS+=("{\"name\": \"ram\", \"status\": \"${status}\", \"value\": ${RAM_TOTAL_GB}, \"min\": ${min}, \"recommended\": ${recommended}, \"details\": \"${details}\"}")
    
    echo -e "  RAM: ${RAM_TOTAL_GB}GB total ${status} (mínimo: ${min}GB, recomendado: ${recommended}GB)"
}

# Validar CPU
validate_cpu() {
    local min
    local recommended
    
    if [[ "$TIPO" == "vps" ]]; then
        min=${RESOURCES_VPS["cpu_min"]}
        recommended=${RESOURCES_VPS["cpu_recommended"]}
    else
        min=${RESOURCES_DEDICADO["cpu_min"]}
        recommended=${RESOURCES_DEDICADO["cpu_recommended"]}
    fi
    
    local status="passed"
    local details="CPU ${CPU_CORES} cores"
    
    if [[ $CPU_CORES -lt $min ]]; then
        status="error"
        details="CPU ${CPU_CORES} cores es menor al mínimo ${min}"
        ERRORS+=("CPU insuficiente: ${CPU_CORES} cores < ${min} mínimo")
    elif [[ $CPU_CORES -lt $recommended ]]; then
        status="warning"
        details="CPU ${CPU_CORES} cores (recomendado: ${recommended})"
        WARNINGS+=("CPU por debajo de recomendado: ${CPU_CORES} < ${recommended} cores")
    fi
    
    CHECKS+=("{\"name\": \"cpu\", \"status\": \"${status}\", \"value\": ${CPU_CORES}, \"min\": ${min}, \"recommended\": ${recommended}, \"details\": \"${details}\"}")
    
    echo -e "  CPU: ${CPU_CORES} cores ${status} (mínimo: ${min}, recomendado: ${recommended})"
}

# Validar Disco
validate_disk() {
    local min
    local recommended
    
    if [[ "$TIPO" == "vps" ]]; then
        min=${RESOURCES_VPS["disk_min"]}
        recommended=${RESOURCES_VPS["disk_recommended"]}
    else
        min=${RESOURCES_DEDICADO["disk_min"]}
        recommended=${RESOURCES_DEDICADO["disk_recommended"]}
    fi
    
    local status="passed"
    local details="Disco ${DISK_AVAIL_GB}GB disponibles"
    
    if [[ $DISK_AVAIL_GB -lt $min ]]; then
        status="error"
        details="Disco ${DISK_AVAIL_GB}GB es menor al mínimo ${min}GB"
        ERRORS+=("Disco insuficiente: ${DISK_AVAIL_GB}GB < ${min}GB mínimo")
    elif [[ $DISK_AVAIL_GB -lt $recommended ]]; then
        status="warning"
        details="Disco ${DISK_AVAIL_GB}GB disponibles (recomendado: ${recommended}GB)"
        WARNINGS+=("Disco por debajo de recomendado: ${DISK_AVAIL_GB}GB < ${recommended}GB")
    fi
    
    CHECKS+=("{\"name\": \"disk\", \"status\": \"${status}\", \"value\": ${DISK_AVAIL_GB}, \"min\": ${min}, \"recommended\": ${recommended}, \"details\": \"${details}\"}")
    
    echo -e "  Disco: ${DISK_AVAIL_GB}GB disponibles ${status} (mínimo: ${min}GB, recomendado: ${recommended}GB)"
}

# Validar puertos
validate_ports() {
    local required_ports=(18789 18790 18791 18792 18793)
    local available_ports=()
    local status="passed"
    
    echo -e "  Puertos:"
    
    for port in "${required_ports[@]}"; do
        if ss -tuln 2>/dev/null | grep -q ":${port} "; then
            echo -e "    Puerto ${port}: ${YELLOW}ocupado${NC}"
            CHECKS+=("{\"name\": \"port_${port}\", \"status\": \"warning\", \"value\": \"occupied\", \"details\": \"Puerto ${port} está en uso, se usará otro puerto\"}")
            WARNINGS+=("Puerto ${port} está en uso, se usará otro puerto")
        else
            echo -e "    Puerto ${port}: ${GREEN}libre${NC}"
            available_ports+=($port)
            CHECKS+=("{\"name\": \"port_${port}\", \"status\": \"passed\", \"value\": \"free\", \"details\": \"Puerto ${port} disponible\"}")
        fi
    done
    
    if [[ ${#available_ports[@]} -eq 0 ]]; then
        status="error"
        ERRORS+=("Ningún puerto del rango 18789-18793 está disponible. Especifique un puerto manualmente.")
    elif [[ ${#available_ports[@]} -lt 5 ]]; then
        status="warning"
        WARNINGS+=("Solo ${#available_ports[@]} puertos disponibles de 5. Puertos libres: ${available_ports[*]}")
    else
        status="passed"
        WARNINGS+=("Todos los puertos del rango 18789-18793 están disponibles")
    fi
    
    # Guardar puertos disponibles como variable global
    PORTS_AVAILABLE="${available_ports[*]}"
}

# Validar acceso root/sudo
validate_access() {
    local status="passed"
    
    # Verificar si es root
    if [[ $EUID -eq 0 ]]; then
        echo -e "  Acceso root: ${GREEN}✓ Sí${NC}"
        CHECKS+=("{\"name\": \"root_access\", \"status\": \"passed\", \"value\": true, \"details\": \"Ejecutando como root\"}")
        return
    fi
    
    # Verificar si tiene sudo sin password
    if sudo -n true 2>/dev/null; then
        echo -e "  Acceso sudo: ${GREEN}✓ Sí (sin password)${NC}"
        CHECKS+=("{\"name\": \"sudo_access\", \"status\": \"passed\", \"value\": true, \"details\": \"Sudo disponible sin password\"}")
        return
    fi
    
    # Verificar si tiene sudo (con password)
    if command -v sudo &>/dev/null; then
        echo -e "  Acceso sudo: ${YELLOW}⚠ Sí (requiere password)${NC}"
        CHECKS+=("{\"name\": \"sudo_access\", \"status\": \"warning\", \"value\": true, \"details\": \"Sudo disponible pero requiere password\"}")
        WARNINGS+=("Sudo requiere password, algunas operaciones pueden fallar")
        return
    fi
    
    # Sin acceso
    echo -e "  Acceso root/sudo: ${RED}✗ No${NC}"
    CHECKS+=("{\"name\": \"root_access\", \"status\": \"error\", \"value\": false, \"details\": \"Sin acceso root o sudo\"}")
    ERRORS+=("Sin acceso root o sudo")
}

# Validar systemd
validate_systemd() {
    if systemctl --version &>/dev/null; then
        echo -e "  Systemd: ${GREEN}✓ Disponible${NC}"
        CHECKS+=("{\"name\": \"systemd\", \"status\": \"passed\", \"value\": true, \"details\": \"Systemd disponible\"}")
    else
        echo -e "  Systemd: ${RED}✗ No disponible${NC}"
        CHECKS+=("{\"name\": \"systemd\", \"status\": \"error\", \"value\": false, \"details\": \"Systemd no disponible\"}")
        ERRORS+=("Systemd no disponible")
    fi
}

# Validar comandos requeridos
validate_commands() {
    local commands=("curl" "jq" "netstat" "free")
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${cmd}: ${GREEN}✓${NC}"
            CHECKS+=("{\"name\": \"cmd_${cmd}\", \"status\": \"passed\", \"value\": true}")
        else
            echo -e "  ${cmd}: ${YELLOW}⚠ No encontrado${NC}"
            CHECKS+=("{\"name\": \"cmd_${cmd}\", \"status\": \"warning\", \"value\": false}")
            WARNINGS+=("Comando ${cmd} no encontrado")
        fi
    done
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main() {
    echo -e "${BLUE}=== Validando recursos del sistema ===${NC}"
    
    # Detectar tipo
    detect_type
    echo -e "${BLUE}Tipo de entorno: ${TIPO}${NC}"
    echo ""
    
    # Obtener recursos actuales
    get_resources
    
    echo -e "${BLUE}Recursos detectados:${NC}"
    echo -e "  RAM:        ${RAM_TOTAL_GB}GB total, ${RAM_AVAIL_GB}GB disponibles"
    echo -e "  CPU:        ${CPU_CORES} cores"
    echo -e "  Disco:      ${DISK_AVAIL_GB}GB disponibles de ${DISK_TOTAL_GB}GB"
    echo ""
    
    echo -e "${BLUE}Validando requisitos (${TIPO}):${NC}"
    
    # Validar cada componente
    validate_ram
    validate_cpu
    validate_disk
    
    echo ""
    echo -e "${BLUE}Validando puertos:${NC}"
    validate_ports
    
    echo ""
    echo -e "${BLUE}Validando accesos:${NC}"
    validate_access
    validate_systemd
    
    echo ""
    echo -e "${BLUE}Validando comandos:${NC}"
    validate_commands
    
    # Determinar estado final
    local final_status="passed"
    local exit_code=0
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        final_status="failed"
        exit_code=1
    elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
        final_status="passed_with_warnings"
        exit_code=2
    fi
    
    # Mostrar resumen
    echo ""
    echo -e "${BLUE}=== Resumen ===${NC}"
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo -e "${RED}ERRORES:${NC}"
        for err in "${ERRORS[@]}"; do
            echo -e "  ${RED}✗${NC} $err"
        done
    fi
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}WARNINGS:${NC}"
        for warn in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $warn"
        done
    fi
    
    if [[ "$final_status" == "passed" ]]; then
        echo -e "${GREEN}✓ Todos los recursos OK${NC}"
    elif [[ "$final_status" == "passed_with_warnings" ]]; then
        echo -e "${YELLOW}⚠ Recursos OK con warnings${NC}"
    else
        echo -e "${RED}✗ Recursos insuficientes${NC}"
    fi
    
    # Generar JSON
    echo ""
    local checks_json
    checks_json=$(IFS=,; echo "[${CHECKS[*]}]")
    
    local errors_json
    errors_json=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
    
    local warnings_json
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
    
    cat <<EOF
{
  "status": "${final_status}",
  "environment_type": "${TIPO}",
  "resources": {
    "ram": {
      "total_gb": ${RAM_TOTAL_GB},
      "available_gb": ${RAM_AVAIL_GB}
    },
    "cpu": {
      "cores": ${CPU_CORES}
    },
    "disk": {
      "total_gb": ${DISK_TOTAL_GB},
      "available_gb": ${DISK_AVAIL_GB}
    },
    "ports_available": "$(echo $PORTS_AVAILABLE | tr ' ' ',')"
  },
  "checks": ${checks_json},
  "errors": ${errors_json},
  "warnings": ${warnings_json}
}
EOF
    
    exit $exit_code
}

# Ejecutar
main "$@"