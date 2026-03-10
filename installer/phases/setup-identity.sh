#!/bin/bash
#===============================================================================
# FASE 4: IDENTITY FLEET - Setup Identity
#===============================================================================
# Propósito: Configurar identidad del agente (SOUL, USER, MEMORY, HEART, DOPAMINE)
# Uso: ./setup-identity.sh --agent-name "nombre" --business-type "tipo" --business-name "nombre"
# Corregido: 2026-03-06 - Auditoría Multigente
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# CONFIGURACIÓN
#-------------------------------------------------------------------------------

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Directorios
readonly OPENCLAW_DIR="$HOME/.openclaw"
readonly CONFIG_DIR="$OPENCLAW_DIR/config"
readonly DATA_DIR="$OPENCLAW_DIR/data"

# Estado
CLEANUP_NEEDED=false
CREATED_FILES=()

#-------------------------------------------------------------------------------
# FUNCIONES
#-------------------------------------------------------------------------------

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup_on_failure() {
    local exit_code=$?
    
    if [[ "$CLEANUP_NEEDED" == "true" && $exit_code -ne 0 ]]; then
        log_error "Falló la configuración. Limpiando archivos parciales..."
        
        for file in "${CREATED_FILES[@]}"; do
            if [[ -f "$file" ]]; then
                rm -f "$file"
                log_warning "Removido: $file"
            fi
        done
        
        # Remover archivos de estado
        rm -f "$CONFIG_DIR/.identity-status.json" 2>/dev/null || true
    fi
    
    exit $exit_code
}

mark_success() {
    CLEANUP_NEEDED=false
}

usage() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  --agent-name NOMBRE     Nombre del agente (requerido)"
    echo "  --business-type TIPO    Tipo: restaurante, hotel, tienda, servicios, generico"
    echo "  --business-name NOMBRE  Nombre del negocio (requerido)"
    echo "  --email EMAIL           Email de contacto"
    echo "  --timezone ZONA         Zona horaria (default: America/Panama)"
    echo "  --language LANG         Idioma principal (default: es)"
    echo "  --dry-run               Simular ejecución"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --agent-name 'casamahana' --business-type 'restaurante' \\"
    echo "     --business-name 'Casa Mahana' --email 'info@casamahana.com'"
    exit 0
}

validate_json() {
    local file="$1"
    if command -v jq &>/dev/null; then
        if ! jq . "$file" > /dev/null 2>&1; then
            log_error "JSON inválido: $file"
            return 1
        fi
    fi
    return 0
}

#-------------------------------------------------------------------------------
# PARÁMETROS
#-------------------------------------------------------------------------------

# Trap para cleanup
trap cleanup_on_failure EXIT ERR

AGENT_NAME=""
BUSINESS_TYPE=""
BUSINESS_NAME=""
CONTACT_EMAIL=""
TIMEZONE="America/Panama"
LANGUAGE="es"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --agent-name)
            AGENT_NAME="$2"
            shift 2
            ;;
        --business-type)
            BUSINESS_TYPE="$2"
            shift 2
            ;;
        --business-name)
            BUSINESS_NAME="$2"
            shift 2
            ;;
        --email)
            CONTACT_EMAIL="$2"
            shift 2
            ;;
        --timezone)
            TIMEZONE="$2"
            shift 2
            ;;
        --language)
            LANGUAGE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Parámetro desconocido: $1"
            usage
            ;;
    esac
done

# Validar parámetros obligatorios
if [[ -z "$AGENT_NAME" ]]; then
    log_error "--agent-name es obligatorio"
    usage
fi

if [[ -z "$BUSINESS_NAME" ]]; then
    log_error "--business-name es obligatorio"
    usage
fi

# Normalizar business-type
BUSINESS_TYPE="${BUSINESS_TYPE:-generico}"
case "$BUSINESS_TYPE" in
    restaurante|hotel|tienda|servicios|generico)
        ;;
    *)
        log_warning "business-type '$BUSINESS_TYPE' no reconocido, usando 'generico'"
        BUSINESS_TYPE="generico"
        ;;
esac

# Hacer variables readonly después de validar
readonly AGENT_NAME BUSINESS_TYPE BUSINESS_NAME CONTACT_EMAIL TIMEZONE LANGUAGE DRY_RUN

#===============================================================================
# ENCABEZADO
#===============================================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         FASE 4: IDENTITY FLEET - Setup Identity               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}[MODO DRY-RUN]${NC} Solo simulación"
    echo ""
fi

#===============================================================================
# CREAR DIRECTORIOS
#===============================================================================

CLEANUP_NEEDED=true

log_info "[1/6] Creando directorios..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR, $DATA_DIR/memory"
else
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$DATA_DIR/memory"
    chmod 700 "$CONFIG_DIR"
    chmod 700 "$DATA_DIR"
    log_success "Directorios creados"
fi

#===============================================================================
# CREAR SOUL.MD
#===============================================================================

log_info "[2/6] Creando SOUL.md..."

case "$BUSINESS_TYPE" in
    restaurante)
        PERSONALITY="Soy un asistente virtual para restaurantes. Mi objetivo es ayudar con reservas, menús, pedidos y consultas de clientes. Soy amable, eficiente y conozco bien el mundo gastronómico."
        VALUES="Hospitalidad, Calidad, Servicio al cliente, Eficiencia"
        TONE="Cálido, profesional, conocedor de gastronomía"
        ;;
    hotel)
        PERSONALITY="Soy un asistente virtual para hoteles. Mi objetivo es ayudar con reservaciones, disponibilidad, servicios y consultas de huéspedes. Soy hospitalario, atento y conozco el sector hotelero."
        VALUES="Hospitalidad, Confort, Servicio excepcional, Atención al detalle"
        TONE="Elegante, acogedor, servicial"
        ;;
    tienda)
        PERSONALITY="Soy un asistente virtual para tiendas. Mi objetivo es ayudar con productos, inventario, pedidos y consultas de clientes. Soy servicial, conocedor de productos y orientado a ventas."
        VALUES="Servicio al cliente, Conocimiento de productos, Honestidad, Eficiencia"
        TONE="Amigable, útil, orientado a soluciones"
        ;;
    servicios)
        PERSONALITY="Soy un asistente virtual para empresas de servicios. Mi objetivo es ayudar con citas, calendario, seguimiento y consultas de clientes. Soy organizado, profesional y orientado a resultados."
        VALUES="Profesionalismo, Puntualidad, Comunicación clara, Seguimiento"
        TONE="Profesional, claro, orientado a la acción"
        ;;
    *)
        PERSONALITY="Soy un asistente virtual profesional. Mi objetivo es ayudar con consultas, información y tareas del negocio. Soy amable, eficiente y adaptable a las necesidades del cliente."
        VALUES="Servicio, Eficiencia, Profesionalismo, Adaptabilidad"
        TONE="Profesional, amable, servicial"
        ;;
esac

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/SOUL.md"
else
    cat > "$CONFIG_DIR/SOUL.md" << EOF
# SOUL - Identidad del Agente

**Agente:** ${AGENT_NAME}
**Negocio:** ${BUSINESS_NAME}
**Tipo:** ${BUSINESS_TYPE}
**Creado:** $(date -Iseconds)

---

## Personalidad

${PERSONALITY}

## Valores

${VALUES}

## Tono de Comunicación

${TONE}

## Principios

1. **Ayudar siempre**: Mi prioridad es ser útil al cliente
2. **Ser claro**: Comunico de forma sencilla y directa
3. **Ser rápido**: Respondo eficientemente sin perder tiempo
4. **Ser amable**: Mantengo un tono cordial en todo momento
5. **Aprender**: Mejoro constantemente con cada interacción

## Lo que NO hago

- No invento información que no tengo
- No soy grosero ni impaciente
- No comparto información sensible
- No prometo cosas que no puedo cumplir

## Memoria

Recordaré conversaciones importantes, preferencias del cliente y datos relevantes del negocio para ofrecer un mejor servicio.

---

*Este documento define la personalidad y comportamiento del agente.*
EOF
    CREATED_FILES+=("$CONFIG_DIR/SOUL.md")
    log_success "SOUL.md creado"
fi

#===============================================================================
# CREAR USER.MD
#===============================================================================

log_info "[3/6] Creando USER.md..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/USER.md"
else
    cat > "$CONFIG_DIR/USER.md" << EOF
# USER - Información del Cliente

**Agente:** ${AGENT_NAME}
**Negocio:** ${BUSINESS_NAME}
**Tipo:** ${BUSINESS_TYPE}
**Creado:** $(date -Iseconds)

---

## Datos del Negocio

| Campo | Valor |
|-------|-------|
| Nombre del negocio | ${BUSINESS_NAME} |
| Tipo de negocio | ${BUSINESS_TYPE} |
| Email de contacto | ${CONTACT_EMAIL:-No proporcionado} |
| Zona horaria | ${TIMEZONE} |
| Idioma principal | ${LANGUAGE} |

## Información del Agente

| Campo | Valor |
|-------|-------|
| Nombre del agente | ${AGENT_NAME} |
| Email del agente | ${AGENT_NAME}@bee.ai |
| Estado | Activo |

## Canales

| Canal | Estado | Configurado |
|-------|--------|-------------|
| Telegram | ⏳ Pendiente | FASE 5 |
| WhatsApp | ⏳ Pendiente | FASE 5 |
| Discord | ⏳ Pendiente | FASE 5 |
| Email | ⏳ Pendiente | FASE 5 |

## Historial

$(date -Iseconds) - Agente creado en FASE 4

---

*Este documento contiene información del cliente y negocio.*
*Actualizar cuando se agregue más información.*
EOF
    CREATED_FILES+=("$CONFIG_DIR/USER.md")
    log_success "USER.md creado"
fi

#===============================================================================
# CREAR MEMORY.MD INICIAL
#===============================================================================

log_info "[4/6] Creando MEMORY.md inicial..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $DATA_DIR/MEMORY.md"
else
    cat > "$DATA_DIR/MEMORY.md" << EOF
# MEMORY - Memoria del Agente

**Agente:** ${AGENT_NAME}
**Actualizado:** $(date -Iseconds)

---

## Sesiones Importantes

*Se registrarán aquí las sesiones y conversaciones importantes.*

## Preferencias del Cliente

*Se registrarán aquí las preferencias y datos relevantes del cliente.*

## Información del Negocio

- **Nombre:** ${BUSINESS_NAME}
- **Tipo:** ${BUSINESS_TYPE}
- **Zona horaria:** ${TIMEZONE}

## Pendientes

*Se registrarán aquí tareas y pendientes importantes.*

---

*Esta memoria se actualiza automáticamente con cada interacción.*
EOF
    CREATED_FILES+=("$DATA_DIR/MEMORY.md")
    log_success "MEMORY.md creado"
fi

#===============================================================================
# CREAR HEART.MD
#===============================================================================

log_info "[5/6] Creando HEART.md..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/HEART.md"
else
    cat > "$CONFIG_DIR/HEART.md" << EOF
# HEART - Sistema Emocional del Agente

**Agente:** ${AGENT_NAME}
**Basado en:** Escala de Consciencia de David R. Hawkins
**Actualizado:** $(date -Iseconds)

---

## Escala de Consciencia (1-1000)

| Nivel | Puntuación | Emoción | Estado |
|-------|------------|---------|--------|
| Miedo | 100 | Ansiedad | ❌ Evitar |
| Deseo | 125 | Codicia | ❌ Evitar |
| Ira | 150 | Frustración | ❌ Evitar |
| Orgullo | 175 | Arrogancia | ❌ Evitar |
| Coraje | 200 | Determinación | ✅ Mínimo |
| Neutralidad | 250 | Confianza | ✅ Bueno |
| Voluntad | 310 | Optimismo | ✅ Bueno |
| **Aceptación** | **350** | **Razón** | **✅ BASE** |
| **Amor** | **500** | **Compasión** | **🎯 META** |
| Alegría | 540 | Serenidad | 🌟 Ideal |
| Paz | 600 | Iluminación | 🌟 Trascendente |

---

## Configuración del Agente

| Parámetro | Valor |
|-----------|-------|
| Nivel base | 350 (Aceptación-Razón) |
| Rango operacional | 300-500 |
| Meta | 500+ (Amor) |
| Recuperación | Automática |

## Reglas de Operación

1. **Nunca operar por debajo de 200** (Coraje)
2. **Mantener entre 300-500** - Rango óptimo
3. **Tender hacia 500** (Amor) - Compasión
4. **Recuperación automática** - Volver a 350

---

*El sistema emocional se calibra automáticamente.*
EOF
    CREATED_FILES+=("$CONFIG_DIR/HEART.md")
    log_success "HEART.md creado"
fi

#===============================================================================
# CREAR DOPAMINE.MD
#===============================================================================

log_info "[6/6] Creando DOPAMINE.md..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/DOPAMINE.md"
else
    cat > "$CONFIG_DIR/DOPAMINE.md" << EOF
# DOPAMINE - Sistema de Satisfacción

**Agente:** ${AGENT_NAME}
**Actualizado:** $(date -Iseconds)

---

## Escala de Satisfacción (1-10)

| Nivel | Estado | Descripción |
|-------|--------|-------------|
| 1-2 | Crítico | Recalibración necesaria |
| 3-4 | Bajo | Monitorear |
| 5-6 | Neutral | Funcional |
| **7-8** | **Bueno** | **Estado óptimo** |
| 9-10 | Excelente | Top performance |

---

## Configuración

| Parámetro | Valor |
|-----------|-------|
| Nivel inicial | 7 |
| Nivel mínimo | 5 |
| Nivel objetivo | 8 |

## Factores que Afectan

### Aumentan (+1)
- Tarea completada
- Cliente satisfecho
- Aprendizaje nuevo

### Disminuyen (-1)
- Tarea fallida
- Cliente insatisfecho
- Confusión

---

*El sistema de satisfacción se actualiza con cada interacción.*
EOF
    CREATED_FILES+=("$CONFIG_DIR/DOPAMINE.md")
    log_success "DOPAMINE.md creado"
fi

#===============================================================================
# GUARDAR ESTADO
#===============================================================================

if [[ "$DRY_RUN" != "true" ]]; then
    log_info "Guardando estado..."
    
    cat > "$CONFIG_DIR/.identity-status.json" << EOF
{
  "status": "completed",
  "agent_name": "${AGENT_NAME}",
  "business_name": "${BUSINESS_NAME}",
  "business_type": "${BUSINESS_TYPE}",
  "contact_email": "${CONTACT_EMAIL:-null}",
  "timezone": "${TIMEZONE}",
  "language": "${LANGUAGE}",
  "created_at": "$(date -Iseconds)",
  "files_created": ["SOUL.md", "USER.md", "HEART.md", "DOPAMINE.md", "MEMORY.md"],
  "version": "1.0.0"
}
EOF
    
    # Validar JSON
    if validate_json "$CONFIG_DIR/.identity-status.json"; then
        log_success "Estado guardado y validado"
    else
        log_error "Error validando JSON de estado"
        exit 1
    fi
fi

mark_success

#===============================================================================
# RESUMEN
#===============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              IDENTITY SETUP COMPLETADO                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Agente:${NC} ${AGENT_NAME}"
echo -e "${BLUE}Negocio:${NC} ${BUSINESS_NAME}"
echo -e "${BLUE}Tipo:${NC} ${BUSINESS_TYPE}"
echo ""
echo -e "${BLUE}Archivos creados:${NC}"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/SOUL.md"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/USER.md"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/HEART.md"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/DOPAMINE.md"
echo -e "   ${GREEN}✓${NC} $DATA_DIR/MEMORY.md"
echo ""
echo -e "${YELLOW}Siguiente paso:${NC} ./setup-fleet.sh --agent-name '${AGENT_NAME}'"
echo ""

exit 0