#!/usr/bin/env bash
#===============================================================================
# TURNKEY v6 - FASE 5: Setup Telegram Bot
#===============================================================================
# Configura bot de Telegram para OpenClaw:
# - Creación/asistencia con BotFather
# - Configuración de webhook
# - Allowed users
# - Validación de funcionamiento
#===============================================================================
# Corregido: 2026-03-06 - Auditoría Multigente
# - Agregado trap para cleanup
# - Agregado validación de FASE 4
# - Agregado validación de prerequisitos
#===============================================================================

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Paths
readonly OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
readonly CONFIG_DIR="$OPENCLAW_DIR/config"
readonly SECRETS_DIR="$OPENCLAW_DIR/secrets"
readonly TELEGRAM_CONFIG="$CONFIG_DIR/telegram.yaml"
readonly TELEGRAM_SECRETS="$SECRETS_DIR/telegram-secrets.yaml"

# Estado
CLEANUP_NEEDED=false

# Configuración
BOT_TOKEN=""
BOT_USERNAME=""
WEBHOOK_URL=""
WEBHOOK_PORT="8443"
ALLOWED_USERS=()
ADMIN_USERS=()
WEBHOOK_SECRET=""
MAX_CONNECTIONS=40

#===============================================================================
# CLEANUP
#===============================================================================

cleanup_on_failure() {
    local exit_code=$?
    
    if [[ "$CLEANUP_NEEDED" == "true" && $exit_code -ne 0 ]]; then
        log_error "Falló la configuración. Limpiando..."
        rm -f "$TELEGRAM_CONFIG" 2>/dev/null || true
        rm -f "$TELEGRAM_SECRETS" 2>/dev/null || true
        log_warn "Archivos parciales removidos"
    fi
    
    exit $exit_code
}

mark_success() {
    CLEANUP_NEEDED=false
}

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

#===============================================================================
# UTILIDADES
#===============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}==>${NC} $1"; }

check_phase4() {
    log_step "Validando FASE 4..."
    
    # Verificar que FASE 4 está completa
    local phase4_files=(
        "$CONFIG_DIR/.fase4-status.json"
        "$CONFIG_DIR/.identity-status.json"
        "$CONFIG_DIR/.fleet-status.json"
        "$OPENCLAW_DIR/openclaw.json"
    )
    
    local found=false
    for file in "${phase4_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "FASE 4 detectada: $file"
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        log_error "FASE 4 no completada"
        log_error "Ejecutar primero: phases/04-identity-fleet/setup-fase4.sh"
        exit 1
    fi
}

check_dependencies() {
    log_step "Verificando dependencias..."
    
    # Primero validar FASE 4
    check_phase4
    
    local deps=("curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing[*]}"
        log_info "Instalando dependencias..."
        sudo apt-get update && sudo apt-get install -y "${missing[@]}"
    fi
    
    log_success "Dependencias verificadas"
}

#===============================================================================
# INTERACCIÓN CON BOTFATHER
#===============================================================================

show_botfather_guide() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           GUÍA DE CREACIÓN DE BOT - BotFather              ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} 1. Abre Telegram y busca: ${GREEN}@BotFather${NC}"
    echo -e "${CYAN}║${NC} 2. Envía: ${YELLOW}/newbot${NC}"
    echo -e "${CYAN}║${NC} 3. Sigue las instrucciones:"
    echo -e "${CYAN}║${NC}    - Nombre del bot (ej: OpenClaw Assistant)"
    echo -e "${CYAN}║${NC}    - Username del bot (ej: OpenClaw_bot)"
    echo -e "${CYAN}║${NC} 4. ${GREEN}COPIA EL TOKEN${NC} que BotFather te dé"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Comandos útiles adicionales:"
    echo -e "${CYAN}║${NC}   ${YELLOW}/setdescription${NC} - Descripción del bot"
    echo -e "${CYAN}║${NC}   ${YELLOW}/setabouttext${NC}   - Texto "About"
    echo -e "${CYAN}║${NC}   ${YELLOW}/setuserpic${NC}     - Imagen del bot"
    echo -e "${CYAN}║${NC}   ${YELLOW}/setcommands${NC}    - Lista de comandos"
    echo -e "${CYAN}║${NC}   ${YELLOW}/setprivacy${NC}     - Modo privacidad"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

prompt_bot_token() {
    log_step "Configuración del Bot Token"
    echo ""
    
    echo "¿Tienes ya un bot token?"
    echo "  1) Sí, tengo el token"
    echo "  2) No, necesito crear un bot"
    echo "  3) Salir y crear manualmente"
    read -p "Opción [1]: " opt
    opt="${opt:-1}"
    
    case "$opt" in
        1)
            read -p "Bot Token: " BOT_TOKEN
            ;;
        2)
            show_botfather_guide
            read -p "Pega el token que BotFather te dio: " BOT_TOKEN
            ;;
        3)
            log_info "Abre Telegram y habla con @BotFather"
            exit 0
            ;;
        *)
            log_error "Opción inválida"
            exit 1
            ;;
    esac
}

#===============================================================================
# VALIDACIONES
#===============================================================================

validate_bot_token() {
    log_step "Validando bot token..."
    
    if [[ -z "$BOT_TOKEN" ]]; then
        log_error "Bot token no proporcionado"
        return 1
    fi
    
    # Formato del token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
    if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        log_error "Formato de token inválido"
        log_info "Formato esperado: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
        return 1
    fi
    
    # Test con getMe
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")
    
    if echo "$response" | jq -e '.ok == true' &>/dev/null; then
        BOT_USERNAME=$(echo "$response" | jq -r '.result.username')
        local bot_id=$(echo "$response" | jq -r '.result.id')
        local first_name=$(echo "$response" | jq -r '.result.first_name')
        
        log_success "Bot válido: @${BOT_USERNAME} (ID: $bot_id)"
        log_info "Nombre: $first_name"
        return 0
    else
        local error_desc=$(echo "$response" | jq -r '.description // "Error desconocido"')
        log_error "Token inválido: $error_desc"
        return 1
    fi
}

get_bot_info() {
    log_step "Obteniendo información del bot..."
    
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe")
    
    echo "Bot Info:"
    echo "$response" | jq -r '.result | "  ID: \(.id)\n  Username: @\(.username)\n  Nombre: \(.first_name)\n  Puede unirse a grupos: \(.can_join_groups)\n  Puede leer mensajes: \(.can_read_all_group_messages)"'
}

get_webhook_info() {
    log_step "Estado actual del webhook..."
    
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getWebhookInfo")
    
    if echo "$response" | jq -e '.ok == true' &>/dev/null; then
        local url=$(echo "$response" | jq -r '.result.url')
        local pending=$(echo "$response" | jq -r '.result.pending_update_count')
        
        if [[ -n "$url" && "$url" != "null" && "$url" != "" ]]; then
            log_info "Webhook actual: $url"
            log_info "Updates pendientes: $pending"
        else
            log_info "Sin webhook configurado"
            log_info "Updates pendientes: $pending (usar getUpdates o configurar webhook)"
        fi
    fi
}

#===============================================================================
# CONFIGURACIÓN DE WEBHOOK
#===============================================================================

configure_webhook() {
    log_step "Configurando webhook..."
    echo ""
    
    if [[ -z "$WEBHOOK_URL" ]]; then
        echo "Métodos de webhook:"
        echo "  1) HTTPS público (requiere certificado válido)"
        echo "  2) Usar ngrok/cloudflared para túnel"
        echo "  3) Long polling (sin webhook)"
        echo "  4) Omitir por ahora"
        read -p "Opción [4]: " method
        method="${method:-4}"
        
        case "$method" in
            1)
                read -p "URL del webhook (https://...): " WEBHOOK_URL
                ;;
            2)
                setup_tunnel_webhook
                ;;
            3)
                log_info "Usando long polling. Configura un servicio para getUpdates."
                WEBHOOK_URL="polling"
                return 0
                ;;
            4)
                log_info "Webhook omitido por ahora"
                return 0
                ;;
        esac
    fi
    
    if [[ "$WEBHOOK_URL" == "polling" ]]; then
        log_info "Modo polling seleccionado"
        return 0
    fi
    
    # Generar secret para webhook
    WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -hex 32)}"
    
    # Configurar webhook
    local webhook_endpoint="${WEBHOOK_URL}/telegram/webhook"
    
    log_info "Configurando webhook: $webhook_endpoint"
    
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/setWebhook" \
        -H "Content-Type: application/json" \
        -d "{
            \"url\": \"$webhook_endpoint\",
            \"secret_token\": \"$WEBHOOK_SECRET\",
            \"max_connections\": $MAX_CONNECTIONS,
            \"allowed_updates\": [\"message\", \"edited_message\", \"callback_query\", \"inline_query\"]
        }")
    
    if echo "$response" | jq -e '.result == true' &>/dev/null; then
        log_success "Webhook configurado correctamente"
    else
        local error=$(echo "$response" | jq -r '.description // "Error desconocido"')
        log_error "Error configurando webhook: $error"
        return 1
    fi
}

setup_tunnel_webhook() {
    log_step "Configurando túnel..."
    
    echo "Herramienta de túnel:"
    echo "  1) cloudflared (recomendado)"
    echo "  2) ngrok"
    read -p "Opción [1]: " tunnel_tool
    tunnel_tool="${tunnel_tool:-1}"
    
    read -p "Puerto local del servidor [3000]: " local_port
    local_port="${local_port:-3000}"
    
    case "$tunnel_tool" in
        1)
            if ! command -v cloudflared &>/dev/null; then
                log_info "Instalando cloudflared..."
                curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
                chmod +x /tmp/cloudflared
                sudo mv /tmp/cloudflared /usr/local/bin/
            fi
            
            log_info "Iniciando túnel cloudflared..."
            WEBHOOK_URL=$(cloudflared tunnel --url "http://localhost:$local_port" 2>&1 | grep -oP 'https://[^\s]+\.trycloudflare\.com' | head -1)
            
            if [[ -n "$WEBHOOK_URL" ]]; then
                log_success "Túnel creado: $WEBHOOK_URL"
            else
                log_error "No se pudo obtener URL del túnel"
                return 1
            fi
            ;;
        2)
            if ! command -v ngrok &>/dev/null; then
                log_error "ngrok no está instalado. Instálalo desde https://ngrok.com"
                return 1
            fi
            
            log_info "Iniciando túnel ngrok..."
            WEBHOOK_URL=$(ngrok http $local_port --log=stdout 2>&1 | grep -oP 'https://[^\s]+\.ngrok\.io' | head -1) || true
            
            # Alternativa: usar API de ngrok
            if [[ -z "$WEBHOOK_URL" ]]; then
                WEBHOOK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null) || true
            fi
            
            if [[ -n "$WEBHOOK_URL" ]]; then
                log_success "Túnel creado: $WEBHOOK_URL"
            else
                log_error "No se pudo obtener URL del túnel"
                return 1
            fi
            ;;
    esac
}

delete_webhook() {
    log_info "Eliminando webhook..."
    
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/deleteWebhook")
    
    if echo "$response" | jq -e '.result == true' &>/dev/null; then
        log_success "Webhook eliminado"
    else
        log_warn "No se pudo eliminar el webhook"
    fi
}

#===============================================================================
# ALLOWED USERS
#===============================================================================

configure_allowed_users() {
    log_step "Configurando usuarios permitidos..."
    echo ""
    
    echo "¿Restringir acceso a usuarios específicos?"
    echo "  1) Sí, lista blanca de usuarios"
    echo "  2) No, permitir todos"
    read -p "Opción [1]: " restrict
    restrict="${restrict:-1}"
    
    if [[ "$restrict" == "1" ]]; then
        echo ""
        echo "Ingresa los IDs de usuario permitidos (uno por línea, vacío para terminar):"
        echo "  Tip: Para obtener tu ID, habla con @userinfobot en Telegram"
        
        while true; do
            read -p "User ID: " user_id
            [[ -z "$user_id" ]] && break
            
            if [[ "$user_id" =~ ^[0-9]+$ ]]; then
                ALLOWED_USERS+=("$user_id")
                log_info "Añadido: $user_id"
            else
                log_warn "ID inválido: $user_id"
            fi
        done
        
        echo ""
        echo "IDs de administradores (pueden añadir/quitar usuarios):"
        while true; do
            read -p "Admin ID: " admin_id
            [[ -z "$admin_id" ]] && break
            
            if [[ "$admin_id" =~ ^[0-9]+$ ]]; then
                ADMIN_USERS+=("$admin_id")
                log_info "Admin añadido: $admin_id"
            else
                log_warn "ID inválido: $admin_id"
            fi
        done
    else
        log_info "Permitiendo acceso a todos los usuarios"
    fi
    
    log_info "Usuarios permitidos: ${ALLOWED_USERS[*]:-todos}"
    log_info "Administradores: ${ADMIN_USERS[*]:-ninguno}"
}

set_bot_commands() {
    log_step "Configurando comandos del bot..."
    
    local commands='[
        {"command": "start", "description": "Iniciar el bot"},
        {"command": "help", "description": "Mostrar ayuda"},
        {"command": "status", "description": "Ver estado del sistema"},
        {"command": "channels", "description": "Listar canales configurados"},
        {"command": "config", "description": "Ver configuración actual"}
    ]'
    
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/setMyCommands" \
        -H "Content-Type: application/json" \
        -d "{\"commands\": $commands}")
    
    if echo "$response" | jq -e '.result == true' &>/dev/null; then
        log_success "Comandos configurados"
    else
        log_warn "No se pudieron configurar los comandos"
    fi
}

#===============================================================================
# TEST DEL BOT
#===============================================================================

test_bot() {
    log_step "Probando funcionamiento del bot..."
    
    # Obtener actualizaciones pendientes
    local response
    response=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?limit=1&timeout=1")
    
    local update_count=$(echo "$response" | jq -r '.result | length')
    
    if [[ "$update_count" -gt 0 ]]; then
        log_info "Hay $update_count actualización(es) pendiente(s)"
        
        local chat_id=$(echo "$response" | jq -r '.result[0].message.chat.id // empty')
        
        if [[ -n "$chat_id" ]]; then
            read -p "¿Enviar mensaje de prueba al chat $chat_id? [y/N]: " send_test
            if [[ "${send_test,,}" == "y" ]]; then
                local send_response
                send_response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                    -H "Content-Type: application/json" \
                    -d "{
                        \"chat_id\": $chat_id,
                        \"text\": \"✅ OpenClaw Bot configurado correctamente!\\n\\nEl bot está listo para recibir comandos.\",
                        \"parse_mode\": \"Markdown\"
                    }")
                
                if echo "$send_response" | jq -e '.ok == true' &>/dev/null; then
                    log_success "Mensaje de prueba enviado"
                else
                    log_warn "No se pudo enviar el mensaje"
                fi
            fi
        fi
    else
        log_info "No hay actualizaciones pendientes"
        log_info "Envía un mensaje a tu bot (@$BOT_USERNAME) para probarlo"
    fi
    
    log_success "Bot verificado y funcionando"
}

#===============================================================================
# GUARDAR CONFIGURACIÓN
#===============================================================================

save_configuration() {
    log_step "Guardando configuración..."
    
    mkdir -p "$CONFIG_DIR" "$SECRETS_DIR"
    
    # Configuración pública
    cat > "$TELEGRAM_CONFIG" << EOF
# OpenClaw Telegram Bot Configuration
# Generated by setup-telegram.sh

bot:
  username: "@${BOT_USERNAME}"
  polling: $([[ "$WEBHOOK_URL" == "polling" ]] && echo "true" || echo "false")

webhook:
$(if [[ -n "$WEBHOOK_URL" && "$WEBHOOK_URL" != "polling" ]]; then
  cat << EOF2
  enabled: true
  url: "$WEBHOOK_URL"
  endpoint: "/telegram/webhook"
  max_connections: $MAX_CONNECTIONS
EOF2
else
  echo "  enabled: false"
fi)

access:
  restricted: $( [[ ${#ALLOWED_USERS[@]} -gt 0 ]] && echo "true" || echo "false")
  allowed_users:
$(for user in "${ALLOWED_USERS[@]}"; do
  echo "    - $user"
done)
  admin_users:
$(for admin in "${ADMIN_USERS[@]}"; do
  echo "    - $admin"
done)

features:
  commands:
    - start
    - help
    - status
    - channels
    - config
  parse_mode: "Markdown"
EOF

    chmod 644 "$TELEGRAM_CONFIG"
    log_success "Configuración guardada en $TELEGRAM_CONFIG"
    
    # Secrets
    cat > "$TELEGRAM_SECRETS" << EOF
# OpenClaw Telegram Secrets - DO NOT COMMIT
bot_token: "$BOT_TOKEN"
$(if [[ -n "$WEBHOOK_SECRET" ]]; then
  echo "webhook_secret: \"$WEBHOOK_SECRET\""
fi)
EOF

    chmod 600 "$TELEGRAM_SECRETS"
    log_success "Secrets guardados en $TELEGRAM_SECRETS"
}

#===============================================================================
# RESUMEN
#===============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         CONFIGURACIÓN TELEGRAM COMPLETADA                  ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Bot:           ${GREEN}@${BOT_USERNAME}${NC}"
    echo -e "${CYAN}║${NC} Webhook:       ${GREEN}$([[ "$WEBHOOK_URL" == "polling" ]] && echo "Polling" || echo "$WEBHOOK_URL")${NC}"
    echo -e "${CYAN}║${NC} Usuarios:      ${GREEN}$([[ ${#ALLOWED_USERS[@]} -gt 0 ]] && echo "${#ALLOWED_USERS[@]} permitidos" || echo "Todos")${NC}"
    echo -e "${CYAN}║${NC} Admins:        ${GREEN}$([[ ${#ADMIN_USERS[@]} -gt 0 ]] && echo "${#ADMIN_USERS[@]}" || echo "Ninguno")${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Config:  ${YELLOW}$TELEGRAM_CONFIG${NC}"
    echo -e "${CYAN}║${NC} Secrets: ${YELLOW}$TELEGRAM_SECRETS${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Próximos pasos:${NC}"
    echo -e "${CYAN}║${NC} 1. Asegura tu servidor tenga HTTPS válido (si usas webhook)"
    echo -e "${CYAN}║${NC} 2. Configura OpenClaw para escuchar /telegram/webhook"
    echo -e "${CYAN}║${NC} 3. Prueba enviando /start a @${BOT_USERNAME}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        TURNKEY v6 - SETUP TELEGRAM BOT                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_dependencies
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --token) BOT_TOKEN="$2"; shift 2 ;;
            --webhook) WEBHOOK_URL="$2"; shift 2 ;;
            --webhook-secret) WEBHOOK_SECRET="$2"; shift 2 ;;
            --allowed-users) IFS=',' read -ra ALLOWED_USERS <<< "$2"; shift 2 ;;
            --admin-users) IFS=',' read -ra ADMIN_USERS <<< "$2"; shift 2 ;;
            --polling) WEBHOOK_URL="polling"; shift ;;
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
    
    # Si falta token, pedirlo
    if [[ -z "$BOT_TOKEN" ]]; then
        prompt_bot_token
    fi
    
    # Validar bot
    validate_bot_token || exit 1
    
    # Obtener info
    get_bot_info
    get_webhook_info
    
    # Si no es no-interactivo, configurar interactivamente
    if [[ -z "${NON_INTERACTIVE:-}" ]]; then
        configure_webhook || true
        configure_allowed_users
        set_bot_commands
        test_bot
    fi
    
    # Guardar configuración
    save_configuration
    
    # Resumen
    print_summary
    
    log_success "Setup de Telegram completado!"
    return 0
}

main "$@"