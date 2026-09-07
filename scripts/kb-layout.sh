#!/usr/bin/env bash
#
# Alterna la distribución de teclado (es <-> us) DEL TECLADO QUE PULSA EL ATAJO,
# sin tocar la de los demás. Funciona como usuario normal (sin sudo).
#
# Uso: kb-layout                 alterna a la siguiente distribución
#      kb-layout <dispositivo>   alterna solo en ese teclado (nombre de
#                                `hyprctl devices`)
#      kb-layout --status        dice en qué distribución está cada teclado
#
# POR QUÉ FUNCIONA POR TECLADO Y NO GLOBALMENTE. En Wayland el estado de xkb
# —qué distribución de la lista está activa— es POR DISPOSITIVO, no de la
# sesión. Cada teclado lleva su propio índice, así que alternar en uno deja el
# otro como estaba. Eso es justo lo que se quiere: el portátil tiene serigrafía
# española y el teclado USB externo americana, y lo normal es que cada uno se
# quede en la suya.
#
# La lista de distribuciones y su orden los pone hyprland.lua, NO este script:
#   - global (portátil incluido)  "es,us" / variantes ",intl"  -> arranca en es
#   - teclado Semitek externo     "us,es" / variantes "intl,"  -> arranca en us
# La americana es US International con teclas muertas, para que también escriba
# tildes, ñ y ç (detalle en docs/PROJECT_CONTEXT.md §20).
# `switchxkblayout next` solo ROTA entre las ya cargadas; si un teclado tuviera
# una sola distribución esto no haría nada (y no fallaría).
#
# `current` es una palabra clave de hyprctl: el último teclado que ha enviado
# una tecla, o sea el que acaba de pulsar Super+Espacio. Por eso no hace falta
# detectar el dispositivo a mano.
#
# ⚠️ POR QUÉ ESTE SCRIPT Y NO UN `hyprctl switchxkblayout current next` PELADO.
# Un teclado USB puede exponer VARIOS endpoints HID, y Hyprland los ve como
# teclados independientes con estado xkb independiente. El Semitek de este
# equipo expone dos (`semitek-usb-hid-gaming-keyboard` y `-1`) y los dos emiten
# teclas. Alternar solo el que mandó la pulsación los DESINCRONIZA —comprobado
# el 2026-09-07: uno se quedaba en Spanish y el otro en English (US)—, con lo
# que parte de las teclas responderían con la distribución equivocada. Así que
# aquí se detecta cuál cambió y se alinean sus hermanos al mismo índice.

set -Eeuo pipefail

instantanea() { hyprctl -j devices; }

case "${1:-}" in
    --status|-s)
        instantanea | jq -r '
            .keyboards[]
            | "\(if .main then "*" else " " end) \(.name)\t\(.active_keymap)"' \
            | column -t -s $'\t'
        exit 0
        ;;
    -h|--help)
        sed -n '2,9p' "$0"
        exit 0
        ;;
esac

antes="$(instantanea)"
hyprctl switchxkblayout "${1:-current}" next >/dev/null
despues="$(instantanea)"

# Qué dispositivo cambió de índice. Se compara en vez de fiarse de `main`
# porque `current` (último teclado que escribió) y `main` no tienen por qué ser
# el mismo, y equivocarse aquí significaría alinear el teclado que no es.
cambiado="$(jq -rn --argjson a "$antes" --argjson d "$despues" '
    ($a.keyboards | map({key: .name, value: .active_layout_index}) | from_entries) as $prev
    | $d.keyboards[]
    | select($prev[.name] != null and $prev[.name] != .active_layout_index)
    | "\(.name)\t\(.active_layout_index)"' | head -1)"

if [ -z "$cambiado" ]; then
    # Una sola distribución cargada: no hay nada entre lo que rotar.
    echo "kb-layout: sin cambios (¿solo una distribución en kb_layout?)"
    exit 0
fi

dispositivo="${cambiado%%$'\t'*}"
indice="${cambiado##*$'\t'}"

# Nombre base sin el sufijo `-N` que Hyprland añade a los endpoints extra del
# mismo dispositivo físico. Solo un `-` seguido de dígitos: `razer-basilisk-v3`
# o `intel-hid-5-button-array` no se tocan.
if [[ "$dispositivo" =~ ^(.*)-[0-9]+$ ]]; then
    base="${BASH_REMATCH[1]}"
else
    base="$dispositivo"
fi

# Alinear los endpoints hermanos al mismo índice.
while IFS= read -r hermano; do
    [ "$hermano" = "$dispositivo" ] && continue
    hyprctl switchxkblayout "$hermano" "$indice" >/dev/null
done < <(jq -rn --argjson d "$despues" --arg base "$base" '
    $d.keyboards[]
    | select(.name == $base or (.name | startswith($base + "-") and test("-[0-9]+$")))
    | .name')

distribucion="$(jq -rn --argjson d "$despues" --arg n "$dispositivo" '
    $d.keyboards[] | select(.name == $n) | .active_keymap')"

# Nombre legible para el aviso. Puramente cosmético: los que no estén aquí
# salen con el nombre crudo de `hyprctl devices`, que sigue siendo informativo.
case "$base" in
    at-translated-set-2-keyboard)   legible="Teclado del portátil" ;;
    semitek-usb-hid-gaming-keyboard) legible="Teclado externo (Semitek)" ;;
    *)                              legible="$base" ;;
esac

# -a agrupa las notificaciones bajo una misma app en dunst (§16); el stack-tag
# hace que pulsar el atajo varias veces REEMPLACE el aviso en vez de apilarlos.
notify-send -a "Teclado" -u low \
    -h "string:x-dunst-stack-tag:kb-layout" \
    "$distribucion" "$legible" 2>/dev/null || true

echo "kb-layout: $legible -> $distribucion"
