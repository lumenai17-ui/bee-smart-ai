#!/usr/bin/env bash
#===============================================================================
# TURNKEY v6 - FASE 5: Validate All Channels
#===============================================================================
# Valida el funcionamiento de todos los canales configurados:
# - WhatsApp
# - Telegram
# - Discord
# - Email
# Genera reporte de estado
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
REPORT_DIR="$OPENCLAW_DIR/reports"
REPORT_FILE="$REPORT_DIR/channel-validation-$(date +%Y%m%d_%H%M%S).json"

# Resultados
declare -A CHANNEL_STATUS
declare -A CHANNEL_DETAILS
ERRORS=()

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

add_error() {
    ERRORS+=("$1")
}

set_channel_status() {
    local channel="$1"
    local status="$2"
    local details="${3:-}"
    
    CHANNEL_STATUS["$channel"]="$status"
    CHANNEL_DETAILS["$channel"]="$details"
}

#===============================================================================
# VALIDACIÓN WHATSAPP
#===============================================================================

validate_whatsapp() {
    log_step "Validando WhatsApp..."
    
    local status_file="$SECRETS_DIR/whatsapp-session.json"
    local config_file="$CONFIG_DIR/whatsapp.yaml"
    
    # Verificar configuración
    if [[ ! -f "$config_file" ]]; then
        log_warn "Configuración WhatsApp no encontrada"
        set_channel_status "whatsapp" "not_configured" "Archivo $config_file no existe"
        return 0
    fi
    
    # Verificar sesión/secretos
    if [[ ! -f "$status_file" ]]; then
        log_warn "Sesión WhatsApp no encontrada"
        set_channel_status "whatsapp" "not_authenticated" "Se requiere autenticación QR"
        return 0
    fi
    
    # Verificar estado de la sesión
    local session_status
    session_status=$(jq -r '.status // "unknown"' "$status_file" 2>/dev/null || echo "unknown")
    
    case "$session_status" in
        "connected"|"authenticated")
            log_success "WhatsApp conectado"
            set_channel_status "whatsapp" "connected" "Sesión activa"
            
            # Obtener info del dispositivo
            local phone=$(jq -r '.phone // .wid // "unknown"' "$status_file" 2>/dev/null || echo "unknown")
            local name=$(jq -r '.name // .pushname // "unknown"' "$status_file" 2>/dev/null || echo "unknown")
            log_info "Teléfono: $phone, Nombre: $name"
            CHANNEL_DETAILS["whatsapp"]="Phone: $phone, Name: $name"
            ;;
        "connecting"|"loading")
            log_warn "WhatsApp conectando..."
            set_channel_status "whatsapp" "connecting" "En proceso de conexión"
            ;;
        "disconnected"|"auth_failure")
            log_error "WhatsApp desconectado"
            set_channel_status "whatsapp" "disconnected" "Sesión expirada o inválida"
            add_error "WhatsApp: sesión inválida, requiere re-autenticación"
            ;;
        *)
            log_warn "Estado WhatsApp desconocido: $session_status"
            set_channel_status "whatsapp" "unknown" "Estado: $session_status"
            ;;
    esac
    
    # Verificar webhook/API si está configurado
    local webhook_url=$(jq -r '.webhook.url // empty' "$config_file" 2>/dev/null || echo "")
    if [[ -n "$webhook_url" ]]; then
        log_info "Verificando webhook: $webhook_url"
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$webhook_url" --connect-timeout 5 2>/dev/null || echo "000")
        
        if [[ "$response" =~ ^2[0-9][0-9]$ ]]; then
            log_success "Webhook WhatsApp responde (HTTP $response)"
        else
            log_warn "Webhook WhatsApp no responde correctamente (HTTP $response)"
        fi
    fi
    
    return 0
}

#===============================================================================
# VALIDACIÓN TELEGRAM
#===============================================================================

validate_telegram() {
    log_step "Validando Telegram..."
    
    local secrets_file="$SECRETS_DIR/telegram-secrets.yaml"
    local config_file="$CONFIG_DIR/telegram.yaml"
    
    # Verificar secretos
    if [[ ! -f "$secrets_file" ]]; then
        log_warn "Secretos Telegram no encontrados"
        set_channel_status "telegram" "not_configured" "Archivo $secrets_file no existe"
        return 0
    fi
    
    # Extraer token
    local bot_token=$(grep 'bot_token:' "$secrets_file" 2>/dev/null | head -1 | sed 's/bot_token: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
    
    if [[ -z "$bot_token" ]]; then
        log_error "No se pudo extraer el bot token"
        set_channel_status "telegram" "missing_token" "Token no encontrado en secrets"
        add_error "Telegram: bot_token no configurado"
        return 0
    fi
    
    # Validar token con API de Telegram
    log_info "Verificando bot token..."
    
    local response
    response=$(curl -s "https://api.telegram.org/bot$bot_token/getMe" --connect-timeout 10 2>/dev/null || echo '{"ok":false,"description":"Connection failed"}')
    
    if echo "$response" | jq -e '.ok == true' &>/dev/null; then
        local bot_username=$(echo "$response" | jq -r '.result.username')
        local bot_id=$(echo "$response" | jq -r '.result.id')
        
        log_success "Bot Telegram válido: @$bot_username"
        set_channel_status "telegram" "connected" "Bot: @$bot_username (ID: $bot_id)"
        
        # Verificar webhook
        local webhook_response
        webhook_response=$(curl -s "https://api.telegram.org/bot$bot_token/getWebhookInfo" --connect-timeout 10 2>/dev/null || echo '{}')
        
        local webhook_url=$(echo "$webhook_response" | jq -r '.result.url // empty')
        local pending=$(echo "$webhook_response" | jq -r '.result.pending_update_count // 0')
        
        if [[ -n "$webhook_url" ]]; then
            log_info "Webhook: $webhook_url (pendientes: $pending)"
            
            # Verificar que el webhook responde
            local wh_status=$(curl -s -o /dev/null -w "%{http_code}" "$webhook_url" --connect-timeout 5 2>/dev/null || echo "000")
            if [[ "$wh_status" =~ ^2[0-9][0-9]$ ]]; then
                log_success "Webhook Telegram responde"
            else
                log_warn "Webhook Telegram no responde (HTTP $wh_status)"
                CHANNEL_DETAILS["telegram"]+=" | Webhook HTTP $wh_status"
            fi
        else
            log_info "Sin webhook (modo polling)"
            CHANNEL_DETAILS["telegram"]+=" | Modo polling"
        fi
        
        # Verificar actualizaciones pendientes
        if [[ "$pending" -gt 5 ]]; then
            log_warn "Hay $pending actualizaciones pendientes"
            CHANNEL_DETAILS["telegram"]+=" | $pending updates pendientes"
        fi
        
    else
        local error=$(echo "$response" | jq -r '.description // "Error desconocido"')
        log_error "Token inválido: $error"
        set_channel_status "telegram" "invalid_token" "$error"
        add_error "Telegram: token inválido - $error"
    fi
    
    # Verificar allowed users
    local allowed_users=$(grep -A 100 'allowed_users:' "$config_file" 2>/dev/null | grep -E '^\s+-\s+[0-9]+$' | wc -l || echo "0")
    if [[ "$allowed_users" -gt 0 ]]; then
        log_info "Usuarios permitidos: $allowed_users"
    fi
    
    return 0
}

#===============================================================================
# VALIDACIÓN DISCORD
#===============================================================================

validate_discord() {
    log_step "Validando Discord..."
    
    local secrets_file="$SECRETS_DIR/discord-secrets.yaml"
    local config_file="$CONFIG_DIR/discord.yaml"
    
    # Verificar secretos
    if [[ ! -f "$secrets_file" ]]; then
        log_warn "Secretos Discord no encontrados"
        set_channel_status "discord" "not_configured" "Archivo $secrets_file no existe"
        return 0
    fi
    
    # Extraer token
    local bot_token=$(grep 'bot_token:' "$secrets_file" 2>/dev/null | head -1 | sed 's/bot_token: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
    
    if [[ -z "$bot_token" ]]; then
        log_error "No se pudo extraer el bot token"
        set_channel_status "discord" "missing_token" "Token no encontrado en secrets"
        add_error "Discord: bot_token no configurado"
        return 0
    fi
    
    # Validar token con API de Discord
    log_info "Verificando bot token..."
    
    local response
    response=$(curl -s "https://discord.com/api/v10/users/@me" \
        -H "Authorization: Bot $bot_token" \
        --connect-timeout 10 2>/dev/null || echo '{"code":0,"message":"Connection failed"}')
    
    if echo "$response" | jq -e '.id' &>/dev/null; then
        local bot_id=$(echo "$response" | jq -r '.id')
        local bot_username=$(echo "$response" | jq -r '.username')
        local bot_discriminator=$(echo "$response" | jq -r '.discriminator // ""')
        local bot_tag="${bot_username}#${bot_discriminator}"
        
        log_success "Bot Discord válido: $bot_tag"
        set_channel_status "discord" "connected" "Bot: $bot_tag (ID: $bot_id)"
        
        # Verificar guilds
        local guilds_response
        guilds_response=$(curl -s "https://discord.com/api/v10/users/@me/guilds" \
            -H "Authorization: Bot $bot_token" \
            --connect-timeout 10 2>/dev/null || echo '[]')
        
        local guild_count=$(echo "$guilds_response" | jq -r 'length // 0')
        log_info "Servidores conectados: $guild_count"
        CHANNEL_DETAILS["discord"]+=" | $guild_count servidores"
        
        # Listar guilds si hay pocos
        if [[ "$guild_count" -le 5 && "$guild_count" -gt 0 ]]; then
            echo "$guilds_response" | jq -r '.[] | "  - \(.name) (\(.id))"' 2>/dev/null
        fi
        
        # Verificar intents
        local application_response
        application_response=$(curl -s "https://discord.com/api/v10/applications/@me" \
            -H "Authorization: Bot $bot_token" \
            --connect-timeout 10 2>/dev/null || echo '{}')
        
        local flags=$(echo "$application_response" | jq -r '.flags // 0')
        log_info "Application flags: $flags"
        
    else
        local error=$(echo "$response" | jq -r '.message // "Error desconocido"')
        log_error "Token inválido: $error"
        set_channel_status "discord" "invalid_token" "$error"
        add_error "Discord: token inválido - $error"
    fi
    
    # Verificar configuración de canales
    if [[ -f "$config_file" ]]; then
        local guild_id=$(grep 'guild_id:' "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        if [[ -n "$guild_id" ]]; then
            log_info "Guild configurado: $guild_id"
        fi
    fi
    
    return 0
}

#===============================================================================
# VALIDACIÓN EMAIL
#===============================================================================

validate_email() {
    log_step "Validando Email..."
    
    local config_file="$CONFIG_DIR/email.yaml"
    local secrets_file="$SECRETS_DIR/email-secrets.yaml"
    
    # Verificar configuración
    if [[ ! -f "$config_file" ]]; then
        log_warn "Configuración Email no encontrada"
        set_channel_status "email" "not_configured" "Archivo $config_file no existe"
        return 0
    fi
    
    # Extraer configuración
    local imap_host=$(grep -A5 '^imap:' "$config_file" 2>/dev/null | grep 'host:' | head -1 | awk '{print $2}' | tr -d '"' || echo "")
    local imap_port=$(grep -A5 '^imap:' "$config_file" 2>/dev/null | grep 'port:' | head -1 | awk '{print $2}' || echo "993")
    local imap_user=$(grep -A5 '^imap:' "$config_file" 2>/dev/null | grep 'user:' | head -1 | awk '{print $2}' | tr -d '"' || echo "")
    
    local smtp_enabled=$(grep -A5 '^smtp:' "$config_file" 2>/dev/null | grep 'enabled:' | head -1 | awk '{print $2}' || echo "false")
    local resend_enabled=$(grep -A5 '^resend:' "$config_file" 2>/dev/null | grep 'enabled:' | head -1 | awk '{print $2}' || echo "false")
    
    local imap_pass=""
    local resend_key=""
    
    if [[ -f "$secrets_file" ]]; then
        imap_pass=$(grep 'imap_password:' "$secrets_file" 2>/dev/null | head -1 | sed 's/imap_password: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
        resend_key=$(grep 'resend_api_key:' "$secrets_file" 2>/dev/null | head -1 | sed 's/resend_api_key: *["'"'"']\?//;s/["'"'"'] *$//' || echo "")
    fi
    
    local status="unknown"
    local details=""
    
    # Validar IMAP
    if [[ -n "$imap_host" && -n "$imap_user" && -n "$imap_pass" ]]; then
        log_info "Probando conexión IMAP a $imap_host:$imap_port..."
        
        # Test TCP
        if timeout 10 bash -c "echo '' | nc -w 5 $imap_host $imap_port" &> /dev/null; then
            log_success "Conexión IMAP TCP exitosa"
            
            # Test autenticación con Python
            if command -v python3 &> /dev/null; then
                local auth_result
                auth_result=$(IMAP_HOST="$imap_host" IMAP_PORT="$imap_port" \
                             IMAP_USER="$imap_user" IMAP_PASS="$imap_pass" \
                             python3 << 'PYEOF' 2>&1 || echo "ERROR:Python failed")
import imaplib
import ssl
import os

try:
    host = os.environ.get('IMAP_HOST', '')
    port = int(os.environ.get('IMAP_PORT', 993))
    user = os.environ.get('IMAP_USER', '')
    password = os.environ.get('IMAP_PASS', '')
    
    context = ssl.create_default_context()
    mail = imaplib.IMAP4_SSL(host, port, ssl_context=context)
    mail.login(user, password)
    mail.select('INBOX')
    status, messages = mail.search(None, 'ALL')
    count = len(messages[0].split()) if messages[0] else 0
    mail.logout()
    print(f"SUCCESS:{count}")
except Exception as e:
    print(f"ERROR:{e}")
PYEOF

                if [[ "$auth_result" == SUCCESS:* ]]; then
                    local count="${auth_result#SUCCESS:}"
                    log_success "IMAP autenticado ($count mensajes)"
                    status="connected"
                    details="IMAP: $imap_host ($count msgs)"
                else
                    log_error "IMAP auth falló: ${auth_result#ERROR:}"
                    status="auth_failed"
                    details="IMAP auth failed: ${auth_result#ERROR:}"
                    add_error "Email: IMAP authentication failed"
                fi
            else
                log_warn "Python no disponible, solo verificación TCP"
                status="partial"
                details="IMAP: $imap_host (TCP OK, auth no verificada)"
            fi
        else
            log_error "No se puede conectar a IMAP $imap_host:$imap_port"
            status="connection_failed"
            details="IMAP connection failed"
            add_error "Email: IMAP connection failed"
        fi
    else
        log_warn "IMAP no configurado completamente"
        [[ -z "$imap_host" ]] && details+="IMAP host faltante. "
        [[ -z "$imap_user" ]] && details+="IMAP user faltante. "
        [[ -z "$imap_pass" ]] && details+="IMAP password faltante."
    fi
    
    # Validar Resend
    if [[ "$resend_enabled" == "true" && -n "$resend_key" ]]; then
        log_info "Probando Resend API..."
        
        local resend_response
        resend_response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $resend_key" \
            "https://api.resend.com/domains" --connect-timeout 10 2>/dev/null || echo "000")
        
        if [[ "$resend_response" == "200" ]]; then
            log_success "Resend API OK"
            details+=" | Resend: OK"
        else
            log_warn "Resend API respuesta: HTTP $resend_response"
            details+=" | Resend: HTTP $resend_response"
        fi
    fi
    
    # Validar SMTP
    if [[ "$smtp_enabled" == "true" ]]; then
        local smtp_host=$(grep -A10 '^smtp:' "$config_file" 2>/dev/null | grep 'host:' | head -1 | awk '{print $2}' | tr -d '"' || echo "")
        
        if [[ -n "$smtp_host" ]]; then
            log_info "SMTP configurado: $smtp_host"
            details+=" | SMTP: $smtp_host"
        fi
    fi
    
    set_channel_status "email" "${status:-not_configured}" "${details:-Sin configuración}"
    return 0
}

#===============================================================================
# RESUMEN Y REPORTE
#===============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ESTADO DE CANALES - RESUMEN                   ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    for channel in whatsapp telegram discord email; do
        local status="${CHANNEL_STATUS[$channel]:-unknown}"
        local details="${CHANNEL_DETAILS[$channel]:-}"
        
        local status_icon
        case "$status" in
            "connected") status_icon="${GREEN}✓${NC}" ;;
            "not_configured") status_icon="${YELLOW}○${NC}" ;;
            "partial") status_icon="${YELLOW}◐${NC}" ;;
            "connecting") status_icon="${BLUE}○${NC}" ;;
            *) status_icon="${RED}✗${NC}" ;;
        esac
        
        printf "${CYAN}║${NC} %-12s %s ${status_icon}${NC}\n" "$(echo $channel | tr '[:lower:]' '[:upper:]')" "$status"
        
        if [[ -n "$details" ]]; then
            echo -e "${CYAN}║${NC}               ${YELLOW}${details}${NC}"
        fi
    done
    
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    local total=${#CHANNEL_STATUS[@]}
    local ok=$(printf '%s\n' "${CHANNEL_STATUS[@]}" | grep -c "^connected$" || echo 0)
    local partial=$(printf '%s\n' "${CHANNEL_STATUS[@]}" | grep -c "^partial$" || echo 0)
    local not_config=$(printf '%s\n' "${CHANNEL_STATUS[@]}" | grep -c "^not_configured$" || echo 0)
    local failed=$((total - ok - partial - not_config))
    
    echo -e "${CYAN}║${NC} Conectados:    ${GREEN}$ok${NC}"
    echo -e "${CYAN}║${NC} Parciales:     ${YELLOW}$partial${NC}"
    echo -e "${CYAN}║${NC} No configurados: ${YELLOW}$not_config${NC}"
    echo -e "${CYAN}║${NC} Con errores:   ${RED}$failed${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo -e "${CYAN}║${NC} ${RED}ERRORES:${NC}"
        for err in "${ERRORS[@]}"; do
            echo -e "${CYAN}║${NC}   ${RED}!${NC} $err"
        done
        echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    fi
    
    echo -e "${CYAN}║${NC} Reporte: ${YELLOW}$REPORT_FILE${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

save_report() {
    log_step "Guardando reporte..."
    
    mkdir -p "$REPORT_DIR"
    
    # Construir JSON del reporte
    local json="{"
    json+="\"timestamp\":\"$(date -Iseconds)\","
    json+="\"channels\":{"
    
    local first=true
    for channel in whatsapp telegram discord email; do
        [[ "$first" == "false" ]] && json+=","
        first=false
        
        json+="\"$channel\":{"
        json+="\"status\":\"${CHANNEL_STATUS[$channel]:-unknown}\","
        json+="\"details\":\"${CHANNEL_DETAILS[$channel]:-}\","
        json+="\"configured\":\"$([[ -f "$SECRETS_DIR/${channel}-secrets.yaml" ]] && echo "true" || echo "false")\""
        json+="}"
    done
    
    json+="},"
    json+="\"errors\":$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)"
    json+="}"
    
    echo "$json" | jq '.' > "$REPORT_FILE"
    log_success "Reporte guardado: $REPORT_FILE"
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        TURNKEY v6 - VALIDATE ALL CHANNELS                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_dependencies
    
    # Validar cada canal
    validate_whatsapp
    validate_telegram
    validate_discord
    validate_email
    
    # Guardar reporte
    save_report
    
    # Mostrar resumen
    print_summary
    
    # Retornar código de salida
    local failed=$(printf '%s\n' "${CHANNEL_STATUS[@]}" | grep -cE "^(auth_failed|connection_failed|invalid_token|disconnected|error)$" || echo 0)
    
    if [[ $failed -gt 0 ]]; then
        log_error "$failed canal(es) con errores"
        return 1
    elif [[ ${#ERRORS[@]} -gt 0 ]]; then
        log_warn "Validación completada con advertencias"
        return 0
    else
        log_success "Todos los canales validados correctamente"
        return 0
    fi
}

main "$@"