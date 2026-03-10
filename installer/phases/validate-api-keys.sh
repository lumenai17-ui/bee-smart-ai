#!/bin/bash
# =============================================================================
# validate-api-keys.sh - Valida API Keys necesarias
# TURNKEY v6 - FASE 1: PRE-FLIGHT
# =============================================================================
#
# DESCRIPCIÓN:
#   Valida que las API keys requeridas estén presentes y funcionando.
#   - Ollama API Key: Requerida
#   - Brave API Key: Opcional (para web_search)
#
# USO:
#   ./validate-api-keys.sh [--ollama KEY] [--brave KEY]
#   Si no se pasan keys, usa variables de entorno
#
# OUTPUT:
#   JSON con estado de validación
#
# EXIT CODES:
#   0 - Todas las keys OK
#   1 - API key requerida faltante o inválida
#   2 - Warnings (keys opcionales faltantes)
#
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# API URLs
OLLAMA_API_URL="https://api.ollama.com/v1/models"
BRAVE_API_URL="https://api.search.brave.com/res/v1/web/search"

# Valores por defecto (desde env o argumentos)
OLLAMA_API_KEY="${OLLAMA_API_KEY:-}"
BRAVE_API_KEY="${BRAVE_API_KEY:-}"

# Arrays para results
declare -a VALIDATIONS=()
declare -a ERRORS=()
declare -a WARNINGS=()

# -----------------------------------------------------------------------------
# FUNCIONES
# -----------------------------------------------------------------------------

# Parsear argumentos
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ollama)
                OLLAMA_API_KEY="$2"
                shift 2
                ;;
            --brave)
                BRAVE_API_KEY="$2"
                shift 2
                ;;
            --help)
                echo "Uso: $0 [--ollama KEY] [--brave KEY]"
                echo "Valida API keys para TURNKEY v6"
                exit 0
                ;;
            *)
                echo "Argumento desconocido: $1"
                exit 1
                ;;
        esac
    done
}

# Validar formato de key de Ollama
validate_ollama_format() {
    local key="$1"
    
    # Las keys de Ollama suelen empezar con "oll-" pero pueden variar
    if [[ -z "$key" ]]; then
        echo "empty"
        return 1
    fi
    
    # Verificar longitud mínima
    if [[ ${#key} -lt 20 ]]; then
        echo "too_short"
        return 1
    fi
    
    echo "valid_format"
    return 0
}

# Validar API key de Ollama contra el servidor
validate_ollama_api() {
    local key="$1"
    local status="error"
    local details=""
    local plan="unknown"
    
    echo -e "${BLUE}Validando API key de Ollama...${NC}"
    
    # Verificar que existe
    if [[ -z "$key" ]]; then
        details="OLLAMA_API_KEY no proporcionada"
        echo -e "  ${RED}✗ ${details}${NC}"
        ERRORS+=("OLLAMA_API_KEY faltante - REQUERIDA")
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"error\", \"key_present\": false, \"key_valid\": false, \"plan\": \"unknown\", \"details\": \"${details}\"}")
        return 1
    fi
    
    # Verificar formato
    local format_result
    format_result=$(validate_ollama_format "$key")
    
    if [[ "$format_result" != "valid_format" ]]; then
        details="Formato de key inválido: $format_result"
        echo -e "  ${RED}✗ ${details}${NC}"
        ERRORS+=("Formato de OLLAMA_API_KEY inválido")
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"error\", \"key_present\": true, \"key_valid\": false, \"plan\": \"unknown\", \"details\": \"${details}\"}")
        return 1
    fi
    
    # Hacer ping a la API
    echo -e "  Probando conexión con API de Ollama..."
    
    local http_code
    local response
    
    # Usar timeout de 10 segundos
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 15 \
        -H "Authorization: Bearer $key" \
        "$OLLAMA_API_URL" 2>/dev/null) || http_code="000"
    
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        # Key válida
        status="passed"
        
        # Intentar detectar plan (free vs paid)
        # La API de Ollama puede indicar el plan en el header o en la respuesta
        local api_response
        api_response=$(echo "$response" | head -n-1)
        
        # Buscar indicadores de plan
        if echo "$api_response" | grep -qi "free\|starter\|basic"; then
            plan="free"
        elif echo "$api_response" | grep -qi "pro\|paid\|premium"; then
            plan="paid"
        else
            plan="unknown"
        fi
        
        details="API key válida"
        
        # Obtener modelos disponibles
        local models
        models=$(echo "$api_response" | jq -r '.data[].id' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        
        echo -e "  ${GREEN}✓ API key válida${NC} (Plan: ${plan})"
        if [[ -n "$models" ]]; then
            echo -e "    Modelos disponibles: $(echo "$models" | cut -c1-50)..."
        fi
        
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"passed\", \"key_present\": true, \"key_valid\": true, \"plan\": \"${plan}\", \"models\": \"${models}\", \"details\": \"${details}\"}")
        
        # Guardar para output global
        OLLAMA_VALID="true"
        OLLAMA_PLAN="$plan"
        
        return 0
    elif [[ "$http_code" == "401" ]] || [[ "$http_code" == "403" ]]; then
        # Key inválida
        details="API key inválida o expirada"
        echo -e "  ${RED}✗ ${details}${NC}"
        ERRORS+=("OLLAMA_API_KEY inválida - Verificar en https://ollama.com/settings")
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"error\", \"key_present\": true, \"key_valid\": false, \"plan\": \"unknown\", \"details\": \"${details}\"}")
        return 1
    elif [[ "$http_code" == "429" ]]; then
        # Rate limit
        status="warning"
        details="Rate limit alcanzado, key válida pero en cooldown"
        echo -e "  ${YELLOW}⚠ ${details}${NC}"
        WARNINGS+=("Ollama API rate limit alcanzado")
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"warning\", \"key_present\": true, \"key_valid\": true, \"plan\": \"${plan}\", \"details\": \"${details}\"}")
        return 2
    else
        # Otro error
        details="Error de conexión (HTTP $http_code)"
        echo -e "  ${RED}✗ ${details}${NC}"
        ERRORS+=("No se pudo validar OLLAMA_API_KEY - Error HTTP $http_code")
        VALIDATIONS+=("{\"name\": \"ollama\", \"status\": \"error\", \"key_present\": true, \"key_valid\": false, \"plan\": \"unknown\", \"details\": \"${details}\"}")
        return 1
    fi
}

# Validar API key de Brave
validate_brave_api() {
    local key="$1"
    local status="warning"
    local details=""
    
    echo -e "${BLUE}Validando API key de Brave Search...${NC}"
    
    # Verificar que existe
    if [[ -z "$key" ]]; then
        details="BRAVE_API_KEY no proporcionada (opcional)"
        echo -e "  ${YELLOW}⚠ ${details}${NC}"
        echo -e "    ${YELLOW}Skill web_search será deshabilitada${NC}"
        WARNINGS+=("BRAVE_API_KEY faltante - Skill web_search deshabilitada")
        VALIDATIONS+=("{\"name\": \"brave\", \"status\": \"warning\", \"key_present\": false, \"key_valid\": false, \"skill_affected\": \"web_search\", \"details\": \"${details}\"}")
        return 2
    fi
    
    # Hacer ping a la API
    echo -e "  Probando conexión con API de Brave..."
    
    local http_code
    local response
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 15 \
        -H "Accept: application/json" \
        -H "X-Subscription-Token: $key" \
        "${BRAVE_API_URL}?q=test" 2>/dev/null) || http_code="000"
    
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        status="passed"
        details="API key válida"
        echo -e "  ${GREEN}✓ API key válida${NC}"
        VALIDATIONS+=("{\"name\": \"brave\", \"status\": \"passed\", \"key_present\": true, \"key_valid\": true, \"details\": \"${details}\"}")
        BRAVE_VALID="true"
        return 0
    elif [[ "$http_code" == "401" ]] || [[ "$http_code" == "403" ]]; then
        details="API key inválida"
        echo -e "  ${RED}✗ ${details}${NC}"
        WARNINGS+=("BRAVE_API_KEY inválida - web_search no funcionará")
        VALIDATIONS+=("{\"name\": \"brave\", \"status\": \"warning\", \"key_present\": true, \"key_valid\": false, \"skill_affected\": \"web_search\", \"details\": \"${details}\"}")
        return 2
    else
        details="Error de conexión (HTTP $http_code)"
        echo -e "  ${YELLOW}⚠ ${details}${NC}"
        WARNINGS+=("No se pudo validar BRAVE_API_KEY - Error HTTP $http_code")
        VALIDATIONS+=("{\"name\": \"brave\", \"status\": \"warning\", \"key_present\": true, \"key_valid\": false, \"details\": \"${details}\"}")
        return 2
    fi
}

# Validar API key de OpenAI (opcional)
validate_openai_api() {
    local key="${OPENAI_API_KEY:-}"
    
    if [[ -z "$key" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}Validando API key de OpenAI...${NC}"
    
    local http_code
    local response
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 15 \
        -H "Authorization: Bearer $key" \
        "https://api.openai.com/v1/models" 2>/dev/null) || http_code="000"
    
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "  ${GREEN}✓ OpenAI API key válida${NC}"
        VALIDATIONS+=("{\"name\": \"openai\", \"status\": \"passed\", \"key_present\": true, \"key_valid\": true}")
        OPENAI_VALID="true"
        return 0
    else
        echo -e "  ${YELLOW}⚠ OpenAI API key no válida (opcional)${NC}"
        VALIDATIONS+=("{\"name\": \"openai\", \"status\": \"warning\", \"key_present\": true, \"key_valid\": false}")
        return 2
    fi
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main() {
    echo -e "${BLUE}=== Validando API Keys ===${NC}"
    echo ""
    
    # Parsear argumentos
    parse_args "$@"
    
    echo -e "${BLUE}API Keys detectadas:${NC}"
    echo -e "  Ollama: $([ -n "$OLLAMA_API_KEY" ] && echo "Presente (${#OLLAMA_API_KEY} chars)" || echo "No proporcionada")"
    echo -e "  Brave:  $([ -n "$BRAVE_API_KEY" ] && echo "Presente (${#BRAVE_API_KEY} chars)" || echo "No proporcionada")"
    echo ""
    
    # Validar Ollama (requerida)
    validate_ollama_api "$OLLAMA_API_KEY"
    local ollama_result=$?
    
    echo ""
    
    # Validar Brave (opcional)
    validate_brave_api "$BRAVE_API_KEY"
    local brave_result=$?
    
    # Validar OpenAI (si existe)
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        echo ""
        validate_openai_api
    fi
    
    # Resumen
    echo ""
    echo -e "${BLUE}=== Resumen de Validación ===${NC}"
    
    # Determinar estado final
    local final_status="passed"
    local exit_code=0
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        final_status="failed"
        exit_code=1
        echo -e "${RED}Estado: FAILED${NC}"
        echo -e "${RED}Errores:${NC}"
        for err in "${ERRORS[@]}"; do
            echo -e "  ${RED}✗${NC} $err"
        done
    elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
        final_status="passed_with_warnings"
        exit_code=2
        echo -e "${YELLOW}Estado: PASSED (con warnings)${NC}"
        echo -e "${YELLOW}Warnings:${NC}"
        for warn in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $warn"
        done
    else
        echo -e "${GREEN}Estado: PASSED${NC}"
    fi
    
    # Generar JSON de salida
    local validations_json
    validations_json=$(IFS=,; echo "[${VALIDATIONS[*]}]")
    
    local errors_json
    errors_json=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
    
    local warnings_json
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
    
    cat <<EOF
{
  "status": "${final_status}",
  "ollama": {
    "present": $([ -n "$OLLAMA_API_KEY" ] && echo "true" || echo "false"),
    "valid": "${OLLAMA_VALID:-false}",
    "plan": "${OLLAMA_PLAN:-unknown}"
  },
  "brave": {
    "present": $([ -n "$BRAVE_API_KEY" ] && echo "true" || echo "false"),
    "valid": "${BRAVE_VALID:-false}"
  },
  "openai": {
    "present": $([ -n "${OPENAI_API_KEY:-}" ] && echo "true" || echo "false"),
    "valid": "${OPENAI_VALID:-false}"
  },
  "validations": ${validations_json},
  "errors": ${errors_json},
  "warnings": ${warnings_json}
}
EOF
    
    exit $exit_code
}

# Ejecutar
main "$@"