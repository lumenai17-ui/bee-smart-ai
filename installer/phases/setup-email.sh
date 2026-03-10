#!/usr/bin/env bash
#===============================================================================
# TURNKEY v6 - FASE 5: Setup Email Channels (IMAP + SMTP/Resend)
#===============================================================================
# Configura canales de email para OpenClaw:
# - IMAP: Recepción de emails
# - SMTP/Resend: Envío de emails
# - Validación de conexión
# - Creación de buzones
#===============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
CONFIG_DIR="$OPENCLAW_DIR/config"
SECRETS_DIR="$OPENCLAW_DIR/secrets"
EMAIL_CONFIG="$CONFIG_DIR/email.yaml"
EMAIL_SECRETS="$SECRETS_DIR/email-secrets.yaml"

# Configuración por defecto
IMAP_HOST=""
IMAP_PORT="993"
IMAP_USER=""
IMAP_PASS=""
SMTP_HOST=""
SMTP_PORT="587"
SMTP_USER=""
SMTP_PASS=""
RESEND_API_KEY=""
SENDER_EMAIL=""
SENDER_NAME="OpenClaw Bot"

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
    
    local deps=("curl" "openssl" "nc")
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
# CONFIGURACIÓN INTERACTIVA
#===============================================================================

prompt_imap_config() {
    log_step "Configuración IMAP (Recepción)"
    echo ""
    
    read -p "Host IMAP (ej: imap.gmail.com): " IMAP_HOST
    read -p "Puerto IMAP [993]: " IMAP_PORT
    IMAP_PORT="${IMAP_PORT:-993}"
    read -p "Usuario IMAP (email): " IMAP_USER
    read -sp "Password IMAP: " IMAP_PASS
    echo ""
}

prompt_smtp_config() {
    log_step "Configuración SMTP/Resend (Envío)"
    echo ""
    
    echo "Opciones de envío:"
    echo "  1) SMTP tradicional"
    echo "  2) Resend API (recomendado)"
    echo "  3) Ambos"
    read -p "Selecciona opción [2]: " smtp_option
    smtp_option="${smtp_option:-2}"
    
    case "$smtp_option" in
        1|3)
            read -p "Host SMTP (ej: smtp.gmail.com): " SMTP_HOST
            read -p "Puerto SMTP [587]: " SMTP_PORT
            SMTP_PORT="${SMTP_PORT:-587}"
            read -p "Usuario SMTP: " SMTP_USER
            read -sp "Password SMTP: " SMTP_PASS
            echo ""
            ;&
        2|3)
            read -p "Resend API Key: " RESEND_API_KEY
            ;;
    esac
    
    read -p "Email remitente: " SENDER_EMAIL
    read -p "Nombre remitente [OpenClaw Bot]: " SENDER_NAME
    SENDER_NAME="${SENDER_NAME:-OpenClaw Bot}"
}

prompt_from_args() {
    # Permitir configuración vía argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --imap-host) IMAP_HOST="$2"; shift 2 ;;
            --imap-port) IMAP_PORT="$2"; shift 2 ;;
            --imap-user) IMAP_USER="$2"; shift 2 ;;
            --imap-pass) IMAP_PASS="$2"; shift 2 ;;
            --smtp-host) SMTP_HOST="$2"; shift 2 ;;
            --smtp-port) SMTP_PORT="$2"; shift 2 ;;
            --smtp-user) SMTP_USER="$2"; shift 2 ;;
            --smtp-pass) SMTP_PASS="$2"; shift 2 ;;
            --resend-key) RESEND_API_KEY="$2"; shift 2 ;;
            --sender-email) SENDER_EMAIL="$2"; shift 2 ;;
            --sender-name) SENDER_NAME="$2"; shift 2 ;;
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
}

#===============================================================================
# VALIDACIÓN DE CONEXIÓN
#===============================================================================

validate_imap_connection() {
    log_step "Validando conexión IMAP..."
    
    if [[ -z "$IMAP_HOST" || -z "$IMAP_USER" || -z "$IMAP_PASS" ]]; then
        log_error "Configuración IMAP incompleta"
        return 1
    fi
    
    # Test de conexión TCP
    log_info "Probando conexión TCP a $IMAP_HOST:$IMAP_PORT..."
    
    if timeout 10 bash -c "echo '' | nc -w 5 $IMAP_HOST $IMAP_PORT" &> /dev/null; then
        log_success "Conexión TCP exitosa"
    else
        log_error "No se puede conectar a $IMAP_HOST:$IMAP_PORT"
        return 1
    fi
    
    # Test TLS/SSL
    log_info "Verificando certificado SSL/TLS..."
    
    local cert_info
    cert_info=$(echo | openssl s_client -connect "$IMAP_HOST:$IMAP_PORT" -servername "$IMAP_HOST" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null) || true
    
    if [[ -n "$cert_info" ]]; then
        log_success "Certificado SSL válido"
        log_info "$cert_info"
    else
        log_warn "No se pudo verificar el certificado SSL"
    fi
    
    # Test de autenticación (usando Python si está disponible)
    if command -v python3 &> /dev/null; then
        log_info "Probando autenticación IMAP..."
        
        local auth_result
        auth_result=$(python3 << 'PYEOF'
import imaplib
import ssl
import sys
import os

host = os.environ.get('IMAP_HOST', '')
port = int(os.environ.get('IMAP_PORT', 993))
user = os.environ.get('IMAP_USER', '')
password = os.environ.get('IMAP_PASS', '')

try:
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
        ) 2>/dev/null || auth_result="ERROR:Python IMAP failed"
        
        if [[ "$auth_result" == SUCCESS:* ]]; then
            local count="${auth_result#SUCCESS:}"
            log_success "Autenticación IMAP exitosa ($count mensajes en INBOX)"
        else
            log_error "Error de autenticación IMAP: ${auth_result#ERROR:}"
            return 1
        fi
    else
        log_warn "Python no disponible, saltando test de autenticación"
    fi
    
    return 0
}

validate_smtp_connection() {
    log_step "Validando conexión SMTP..."
    
    if [[ -z "$SMTP_HOST" ]]; then
        log_info "SMTP no configurado, usando Resend"
        return 0
    fi
    
    # Test de conexión TCP
    log_info "Probando conexión TCP a $SMTP_HOST:$SMTP_PORT..."
    
    if timeout 10 bash -c "echo '' | nc -w 5 $SMTP_HOST $SMTP_PORT" &> /dev/null; then
        log_success "Conexión TCP SMTP exitosa"
    else
        log_error "No se puede conectar a $SMTP_HOST:$SMTP_PORT"
        return 1
    fi
    
    return 0
}

validate_resend_api() {
    log_step "Validando Resend API..."
    
    if [[ -z "$RESEND_API_KEY" ]]; then
        log_info "Resend API no configurado"
        return 0
    fi
    
    # Validar formato de API key
    if [[ ! "$RESEND_API_KEY" =~ ^re_[a-zA-Z0-9_]+$ ]]; then
        log_warn "Formato de API key Resend puede ser inválido"
    fi
    
    # Test de API
    log_info "Probando conexión a Resend API..."
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $RESEND_API_KEY" \
        "https://api.resend.com/domains" 2>/dev/null) || response="000"
    
    case "$response" in
        200)
            log_success "Resend API conectada correctamente"
            ;;
        401)
            log_error "API key de Resend inválida"
            return 1
            ;;
        *)
            log_warn "Respuesta inesperada de Resend API: HTTP $response"
            ;;
    esac
    
    return 0
}

#===============================================================================
# CREACIÓN DE BUZONES
#===============================================================================

create_mailboxes() {
    log_step "Creando buzones estándar..."
    
    if ! command -v python3 &> /dev/null; then
        log_warn "Python no disponible, saltando creación de buzones"
        return 0
    fi
    
    local mailboxes=("OpenClaw" "OpenClaw/Processed" "OpenClaw/Archive" "OpenClaw/Errors")
    
    python3 << PYEOF
import imaplib
import ssl
import os

host = os.environ.get('IMAP_HOST', '')
port = int(os.environ.get('IMAP_PORT', 993))
user = os.environ.get('IMAP_USER', '')
password = os.environ.get('IMAP_PASS', '')
mailboxes = ${mailboxes[@]@Q}

try:
    context = ssl.create_default_context()
    mail = imaplib.IMAP4_SSL(host, port, ssl_context=context)
    mail.login(user, password)
    
    for mb in mailboxes:
        try:
            result = mail.create(mb)
            if result[0] == 'OK':
                print(f"Created: {mb}")
            else:
                print(f"Exists: {mb}")
        except:
            print(f"Skip: {mb}")
    
    mail.logout()
except Exception as e:
    print(f"Error: {e}")
PYEOF
}

#===============================================================================
# GUARDAR CONFIGURACIÓN
#===============================================================================

save_configuration() {
    log_step "Guardando configuración..."
    
    mkdir -p "$CONFIG_DIR" "$SECRETS_DIR"
    
    # Configuración pública
    cat > "$EMAIL_CONFIG" << EOF
# OpenClaw Email Configuration
# Generated by setup-email.sh

imap:
  host: "$IMAP_HOST"
  port: $IMAP_PORT
  user: "$IMAP_USER"
  tls: true
  mailboxes:
    inbox: "INBOX"
    processed: "OpenClaw/Processed"
    archive: "OpenClaw/Archive"
    errors: "OpenClaw/Errors"

smtp:
$(if [[ -n "$SMTP_HOST" ]]; then
  cat << EOF2
  enabled: true
  host: "$SMTP_HOST"
  port: $SMTP_PORT
  user: "$SMTP_USER"
  tls: true
EOF2
else
  echo "  enabled: false"
fi)

resend:
$(if [[ -n "$RESEND_API_KEY" ]]; then
  echo "  enabled: true"
else
  echo "  enabled: false"
fi)

sender:
  email: "$SENDER_EMAIL"
  name: "$SENDER_NAME"
EOF

    chmod 644 "$EMAIL_CONFIG"
    log_success "Configuración guardada en $EMAIL_CONFIG"
    
    # Secrets (permisos restrictivos)
    cat > "$EMAIL_SECRETS" << EOF
# OpenClaw Email Secrets - DO NOT COMMIT
imap_password: "$IMAP_PASS"
$(if [[ -n "$SMTP_PASS" ]]; then
  echo "smtp_password: \"$SMTP_PASS\""
fi)
$(if [[ -n "$RESEND_API_KEY" ]]; then
  echo "resend_api_key: \"$RESEND_API_KEY\""
fi)
EOF

    chmod 600 "$EMAIL_SECRETS"
    log_success "Secrets guardados en $EMAIL_SECRETS"
}

#===============================================================================
# TEST DE ENVÍO
#===============================================================================

test_send_email() {
    log_step "Probando envío de email..."
    
    read -p "Email de prueba (dejar vacío para saltar): " test_email
    
    if [[ -z "$test_email" ]]; then
        log_info "Test de envío omitido"
        return 0
    fi
    
    if [[ -n "$RESEND_API_KEY" ]]; then
        log_info "Enviando via Resend..."
        
        local response
        response=$(curl -s -X POST "https://api.resend.com/emails" \
            -H "Authorization: Bearer $RESEND_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"from\": \"$SENDER_NAME <$SENDER_EMAIL>\",
                \"to\": [\"$test_email\"],
                \"subject\": \"OpenClaw Email Test\",
                \"text\": \"Este es un email de prueba de OpenClaw.\\n\\nSi recibes este mensaje, la configuración es correcta.\"
            }")
        
        if echo "$response" | grep -q '"id"'; then
            log_success "Email enviado via Resend (ID: $(echo "$response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4))"
        else
            log_error "Error enviando via Resend: $response"
        fi
        
    elif [[ -n "$SMTP_HOST" ]]; then
        log_info "Enviando via SMTP..."
        
        if command -v python3 &> /dev/null; then
            python3 << PYEOF
import smtplib
import ssl
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

try:
    context = ssl.create_default_context()
    with smtplib.SMTP(os.environ.get('SMTP_HOST', ''), int(os.environ.get('SMTP_PORT', 587))) as server:
        server.starttls(context=context)
        server.login(os.environ.get('SMTP_USER', ''), os.environ.get('SMTP_PASS', ''))
        
        msg = MIMEMultipart()
        msg['From'] = os.environ.get('SENDER_EMAIL', '')
        msg['To'] = '$test_email'
        msg['Subject'] = 'OpenClaw Email Test'
        msg.attach(MIMEText('Este es un email de prueba de OpenClaw.\n\nSi recibes este mensaje, la configuración es correcta.', 'plain'))
        
        server.send_message(msg)
        print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
PYEOF
        fi
    else
        log_error "No hay método de envío configurado"
    fi
}

#===============================================================================
# RESUMEN
#===============================================================================

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          CONFIGURACIÓN EMAIL COMPLETADA                    ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} IMAP Host:     ${GREEN}$IMAP_HOST${NC}"
    echo -e "${CYAN}║${NC} IMAP User:     ${GREEN}$IMAP_USER${NC}"
    echo -e "${CYAN}║${NC} SMTP:          ${GREEN}$([ -n "$SMTP_HOST" ] && echo "$SMTP_HOST" || echo "No configurado")${NC}"
    echo -e "${CYAN}║${NC} Resend:        ${GREEN}$([ -n "$RESEND_API_KEY" ] && echo "Configurado" || echo "No configurado")${NC}"
    echo -e "${CYAN}║${NC} Sender:        ${GREEN}$SENDER_EMAIL${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Config:  ${YELLOW}$EMAIL_CONFIG${NC}"
    echo -e "${CYAN}║${NC} Secrets: ${YELLOW}$EMAIL_SECRETS${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        TURNKEY v6 - SETUP EMAIL CHANNELS                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_dependencies
    
    # Parsear argumentos
    prompt_from_args "$@"
    
    # Si falta configuración esencial, pedir interactivamente
    if [[ -z "$IMAP_HOST" && -z "${NON_INTERACTIVE:-}" ]]; then
        prompt_imap_config
        prompt_smtp_config
    fi
    
    # Exportar variables para Python
    export IMAP_HOST IMAP_PORT IMAP_USER IMAP_PASS
    export SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS
    export SENDER_EMAIL
    
    # Validaciones
    validate_imap_connection || log_warn "Problemas con IMAP, continuando..."
    validate_smtp_connection || true
    validate_resend_api || true
    
    # Crear buzones
    create_mailboxes
    
    # Guardar configuración
    save_configuration
    
    # Test de envío
    if [[ -z "${NON_INTERACTIVE:-}" ]]; then
        test_send_email
    fi
    
    # Resumen
    print_summary
    
    log_success "Setup de email completado!"
    return 0
}

main "$@"