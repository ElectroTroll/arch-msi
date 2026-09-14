#!/usr/bin/env bash
#
# Rota la salida de audio DE TODO EL SISTEMA entre los altavoces internos del
# portátil, la interfaz USB (Solid State Logic SSL 2+ Mk II) y cualquier
# altavoz o auricular Bluetooth conectado, sin desenchufar nada. Funciona como
# usuario normal (sin sudo).
#
# Uso: audio-salida            pasa a la siguiente salida disponible
#      audio-salida --status   lista las salidas y marca cuáles entran en la rotación
#
# POR QUÉ NO BASTA CON `pactl set-default-sink`. Cambiar el predeterminado solo
# afecta a los flujos NUEVOS y a los que no tengan destino fijado; una app que
# ya esté sonando —o que pavucontrol haya anclado a un dispositivo concreto— se
# queda donde estaba. Por eso, después de cambiar el predeterminado, aquí se
# mueven a mano todos los sink-inputs vivos. Eso es lo que hace que el atajo
# valga para "todo el sistema" y no solo para lo que se abra a partir de ahora.
#
# POR QUÉ SE IDENTIFICAN LOS SINKS POR NOMBRE Y NO POR ID. Los IDs numéricos de
# `wpctl`/`pactl` se reasignan en cada arranque y cada vez que se reconecta la
# interfaz; los nombres (`alsa_output.usb-...`, `alsa_output.pci-...`,
# `bluez_output.<MAC>.N`) son estables porque los deriva ALSA o BlueZ de la ruta
# del dispositivo o de la dirección del aparato.
#
# LOS HDMI QUEDAN FUERA A PROPÓSITO. Este equipo expone cuatro sinks HDMI/DP
# (tres del iGPU Intel + uno de la RTX 4060) que aparecen aunque no haya nada
# enchufado. Meterlos en la rotación la llenaría de destinos mudos. Para esos
# casos está pavucontrol.
#
# EL BLUETOOTH SÍ ENTRA, Y NO ESTORBA CUANDO NO ESTÁ. A diferencia de los HDMI,
# un `bluez_output.*` solo existe mientras el aparato está emparejado Y
# conectado: si no hay nada, la rotación vuelve sola a dos posiciones. Si hay
# varios conectados a la vez, cada uno es una parada más, en orden estable.

set -Eeuo pipefail

# El sink de los altavoces del portátil: tarjeta `sof-hda-dsp` del chipset
# Meteor Lake, verbo UCM `Speaker`. El resto de sinks de esa misma tarjeta son
# los HDMI, de ahí que el patrón exija las dos partes.
PATRON_INTERNO='skl_hda_dsp_generic.*Speaker'

# Cualquier interfaz de audio USB, no solo la SSL: `alsa_output.usb-` es el
# prefijo que ALSA da a todas. Así el script sigue sirviendo si algún día se
# conecta otra interfaz distinta.
PATRON_USB='^alsa_output\.usb-'

# Cualquier salida Bluetooth. PipeWire crea estos sinks a través de BlueZ y el
# nombre lleva la MAC del aparato, que es fija.
PATRON_BT='^bluez_output\.'

# La SSL 2+ Mk II expone dos sinks (`Line1` y `Line2`). Line1 son las salidas
# principales, que es lo que WirePlumber elige por defecto y donde están los
# monitores; Line2 se ignora salvo que Line1 no exista.
PREFERENCIA_USB='Line1'

sinks() { pactl list short sinks | cut -f2; }

descripcion() {
    pactl list sinks \
        | awk -v n="$1" '
            $1 == "Name:" { actual = ($2 == n) }
            actual && ($1 == "Description:" || $1 == "Descripción:") {
                $1 = ""; sub(/^ /, ""); print; exit
            }'
}

todos="$(sinks)"

interno="$(printf '%s\n' "$todos" | grep -m1 -E "$PATRON_INTERNO" || true)"
usb="$(printf '%s\n' "$todos" | grep -E "$PATRON_USB" | grep -m1 "$PREFERENCIA_USB" || true)"
[ -z "$usb" ] && usb="$(printf '%s\n' "$todos" | grep -m1 -E "$PATRON_USB" || true)"
# Ordenados para que dos aparatos Bluetooth conectados a la vez den siempre la
# misma secuencia; `pactl` los lista por ID, que cambia en cada reconexión.
bt="$(printf '%s\n' "$todos" | grep -E "$PATRON_BT" | sort || true)"

# El orden de la rotación: internos -> USB -> Bluetooth -> internos. Las paradas
# que no existen simplemente no se añaden.
anillo="$(printf '%s\n%s\n%s\n' "$interno" "$usb" "$bt" | grep -v '^$' || true)"

actual="$(pactl get-default-sink)"

case "${1:-}" in
    --status|-s)
        # `*` la salida activa, `·` las demás paradas de la rotación, nada las
        # que quedan fuera (los HDMI).
        for s in $todos; do
            marca=" "
            printf '%s\n' "$anillo" | grep -qxF "$s" && marca="·"
            [ "$s" = "$actual" ] && marca="*"
            printf "%s %s\t%s\n" "$marca" "$s" "$(descripcion "$s")"
        done | column -t -s $'\t'
        exit 0
        ;;
    -h|--help)
        sed -n '2,9p' "$0"
        exit 0
        ;;
esac

if [ -z "$interno" ]; then
    echo "audio-salida: no encuentro los altavoces internos" >&2
    exit 1
fi

# Siguiente parada. Si el predeterminado está en la rotación se avanza una
# posición y se vuelve al principio al llegar al final; si está fuera (un HDMI
# que se haya colado como predeterminado) se entra por los altavoces internos.
destino="$(printf '%s\n' "$anillo" | awk -v a="$actual" '
    { parada[NR] = $0 }
    $0 == a { i = NR }
    END { print parada[(i % NR) + 1] }')"

if [ "$destino" = "$actual" ]; then
    echo "audio-salida: sin cambios (no hay más salidas disponibles)"
    exit 0
fi

pactl set-default-sink "$destino"

# Arrastrar lo que ya estaba sonando. La lista se relee AQUÍ y no antes porque
# `set-default-sink` ya puede haber movido parte de los flujos por su cuenta;
# mover un sink-input al sink en el que ya está es inocuo.
while IFS= read -r id; do
    [ -n "$id" ] || continue
    pactl move-sink-input "$id" "$destino" 2>/dev/null || true
done < <(pactl list short sink-inputs | cut -f1)

# El destino puede venir silenciado de una sesión anterior: sin esto el atajo
# parecería no hacer nada. El volumen NO se toca, para respetar el nivel que
# tenga puesto cada salida.
pactl set-sink-mute "$destino" 0

etiqueta="$(descripcion "$destino")"
[ -n "$etiqueta" ] || etiqueta="$destino"

# -a agrupa las notificaciones bajo una misma app en dunst; el stack-tag hace
# que pulsar el atajo varias veces REEMPLACE el aviso en vez de apilarlos.
notify-send -a "Audio" -u low \
    -h "string:x-dunst-stack-tag:audio-salida" \
    "Salida de audio" "$etiqueta" 2>/dev/null || true

echo "audio-salida: -> $etiqueta"
