#!/usr/bin/env bash
#
# Parchea el perfil UCM de la SSL 2+ Mk II para que declare los canales que el
# aparato tiene de verdad, y así quitar el rótulo «[ALSA UCM error]».
#
# Uso:  sudo /ruta/a/scripts/alsa-ucm-apply.sh            aplica el parche
#       sudo /ruta/a/scripts/alsa-ucm-apply.sh --revert   restaura los originales
#       scripts/alsa-ucm-apply.sh --status                qué hay (sin root)
#
# ⚠️ CON SUDO HAY QUE DAR LA RUTA COMPLETA. Mismo motivo que en greeter-apply:
# sudo usa el `secure_path` de /etc/sudoers, que no incluye ~/.local/bin.
#
# QUÉ ARREGLA. `alsa-ucm-conf` declara para esta tarjeta PlaybackChannels=4 y
# CaptureChannels=4. El hardware expone 6 y 8 (ver /proc/asound/cardN/stream0).
# PipeWire compara ambos, avisa en el journal y cuelga la cadena
# «[ALSA UCM error]» de la descripción de la tarjeta, que sale en todas partes:
# pavucontrol, Waybar, el selector de salida. Es cosmético —los cuatro canales
# que UCM sí expone funcionan— pero es ruido permanente en la interfaz.
#
# NO SE PIERDE NINGÚN CANAL FÍSICO. Los 8 de captura son 2 entradas reales + 6
# de loopback (3 pares estéreo, que llegaron por actualización de firmware); los
# 6 de reproducción son las 4 salidas del panel trasero + un par 5/6 que no
# suena por ninguna salida. Line1/Line2/Mic1/Mic2 ya cubren todo lo que tiene
# conectores. Ver PROJECT_CONTEXT §22.
#
# ⚠️ ESTO PISA ARCHIVOS DE UN PAQUETE, y es a propósito. `alsa-lib` solo busca
# perfiles UCM en /usr/share/alsa/ucm2: no hay ruta de override en /etc ni en
# $HOME, así que no existe forma limpia de hacerlo. Consecuencia asumida:
#
#   *** CADA ACTUALIZACIÓN DE alsa-ucm-conf DEVUELVE LOS ORIGINALES ***
#   *** EN SILENCIO, Y EL RÓTULO VUELVE. HAY QUE REEJECUTAR ESTO.  ***
#
# POR QUÉ UN PARCHE LOCAL Y NO ESPERAR. El arreglo es el PR #837 de
# alsa-ucm-conf (Alan Tran-Kiem, 2026-08-24), probado por su autor en una
# Mk II con el mismo firmware que esta (bcdDevice 0116). Está ABIERTO y sin
# revisar, no entra en ninguna versión publicada. Copia en
# system/alsa/ssl2-mkii-pr837.patch.
#   https://github.com/alsa-project/alsa-ucm-conf/pull/837
#
# CUANDO EL PR ENTRE UPSTREAM, ESTE SCRIPT SOBRA: pasar --revert, borrar
# system/alsa/ y el script, y quitar la nota de §22.

set -Eeuo pipefail

DESTINO="/usr/share/alsa/ucm2/USB-Audio/SolidStateLabs"
RESPALDO="/var/lib/arch-msi/alsa-ucm-orig"
ARCHIVOS=(SSL2.conf SSL2-HiFi.conf)

# Versión contra la que se verificó el parche. El guardián de abajo compara las
# sumas, no esto; queda aquí para que se sepa de un vistazo qué se parcheó.
VERSION_ESPERADA="alsa-ucm-conf 1.2.16.1-1"

# Sumas de los archivos DE FÁBRICA y de los YA PARCHEADOS. Son el guardián: si
# lo instalado no es ninguna de las dos cosas, upstream cambió el perfil y este
# parche ya no es válido, así que el script se niega en vez de pisar a ciegas.
declare -A MD5_ORIGINAL=(
  [SSL2.conf]=c0661de17bc09ef707344d094ba66c63
  [SSL2-HiFi.conf]=6f5f2f5f089197ce0bcf0e95d888520b
)
declare -A MD5_PARCHEADO=(
  [SSL2.conf]=fbea668e25e0c5ee2521b87efd4dc825
  [SSL2-HiFi.conf]=a787b409bb86804e87d01b2090d359ad
)

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
ORIGEN="$REPO/system/alsa/ucm2/USB-Audio/SolidStateLabs"

suma() { md5sum "$1" | cut -d' ' -f1; }

# Devuelve original / parcheado / desconocido / ausente
estado_de() {
  local f="$1"
  [ -f "$DESTINO/$f" ] || { echo ausente; return; }
  local s; s="$(suma "$DESTINO/$f")"
  if   [ "$s" = "${MD5_ORIGINAL[$f]}" ];  then echo original
  elif [ "$s" = "${MD5_PARCHEADO[$f]}" ]; then echo parcheado
  else echo desconocido
  fi
}

estado() {
  echo "Perfil UCM de la SSL 2+ Mk II"
  echo "  instalado:  $(pacman -Q alsa-ucm-conf 2>/dev/null || echo '?')"
  echo "  se parcheó: $VERSION_ESPERADA"
  for f in "${ARCHIVOS[@]}"; do
    printf '  %-16s %s\n' "$f" "$(estado_de "$f")"
  done
  echo "  respaldo:   $([ -d "$RESPALDO" ] && echo "$RESPALDO" || echo '(no hay)')"
  if command -v pactl >/dev/null 2>&1; then
    local d
    d="$(pactl list cards 2>/dev/null | grep -m1 'device.description = "SSL' || true)"
    [ -n "$d" ] && echo "  tarjeta:   ${d#*= }"
  fi
}

exige_root() {
  [ "$(id -u)" -eq 0 ] || { echo "error: esto necesita root. Usa: sudo $0" >&2; exit 1; }
}

aplicar() {
  exige_root
  local pendientes=()
  for f in "${ARCHIVOS[@]}"; do
    case "$(estado_de "$f")" in
      parcheado) echo "· $f ya está parcheado, se deja como está" ;;
      original)  pendientes+=("$f") ;;
      ausente)
        echo "error: no existe $DESTINO/$f. ¿Está instalado alsa-ucm-conf?" >&2; exit 1 ;;
      desconocido)
        echo "error: $DESTINO/$f no coincide ni con el original ni con el parcheado." >&2
        echo "       Upstream cambió el perfil: este parche ya no vale. Comprueba si" >&2
        echo "       el PR #837 entró y, si es así, retira este script." >&2
        exit 1 ;;
    esac
  done
  [ ${#pendientes[@]} -eq 0 ] && { echo "Nada que hacer."; return; }

  install -d "$RESPALDO"
  for f in "${pendientes[@]}"; do
    # El respaldo solo se escribe la primera vez: si ya existe, es de fábrica y
    # sobrescribirlo con algo ya parcheado destruiría la vuelta atrás.
    [ -f "$RESPALDO/$f" ] || cp -p "$DESTINO/$f" "$RESPALDO/$f"
    install -m644 -o root -g root "$ORIGEN/$f" "$DESTINO/$f"
    echo "· $f parcheado (original en $RESPALDO/$f)"
  done
  echo
  echo "Falta recargar el audio COMO TU USUARIO, no con sudo:"
  echo "    systemctl --user restart wireplumber"
}

revertir() {
  exige_root
  local hechos=0
  for f in "${ARCHIVOS[@]}"; do
    if [ -f "$RESPALDO/$f" ]; then
      install -m644 -o root -g root "$RESPALDO/$f" "$DESTINO/$f"
      echo "· $f restaurado desde el respaldo"; hechos=1
    else
      echo "· $f sin respaldo; si hace falta: sudo pacman -S alsa-ucm-conf"
    fi
  done
  [ $hechos -eq 1 ] && { echo; echo "Recarga el audio como tu usuario:"; echo "    systemctl --user restart wireplumber"; }
}

case "${1:-}" in
  --status) estado ;;
  --revert) revertir ;;
  "")       aplicar ;;
  *)        echo "uso: $0 [--revert|--status]" >&2; exit 1 ;;
esac
