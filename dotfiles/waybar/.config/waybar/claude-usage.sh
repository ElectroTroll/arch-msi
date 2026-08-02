#!/usr/bin/env bash
# claude-usage.sh — módulo `custom/claude` de Waybar (arch-msi)
# Fecha: 2026-08-02 · Tarea 2.1, paso 2/4.
#
# Lee $XDG_RUNTIME_DIR/claude-usage.json —que escribe el hook statusLine, ver
# scripts/claude-statusline.sh— y devuelve JSON para Waybar (`return-type`:
# json), lo que permite fijar una clase CSS además del texto.
#
# Vive DENTRO del paquete Stow de Waybar, no en scripts/, para que la ruta
# quede fija en ~/.config/waybar/ y el módulo no dependa de dónde esté clonado
# el repositorio.
#
# TRES ESTADOS:
#   sin-dato  → nunca ha corrido una sesión de Claude Code en este arranque
#   fresco    → hay sesión abierta refrescando el archivo
#   viejo     → el archivo existe pero lleva rato sin actualizarse
#
# El estado `viejo` es el importante: sin él, la barra enseñaría un porcentaje
# de hace horas como si fuera de ahora. Preferimos marcarlo antes que mentir.

set -uo pipefail

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
file="$runtime/claude-usage.json"

# 600 s = 10 min. El hook se dispara en cada redibujado de la línea de estado,
# así que con una sesión abierta el archivo se refresca constantemente. Diez
# minutos sin una sola escritura significa que ya no hay sesión viva.
stale_after=600

sin_dato() {
    printf '%s\n' '{"text":"—","class":"sin-dato","tooltip":"Uso de Claude: sin datos.\nSe rellenan solos al abrir una sesión de Claude Code."}'
    exit 0
}

[ -r "$file" ] || sin_dato

jq -c --argjson stale "$stale_after" '
    def pct(x): if x == null then null else (x | floor) end;

    (now | floor) - (.written_at // 0)          as $age
    | pct(.five_hour.used_percentage)            as $five
    | pct(.seven_day.used_percentage)            as $seven
    | pct(.context)                              as $ctx

    # Texto: se omite el tramo que falte en vez de escribir 0%.
    | ( [ (if $five  != null then "5h \($five)%"  else empty end),
          (if $seven != null then "7d \($seven)%" else empty end) ]
        | join(" · ") ) as $txt

    # Antigüedad en lenguaje llano para el tooltip.
    | ( if   $age < 60    then "hace instantes"
        elif $age < 3600  then "hace \(($age/60) | floor) min"
        else                   "hace \(($age/3600) | floor) h"
        end ) as $edad

    | if $txt == "" then
          # El archivo existe pero no traía ningún rate_limit: los dos bloques
          # son opcionales en el esquema de Claude Code y pueden faltar.
          {text: "—", class: "sin-dato",
           tooltip: "Uso de Claude: la sesión no informó de límites.\nActualizado \($edad)."}
      elif $age > $stale then
          {text: $txt, class: "viejo",
           tooltip: "Uso de Claude (DATO VIEJO, \($edad))\nNo hay ninguna sesión abierta refrescándolo.\n\($ctx // "?" | tostring)% de contexto en la última sesión."}
      else
          {text: $txt, class: "fresco",
           tooltip: "Uso de Claude · actualizado \($edad)\nVentana de 5 h: \($five // "?" | tostring)%\nVentana de 7 días: \($seven // "?" | tostring)%\nContexto de la sesión: \($ctx // "?" | tostring)%"}
      end
' "$file" 2>/dev/null || sin_dato
