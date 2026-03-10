#!/bin/bash
#===============================================================================
# FASE 4: IDENTITY FLEET - Setup Skills (Super Agente)
#===============================================================================
# Propósito: Configurar habilidades del Super Agente (39 habilidades)
# Uso: ./setup-skills.sh --agent-name "nombre" [--business-type "tipo"]
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
readonly SECRETS_DIR="$OPENCLAW_DIR/workspace/secrets"

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
        
        rm -f "$CONFIG_DIR/.skills-status.json" 2>/dev/null || true
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
    echo "  --dry-run               Simular ejecución"
    echo "  --help                  Mostrar esta ayuda"
    echo ""
    echo "Tipos de negocio y sus skills:"
    echo "  restaurante  → menu, reservas, pedidos, horarios, delivery"
    echo "  hotel        → reservas, disponibilidad, habitaciones, FAQ"
    echo "  tienda       → inventario, productos, pedidos, pagos"
    echo "  servicios    → citas, calendario, reminders, seguimiento"
    echo "  generico     → FAQ, contacto, horarios"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --agent-name 'casamahana' --business-type 'restaurante'"
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
BUSINESS_TYPE="generico"
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

# Validar parámetros
if [[ -z "$AGENT_NAME" ]]; then
    log_error "--agent-name es obligatorio"
    usage
fi

# Normalizar business-type
case "$BUSINESS_TYPE" in
    restaurante|hotel|tienda|servicios|generico)
        ;;
    *)
        log_warning "business-type '$BUSINESS_TYPE' no reconocido, usando 'generico'"
        BUSINESS_TYPE="generico"
        ;;
esac

# Hacer variables readonly
readonly AGENT_NAME BUSINESS_TYPE DRY_RUN

#===============================================================================
# ENCABEZADO
#===============================================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         FASE 4: IDENTITY FLEET - Setup Skills                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}[MODO DRY-RUN]${NC} Solo simulación"
    echo ""
fi

#===============================================================================
# VALIDAR PREREQUISITOS
#===============================================================================

CLEANUP_NEEDED=true

log_info "Verificando prerequisitos..."

# Verificar que existe fleet
if [[ ! -f "$CONFIG_DIR/.fleet-status.json" ]]; then
    log_error "Fleet no configurado"
    log_warning "Ejecutar primero: ./setup-fleet.sh"
    exit 1
fi

log_success "Fleet verificado"

#===============================================================================
# HABILIDADES CORE (25)
#===============================================================================

log_info "[1/4] Configurando habilidades CORE (25)..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/skills-core.json"
else
    cat > "$CONFIG_DIR/skills-core.json" << 'CORE_EOF'
{
  "version": "2.0.0",
  "description": "25 habilidades CORE - Siempre funcionan sin configuración",
  "skills": {
    "documents": {
      "pdf_generate": {
        "enabled": true,
        "limit": 5000,
        "description": "Crear documentos PDF"
      },
      "pdf_read": {
        "enabled": true,
        "limit": 1000,
        "description": "Extraer texto de PDFs"
      },
      "pdf_edit": {
        "enabled": true,
        "limit": 5000,
        "description": "Modificar/combinar PDFs"
      },
      "doc_generate": {
        "enabled": true,
        "limit": 5000,
        "description": "Crear Word/Docs"
      },
      "excel_generate": {
        "enabled": true,
        "limit": 5000,
        "description": "Crear Excel"
      },
      "excel_read": {
        "enabled": true,
        "limit": 5000,
        "description": "Leer Excel"
      },
      "presentation_create": {
        "enabled": true,
        "limit": 50,
        "description": "Crear presentaciones"
      }
    },
    "email": {
      "email_send": {
        "enabled": true,
        "limit": 3000,
        "description": "Enviar emails con adjuntos"
      },
      "email_read": {
        "enabled": true,
        "limit": null,
        "description": "Leer y procesar emails"
      }
    },
    "video": {
      "video_process": {
        "enabled": true,
        "limit": 100,
        "description": "Analizar videos"
      },
      "video_edit": {
        "enabled": true,
        "limit": 100,
        "description": "Editar videos"
      }
    },
    "automation": {
      "browser": {
        "enabled": true,
        "limit": null,
        "description": "Navegador automatizado"
      },
      "scraping": {
        "enabled": true,
        "limit": 1000,
        "description": "Web scraping"
      },
      "forms": {
        "enabled": true,
        "limit": null,
        "description": "Formularios"
      },
      "cron": {
        "enabled": true,
        "limit": null,
        "description": "Tareas programadas"
      },
      "webhook": {
        "enabled": true,
        "limit": null,
        "description": "Webhooks"
      }
    },
    "communication": {
      "sms_send": {
        "enabled": true,
        "limit": 500,
        "description": "Enviar SMS"
      },
      "whatsapp_send": {
        "enabled": true,
        "limit": null,
        "description": "Enviar WhatsApp"
      },
      "telegram_send": {
        "enabled": true,
        "limit": null,
        "description": "Enviar Telegram"
      },
      "discord_send": {
        "enabled": true,
        "limit": null,
        "description": "Enviar Discord"
      }
    },
    "business": {
      "invoice_generate": {
        "enabled": true,
        "limit": 5000,
        "description": "Crear facturas"
      },
      "report_generate": {
        "enabled": true,
        "limit": 5000,
        "description": "Crear reportes"
      },
      "qrcode_generate": {
        "enabled": true,
        "limit": null,
        "description": "Crear QR codes"
      }
    },
    "productivity": {
      "summarize": {
        "enabled": true,
        "provider": "ollamacloud",
        "description": "Resumir textos"
      },
      "extract_data": {
        "enabled": true,
        "provider": "ollamacloud",
        "description": "Extraer datos"
      },
      "sentiment": {
        "enabled": true,
        "provider": "ollamacloud",
        "description": "Análisis de sentimiento"
      },
      "ocr": {
        "enabled": true,
        "provider": "ollamacloud",
        "description": "OCR de imágenes"
      }
    }
  }
}
CORE_EOF

    if validate_json "$CONFIG_DIR/skills-core.json"; then
        CREATED_FILES+=("$CONFIG_DIR/skills-core.json")
        log_success "25 habilidades CORE configuradas"
    else
        log_error "Error creando skills-core.json"
        exit 1
    fi
fi

#===============================================================================
# HABILIDADES OPCIONALES (14)
#===============================================================================

log_info "[2/4] Configurando habilidades OPCIONALES (14)..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/skills-optional.json"
else
    cat > "$CONFIG_DIR/skills-optional.json" << 'OPTIONAL_EOF'
{
  "version": "2.0.0",
  "description": "14 habilidades OPCIONALES - Requieren API keys",
  "skills": {
    "voice": {
      "voice_receive": {
        "enabled": false,
        "requires": "OPENAI_API_KEY",
        "description": "Recibir y procesar voz"
      },
      "voice_send": {
        "enabled": false,
        "requires": "OPENAI_API_KEY",
        "description": "Generar voz (TTS)"
      },
      "audio_transcribe": {
        "enabled": false,
        "requires": "OPENAI_API_KEY",
        "description": "Transcribir audio"
      }
    },
    "image": {
      "image_generate": {
        "enabled": false,
        "requires": "OPENAI_API_KEY",
        "description": "Generar imágenes (DALL-E)"
      },
      "image_edit": {
        "enabled": false,
        "requires": "OPENAI_API_KEY",
        "description": "Editar imágenes"
      },
      "image_receive": {
        "enabled": true,
        "requires": "OLLAMA_API_KEY",
        "description": "Analizar imágenes (Vision)"
      }
    },
    "media": {
      "audio_generate": {
        "enabled": false,
        "requires": "SUNO_API_KEY",
        "description": "Generar música/audio"
      },
      "video_create": {
        "enabled": false,
        "requires": "RUNWAY_API_KEY",
        "description": "Crear videos (AI)"
      }
    },
    "services": {
      "translate": {
        "enabled": false,
        "requires": "DEEPL_API_KEY",
        "description": "Traducción profesional"
      },
      "location": {
        "enabled": false,
        "requires": "GOOGLE_MAPS_KEY",
        "description": "Servicios de ubicación"
      },
      "calendar": {
        "enabled": false,
        "requires": "GOOGLE_OAUTH",
        "description": "Google Calendar"
      },
      "sheets": {
        "enabled": false,
        "requires": "GOOGLE_OAUTH",
        "description": "Google Sheets"
      },
      "deep_search": {
        "enabled": false,
        "requires": "PERPLEXITY_API_KEY",
        "description": "Búsqueda profunda"
      }
    },
    "code": {
      "code_execute": {
        "enabled": true,
        "requires": null,
        "description": "Ejecutar código"
      }
    }
  }
}
OPTIONAL_EOF

    if validate_json "$CONFIG_DIR/skills-optional.json"; then
        CREATED_FILES+=("$CONFIG_DIR/skills-optional.json")
        log_success "14 habilidades OPCIONALES configuradas"
    else
        log_error "Error creando skills-optional.json"
        exit 1
    fi
fi

#===============================================================================
# SKILLS BUNDLE (por tipo de negocio)
#===============================================================================

log_info "[3/4] Configurando Skills Bundle para '$BUSINESS_TYPE'..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/skills-bundle.json"
else
    # Bundle según tipo de negocio
    case "$BUSINESS_TYPE" in
        restaurante)
            BUNDLE_DESC="Habilidades para restaurantes"
            BUNDLE='{"bundle":"restaurante","skills":["menu","reservas","pedidos","horarios","delivery","faq"],"context":{"menu":"Puedo consultar el menú y precios.","reservas":"Puedo gestionar reservaciones.","pedidos":"Puedo tomar pedidos para llevar o delivery.","horarios":"Puedo informar horarios de atención.","delivery":"Puedo coordinar entregas a domicilio."}}'
            ;;
        hotel)
            BUNDLE_DESC="Habilidades para hoteles"
            BUNDLE='{"bundle":"hotel","skills":["reservas","disponibilidad","habitaciones","faq","checkin","amenidades"],"context":{"reservas":"Puedo gestionar reservaciones de habitaciones.","disponibilidad":"Puedo consultar disponibilidad en tiempo real.","habitaciones":"Puedo mostrar tipos de habitaciones y precios.","faq":"Puedo responder preguntas frecuentes del hotel.","checkin":"Puedo gestionar check-in y check-out.","amenidades":"Puedo informar sobre servicios del hotel."}}'
            ;;
        tienda)
            BUNDLE_DESC="Habilidades para tiendas"
            BUNDLE='{"bundle":"tienda","skills":["inventario","productos","pedidos","pagos","faq","envios"],"context":{"inventario":"Puedo consultar disponibilidad de productos.","productos":"Puedo mostrar catálogo y precios.","pedidos":"Puedo procesar pedidos.","pagos":"Puedo informar métodos de pago.","faq":"Puedo responder preguntas frecuentes.","envios":"Puedo coordinar envíos."}}'
            ;;
        servicios)
            BUNDLE_DESC="Habilidades para servicios"
            BUNDLE='{"bundle":"servicios","skills":["citas","calendario","reminders","seguimiento","faq","pagos"],"context":{"citas":"Puedo agendar y gestionar citas.","calendario":"Puedo mostrar disponibilidad.","reminders":"Puedo enviar recordatorios.","seguimiento":"Puedo dar seguimiento a clientes.","faq":"Puedo responder preguntas frecuentes.","pagos":"Puedo informar sobre pagos."}}'
            ;;
        *)
            BUNDLE_DESC="Habilidades genéricas"
            BUNDLE='{"bundle":"generico","skills":["faq","contacto","horarios","info","ayuda"],"context":{"faq":"Puedo responder preguntas frecuentes.","contacto":"Puedo proporcionar información de contacto.","horarios":"Puedo informar horarios de atención.","info":"Puedo dar información general.","ayuda":"Puedo ayudar con consultas diversas."}}'
            ;;
    esac

    echo "$BUNDLE" > "$CONFIG_DIR/skills-bundle.json"
    
    if validate_json "$CONFIG_DIR/skills-bundle.json"; then
        CREATED_FILES+=("$CONFIG_DIR/skills-bundle.json")
        log_success "Skills Bundle: $BUNDLE_DESC"
    else
        log_error "Error creando skills-bundle.json"
        exit 1
    fi
fi

#===============================================================================
# SKILLS.MD
#===============================================================================

log_info "[4/4] Generando SKILLS.md..."

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Crearía: $CONFIG_DIR/SKILLS.md"
else
    cat > "$CONFIG_DIR/SKILLS.md" << SKILLSEOF
# SKILLS - Habilidades del Super Agente

**Agente:** ${AGENT_NAME}
**Tipo de negocio:** ${BUSINESS_TYPE}
**Total habilidades:** 39 (25 CORE + 14 OPCIONALES)
**Actualizado:** $(date -Iseconds)

---

## Habilidades CORE (25) - Siempre funcionan

Estas habilidades están disponibles SIEMPRE, sin configuración adicional.

### Documentos (7)
- pdf_generate: Crear documentos PDF
- pdf_read: Extraer texto de PDFs
- pdf_edit: Modificar/combinar PDFs
- doc_generate: Crear Word/Docs
- excel_generate: Crear Excel
- excel_read: Leer Excel
- presentation_create: Crear presentaciones

### Email (2)
- email_send: Enviar emails con adjuntos
- email_read: Leer y procesar emails

### Video (2)
- video_process: Analizar videos
- video_edit: Editar videos

### Automatización (5)
- browser: Navegador automatizado
- scraping: Web scraping
- forms: Formularios
- cron: Tareas programadas
- webhook: Webhooks

### Comunicación (4)
- sms_send: Enviar SMS
- whatsapp_send: Enviar WhatsApp
- telegram_send: Enviar Telegram
- discord_send: Enviar Discord

### Negocio (3)
- invoice_generate: Crear facturas
- report_generate: Crear reportes
- qrcode_generate: Crear QR codes

### Productividad (4)
- summarize: Resumir textos
- extract_data: Extraer datos
- sentiment: Análisis de sentimiento
- ocr: OCR de imágenes

---

## Habilidades OPCIONALES (14) - Requieren API key

| Habilidad | API necesaria |
|-----------|--------------|
| voice_receive | OPENAI_API_KEY |
| voice_send | OPENAI_API_KEY |
| audio_transcribe | OPENAI_API_KEY |
| image_generate | OPENAI_API_KEY |
| image_edit | OPENAI_API_KEY |
| audio_generate | SUNO_API_KEY |
| video_create | RUNWAY_API_KEY |
| translate | DEEPL_API_KEY |
| location | GOOGLE_MAPS_KEY |
| calendar | GOOGLE_OAUTH |
| sheets | GOOGLE_OAUTH |
| deep_search | PERPLEXITY_API_KEY |
| code_execute | (ninguna) ✅ |
| image_receive | OLLAMA_API_KEY ✅ |

---

## Bundle: ${BUSINESS_TYPE}

${BUNDLE_DESC}

---

*Habilidades configuradas en FASE 4.*
SKILLSEOF

    CREATED_FILES+=("$CONFIG_DIR/SKILLS.md")
    log_success "SKILLS.md generado"
fi

#===============================================================================
# GUARDAR ESTADO
#===============================================================================

if [[ "$DRY_RUN" != "true" ]]; then
    log_info "Guardando estado..."
    
    cat > "$CONFIG_DIR/.skills-status.json" << EOF
{
  "status": "completed",
  "agent_name": "${AGENT_NAME}",
  "business_type": "${BUSINESS_TYPE}",
  "total_skills": 39,
  "core_skills": 25,
  "optional_skills": 14,
  "bundle": "${BUSINESS_TYPE}",
  "created_at": "$(date -Iseconds)",
  "version": "1.0.0"
}
EOF

    validate_json "$CONFIG_DIR/.skills-status.json" || true
fi

mark_success

#===============================================================================
# RESUMEN
#===============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              SKILLS SETUP COMPLETADO                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Agente:${NC} ${AGENT_NAME}"
echo -e "${BLUE}Tipo de negocio:${NC} ${BUSINESS_TYPE}"
echo ""
echo -e "${BLUE}Habilidades configuradas:${NC}"
echo -e "   ${GREEN}✓${NC} 25 habilidades CORE (siempre disponibles)"
echo -e "   ${GREEN}✓${NC} 14 habilidades OPCIONALES (requieren API key)"
echo -e "   ${GREEN}✓${NC} Bundle: ${BUSINESS_TYPE}"
echo ""
echo -e "${BLUE}Archivos creados:${NC}"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/skills-core.json"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/skills-optional.json"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/skills-bundle.json"
echo -e "   ${GREEN}✓${NC} $CONFIG_DIR/SKILLS.md"
echo ""
echo -e "${YELLOW}Siguiente paso:${NC} ./process-knowledge.sh --agent-name '${AGENT_NAME}'"
echo ""

exit 0