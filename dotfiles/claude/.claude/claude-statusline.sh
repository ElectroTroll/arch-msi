#!/usr/bin/env bash
# claude-statusline.sh — hook `statusLine` de Claude Code (arch-msi)
# Fecha: 2026-08-02 · Tarea 2.1, paso 2/4.
#
# HACE DOS COSAS:
#   1. Imprime la línea de estado que Claude Code muestra en la sesión.
#   2. Vuelca los porcentajes de uso a $XDG_RUNTIME_DIR/claude-usage.json,
#      que es de donde los lee el módulo `custom/claude` de Waybar.
#
# POR QUÉ ESTE RODEO: los porcentajes de las ventanas de 5 h y 7 días NO son
# consultables desde fuera. No hay subcomando del CLI, ni archivo en ~/.claude,
# ni endpoint local. El único sitio donde aparecen es el JSON que Claude Code
# entrega por stdin a este hook. Por eso Waybar no puede pedirlos: hay que
# dejárselos escritos.
#
# CONSECUENCIA ASUMIDA: el dato solo se refresca mientras haya una sesión de
# Claude Code abierta redibujando su línea de estado. Sin sesión, el archivo
# envejece. El lector de Waybar lo detecta por la marca `written_at` y lo
# muestra como viejo en vez de mentir con una cifra caducada.
#
# UBICACIÓN: paquete Stow `claude`, enlazado a ~/.claude/claude-statusline.sh.
# Se puso aquí y no en scripts/ para que settings.json apunte a una ruta que NO
# depende de dónde esté clonado el repositorio: mover o renombrar arch-msi no
# rompe la línea de estado.
#
# EL PAQUETE STOW `claude` DEBE CONTENER SOLO ESTE SCRIPT. ~/.claude guarda
# credenciales (.credentials.json), historial y datos de sesión, nada de lo
# cual puede versionarse (ver CLAUDE.md). Stow enlaza archivo a archivo, no
# pliega el directorio, así que el resto de ~/.claude queda intacto — pero
# añadir cualquier otra cosa a este paquete exige comprobarlo antes.
#
# LO QUE SIGUE SIN CUBRIR: ~/.claude/settings.json, que es quien invoca este
# script, NO está versionado. Una restauración del repo deja el script en su
# sitio pero sin nadie que lo llame, y el módulo de Waybar se queda mudo sin
# avisar. Mismo agujero que el `enable` de hypridle.service: ver
# PROJECT_CONTEXT §14.
#
# ESQUEMA DE ENTRADA verificado en el binario de claude 2.1.220. Los dos
# bloques de rate_limits están documentados allí como OPCIONALES ("may be
# absent"), de ahí los `// null` en todas las extracciones.

set -uo pipefail

input=$(cat)

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
out="$runtime/claude-usage.json"

# --- 1. Volcado para Waybar ------------------------------------------------
# Escritura atómica: se crea un temporal en el MISMO directorio y se mueve
# encima. Sin esto, Waybar podría leer el archivo a medio escribir y mostrar
# basura. `mv` dentro del mismo sistema de archivos es atómico.
#
# `now` lo da jq: evita invocar `date` y ahorra un proceso. Este script corre
# en cada redibujado de la línea de estado, así que conviene que sea barato.
if tmp=$(mktemp "$out.XXXXXX" 2>/dev/null); then
    if printf '%s' "$input" | jq -c '{
            five_hour:  (.rate_limits.five_hour  // null),
            seven_day:  (.rate_limits.seven_day  // null),
            context:    (.context_window.used_percentage // null),
            written_at: (now | floor)
        }' > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$out" 2>/dev/null || rm -f "$tmp"
    else
        rm -f "$tmp"
    fi
fi

# --- 2. Línea de estado de la sesión ---------------------------------------
# Los campos ausentes se omiten en lugar de imprimirse a cero: un 0% real y un
# "no disponible" no son lo mismo, y confundirlos en una línea de estado que se
# mira de reojo es peor que no enseñar nada.
printf '%s' "$input" | jq -r '
    [
      (.model.display_name // empty),
      (if .context_window.used_percentage != null
       then "ctx \(.context_window.used_percentage | floor)%" else empty end),
      (if .rate_limits.five_hour.used_percentage != null
       then "5h \(.rate_limits.five_hour.used_percentage | floor)%" else empty end),
      (if .rate_limits.seven_day.used_percentage != null
       then "7d \(.rate_limits.seven_day.used_percentage | floor)%" else empty end)
    ] | join("  ·  ")
' 2>/dev/null || true
