#!/usr/bin/env bash
#
# Alterna la salida de audio DE TODO EL SISTEMA entre la interfaz USB
# (Solid State Logic SSL 2+ Mk II) y los altavoces internos del portátil,
# sin desenchufar nada. Funciona como usuario normal (sin sudo).
#
# Uso: audio-salida            alterna interfaz <-> altavoces internos
#      audio-salida --status   dice cuál es la salida activa
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
# interfaz; los nombres (`alsa_output.usb-...`, `alsa_output.pci-...`) son
# estables porque los deriva ALSA de la ruta del dispositivo.
#
# LOS HDMI QUEDAN FUERA A PROPÓSITO. Este equipo expone cuatro sinks HDMI/DP
# (tres del iGPU Intel + uno de la RTX 4060) que aparecen aunque no haya nada
# enchufado. Meterlos en la rotación convertiría un atajo de dos posiciones en
# uno de seis, en su mayoría mudos. Para esos casos está pavucontrol.

set -Eeuo pipefail

# El sink de los altavoces del portátil: tarjeta `sof-hda-dsp` del chipset
# Meteor Lake, verbo UCM `Speaker`. El resto de sinks de esa misma tarjeta son
# los HDMI, de ahí que el patrón exija las dos partes.
PATRON_INTERNO='skl_hda_dsp_generic.*Speaker'

# Cualquier interfaz de audio USB, no solo la SSL: `alsa_output.usb-` es el
# prefijo que ALSA da a todas. Así el script sigue sirviendo si algún día se
# conecta otra interfaz distinta.
PATRON_USB='^alsa_output\.usb-'

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

interno="$(sinks | grep -m1 -E "$PATRON_INTERNO" || true)"
usb="$(sinks | grep -E "$PATRON_USB" | grep -m1 "$PREFERENCIA_USB" || true)"
[ -z "$usb" ] && usb="$(sinks | grep -m1 -E "$PATRON_USB" || true)"

actual="$(pactl get-default-sink)"

case "${1:-}" in
    --status|-s)
        for s in $(sinks); do
            marca=" "
            [ "$s" = "$actual" ] && marca="*"
            printf "%s %s\t%s\n" "$marca" "$s" "$(descripcion "$s")"
        done | column -t -s $'\t'
        exit 0
        ;;
    -h|--help)
        sed -n '2,8p' "$0"
        exit 0
        ;;
esac

if [ -z "$interno" ]; then
    echo "audio-salida: no encuentro los altavoces internos" >&2
    exit 1
fi

# Estando en la interfaz se va a los altavoces; desde CUALQUIER otro sitio
# (altavoces, o un HDMI que se haya colado como predeterminado) se va a la
# interfaz, y si no hay interfaz conectada, a los altavoces.
if [ -n "$usb" ] && [ "$actual" != "$usb" ]; then
    destino="$usb"
else
    destino="$interno"
fi

if [ "$destino" = "$actual" ]; then
    echo "audio-salida: sin cambios (no hay interfaz USB conectada)"
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
