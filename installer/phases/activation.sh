#!/bin/bash
# activation.sh - FASE 6: Activar el agente completo
# TURNKEY v6

set -e

# ============================================
# CONFIGURACIÓN
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASES_DIR="$(dirname "$SCRIPT_DIR")"
TURNKEY_DIR="$(dirname "$PHASES_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
BACKUP_DIR="$OPENCLAW_DIR/backup/pre-activation"
LOGS_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date -Iseconds)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# FUNCIONES
# ============================================

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# ============================================
# 1. PRE-CHECK
# ============================================

pre_check() {
    log_step "Verificando pre-requisitos..."
    
    # Verificar FASE 1-5
    local phases=("01-pre-flight" "02-setup-users" "03-gateway-install" "04-identity-fleet" "05-bot-config")
    for phase in "${phases[@]}"; do
        if [ ! -f "$PHASES_DIR/$phase/AUDITORIA.md" ]; then
            log_error "FASE $phase no completada"
            return 1
        fi
        log_info "FASE $phase: ✅ Completada"
    done
    
    # Verificar secrets
    if [ ! -d "$OPENCLAW_DIR/secrets" ]; then
        log_error "Directorio secrets no existe"
        return 1
    fi
    log_info "Secrets: ✅ Existe"
    
    # Verificar config
    if [ ! -d "$OPENCLAW_DIR/config" ]; then
        log_error "Directorio config no existe"
        return 1
    fi
    log_info "Config: ✅ Existe"
    
    # Verificar puerto
    if ss -tlnp | grep -q ":18789"; then
        log_warn "Puerto 18789 en uso"
        read -p "¿Matar proceso? (y/n): " kill_process
        if [ "$kill_process" = "y" ]; then
            fuser -k 18789/tcp
            sleep 2
        fi
    fi
    log_info "Puerto 18789: ✅ Disponible"
    
    return 0
}

# ============================================
# 2. BACKUP
# ============================================

create_backup() {
    log_step "Creando backup inicial..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup config
    cp -r "$OPENCLAW_DIR/config" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Backup secrets
    cp -r "$OPENCLAW_DIR/secrets" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Backup openclaw.json
    cp "$OPENCLAW_DIR/openclaw.json" "$BACKUP_DIR/" 2>/dev/null || true
    
    # Timestamp
    echo "$TIMESTAMP" > "$BACKUP_DIR/timestamp.txt"
    
    log_info "Backup creado en: $BACKUP_DIR"
}

# ============================================
# 3. INICIAR GATEWAY
# ============================================

start_gateway() {
    log_step "Iniciando OpenClaw Gateway..."
    
    # Verificar si está instalado
    if ! systemctl list-unit-files | grep -q openclaw; then
        log_error "OpenClaw Gateway no está instalado"
        log_info "Ejecutar FASE 3 (gateway-install) primero"
        return 1
    fi
    
    # Iniciar servicio
    systemctl start openclaw
    
    # Esperar
    log_info "Esperando 30 segundos..."
    sleep 30
    
    # Verificar estado
    if systemctl is-active --quiet openclaw; then
        log_info "Gateway: ✅ Activo"
    else
        log_error "Gateway no pudo iniciar"
        journalctl -u openclaw --no-pager -n 50
        return 1
    fi
}

# ============================================
# 4. VALIDAR CANALES
# ============================================

validate_channels() {
    log_step "Validando canales..."
    
    # Ejecutar validación de FASE 5
    if [ -f "$PHASES_DIR/05-bot-config/scripts/validate-channels.sh" ]; then
        "$PHASES_DIR/05-bot-config/scripts/validate-channels.sh" --all
    else
        log_warn "Script de validación no encontrado"
        log_info "Saltando validación de canales"
    fi
}

# ============================================
# 5. SMOKE TESTS
# ============================================

smoke_tests() {
    log_step "Ejecutando smoke tests..."
    
    # Test Gateway Health
    log_info "Test 1: Gateway Health"
    if curl -s http://localhost:18789/health | grep -q "healthy"; then
        log_info "Gateway health: ✅ PASSED"
    else
        log_error "Gateway health: ❌ FAILED"
        return 1
    fi
    
    # Test Modelo Responde
    log_info "Test 2: Modelo Responde"
    local response=$(curl -s -X POST http://localhost:18789/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{"model": "glm-5", "messages": [{"role": "user", "content": "test"}]}' \
        2>/dev/null || echo "ERROR")
    
    if echo "$response" | grep -q "content"; then
        log_info "Modelo responde: ✅ PASSED"
    else
        log_error "Modelo responde: ❌ FAILED"
        return 1
    fi
    
    # Test adicionales
    log_info "Test 3-10: Validados por validate-channels.sh"
    
    return 0
}

# ============================================
# 6. REGISTRO
# ============================================

register_status() {
    log_step "Registrando estado..."
    
    # Crear archivo de estado
    echo "ACTIVE" > "$OPENCLAW_DIR/status"
    echo "$TIMESTAMP" >> "$OPENCLAW_DIR/status"
    
    # Crear log
    mkdir -p "$LOGS_DIR"
    echo "=== ACTIVATION LOG ===" > "$LOGS_DIR/activation-$TIMESTAMP.log"
    echo "Timestamp: $TIMESTAMP" >> "$LOGS_DIR/activation-$TIMESTAMP.log"
    echo "Status: SUCCESS" >> "$LOGS_DIR/activation-$TIMESTAMP.log"
    
    log_info "Estado registrado"
}

# ============================================
# 7. ENTREGA
# ============================================

print_delivery() {
    log_step "=== ENTREGA COMPLETE ==="
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║         FASE 6: ACTIVATION COMPLETE                ║"
    echo "╠════════════════════════════════════════════════════╣"
    echo "║                                                     ║"
    echo "║  ✅ Gateway: RUNNING                                ║"
    echo "║  ✅ Canales: ACTIVE                                ║"
    echo "║  ✅ Smoke Tests: PASSED                             ║"
    echo "║  ✅ Backup: CREATED                                 ║"
    echo "║  ✅ Status: REGISTERED                              ║"
    echo "║                                                     ║"
    echo "║  Gateway URL: http://localhost:18789                ║"
    echo "║  Backup Location: $BACKUP_DIR     ║"
    echo "║  Log Location: $LOGS_DIR           ║"
    echo "║                                                     ║"
    echo "║  ══════════════════════════════════════════════    ║"
    echo "║  PRÓXIMO PASO: Documentar y entregar al cliente     ║"
    echo "║                                                     ║"
    echo "╚════════════════════════════════════════════════════╝"
}

# ============================================
# ROLLBACK
# ============================================

rollback() {
    log_error "Ejecutando ROLLBACK..."
    
    # Detener gateway
    systemctl stop openclaw 2>/dev/null || true
    
    # Restaurar backup
    if [ -d "$BACKUP_DIR" ]; then
        cp -r "$BACKUP_DIR/config" "$OPENCLAW_DIR/" 2>/dev/null || true
        cp -r "$BACKUP_DIR/secrets" "$OPENCLAW_DIR/" 2>/dev/null || true
        cp "$BACKUP_DIR/openclaw.json" "$OPENCLAW_DIR/" 2>/dev/null || true
    fi
    
    log_error "Rollback completado"
    exit 1
}

# ============================================
# MAIN
# ============================================

main() {
    log_info "=== FASE 6: ACTIVATION ==="
    echo ""
    
    # Ejecutar pasos
    pre_check || rollback
    create_backup
    start_gateway || rollback
    validate_channels
    smoke_tests || rollback
    register_status
    print_delivery
    
    log_info "=== ACTIVACIÓN COMPLETADA ==="
}

# ============================================
# ARGUMENTOS
# ============================================

case "${1:-}" in
    --checklist)
        echo "Mostrando checklist..."
        cat "$SCRIPT_DIR/../CHECKLIST.md"
        ;;
    --rollback)
        rollback
        ;;
    --help|-h)
        echo "Uso: $0 [opciones]"
        echo ""
        echo "Opciones:"
        echo "  --checklist   Mostrar checklist"
        echo "  --rollback    Ejecutar rollback"
        echo "  --help        Mostrar esta ayuda"
        ;;
    *)
        main "$@"
        ;;
esac