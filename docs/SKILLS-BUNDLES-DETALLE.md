# Skills Bundles - Detalle por Tipo de Negocio

**Versión:** 1.1.0
**Fecha:** 2026-03-05
**Área:** FASE 4 - ÁREA 6 - SKILLS BUNDLES

---

## 📋 RESUMEN EJECUTIVO

Este documento detalla cada skill específico por tipo de negocio, incluyendo:

- **Descripción funcional**
- **Intents (frases de activación)**
- **Responses (respuestas predefinidas)**
- **Dependencias (skills natas requeridas)**
- **Implementación técnica**
- **Configuración necesaria**

---

# 1️⃣ RESTAURANTE

## Overview

| Aspecto | Detalle |
|---------|---------|
| **Skills totales** | 8 |
| **Dependencias CORE** | email_send, pdf_generate, calendar, forms, location |
| **Dependencias OPCIONALES** | sms_send (delivery), voice_send (confirmaciones) |
| **Tiempo setup** | ~15 minutos |
| **Documentos requeridos** | menu.pdf, faq.json (opcional) |

---

## Skill 1.1: Menú Digital (`menu_parse`)

### Descripción Funcional

Permite al agente:
- Mostrar el menú completo o por categorías
- Consultar precios de platos específicos
- Recomendar platos según preferencias
- Informar sobre ingredientes y alérgenos
- Mostrar promociones del día

### Intents (Frases de Activación)

| Categoría | Intents |
|-----------|---------|
| **Menú general** | "menú", "carta", "qué tienen", "ver menú", "platos" |
| **Precios** | "cuánto cuesta", "precio de", "cuánto sale", "vale" |
| **Recomendaciones** | "qué me recomiendas", "qué es bueno", "mejores platos", "sugerencia" |
| **Categorías** | "entradas", "principales", "postres", "bebidas", "especiales" |
| **Detalles** | "ingredientes", "alérgenos", "sin gluten", "vegetariano", "vegano" |
| **Promociones** | "promociones", "ofertas", "especial del día", "descuentos" |

### Responses Predefinidas

```json
{
  "menu_general": "🍽️ Nuestro menú incluye:\n\n📋 **Entradas:** {entradas_list}\n🍽️ **Principales:** {principales_list}\n🍰 **Postres:** {postres_list}\n🥤 **Bebidas:** {bebidas_list}\n\n¿Te gustaría que te recomiende algo?",
  
  "menu_categoria": "Aquí está nuestra carta de **{categoria}**:\n\n{items_con_precios}\n\n¿Algo te llama la atención?",
  
  "precio_item": "💰 **{item}** cuesta **${precio}**.\n\nPlato completo con guarnición. ¿Te gustaría agregarlo a tu orden?",
  
  "recomendacion": "🎯 Te recomiendo **{item}**!\n\n**Por qué:** {razon}\n\n**Precio:** ${precio}\n**Tiempo preparación:** ~{tiempo} minutos\n\n¿Lo agregamos a tu orden?",
  
  "ingredientes": "🥗 **{item}** contiene:\n\n{ingredientes_list}\n\n⚠️ **Alergenos:** {alergenos}",
  
  "promocion": "🎉 **Promoción del día:**\n\n{promocion}\n\nVálido hasta: {fecha_validez}\n¿Te gustaría aprovecharla?",
  
  "no_encontrado": "No encontré '{busqueda}' en nuestro menú. ¿Te gustaría ver categorías similares?\n\nDisponibles: {sugerencias}"
}
```

### Dependencias

| Skill Nata | Uso | Requerido |
|------------|-----|-----------|
| `pdf_read` | Leer menu.pdf | ✅ Sí |
| `extract_data` | Extraer items y precios | ✅ Sí |
| `summarize` | Resumir categorías | ⚪ Opcional |

### Implementación Técnica

```bash
# Estructura de archivos
~/.openclaw/knowledge/menu/
├── menu.pdf              # Menú principal
├── promociones.pdf       # Promociones (opcional)
└── menu_index.json       # Índice de categorías (auto-generado)

# Configuración en skills-bundle.json
{
  "id": "menu_parse",
  "knowledge_sources": ["menu/menu.pdf", "menu/promociones.pdf"],
  "cache_duration": 3600,
  "max_results": 20,
  "search_type": "semantic"
}
```

### Script de Setup

```bash
#!/bin/bash
# setup-menu.sh

BUSINESS_NAME=$1
KNOWLEDGE_DIR="$HOME/.openclaw/knowledge/menu"

mkdir -p "$KNOWLEDGE_DIR"

# Crear plantilla de menú si no existe
if [ ! -f "$KNOWLEDGE_DIR/menu.pdf" ]; then
  echo "⚠️ No se encontró menu.pdf"
  echo "Por favor, coloca tu menú en: $KNOWLEDGE_DIR/menu.pdf"
fi

# Validar formato del menú
python3 << 'EOF'
import json
from pathlib import Path

# Validar que el PDF sea legible
menu_path = Path.home() / ".openclaw/knowledge/menu/menu.pdf"
if menu_path.exists():
    # Aquí iría la validación real
    print("✅ Menú encontrado y validado")
else:
    print("⏳ Pendiente: Subir menu.pdf")
EOF
```

---

## Skill 1.2: Reservas (`reservations`)

### Descripción Funcional

Permite al agente:
- Consultar disponibilidad de mesas
- Crear nuevas reservaciones
- Modificar reservas existentes
- Cancelar reservas
- Enviar confirmaciones

### Intents

| Categoría | Intents |
|-----------|---------|
| **Nueva reserva** | "reservar", "mesa", "reservación", "quiero hacer una reserva" |
| **Consultar** | "tienen disponibilidad", "hay mesas", "para cuántos", "para qué hora" |
| **Modificar** | "cambiar reserva", "modificar reserva", "otra fecha", "más personas" |
| **Cancelar** | "cancelar reserva", "no voy a poder", "anular" |
| **Info** | "mi reserva", "código de reserva", "confirmación" |

### Responses

```json
{
  "solicitar_datos": "📅 Para hacer tu reservación necesito:\n\n👤 Nombre\n👥 Cantidad de personas\n📅 Fecha\n🕐 Hora\n📞 Teléfono (opcional)\n\n¿Me das estos datos?",
  
  "disponibilidad_ok": "✅ ¡Perfecto! Tenemos disponibilidad para:\n\n👥 **{personas} personas**\n📅 **{fecha}**\n🕐 **{hora}**\n\n¿Confirmas la reserva?",
  
  "disponibilidad_no": "😔 Lo siento, no tenemos mesas disponibles para {personas} personas el {fecha} a las {hora}.\n\n**Alternativas disponibles:**\n{alternativas}\n\n¿Alguna de estas te funciona?",
  
  "confirmacion": "🎉 **¡Reserva confirmada!**\n\n📋 **Código de reserva:** #{codigo}\n👤 Nombre: {nombre}\n👥 Personas: {personas}\n📅 Fecha: {fecha}\n🕐 Hora: {hora}\n📍 Ubicación: {direccion}\n\n📧 Te enviaremos un email de confirmación.\n\n¿Necesitas algo más?",
  
  "modificacion_ok": "✅ Reserva modificada correctamente.\n\n📋 **Nuevo código:** #{codigo}\n📅 **Nueva fecha:** {fecha}\n🕐 **Nueva hora:** {hora}\n\n¿Hay algo más en lo que pueda ayudarte?",
  
  "cancelacion_ok": "❌ Reserva #{codigo} cancelada.\n\nEsperamos verte pronto. ¿Te gustaría hacer otra reserva?",
  
  "recordatorio": "⏰ **Recordatorio:** Tu reserva es mañana a las {hora}.\n\n📍 {direccion}\n👤 {personas} personas\n\n¿Necesitas modificar o cancelar? Responde 'cancelar' si no podrás asistir."
}
```

### Dependencias

| Skill Nata | Uso | Requerido |
|------------|-----|-----------|
| `calendar` | Consultar disponibilidad | ✅ Sí |
| `forms` | Capturar datos de reserva | ✅ Sí |
| `email_send` | Confirmaciones por email | ✅ Sí |
| `sms_send` | Recordatorios SMS | ⚪ Opcional |

### Implementación

```bash
# Estructura de archivos
~/.openclaw/knowledge/reservas/
├── config.json            # Configuración de mesas
├── horarios.json          # Horarios disponibles
└── reservas.db           # Base de datos de reservas

# config.json ejemplo
{
  "mesas": {
    "2_personas": 4,
    "4_personas": 6,
    "6_personas": 3,
    "8_personas": 2,
    "12_personas": 1
  },
  "horarios": {
    "almuerzo": ["12:00", "13:00", "14:00", "15:00"],
    "cena": ["19:00", "20:00", "21:00", "22:00"]
  },
  "politicas": {
    "anticipacion_minima": "2 horas",
    "cancelacion_max": "24 horas",
    "tiempo_limite": "15 minutos llegada"
  }
}
```

### Flujo de Reserva

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUJO DE RESERVACIÓN                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Usuario: "Quiero reservar para 4 personas"                         │
│      │                                                                │
│      ▼                                                                │
│  1. DETECTAR INTENT                                                  │
│     └── Intent: reservations → nueva_reserva                        │
│                                                                       │
│  2. SOLICITAR DATOS FALTANTES                                        │
│     └── ¿Fecha? → ¿Hora? → ¿Nombre?                                 │
│                                                                       │
│  3. CONSULTAR DISPONIBILIDAD                                         │
│     └── calendar.check_availability(date, time, people)             │
│         └── Si disponible → Confirmar                               │
│         └── Si no disponible → Ofrecer alternativas                 │
│                                                                       │
│  4. CONFIRMAR                                                        │
│     └── Generar código de reserva                                   │
│     └── Guardar en reservas.db                                       │
│     └── Enviar email de confirmación                                 │
│                                                                       │
│  5. RECORDATORIO (automático)                                        │
│     └── 24 horas antes → email + SMS                                 │
│     └── 2 horas antes → SMS                                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Skill 1.3: Pedidos (`orders`)

### Descripción Funcional

Permite al agente:
- Tomar pedidos de clientes
- Modificar pedidos existentes
- Mostrar resumen del pedido
- Calcular totales (con/sin descuentos)
- Enviar pedido a cocina/barra

### Intents

| Categoría | Intents |
|-----------|---------|
| **Nuevo pedido** | "pedir", "ordenar", "quiero", "me trae", "vamos a ordenar" |
| **Agregar** | "agregar", "sumar", "también", "adicional", "otro más" |
| **Quitar** | "quitar", "sacar", "cancelar", "sin", "no quiero" |
| **Modificar** | "cambiar", "modificar", "en vez de", "mejor" |
| **Ver pedido** | "mi pedido", "resumen", "total", "cuánto es" |
| **Confirmar** | "confirmar", "sí ese es", "listo", "pedir" |

### Responses

```json
{
  "tomar_pedido": "📝 Anotando tu pedido...\n\n¿Qué deseas ordenar?",
  
  "agregar_item": "✅ Agregado: **{item}** x{cantidad}\n💰 Subtotal: ${subtotal}\n\n¿Algo más?",
  
  "quitar_item": "❌ Eliminado: **{item}**\n\nPedido actualizado. Tu pedido ahora es:\n{pedido_actual}\n\n¿Deseas agregar algo más?",
  
  "resumen_pedido": "📋 **Tu Pedido:**\n\n{items_list}\n\n subtotal: ${subtotal}\n{descuentos}\n💰 **Total: ${total}**\n\n¿Confirmas el pedido?",
  
  "confirmacion_pedido": "🎉 **¡Pedido confirmado!**\n\n📋 **Orden #:** #{orden_id}\n📍 **Mesa:** {mesa}\n⏱️ **Tiempo estimado:** {tiempo_estimado} minutos\n\nTu pedido ya fue enviado a cocina. Te avisaré cuando esté listo.",
  
  "pedido_listo": "🔔 **¡Tu pedido está listo!**\n\nPuedes pasar a retirarlo a {ubicacion}.\n\n¿Necesitas algo más?",

  "modificacion_item": "✅ Modificado: **{item_anterior}** → **{item_nuevo}**\n\nTu pedido actualizado:\n{pedido_actual}\n\n¿Algo más?",
  
  "pedido_vacio": "📭 Tu pedido está vacío.\n\n¿Te gustaría ver el menú para ordenar?",
  
  "error_item": "❌ No encontré '{item}' en el menú.\n\nQuizás quisiste decir: {sugerencias}"
}
```

### Dependencias

| Skill Nata | Uso | Requerido |
|------------|-----|-----------|
| `forms` | Capturar pedido | ✅ Sí |
| `pdf_generate` | Generar ticket | ✅ Sí |
| `email_send` | Enviar comprobante | ⚪ Opcional |
| `cron` | Temporizadores | ⚪ Opcional |

### Implementación

```bash
# Estructura de archivos
~/.openclaw/knowledge/pedidos/
├── productos.json        # Catálogo con precios
├── pedidos.db            # Pedidos activos
└── config.json           # Configuración

# productos.json ejemplo
{
  "categorias": {
    "entradas": [
      {"id": "e1", "nombre": "Bruschetta", "precio": 8.50, "tiempo": 10},
      {"id": "e2", "nombre": "Ensalada César", "precio": 12.00, "tiempo": 8}
    ],
    "principales": [
      {"id": "p1", "nombre": "Pasta Carbonara", "precio": 18.00, "tiempo": 20},
      {"id": "p2", "nombre": "Milanesa", "precio": 22.00, "tiempo": 25}
    ]
  },
  "modificadores": {
    "sin_gluten": {"extra": 3.00},
    "porcion_extra": {"extra": 5.00},
    "sin_cebolla": {"extra": 0}
  }
}
```

---

## Skill 1.4: Horarios (`hours`)

### Descripción Funcional

Permite al agente:
- Informar horarios de atención
- Indicar días abiertos/cerrados
- Mostrar horarios especiales (festivos, eventos)
- Calcular tiempo hasta próxima apertura

### Intents

| Categoría | Intents |
|-----------|---------|
| **General** | "horarios", "horario", "¿a qué hora abren?", "¿cuándo cierran?" |
| **Día específico** | "¿abren los domingos?", "sábado", "feriado" |
| **Estado** | "¿están abiertos?", "¿puedo ir ahora?", "¿atienen hoy?" |
| **Especiales** | "horarios navidad", "feriado", "evento especial" |

### Responses

```json
{
  "horarios_general": "🕐 **Horarios de Atención:**\n\n📅 Lunes a Viernes: {hora_lv}\n📅 Sábado: {hora_sab}\n📅 Domingo: {hora_dom}\n\n{estado_actual}",
  
  "abierto": "✅ **Estamos ABIERTOS ahora.**\n\n🕐 Cerramos a las {hora_cierre}\n⏰ Tiempo restante: {tiempo_restante}\n\n¿Te gustaría hacer una reserva?",
  
  "cerrado": "❌ **Estamos CERRADOS ahora.**\n\n⏰ Abrimos: {proxima_apertura}\n📅 Día: {dia_apertura}\n\n¿Te gustaría reservar para cuando abramos?",
  
  "dia_especifico": "📅 **{dia}:**\n\n🕐 Horario: {horario}\n{estado}\n\n¿Necesitas algo más?",
  
  "feriado": "🎉 **Horario especial para {feriado}:**\n\n🕐 {horario_especial}\n\n{nota_especial}",
  
  "cerrado_dia": "❌ **No abrimos los {dia}.**\n\nPróxima apertura: {proxima}\n\n¿Te gustaría reservar para otro día?"
}
```

### Implementación

```json
// config/horarios.json
{
  "horarios": {
    "lunes": {"abierto": true, "apertura": "12:00", "cierre": "22:00"},
    "martes": {"abierto": true, "apertura": "12:00", "cierre": "22:00"},
    "miercoles": {"abierto": true, "apertura": "12:00", "cierre": "22:00"},
    "jueves": {"abierto": true, "apertura": "12:00", "cierre": "22:00"},
    "viernes": {"abierto": true, "apertura": "12:00", "cierre": "23:00"},
    "sabado": {"abierto": true, "apertura": "11:00", "cierre": "23:00"},
    "domingo": {"abierto": false, "nota": "Cerrados los domingos"}
  },
  "feriados": {
    "2026-03-21": {"abierto": true, "horario": "12:00-20:00", "nota": "Feriado - horario reducido"},
    "2026-12-25": {"abierto": false, "nota": "Cerrado por Navidad"}
  },
  "timezone": "America/Mexico_City"
}
```

---

## Skill 1.5: Delivery (`delivery`)

### Descripción Funcional

Permite al agente:
- Consultar zonas de cobertura
- Calcular costo de envío
- Estimar tiempo de entrega
- Tomar pedidos para delivery
- Seguimiento de órdenes

### Intents

| Categoría | Intents |
|-----------|---------|
| **Info delivery** | "delivery", "domicilio", "envío", "a domicilio", "llevar" |
| **Zonas** | "zona de entrega", "cobertura", "dónde entregan" |
| **Costo** | "cuánto cuesta el envío", "costo delivery" |
| **Tiempo** | "cuánto tarda", "cuánto demoran", "tiempo de entrega" |
| **Seguimiento** | "mi pedido", "dónde está", "estado del pedido" |

### Responses

```json
{
  "zona_cobertura": "📍 **Zonas de Delivery:**\n\n{zonas}\n\n💰 **Costo de envío según zona:**\n{costos}\n\n¿Cuál es tu dirección?",

  "cobertura_ok": "✅ **Sí llegamos a tu zona!**\n\n📍 {direccion}\n💰 Costo de envío: ${costo}\n⏱️ Tiempo estimado: {tiempo} minutos\n\n¿Deseas hacer un pedido?",

  "cobertura_no": "❌ **Lo siento, no llegamos a esa zona.**\n\n{direccion}\n\n📋 **Zonas disponibles:**\n{zonas_disponibles}\n\n¿Elegí una dirección dentro de nuestra cobertura o puedes recoger en el local?",

  "pedido_delivery": "🛵 **Pedido para Delivery:**\n\n{items}\n📦 Subtotal: ${subtotal}\n🚚 Envío: ${envio}\n💰 **Total: ${total}**\n\n📍 Entregar en: {direccion}\n📞 Teléfono: {telefono}\n\n¿Confirmas el pedido?",

  "confirmacion_delivery": "🎉 **¡Pedido confirmado!**\n\n📋 **Orden #:** #{orden_id}\n🛵 Tu pedido está en camino.\n\n📍 {direccion}\n⏱️ Llegada estimada: {tiempo}\n\n🔔 Te avisaré cuando esté cerca."
}
```

### Dependencias

| Skill Nata | Uso | Requerido |
|------------|-----|-----------|
| `location` | Validar zona de cobertura | ✅ Sí |
| `forms` | Capturar datos | ✅ Sí |
| `sms_send` | Notificaciones | ⚪ Opcional |

---

## Skill 1.6: FAQ Restaurante (`faq_restaurant`)

### Descripción Funcional

Preguntas frecuentes específicas de restaurantes.

### Intents y Responses Predefinidas

| Pregunta | Response |
|-----------|----------|
| "¿tienen estacionamiento?" | "🅿️ **Sí, contamos con estacionamiento.**\n\nLugares: {cantidad}\nTarifa: {tarifa}\n\n¿Necesitas reservar lugar?" |
| "¿aceptan mascotas?" | "🐕 **{respuesta}**\n\n{politica_mascotas}" |
| "¿tienen menú infantil?" | "👶 **Sí, tenemos menú para niños.**\n\nOpciones:\n{menu_infantil}\n\nPrecio: ${precio}" |
| "¿tienen WiFi?" | "📶 **Sí, WiFi gratuito para clientes.**\n\nRed: {ssid}\nContraseña: {password}" |
| "¿aceptan tarjetas?" | "💳 **Métodos de pago:**\n\n✅ Tarjetas: Visa, Mastercard, American Express\n✅ Efectivo\n✅ Transferencias\n{otros_metodos}" |
| "¿tienen área de fumadores?" | "🚭 **{respuesta}**\n\n{politica}" |
| "¿tienen descuentos?" | "🎉 **Promociones vigentes:**\n\n{promociones}\n\n{condiciones}" |

---

## Skill 1.7: Contacto (`contact_restaurant`)

### Responses

```json
{
  "contacto_completo": "📍 **{nombre_restaurante}**\n\n🏠 {direccion}\n📞 {telefono}\n📧 {email}\n🌐 {web}\n📱 {redes}\n\n🕐 Horarios: {horarios}\n\n¿Necesitas algo más?"
}
```

---

## Skill 1.8: Especiales del Día (`daily_specials`)

### Intents

| Categoría | Intents |
|-----------|---------|
| **Especiales** | "especial del día", "promoción", "oferta", "qué tienen de rico" |
| **Día específico** | "viernes", "fin de semana", "hoy" |

### Responses

```json
{
  "especial_dia": "🎯 **Especial del Día - {dia}:**\n\n🍽️ **{plato}**\n📝 {descripcion}\n💰 **${precio}** (precio normal: ${precio_normal})\n⏰ Disponible hasta: {hora_cierre}\n\n¿Te gustaría ordenarlo?"
}
```

---

# 2️⃣ HOTEL

## Overview

| Aspecto | Detalle |
|---------|---------|
| **Skills totales** | 6 |
| **Dependencias CORE** | email_send, calendar, forms, location, pdf_generate |
| **Dependencias OPCIONALES** | sheets (reportes), sms_send (confirmaciones) |
| **Tiempo setup** | ~20 minutos |
| **Documentos requeridos** | habitaciones.json, servicios.pdf, faq.json |

---

## Skill 2.1: Habitaciones (`rooms`)

### Descripción Funcional

Permite al agente:
- Mostrar tipos de habitaciones disponibles
- Detallar amenidades incluidas
- Consultar disponibilidad por fechas
- Comparar habitaciones
- Mostrar Precios

### Intents

| Categoría | Intents |
|-----------|---------|
| **General** | "habitaciones", "tipos", "qué habitaciones tienen", "cuartos" |
| **Disponibilidad** | "disponibilidad", "tienen habitaciones", "para qué fechas" |
| **Detalles** | "qué incluye", "amenidades", "servicios habitación" |
| **Precios** | "cuánto cuesta", "precio", "tarifas" |
| **Comparar** | "diferencia entre", "cuál es mejor", "comparar" |

### Responses

```json
{
  "tipos_habitaciones": "🏨 **Tipos de Habitaciones:**\n\n{habitaciones_lista}\n\n¿Te gustaría ver detalles de alguna?",

  "detalle_habitacion": "🏨 **{tipo_habitacion}**\n\n📐 Superficie: {superficie} m²\n👥 Capacidad: {capacidad} personas\n🛏️ Camas: {camas}\n\n✨ **Amenidades incluidas:**\n{amenidades_lista}\n\n💰 **Precio por noche:** ${precio}\n{notas}\n\n¿Deseas ver disponibilidad?",

  "disponibilidad": "📅 **Disponibilidad para {fechas}:**\n\n{habitaciones_disponibles}\n\n💰 **Mejor precio:** ${precio} por noche\n\n¿Te gustaría reservar?",

  "comparacion": "📊 **Comparación de Habitaciones:**\n\n| Tipo | Capacidad | Precio | Amenidades |\n{tabla_comparativa}\n\n¿Cuál te interesa?"
}
```

### Implementación

```json
// habitaciones.json
{
  "habitaciones": [
    {
      "id": "simple",
      "nombre": "Habitación Simple",
      "capacidad": 2,
      "camas": "1 cama doble",
      "superficie_m2": 20,
      "precio_base": 80,
      "amenidades": ["WiFi", "TV", "Aire acondicionado", "Baño privado"],
      "imagenes": ["simple1.jpg", "simple2.jpg"]
    },
    {
      "id": "doble",
      "nombre": "Habitación Doble",
      "capacidad": 4,
      "camas": "2 camas dobles",
      "superficie_m2": 30,
      "precio_base": 120,
      "amenidades": ["WiFi", "TV 50\"", "Aire acondicionado", "Baño privado", "Secador", "Minibar"],
      "imagenes": ["doble1.jpg", "doble2.jpg"]
    },
    {
      "id": "suite",
      "nombre": "Suite Ejecutiva",
      "capacidad": 4,
      "camas": "1 cama King",
      "superficie_m2": 50,
      "precio_base": 200,
      "amenidades": ["WiFi premium", "TV 65\"", "Aire acondicionado", "Baño con jacuzzi", "Sala de estar", "Minibar completo", "Cafetera Nespresso"],
      "imagenes": ["suite1.jpg", "suite2.jpg"]
    }
  ]
}
```

---

## Skill 2.2: Reservas Hotel (`reservations_hotel`)

### Description y Responses

```json
{
  "solicitar_datos": "📅 Para tu reservación necesito:\n\n👥 Nombre completo\n📧 Email\n📞 Teléfono\n📅 Check-in\n📅 Check-out\n🏨 Tipo de habitación\n👥 Cantidad de huéspedes\n\n¿Me proporcionas estos datos?",

  "disponibilidad_ok": "✅ **¡Tenemos disponibilidad!**\n\n🏨 **{habitacion}**\n📅 Check-in: {checkin}\n📅 Check-out: {checkout}\n🌙 Noches: {noches}\n💰 **Total: ${total}**\n\n¿Confirmas la reserva?",

  "confirmacion": "🎉 **¡Reserva confirmada!**\n\n📋 **Código de reserva:** #{codigo}\n🏨 {hotel_nombre}\n👤 {nombre}\n📅 {checkin} → {checkout}\n🏨 {habitacion}\n💰 ${total}\n\n📧 Email de confirmación enviado a {email}\n\n🔒 Para modificar, necesitarás tu código: {codigo}"
}
```

---

## Skill 2.3: Servicios (`services`)

### Intents

| Categoría | Intents |
|-----------|---------|
| **Spa** | "spa", "masajes", "tratamientos", "centro de bienestar" |
| **Restaurante** | "restaurante", "desayuno", "cena", "room service" |
| **Piscina** | "piscina", "alberca", "gimnasio", "gym" |
| **Transporte** | "transporte", "traslado", "aeropuerto", "taxi" |
| **Lavandería** | "lavandería", "limpieza", "tintorería" |
| **Otros** | "wi-fi", "caja fuerte", "guardería", "business center" |

### Responses

```json
{
  "lista_servicios": "🌟 **Servicios del Hotel:**\n\n💆 **Spa:** {spa_horarios}\n🍽️ **Restaurante:** {restaurante_horarios}\n🏊 **Piscina:** {piscina_horarios}\n💪 **Gimnasio:** {gym_horarios}\n🚗 **Transporte:** Disponible 24h\n\n¿Te gustaría más información de alguno?",

  "detalle_servicio": "{emoji} **{servicio}**\n\n{descripcion}\n\n🕐 Horario: {horario}\n📍 Ubicación: {ubicacion}\n💰 Precio: {precio}\n📞 Extensión: {extension}\n\n¿Deseas reservar?"
}
```

---

## Skill 2.4: FAQ Hotel (`faq_hotel`)

### Preguntas Frecuentes

| Pregunta | Response |
|-----------|----------|
| Check-in | "🏨 **Check-in**\n\n🕐 Hora: 15:00\n📋 Requisitos:\n• Documento de identidad\n• Tarjeta para depósito\n• Confirmación de reserva\n\n¿Tienes tu código de reserva?" |
| Check-out | "🏨 **Check-out**\n\n🕐 Hora: 12:00\n📋 Puedes:\n• Dejar llaves en recepción\n• Request late check-out (+$X)\n• Dejamos equipaje si necesitas\n\n¿Necesitas algo más?" |
| Cancelación | "❌ **Política de Cancelación:**\n\n• Gratis hasta 24h antes\n• 50% cargo si cancelas el mismo día\n• 100% si no te presentas\n\n¿Necesitas cancelar una reserva?" |
| Mascotas | "🐕 **Mascotas:**\n\n{politica_mascotas}\nCargo adicional: ${cargo_mascota}\n\n¿Vienes con tu mascota?" |
| Niños | "👶 **Niños:**\n\n• Menores de 5 años: Gratis (mismo cuarto)\n• Cunas disponibles: Gratis\n• Menú infantil en restaurante\n• Área de juegos\n\n¿Viajas con niños?" |

---

## Skill 2.5: Contacto Hotel (`contact_hotel`)

### Responses

```json
{
  "contacto_completo": "🏨 **{nombre_hotel}**\n\n⭐ {categoria}\n📍 {direccion}\n📞 {telefono}\n📧 {email}\n🌐 {web}\n\n🗺️ {mapa_url}\n\n🕐 Recepción: 24 horas\n🛎️ Concierge: {concierge_horario}\n\n¿Necesitas algo más?"
}
```

---

## Skill 2.6: Ubicación y Mapas (`location_hotel`)

### Responses

```json
{
  "ubicacion": "📍 **Cómo Llegar:**\n\n{direccion}\n\n🚕 **Desde el aeropuerto:**\n• Taxi: ~{tiempo_aeropuerto} minutos (${costo_aprox})\n• Uber/Didi: ~{costo_app}\n\n🚌 **Transporte público:**\n{indicaciones_bus}\n\n🚗 **En auto:**\n{indicaciones_auto}\n\n¿Necesitas que te reservemos transporte?"
}
```

---

# 3️⃣ TIENDA/RETAIL

## Overview

| Aspecto | Detalle |
|---------|---------|
| **Skills totales** | 7 |
| **Dependencias CORE** | email_send, pdf_generate, excel_read, forms, location |
| **Dependencias OPCIONALES** | sms_send (notificaciones), sheets (inventario) |
| **Tiempo setup** | ~15 minutos |
| **Documentos requeridos** | productos.xlsx, categorias.json, promociones.json |

---

## Skill 3.1: Inventario (`inventory`)

### Intens

| Categoría | Intents |
|-----------|---------|
| **Disponibilidad** | "¿tienen?", "¿hay?", "stock", "disponibilidad" |
| **Consultar** | "cuántos", "hay stock", "tienen producto" |
| **Búsqueda** | "buscar", "encontrar", "necesito" |
| **Alerta** | "avisame", "notifícame cuando" |

### Responses

```json
{
  "disponibilidad_ok": "✅ **{producto} disponible**\n\n📦 Stock: {cantidad} unidades\n📍 Ubicación: {ubicacion_tienda}\n💰 Precio: ${precio}\n\n¿Deseas agregarlo al carrito?",

  "disponibilidad_no": "❌ **{producto} sin stock**\n\nProducto: {producto}\nEstado: Agotado\nRestock estimado: {fecha_restock}\n\n🔔 ¿Te avisamos cuando vuelva a estar disponible?",

  "busqueda_resultados": "🔍 **Resultados para '{busqueda}':**\n\n{productos}\n\nEncontrados: {total} productos\n\n¿Alguno te interesa?",

  "alerta_stock": "🔔 **Alerta de Stock configurada**\n\nProducto: {producto}\nNotificaremos cuando vuelva a estar disponible.\n\nMétodo: {metodo_notificacion}\n\n¿Necesitas algo más?"
}
```

### Dependencias

| Skill Nata | Uso | Requerido |
|------------|-----|-----------|
| `excel_read` | Leer inventario.xlsx | ✅ Sí |
| `extract_data` | Extraer info productos | ✅ Sí |
| `forms` | Capturar email para alertas | ⚪ Opcional |

---

## Skill 3.2: Productos (`products`)

### Intens

| Categoría | Intents |
|-----------|---------|
| **General** | "productos", "catálogo", "qué tienen" |
| **Categoría** | "vestimenta", "tecnología", "hogar", "alimentos" |
| **Recomendación** | "recomiéndame", "qué me recomiendas", "para regalar" |
| **Detalles** | "detalles", "características", "especificaciones" |

### Responses

```json
{
  "catalogo": "🛍️ **Nuestro Catálogo:**\n\n{categorias}\n\n📦 Total: {total_productos} productos\n\n¿Qué categoría te interesa?",

  "categoria": "📦 **{categoria}:**\n\n{productos}\n\n💰 Precios desde: ${precio_min}\n💰 Hasta: ${precio_max}\n\n¿Te gustaría filtrar por algo específico?",

  "detalle_producto": "📦 **{producto}**\n\n📝 {descripcion}\n\n📊 **Especificaciones:**\n{especificaciones}\n\n💰 **Precio: ${precio}**\n🎁 {promocion}\n📦 Stock: {stock}\n\n¿Agregar al carrito?",

  "recomendacion": "🎯 **Te recomendamos:**\n\n{producto_recomendado}\n\n**Por qué:** {razon}\n\n💰 ${precio}\n⭐ {rating}/5 ({reviews} reseñas)\n\n¿Te interesa?"
}
```

---

## Skill 3.3: Pedidos Retail (`orders_retail`)

### Intens y Responses

```json
{
  "carrito_nuevo": "🛒 **Tu Carrito:**\n\nVacío\n\n¿Qué te gustaría agregar?",

  "carrito_agregar": "✅ **Agregado:**\n\n📦 {producto} x{cantidad}\n💰 Subtotal: ${subtotal}\n\n🛒 Tu carrito ahora tiene {items} productos\n💰 Total: ${total}\n\n¿Algo más?",

  "carrito_ver": "🛒 **Tu Carrito:**\n\n{items_lista}\n\n💰 Subtotal: ${subtotal}\n🚚 Envío: ${envio}\n💸 Descuento: -${descuento}\n💰 **Total: ${total}**\n\n¿Procedemos al checkout?",

  "checkout": "💳 **Checkout**\n\n¿Cómo deseas pagar?\n\n1️⃣ Tarjeta de crédito/débito\n2️⃣ Transferencia bancaria\n3️⃣ Efectivo en tienda\n4️⃣ Pago contra entrega\n\n¿Método de pago?",

  "pedido_confirmado": "🎉 **¡Pedido Confirmado!**\n\n📋 **Orden #:** #{orden_id}\n📅 {fecha}\n💰 Total: ${total}\n📍 Entrega: {direccion}\n⏱️ Llegada estimada: {fecha_entrega}\n\n📧 Confirmación enviada a {email}"
}
```

---

## Skill 3.4: Pagos (`payments`)

### Intents

| Categoría | Intents |
|-----------|---------|
| **Métodos** | "pagar", "métodos de pago", "tarjeta", "efectivo" |
| **Factura** | "factura", "comprobante", "CFDI", "recibo" |
| **Cuotas** | "cuotas", " meses sin intereses", "crédito" |
| **Promociones** | "descuentos", "cupones", "promociones" |

### Responses

```json
{
  "metodos_pago": "💳 **Métodos de Pago:**\n\n✅ Tarjetas: Visa, Mastercard, Amex\n✅ Débito\n✅ Efectivo en tienda\n✅ Transferencia\n✅ Pago contra entrega\n{otros_metodos}\n\n¿Con cuál deseas pagar?",

  "pedir_factura": "📄 **Para emitir factura necesito:**\n\n• RFC\n• Razón social\n• Uso de CFDI\n• Email\n\n¿Me proporcionas estos datos?",

  "factura_generada": "📄 **Factura Generada**\n\nRFC: {rfc}\nRazón social: {razon_social}\nTotal: ${total}\n\n📧 Enviada a {email}\n\n¿Necesitas algo más?",

  "promociones": "🎁 **Promociones Vigentes:**\n\n{promociones_lista}\n\n{terminos_y_condiciones}"
}
```

---

## Skill 3.5: Promociones (`promotions`)

### Responses

```json
{
  "promociones_activas": "🎉 **Promociones Vigentes:**\n\n{promociones}\n\n📅 Vigencia: {vigencia}\n📋 Condiciones: {condiciones}\n\n¿Te gustaría aplicar alguna?",

  "cupon_aplicado": "✅ **Cupón Aplicado:**\n\n🎫 {cupon}\n💰 Descuento: ${descuento}\n💰 Nuevo total: ${nuevo_total}\n\n¿Procedes al pago?"
}
```

---

## Skill 3.6: FAQ Tienda (`faq_retail`)

### Preguntas Frecuentes

| Pregunta | Response |
|-----------|----------|
| Devoluciones | "↩️ **Política de Devoluciones:**\n\n• Plazo: {dias} días\n• Producto en estado original\n• Empaque sin abrir\n• Con ticket de compra\n\n¿Necesitas devolver algo?" |
| Garantía | "🛡️ **Garantía:**\n\n{garantia_info}\n\nVigencia: {vigencia}\nCondiciones: {condiciones}" |
| Envíos | "🚚 **Envíos:**\n\nZonas: {zonas}\nCosto: ${costo}\nTiempo: {tiempo}\nGratis en compras mayores a ${minimo}\n\n¿Tu código postal está en cobertura?" |
| Horarios | "🕐 **Horarios de Atención:**\n\n{horarios}\n\n📍 Dirección: {direccion}" |

---

## Skill 3.7: Contacto Tienda (`contact_retail`)

```json
{
  "contacto_completo": "🏪 **{nombre_tienda}**\n\n📍 {direccion}\n📞 {telefono}\n📧 {email}\n🌐 {web}\n📱 {redes}\n\n🕐 Horarios: {horarios}\n\n¿En qué puedo ayudarte?"
}
```

---

# 4️⃣ SERVICIOS PROFESIONALES

## Overview

| Aspecto | Detalle |
|---------|---------|
| **Skills totales** | 6 |
| **Dependencias CORE** | calendar, forms, email_send, cron, sms_send |
| **Dependencias OPCIONALES** | sheets (reportes), video (consultas virtuales) |
| **Tiempo setup** | ~20 minutos |
| **Documentos requeridos** | servicios.json, profesionales.json |

---

## Skill 4.1: Citas (`appointments`)

### Descripción Funcional

Permite al agente:
- Agendar citas
- Consultar disponibilidad
- Modificar citas
- Cancelar citas
- Enviar recordatorios

### Intents

| Categoría | Intents |
|-----------|---------|
| **Agendar** | "cita", "agendar", "reservar", "consulta", "turno" |
| **Consultar** | "disponibilidad", "horarios", "cuándo puedes" |
| **Modificar** | "cambiar", "reagendar", "mover" |
| **Cancelar** | "cancelar", "anular", "no puedo asistir" |
| **Info** | "mi cita", "confirmación", "código" |

### Responses

```json
{
  "solicitar_datos": "📅 **Para agendar tu cita necesito:**\n\n👤 Nombre completo\n📧 Email\n📞 Teléfono\n🏥 Servicio: {servicios_disponibles}\n📅 Fecha preferida\n🕐 Hora preferida\n\n¿Me das estos datos?",

  "seleccionar_servicio": "📋 **Servicios Disponibles:**\n\n{servicios_lista}\n\n¿Cuál te interesa?",

  "seleccionar_profesional": "👤 **Profesionales Disponibles:**\n\n{profesionales_lista}\n\n¿Con quién prefieres?",

  "seleccionar_horario": "📅 **Horarios Disponibles para {fecha}:**\n\n{horarios}\n\n¿Cuál prefieres?",

  "cita_confirmada": "✅ **Cita Confirmada**\n\n📋 **Código:** #{codigo}\n👤 {nombre}\n🏥 {servicio}\n👨‍⚕️ {profesional}\n📅 {fecha}\n🕐 {hora}\n⏱️ Duración: {duracion}\n💰 Costo: ${costo}\n\n📧 Confirmación enviada a {email}\n\n🔔 Te recordaremos {recordatorio_tiempo} antes.",

  "cancelacion": "❌ **Cita Cancelada**\n\n📋 Código: #{codigo}\n\n{politica_cancelacion}\n\n¿Deseas reagendar?",

  "modificacion": "✅ **Cita Modificada**\n\n📋 Código: #{codigo}\n📅 Nueva fecha: {fecha}\n🕐 Nueva hora: {hora}\n\n📧 Confirmación enviada a {email}"
}
```

### Implementación

```json
// servicios.json
{
  "servicios": [
    {
      "id": "consulta_general",
      "nombre": "Consulta General",
      "duracion_minutos": 30,
      "precio": 50,
      "descripcion": "Evaluación inicial y diagnóstico"
    },
    {
      "id": "seguimiento",
      "nombre": "Cita de Seguimiento",
      "duracion_minutos": 20,
      "precio": 40,
      "descripcion": "Revisión de tratamiento"
    }
  ],
  "profesionales": [
    {
      "id": "dr1",
      "nombre": "Dr. Juan Pérez",
      "especialidad": "Medicina General",
      "horarios": {
        "lunes": ["09:00", "10:00", "11:00", "16:00", "17:00"],
        "martes": ["09:00", "10:00", "11:00"],
        "miercoles": ["16:00", "17:00", "18:00"]
      }
    }
  ]
}
```

---

## Skill 4.2: Calendario (`calendar_service`)

### Intents y Responses

```json
{
  "ver_disponibilidad": "📅 **Disponibilidad de {profesional}:**\n\n{fechas_disponibles}\n\n¿Qué fecha te conviene?",

  "ver_agenda": "📅 **Tu Agenda:**\n\n{citas}\n\nTotal: {total} citas programadas",

  "proxima_cita": "📋 **Próxima Cita:**\n\n👤 {profesional}\n🏥 {servicio}\n📅 {fecha}\n🕐 {hora}\n📍 {ubicacion}\n\n🔔 Recordatorio: Enviado {recordatorio_tiempo} antes"
}
```

---

## Skill 4.3: Recordatorios (`reminders`)

### Intents

| Categoría | Intents |
|-----------|---------|
| **Configurar** | "recordarme", "avisame", "notifícame" |
| **Modificar** | "cambiar recordatorio", "otro horario" |
| **Cancelar** | "quitar recordatorio", "ya no me avises" |

### Responses

```json
{
  "configurar": "🔔 **Recordatorio Configurado**\n\n📅 Cita: {fecha} a las {hora}\n⏰ Te avisaré {tiempo_antes}\n📱 Método: {metodo}\n\n¿Necesitas algo más?",

  "recordatorio_enviado": "🔔 **Recordatorio:**\n\n🏥 Tienes una cita mañana\n📅 {fecha}\n🕐 {hora}\n📍 {ubicacion}\n\n¿Confirmas asistencia?"
}
```

---

## Skill 4.4: Seguimiento (`followup`)

### Intents y Responses

```json
{
  "solicitar_seguimiento": "📋 **Para tu seguimiento necesito:**\n\n📧 Email\n📞 Teléfono\n📅 Fecha preferida\n\n¿Te envío el formulario?",

  "formularios": "📝 **Formularios de Seguimiento:**\n\n{formularios}\n\n¿Cuál necesitas?",

  "seguimiento_configurado": "✅ **Seguimiento Configurado**\n\n📧 Te contactaremos el {fecha}\n📞 Método: {metodo}\n📋 Motivo: {motivo}\n\nRegistro guardado en tu expediente."
}
```

---

## Skill 4.5: FAQ Servicios (`faq_services`)

### Preguntas Frecuentes

| Pregunta | Response |
|-----------|----------|
| Precios | "💰 **Precios:**\n\n{precios_lista}\n\nPagos aceptados: {metodos_pago}" |
| Duración | "⏱️ **Duración de Servicios:**\n\n{duracion_lista}" |
| Ubicación | "📍 **Ubicación:**\n\n{direccion}\n{indicaciones}\n\n¿Necesitas mapa?" |
| Preparación | "📋 **Preparación para tu Cita:**\n\n{preparacion_lista}" |
| Documentos | "📄 **Documentos Requeridos:**\n\n{documentos_lista}" |

---

## Skill 4.6: Contacto Servicios (`contact_services`)

```json
{
  "contacto_completo": "🏥 **{nombre_servicio}**\n\n👨‍⚕️ {profesional}\n📍 {direccion}\n📞 {telefono}\n📧 {email}\n🌐 {web}\n\n🕐 Horarios:\n{horarios}\n\n¿Deseas agendar una cita?"
}
```

---

# 5️⃣ GENÉRICO

## Overview

| Aspecto | Detalle |
|---------|---------|
| **Skills totales** | 5 |
| **Dependencias CORE** | pdf_read, extract_data, location |
| **Dependencias OPCIONALES** | email_send, calendar |
| **Tiempo setup** | ~10 minutos |
| **Documentos requeridos** | faq.json, contacto.json |

---

## Skill 5.1: FAQ Genérico (`faq_generic`)

### Intents

| Categoría | Intents |
|-----------|---------|
| **Qué** | "¿qué es?", "información", "descripción" |
| **Cómo** | "¿cómo funciona?", "¿cómo hago?", "proceso" |
| **Cuándo** | "¿cuándo?", "horarios", "tiempos" |
| **Dónde** | "¿dónde?", "ubicación", "dirección" |
| **Por qué** | "¿por qué?", "razón", "motivo" |
| **Cuánto** | "¿cuánto cuesta?", "precio", "tarifa" |

### Responses

```json
{
  "faq_general": "📋 **{negocio} - Preguntas Frecuentes:**\n\n{preguntas_lista}\n\n¿Sobre cuál quieres saber más?",

  "faq_respuesta": "**{pregunta}:**\n\n{respuesta}\n\n¿Hay algo más en lo que pueda ayudarte?",

  "no_encontrado": "❓ No encontré una respuesta específica para '{pregunta}'.\n\n¿Te gustaría hablar con un asesor?\n\n📞 {telefono}\n📧 {email}"
}
```

### Implementación

```json
// faq.json
{
  "negocio": "Nombre del Negocio",
  "preguntas": [
    {
      "id": "que_es",
      "pregunta": "¿Qué es {negocio}?",
      "respuesta": "Somos una empresa dedicada a {descripcion_corta}. Ofrecemos {servicios}.",
      "intents": ["qué es", "información", "descripción", "quiénes son"]
    },
    {
      "id": "horarios",
      "pregunta": "¿Cuáles son los horarios de atención?",
      "respuesta": "Atendemos de {hora_apertura} a {hora_cierre}, {dias_atencion}.",
      "intents": ["horarios", "horario", "a qué hora", "cuándo abren", "cuándo cierran"]
    },
    {
      "id": "precios",
      "pregunta": "¿Cuánto cuestan sus servicios?",
      "respuesta": "Nuestros precios van desde ${precio_min} hasta ${precio_max}. Para una cotización exacta, te recomendamos contactarnos.",
      "intents": ["precio", "cuánto cuesta", "tarifas", "costo"]
    },
    {
      "id": "ubicacion",
      "pregunta": "¿Dónde están ubicados?",
      "respuesta": "Estamos en {direccion}. Puedes llegar por {indicaciones}.",
      "intents": ["dónde están", "ubicación", "dirección", "cómo llegar"]
    },
    {
      "id": "contacto",
      "pregunta": "¿Cómo puedo contactarlos?",
      "respuesta": "Puedes contactarnos por:\n\n📞 Teléfono: {telefono}\n📧 Email: {email}\n🌐 Web: {web}\n📱 WhatsApp: {whatsapp}",
      "intents": ["contacto", "contactar", "teléfono", "email", "whatsapp"]
    }
  ]
}
```

---

## Skill 5.2: Contacto Genérico (`contact_generic`)

### Responses

```json
{
  "contacto_principal": "📞 **Contacto:**\n\n📱 WhatsApp: {whatsapp}\n📧 Email: {email}\n📞 Teléfono: {telefono}\n🌐 Web: {web}\n\n🕐 Atención: {horarios}",

  "contacto_redes": "📱 **Redes Sociales:**\n\n📘 Facebook: {facebook}\n📸 Instagram: {instagram}\n🐦 Twitter: {twitter}\n💼 LinkedIn: {linkedin}\n▶️ YouTube: {youtube}\n\n¿Te gustaría seguirnos?",

  "contacto_ubicacion": "📍 **Ubicación:**\n\n{direccion}\n\n🗺️ Ver mapa: {mapa_url}\n\n🚗 Cómo llegar:\n{indicaciones}"
}
```

---

## Skill 5.3: Horarios Genérico (`hours_generic`)

### Responses

```json
{
  "horarios_atencion": "🕐 **Horarios de Atención:**\n\n📅 Lunes a Viernes: {hora_lv}\n📅 Sábado: {hora_sab}\n📅 Domingo: {hora_dom}\n\n{estado_actual}",

  "estado_actual_abierto": "✅ **Estamos ABIERTOS ahora.**\n\nCerramos a las {hora_cierre}. ¿En qué puedo ayudarte?",

  "estado_actual_cerrado": "❌ **Estamos CERRADOS ahora.**\n\nAbriremos: {proxima_apertura}\n\n¿Te gustaría dejar un mensaje?"
}
```

---

## Skill 5.4: Ubicación Genérico (`location_generic`)

### Intents y Responses

```json
{
  "ubicacion": "📍 **Ubicación:**\n\n{direccion}\n{ciudad}, {estado} {codigo_postal}\n{pais}\n\n🗺️ Ver mapa: {mapa_url}",

  "como_llegar": "🚗 **Cómo Llegar:**\n\n{indicaciones}\n\n🚌 Transporte público:\n{transporte_publico}\n\n🚗 Estacionamiento:\n{estacionamiento_info}"
}
```

---

## Skill 5.5: Consultas Generales (`general_queries`)

### Intents y Responses

```json
{
  "saludo": "👋 ¡Hola! Bienvenido/a a {negocio}.\n\nSoy {nombre_asistente}, tu asistente virtual. ¿En qué puedo ayudarte?",

  "despedida": "👋 ¡Gracias por contactarnos!\n\nSi tienes más preguntas, no dudes en escribirnos.\n\n{contacto_info}\n\n¡Que tengas un excelente día!",

  "ayuda": "🤝 **Puedo ayudarte con:**\n\n• Información sobre {servicios}\n• Horarios y ubicación\n• Precios y cotizaciones\n• Agendar citas\n• Preguntas frecuentes\n\n¿Qué necesitas?",

  "no_entendido": "🤔 No estoy seguro de entender tu pregunta.\n\n¿Podrías reformularla? O puedo transferirte con un asesor humano.\n\n¿Qué prefieres?",

  "agradecimiento": "😊 ¡De nada! Si tienes más preguntas, estoy aquí para ayudarte.\n\n¿Hay algo más en lo que pueda asistirte?",

  "error": "❌ Lo siento, hubo un problema procesando tu solicitud.\n\nPor favor intenta de nuevo o contacta directamente:\n\n📞 {telefono}\n📧 {email}"
}
```

---

# 📋 RESUMEN FINAL - SKILLS POR NEGOCIO

| Negocio | Skills | Deps CORE | Deps OPC | Docs Requeridos | Setup |
|---------|--------|-----------|----------|-----------------|-------|
| **RESTAURANTE** | 8 | email, pdf, calendar, forms, location | sms, voice | menu.pdf, faq.json | ~15 min |
| **HOTEL** | 6 | email, calendar, forms, location, pdf | sheets, sms | habitaciones.json, servicios.pdf | ~20 min |
| **TIENDA/RETAIL** | 7 | email, pdf, excel, forms, location | sms, sheets | productos.xlsx, promociones.json | ~15 min |
| **SERVICIOS** | 6 | calendar, forms, email, cron, sms | sheets, video | servicios.json, profesionales.json | ~20 min |
| **GENÉRICO** | 5 | pdf, extract, location | email, calendar | faq.json, contacto.json | ~10 min |

---

# 🔧 ARCHIVOS DE CONFIGURACIÓN

## Estructura Final

```
~/.openclaw/knowledge/
├── business/
│   ├── tipo.json           # restaurante | hotel | tienda | servicios | generic
│   ├── config.json         # Configuración general
│   └── faq.json            # FAQ específico
│
├── restaurante/
│   ├── menu.pdf
│   ├── promociones.pdf
│   ├── horarios.json
│   └── reservas.db
│
├── hotel/
│   ├── habitaciones.json
│   ├── servicios.json
│   ├── horarios.json
│   └── faq.json
│
├── tienda/
│   ├── productos.xlsx
│   ├── categorias.json
│   ├── promociones.json
│   └── inventario.db
│
├── servicios/
│   ├── servicios.json
│   ├── profesionales.json
│   ├── horarios.json
│   └── citas.db
│
└── generico/
    ├── faq.json
    ├── contacto.json
    └── horarios.json
```

---

*Documento detallado para FASE 4 ÁREA 6 - SKILLS BUNDLES*
*Versión: 1.1.0*
*Fecha: 2026-03-05*