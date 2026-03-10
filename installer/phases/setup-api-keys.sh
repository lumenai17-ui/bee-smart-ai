#!/usr/bin/env bash
#===============================================================================
# TURNKEY v6 - FASE 5: Setup API Keys
#===============================================================================
# Configura y valida APIs compartidas para OpenClaw:
# - OpenAI / Anthropic / Gemini (LLMs)
# - Brave Search (Búsqueda web)
# - Resend (Email)
# - Otros servicios
# Guarda todo en secrets de forma segura
#===============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
CONFIG_DIR="$OPENCLAW_DIR/config"
SECRETS_DIR="$OPENCLAW_DIR/secrets"
API_KEYS_FILE="$SECRETS_DIR/api-keys.yaml"
API_CONFIG_FILE="$CONFIG_DIR/api-providers.yaml"

# APIs a configurar
declare -A API_KEYS
declare -A API_STATUS

# Valores
OPENAI_KEY=""
ANTHROPIC_KEY=""
GEMINI_KEY=""
BRAVE_KEY=""
RESEND_KEY=""
SERPER_KEY=""
TAVILY_KEY=""
FIRECRAWL_KEY=""
JINA_KEY=""
CUSTOM_KEYS=""

#===============================================================================
# UTILIDADES
#===============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}==>${NC} $1"; }

check_dependencies() {
    log_step "Verificando dependencias..."
    
    local deps=("curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing[*]}"
        exit 1
    fi
    
    log_success "Dependencias verificadas"
}

mask_key() {
    local key="$1"
    if [[ ${#key} -gt 8 ]]; then
        echo "${key:0:4}...${key: -4}"
    else
        echo "****"
    fi
}

#===============================================================================
# PROMPT DE APIs
#===============================================================================

show_api_menu() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               CONFIGURACIÓN DE API KEYS                    ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} LLM Providers:"
    echo -e "${CYAN}║${NC}   ${YELLOW}1)${NC} OpenAI        - GPT-4, GPT-4o, GPT-3.5"
    echo -e "${CYAN}║${NC}   ${YELLOW}2)${NC} Anthropic     - Claude 3.5 Sonnet, Claude 3 Opus"
    echo -e "${CYAN}║${NC}   ${YELLOW}3)${NC} Google Gemini - Gemini Pro, Gemini Flash"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Search & Tools:"
    echo -e "${CYAN}║${NC}   ${YELLOW}4)${NC} Brave Search  - Búsqueda web"
    echo -e "${CYAN}║${NC}   ${YELLOW}5)${NC} Serper         - Google Search API"
    echo -e "${CYAN}║${NC}   ${YELLOW}6)${NC} Tavily         - AI Search API"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Email & Communication:"
    echo -e "${CYAN}║${NC}   ${YELLOW}7)${NC} Resend        - Email API"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Content & Embedding:"
    echo -e "${CYAN}║${NC}   ${YELLOW}8)${NC} Firecrawl     - Web scraping"
    echo -e "${CYAN}║${NC}   ${YELLOW}9)${NC} Jina AI       - Embeddings, Reader"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${YELLOW}a)${NC} Configurar TODAS"
    echo -e "${CYAN}║${NC}   ${YELLOW}v)${NC} Ver configuración actual"
    echo -e "${CYAN}║${NC}   ${YELLOW}s)${NC} Guardar y salir"
    echo -e "${CYAN}║${NC}   ${YELLOW}q)${NC} Salir sin guardar"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

prompt_api_key() {
    local name="$1"
    local env_var="$2"
    local description="$3"
    local prefix="$4"
    
    echo ""
    echo -e "${CYAN}=== $name ===${NC}"
    echo "$description"
    echo ""
    
    # Check if already configured
    local existing=""
    case "$name" in
        "OpenAI") existing="${OPENAI_KEY:-}" ;;
        "Anthropic") existing="${ANTHROPIC_KEY:-}" ;;
        "Google Gemini") existing="${GEMINI_KEY:-}" ;;
        "Brave Search") existing="${BRAVE_KEY:-}" ;;
        "Serper") existing="${SERPER_KEY:-}" ;;
        "Tavily") existing="${TAVILY_KEY:-}" ;;
        "Resend") existing="${RESEND_KEY:-}" ;;
        "Firecrawl") existing="${FIRECRAWL_KEY:-}" ;;
        "Jina AI") existing="${JINA_KEY:-}" ;;
    esac
    
    # Check environment variable
    if [[ -z "$existing" ]]; then
        existing="${!env_var:-}"
    fi
    
    if [[ -n "$existing" ]]; then
        echo -e "Key actual: ${GREEN}$(mask_key "$existing")${NC}"
        read -p "¿Actualizar? [y/N]: " update
        [[ "${update,,}" != "y" ]] && return 0
    fi
    
    echo -e "Ingresa tu API key (formato esperado: ${YELLOW}$prefix...${NC})"
    read -p "API Key (vacío para omitir): " key
    
    if [[ -n "$key" ]]; then
        # Validar formato básico
        if [[ -n "$prefix" && ! "$key" == "$prefix"* ]]; then
            log_warn "La key no tiene el prefiso esperado ($prefix)"
            read -p "¿Continuar de todas formas? [y/N]: " cont
            [[ "${cont,,}" != "y" ]] && return 1
        fi
        
        # Guardar
        case "$name" in
            "OpenAI") OPENAI_KEY="$key" ;;
            "Anthropic") ANTHROPIC_KEY="$key" ;;
            "Google Gemini") GEMINI_KEY="$key" ;;
            "Brave Search") BRAVE_KEY="$key" ;;
            "Serper") SERPER_KEY="$key" ;;
            "Tavily") TAVILY_KEY="$key" ;;
            "Resend") RESEND_KEY="$key" ;;
            "Firecrawl") FIRECRAWL_KEY="$key" ;;
            "Jina AI") JINA_KEY="$key" ;;
        esac
        
        log_success "Key guardada para $name"
    fi
}

#===============================================================================
# VALIDACIÓN DE APIs
#===============================================================================

validate_openai() {
    log_step "Validando OpenAI API..."
    
    if [[ -z "$OPENAI_KEY" ]]; then
        API_STATUS["openai"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.openai.com/v1/models" \
        -H "Authorization: Bearer $OPENAI_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{"error":{"message":"Connection failed"}}')
    
    if echo "$response" | jq -e '.data' &>/dev/null; then
        local model_count=$(echo "$response" | jq '.data | length')
        log_success "OpenAI API válida ($model_count modelos disponibles)"
        API_STATUS["openai"]="connected"
        API_KEYS["openai_models"]="$model_count"
    else
        local error=$(echo "$response" | jq -r '.error.message // "Error desconocido"')
        log_error "OpenAI API inválida: $error"
        API_STATUS["openai"]="error"
        API_KEYS["openai_error"]="$error"
    fi
}

validate_anthropic() {
    log_step "Validando Anthropic API..."
    
    if [[ -z "$ANTHROPIC_KEY" ]]; then
        API_STATUS["anthropic"]="not_configured"
        return 0
    fi
    
    # Anthropic no tiene endpoint de validación directo, usar un request mínimo
    local response
    response=$(curl -s "https://api.anthropic.com/v1/messages" \
        -H "x-api-key: $ANTHROPIC_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "Content-Type: application/json" \
        -d '{"model": "claude-3-haiku-20240307", "max_tokens": 1, "messages": [{"role": "user", "content": "hi"}]}' \
        --connect-timeout 15 2>/dev/null || echo '{"error":{"message":"Connection failed"}}')
    
    if echo "$response" | jq -e '.content' &>/dev/null; then
        log_success "Anthropic API válida"
        API_STATUS["anthropic"]="connected"
    elif echo "$response" | jq -e '.error.type' &>/dev/null; then
        # Error known (rate limit, etc) means key is valid
        local error_type=$(echo "$response" | jq -r '.error.type')
        if [[ "$error_type" == "rate_limit_error" || "$error_type" == "overloaded_error" ]]; then
            log_success "Anthropic API válida (rate limited)"
            API_STATUS["anthropic"]="connected"
        else
            log_error "Anthropic API error: $error_type"
            API_STATUS["anthropic"]="error"
        fi
    else
        local error=$(echo "$response" | jq -r '.error.message // "Error desconocido"')
        log_error "Anthropic API inválida: $error"
        API_STATUS["anthropic"]="error"
    fi
}

validate_gemini() {
    log_step "Validando Google Gemini API..."
    
    if [[ -z "$GEMINI_KEY" ]]; then
        API_STATUS["gemini"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://generativelanguage.googleapis.com/v1/models?key=$GEMINI_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{"error":{"message":"Connection failed"}}')
    
    if echo "$response" | jq -e '.models' &>/dev/null; then
        local model_count=$(echo "$response" | jq '.models | length')
        log_success "Gemini API válida ($model_count modelos disponibles)"
        API_STATUS["gemini"]="connected"
        API_KEYS["gemini_models"]="$model_count"
    else
        local error=$(echo "$response" | jq -r '.error.message // "Error desconocido"')
        log_error "Gemini API inválida: $error"
        API_STATUS["gemini"]="error"
    fi
}

validate_brave() {
    log_step "Validando Brave Search API..."
    
    if [[ -z "$BRAVE_KEY" ]]; then
        API_STATUS["brave"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.search.brave.com/res/v1/web/search?q=test" \
        -H "Accept: application/json" \
        -H "Accept-Encoding: gzip" \
        -H "X-Subscription-Token: $BRAVE_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.web' &>/dev/null || echo "$response" | jq -e '.results' &>/dev/null; then
        log_success "Brave Search API válida"
        API_STATUS["brave"]="connected"
    else
        local error=$(echo "$response" | jq -r '.error // .description // "Error desconocido"')
        if [[ -z "$error" || "$error" == "null" ]]; then
            # Might still be valid, check for 401
            if echo "$response" | grep -qi "unauthorized\|invalid"; then
                log_error "Brave Search API inválida"
                API_STATUS["brave"]="error"
            else
                log_warn "Brave Search: respuesta no determinada"
                API_STATUS["brave"]="unknown"
            fi
        else
            log_error "Brave Search API inválida: $error"
            API_STATUS["brave"]="error"
        fi
    fi
}

validate_serper() {
    log_step "Validando Serper API..."
    
    if [[ -z "$SERPER_KEY" ]]; then
        API_STATUS["serper"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://google.serper.dev/search" \
        -H "X-API-KEY: $SERPER_KEY" \
        -H "Content-Type: application/json" \
        -d '{"q":"test"}' \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.organic' &>/dev/null; then
        log_success "Serper API válida"
        API_STATUS["serper"]="connected"
    else
        local error=$(echo "$response" | jq -r '.message // "Error desconocido"')
        log_error "Serper API inválida: $error"
        API_STATUS["serper"]="error"
    fi
}

validate_tavily() {
    log_step "Validando Tavily API..."
    
    if [[ -z "$TAVILY_KEY" ]]; then
        API_STATUS["tavily"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.tavily.com/search" \
        -H "Content-Type: application/json" \
        -d "{\"api_key\": \"$TAVILY_KEY\", \"query\": \"test\", \"max_results\": 1}" \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.results' &>/dev/null; then
        log_success "Tavily API válida"
        API_STATUS["tavily"]="connected"
    else
        local error=$(echo "$response" | jq -r '.error // .message // "Error desconocido"')
        log_error "Tavily API inválida: $error"
        API_STATUS["tavily"]="error"
    fi
}

validate_resend() {
    log_step "Validando Resend API..."
    
    if [[ -z "$RESEND_KEY" ]]; then
        API_STATUS["resend"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.resend.com/domains" \
        -H "Authorization: Bearer $RESEND_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.data' &>/dev/null; then
        local domain_count=$(echo "$response" | jq '.data | length')
        log_success "Resend API válida ($domain_count dominios)"
        API_STATUS["resend"]="connected"
    elif echo "$response" | jq -e '.name' &>/dev/null; then
        # Single domain response
        log_success "Resend API válida"
        API_STATUS["resend"]="connected"
    else
        local error=$(echo "$response" | jq -r '.message // "Error desconocido"')
        log_error "Resend API inválida: $error"
        API_STATUS["resend"]="error"
    fi
}

validate_firecrawl() {
    log_step "Validando Firecrawl API..."
    
    if [[ -z "$FIRECRAWL_KEY" ]]; then
        API_STATUS["firecrawl"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.firecrawl.dev/v1/me" \
        -H "Authorization: Bearer $FIRECRAWL_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.email' &>/dev/null; then
        local email=$(echo "$response" | jq -r '.email')
        log_success "Firecrawl API válida ($email)"
        API_STATUS["firecrawl"]="connected"
    else
        local error=$(echo "$response" | jq -r '.error // .message // "Error desconocido"')
        log_error "Firecrawl API inválida: $error"
        API_STATUS["firecrawl"]="error"
    fi
}

validate_jina() {
    log_step "Validando Jina AI API..."
    
    if [[ -z "$JINA_KEY" ]]; then
        API_STATUS["jina"]="not_configured"
        return 0
    fi
    
    local response
    response=$(curl -s "https://api.jina.ai/v1/models" \
        -H "Authorization: Bearer $JINA_KEY" \
        --connect-timeout 10 2>/dev/null || echo '{}')
    
    if echo "$response" | jq -e '.data' &>/dev/null; then
        log_success "Jina AI API válida"
        API_STATUS["jina"]="connected"
    else
        local error=$(echo "$response" | jq -r '.error // .message // "Error desconocido"')
        log_error "Jina AI API inválida: $error"
        API_STATUS["jina"]="error"
    fi
}

validate_all_apis() {
    log_step "Validando todas las APIs configuradas..."
    echo ""
    
    validate_openai
    validate_anthropic
    validate_gemini
    validate_brave
    validate_serper
    validate_tavily
    validate_resend
    validate_firecrawl
    validate_jina
    
    echo ""
}

#===============================================================================
# GUARDAR CONFIGURACIÓN
#===============================================================================

save_configuration() {
    log_step "Guardando configuración..."
    
    mkdir -p "$CONFIG_DIR" "$SECRETS_DIR"
    
    # Secrets (API Keys)
    cat > "$API_KEYS_FILE" << EOF
# OpenClaw API Keys - DO NOT COMMIT
# Generated by setup-api-keys.sh on $(date -Iseconds)

# LLM Providers
$(if [[ -n "$OPENAI_KEY" ]]; then echo "openai_api_key: \"$OPENAI_KEY\""; else echo "# openai_api_key: \"\""; fi)
$(if [[ -n "$ANTHROPIC_KEY" ]]; then echo "anthropic_api_key: \"$ANTHROPIC_KEY\""; else echo "# anthropic_api_key: \"\""; fi)
$(if [[ -n "$GEMINI_KEY" ]]; then echo "gemini_api_key: \"$GEMINI_KEY\""; else echo "# gemini_api_key: \"\""; fi)

# Search
$(if [[ -n "$BRAVE_KEY" ]]; then echo "brave_api_key: \"$BRAVE_KEY\""; else echo "# brave_api_key: \"\""; fi)
$(if [[ -n "$SERPER_KEY" ]]; then echo "serper_api_key: \"$SERPER_KEY\""; else echo "# serper_api_key: \"\""; fi)
$(if [[ -n "$TAVILY_KEY" ]]; then echo "tavily_api_key: \"$TAVILY_KEY\""; else echo "# tavily_api_key: \"\""; fi)

# Email
$(if [[ -n "$RESEND_KEY" ]]; then echo "resend_api_key: \"$RESEND_KEY\""; else echo "# resend_api_key: \"\""; fi)

# Content
$(if [[ -n "$FIRECRAWL_KEY" ]]; then echo "firecrawl_api_key: \"$FIRECRAWL_KEY\""; else echo "# firecrawl_api_key: \"\""; fi)
$(if [[ -n "$JINA_KEY" ]]; then echo "jina_api_key: \"$JINA_KEY\""; else echo "# jina_api_key: \"\""; fi)
EOF

    chmod 600 "$API_KEYS_FILE"
    log_success "Keys guardadas en $API_KEYS_FILE"
    
    # Configuración de providers
    cat > "$API_CONFIG_FILE" << EOF
# OpenClaw API Providers Configuration
# Generated by setup-api-keys.sh

llm:
  default: "$([ -n "$OPENAI_KEY" ] && echo "openai" || ([ -n "$ANTHROPIC_KEY" ] && echo "anthropic" || ([ -n "$GEMINI_KEY" ] && echo "gemini" || echo "none")))"
  
  openai:
    enabled: $([ -n "$OPENAI_KEY" ] && echo "true" || echo "false")
    models:
      - "gpt-4o"
      - "gpt-4o-mini"
      - "gpt-4-turbo"
      - "gpt-3.5-turbo"
    default_model: "gpt-4o-mini"
  
  anthropic:
    enabled: $([ -n "$ANTHROPIC_KEY" ] && echo "true" || echo "false")
    models:
      - "claude-3-5-sonnet-20241022"
      - "claude-3-opus-20240229"
      - "claude-3-haiku-20240307"
    default_model: "claude-3-5-sonnet-20241022"
  
  gemini:
    enabled: $([ -n "$GEMINI_KEY" ] && echo "true" || echo "false")
    models:
      - "gemini-2.0-flash-exp"
      - "gemini-1.5-pro"
      - "gemini-1.5-flash"
    default_model: "gemini-2.0-flash-exp"

search:
  default: "$([ -n "$BRAVE_KEY" ] && echo "brave" || ([ -n "$SERPER_KEY" ] && echo "serper" || ([ -n "$TAVILY_KEY" ] && echo "tavily" || echo "none")))"
  
  brave:
    enabled: $([ -n "$BRAVE_KEY" ] && echo "true" || echo "false")
    endpoint: "https://api.search.brave.com/res/v1/web/search"
  
  serper:
    enabled: $([ -n "$SERPER_KEY" ] && echo "true" || echo "false")
    endpoint: "https://google.serper.dev/search"
  
  tavily:
    enabled: $([ -n "$TAVILY_KEY" ] && echo "true" || echo "false")
    endpoint: "https://api.tavily.com/search"

email:
  resend:
    enabled: $([ -n "$RESEND_KEY" ] && echo "true" || echo "false")
    endpoint: "https://api.resend.com"

content:
  firecrawl:
    enabled: $([ -n "$FIRECRAWL_KEY" ] && echo "true" || echo "false")
    endpoint: "https://api.firecrawl.dev/v1"
  
  jina:
    enabled: $([ -n "$JINA_KEY" ] && echo "true" || echo "false")
    endpoint: "https://api.jina.ai/v1"
    reader_endpoint: "https://r.jina.ai"
EOF

    chmod 644 "$API_CONFIG_FILE"
    log_success "Configuración guardada en $API_CONFIG_FILE"
}

#===============================================================================
# CARGAR CONFIGURACIÓN EXISTENTE
#===============================================================================

load_existing_config() {
    if [[ -f "$API_KEYS_FILE" ]]; then
        log_info "Cargando configuración existente..."
        
        OPENAI_KEY=$(grep '^openai_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/openai_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        ANTHROPIC_KEY=$(grep '^anthropic_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/anthropic_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        GEMINI_KEY=$(grep '^gemini_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/gemini_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        BRAVE_KEY=$(grep '^brave_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/brave_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        SERPER_KEY=$(grep '^serper_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/serper_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        TAVILY_KEY=$(grep '^tavily_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/tavily_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        RESEND_KEY=$(grep '^resend_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/resend_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        FIRECRAWL_KEY=$(grep '^firecrawl_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/firecrawl_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        JINA_KEY=$(grep '^jina_api_key:' "$API_KEYS_FILE" 2>/dev/null | sed 's/jina_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
    fi
}

#===============================================================================
# MOSTRAR ESTADO ACTUAL
#===============================================================================

show_current_config() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               API KEYS CONFIGURADAS                        ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    printf "${CYAN}║${NC} %-15s %-30s %s\n" "PROVIDER" "KEY" "STATUS"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    declare -A keys
    keys["OpenAI"]="$OPENAI_KEY"
    keys["Anthropic"]="$ANTHROPIC_KEY"
    keys["Gemini"]="$GEMINI_KEY"
    keys["Brave"]="$BRAVE_KEY"
    keys["Serper"]="$SERPER_KEY"
    keys["Tavily"]="$TAVILY_KEY"
    keys["Resend"]="$RESEND_KEY"
    keys["Firecrawl"]="$FIRECRAWL_KEY"
    keys["Jina"]="$JINA_KEY"
    
    for provider in OpenAI Anthropic Gemini Brave Serper Tavily Resend Firecrawl Jina; do
        local key="${keys[$provider]}"
        local status_icon
        
        if [[ -n "$key" ]]; then
            if [[ "${API_STATUS[$provider]:-}" == "connected" ]]; then
                status_icon="${GREEN}✓${NC}"
            elif [[ "${API_STATUS[$provider]:-}" == "error" ]]; then
                status_icon="${RED}✗${NC}"
            elif [[ "${API_STATUS[$provider]:-}" == "not_configured" ]]; then
                status_icon="${YELLOW}○${NC}"
            else
                status_icon="${BLUE}?${NC}"
            fi
            printf "${CYAN}║${NC} %-15s ${GREEN}%-30s${NC} %b\n" "$provider" "$(mask_key "$key")" "$status_icon"
        else
            printf "${CYAN}║${NC} %-15s ${YELLOW}%-30s${NC} ${YELLOW}○${NC}\n" "$provider" "no configurado"
        fi
    done
    
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#===============================================================================
# RESUMEN FINAL
#===============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           CONFIGURACIÓN DE APIs COMPLETADA                 ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    local total=0
    local configured=0
    local valid=0
    
    for provider in openai anthropic gemini brave serper tavily resend firecrawl jina; do
        ((total++))
        if [[ "${API_STATUS[$provider]:-}" != "not_configured" && -n "${API_STATUS[$provider]:-}" ]]; then
            ((configured++))
            if [[ "${API_STATUS[$provider]}" == "connected" ]]; then
                ((valid++))
            fi
        fi
    done
    
    echo -e "${CYAN}║${NC} APIs revisadas:    ${GREEN}$total${NC}"
    echo -e "${CYAN}║${NC} APIs configuradas: ${GREEN}$configured${NC}"
    echo -e "${CYAN}║${NC} APIs válidas:      ${GREEN}$valid${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Secrets: ${YELLOW}$API_KEYS_FILE${NC}"
    echo -e "${CYAN}║${NC} Config:  ${YELLOW}$API_CONFIG_FILE${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Proveedores configurados:${NC}"
    
    [[ -n "$OPENAI_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} OpenAI - GPT-4, GPT-4o, GPT-3.5"
    [[ -n "$ANTHROPIC_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Anthropic - Claude 3.5, Claude 3"
    [[ -n "$GEMINI_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Google Gemini - Gemini Pro, Flash"
    [[ -n "$BRAVE_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Brave Search"
    [[ -n "$SERPER_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Serper (Google Search)"
    [[ -n "$TAVILY_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Tavily AI Search"
    [[ -n "$RESEND_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Resend Email"
    [[ -n "$FIRECRAWL_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Firecrawl"
    [[ -n "$JINA_KEY" ]] && echo -e "${CYAN}║${NC}   ${GREEN}✓${NC} Jina AI"
    
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        TURNKEY v6 - SETUP API KEYS                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_dependencies
    load_existing_config
    
    # Parsear argumentos
    local validate_only=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --openai) OPENAI_KEY="$2"; shift 2 ;;
            --anthropic) ANTHROPIC_KEY="$2"; shift 2 ;;
            --gemini) GEMINI_KEY="$2"; shift 2 ;;
            --brave) BRAVE_KEY="$2"; shift 2 ;;
            --serper) SERPER_KEY="$2"; shift 2 ;;
            --tavily) TAVILY_KEY="$2"; shift 2 ;;
            --resend) RESEND_KEY="$2"; shift 2 ;;
            --firecrawl) FIRECRAWL_KEY="$2"; shift 2 ;;
            --jina) JINA_KEY="$2"; shift 2 ;;
            --validate-only) validate_only=true; shift ;;
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
    
    if [[ "$validate_only" == "true" ]]; then
        validate_all_apis
        show_current_config
        return 0
    fi
    
    if [[ -z "${NON_INTERACTIVE:-}" ]]; then
        # Modo interactivo
        while true; do
            show_api_menu
            show_current_config
            
            read -p "Opción: " option
            
            case "$option" in
                1) prompt_api_key "OpenAI" "OPENAI_API_KEY" "GPT-4, GPT-4o, GPT-3.5" "sk-" ;;
                2) prompt_api_key "Anthropic" "ANTHROPIC_API_KEY" "Claude 3.5, Claude 3" "sk-ant-" ;;
                3) prompt_api_key "Google Gemini" "GEMINI_API_KEY" "Gemini Pro, Flash" "AI" ;;
                4) prompt_api_key "Brave Search" "BRAVE_API_KEY" "Web Search API" "" ;;
                5) prompt_api_key "Serper" "SERPER_API_KEY" "Google Search API" "" ;;
                6) prompt_api_key "Tavily" "TAVILY_API_KEY" "AI Search API" "tvly-" ;;
                7) prompt_api_key "Resend" "RESEND_API_KEY" "Email API" "re_" ;;
                8) prompt_api_key "Firecrawl" "FIRECRAWL_API_KEY" "Web Scraping" "" ;;
                9) prompt_api_key "Jina AI" "JINA_API_KEY" "Embeddings, Reader" "" ;;
                a|A)
                    prompt_api_key "OpenAI" "OPENAI_API_KEY" "GPT-4, GPT-4o, GPT-3.5" "sk-"
                    prompt_api_key "Anthropic" "ANTHROPIC_API_KEY" "Claude 3.5, Claude 3" "sk-ant-"
                    prompt_api_key "Google Gemini" "GEMINI_API_KEY" "Gemini Pro, Flash" "AI"
                    prompt_api_key "Brave Search" "BRAVE_API_KEY" "Web Search API" ""
                    prompt_api_key "Serper" "SERPER_API_KEY" "Google Search API" ""
                    prompt_api_key "Tavily" "TAVILY_API_KEY" "AI Search API" "tvly-"
                    prompt_api_key "Resend" "RESEND_API_KEY" "Email API" "re_"
                    prompt_api_key "Firecrawl" "FIRECRAWL_API_KEY" "Web Scraping" ""
                    prompt_api_key "Jina AI" "JINA_API_KEY" "Embeddings, Reader" ""
                    ;;
                v|V) show_current_config ;;
                s|S)
                    validate_all_apis
                    save_configuration
                    print_summary
                    return 0
                    ;;
                q|Q)
                    log_info "Saliendo sin guardar"
                    return 0
                    ;;
                *) log_warn "Opción inválida" ;;
            esac
        done
    else
        # Modo no interactactivo
        validate_all_apis
        save_configuration
        print_summary
    fi
}

main "$@"