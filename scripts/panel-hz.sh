#!/usr/bin/env bash
#
# Baja el panel interno a 60 Hz cuando el portátil va con batería en el perfil
# power-saver, y lo devuelve a 165 Hz en cuanto deja de cumplirse.
# Funciona como usuario normal (sin sudo).
#
# Uso: panel-hz              demonio; lo lanza hyprland.lua en hyprland.start
#      panel-hz --once       evalúa el estado una vez, aplica y sale
#      panel-hz --status     dice qué ve y qué haría, sin tocar nada
#      panel-hz --dry-run    como el demonio, pero solo informa
#
# LA REGLA, ENTERA:
#
#   AC enchufado            -> 165 Hz   (con cualquier perfil)
#   batería + power-saver   ->  60 Hz
#   batería + otro perfil   -> 165 Hz
#
# El perfil es el interruptor deliberado: en clase se pone power-saver y la
# pantalla acompaña; si hace falta fluidez, se cambia de perfil y vuelve a 165
# sin enchufar nada.
#
# POR QUÉ UN DEMONIO Y NO UNA REGLA DE UDEV. Cambiar el modo exige hablar con
# Hyprland (hyprctl), o sea estar dentro de la sesión gráfica y con su socket a
# mano. Una regla de udev corre como root y fuera de la sesión: habría que
# reinyectar el entorno del usuario a mano, y además pide tocar /etc. Aquí no
# hace falta ninguna de las dos cosas, y se sigue la convención del repo
# (ver la cabecera de vpn-autoconnect.sh): el autoarranque de la sesión vive en
# hyprland.lua, no en unidades de systemd.
#
# ⚠️ POR QUÉ `hyprctl eval` Y NO `hyprctl keyword`. La configuración es Lua, y
# con el parser no-legacy `hyprctl keyword` responde «keyword can't work with
# non-legacy parsers» (ya documentado en hyprland.lua, sección MONITORS). La vía
# buena es evaluar la misma llamada hl.monitor() que usa el archivo.
#
# ⚠️ POR QUÉ SE ESCUCHA `configreloaded`. `theme-apply` termina con un
# `hyprctl reload` (theme-apply.sh, última línea), y un reload re-aplica
# hyprland.lua entero: el panel vuelve a 165 Hz aunque estés en batería. Sin
# escuchar ese evento, cambiar el tema deshacía el ahorro en silencio.
#
# LAS TRES FUENTES DE EVENTOS, y por qué cada una:
#   1. udev (subsistema power_supply) -> enchufar/desenchufar. Se escucha al
#      KERNEL y no a UPower: es la fuente de verdad y no depende de que el
#      demonio de UPower esté vivo. `udevadm monitor --udev` funciona como
#      usuario normal (comprobado 2026-09-16).
#   2. D-Bus, net.hadess.PowerProfiles -> cambio de perfil. La señal es
#      PropertiesChanged con ActiveProfile (comprobado 2026-09-16 cambiando a
#      balanced y volviendo).
#   3. socket2 de Hyprland -> `configreloaded`, lo de arriba.
# Y por encima, un sondeo de respaldo cada SONDEO segundos: si alguna señal se
# pierde (típico al volver de suspensión), el estado se corrige solo en menos
# de un minuto. Es barato: leer un archivo de sysfs y preguntar el modo actual.

set -Eeuo pipefail

# El locale del equipo es es_ES, con COMA decimal: `printf %.0f 165.04` falla con
# «número inválido» porque espera 165,04. Los números que se manejan aquí vienen
# de hyprctl y van en formato C, así que se fija solo LC_NUMERIC (el resto del
# locale se respeta, para que las notificaciones sigan saliendo con acentos).
export LC_NUMERIC=C

# --- Configuración -----------------------------------------------------------
# La resolución, la posición y la escala son las de hyprland.lua (sección
# MONITORS): aquí solo cambia la frecuencia. Si allí cambian, cámbialas aquí.
SALIDA="eDP-1"
RESOLUCION="2560x1600"
POSICION="0x0"
ESCALA="1.6"
HZ_ALTO="165.04"     # modo nativo del AU Optronics 0xD298
HZ_BAJO="60.04"      # el único otro modo que ofrece el panel
SONDEO=60            # segundos del sondeo de respaldo

MODO=demonio
while [ $# -gt 0 ]; do
    case "$1" in
        --once)    MODO=once; shift ;;
        --status)  MODO=status; shift ;;
        --dry-run) MODO=dry; shift ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "opción desconocida: $1" >&2; exit 2 ;;
    esac
done

# --- Estado: alimentación, perfil, frecuencia actual --------------------------
# El adaptador se busca por TYPE=Mains en vez de fijar "ADP1": el nombre lo pone
# el firmware (aquí ADP1, en otros equipos AC o ACAD) y no cuesta nada no
# depender de él.
ac_enchufado() {
    local ps
    # Gancho SOLO para pruebas: permite validar la cadena entera (evento ->
    # decisión -> cambio de modo) sin tener que desenchufar el portátil, que es
    # justo lo que no se puede hacer desde una terminal.
    [ "${PANEL_HZ_SIMULA_BATERIA:-0}" = "1" ] && return 1
    for ps in /sys/class/power_supply/*; do
        [ -r "$ps/type" ] || continue
        [ "$(cat "$ps/type")" = "Mains" ] || continue
        [ "$(cat "$ps/online" 2>/dev/null || echo 0)" = "1" ] && return 0
    done
    return 1
}

perfil() { powerprofilesctl get 2>/dev/null || echo desconocido; }

# Hyprland informa 165.03999 y 60.04300; se compara en enteros para no pelearse
# con los decimales.
hz_actual() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r --arg s "$SALIDA" '.[] | select(.name==$s) | .refreshRate' \
        | awk 'NR==1 {printf "%.0f", $0}'
}

hz_deseado() {
    if ! ac_enchufado && [ "$(perfil)" = "power-saver" ]; then
        echo "$HZ_BAJO"
    else
        echo "$HZ_ALTO"
    fi
}

entero() { printf '%.0f' "$1"; }

# --- Aplicar ------------------------------------------------------------------
# Idempotente a propósito: se llama con cada evento, y las ráfagas (al enchufar
# llegan varios uevents seguidos) no deben provocar parpadeos. Si el modo ya es
# el que toca, no se toca nada.
aplicar() {
    local objetivo actual
    objetivo="$(hz_deseado)"
    actual="$(hz_actual)"

    if [ -z "$actual" ]; then
        echo "panel-hz: $SALIDA no aparece en hyprctl monitors; no hago nada"
        return 0
    fi
    [ "$actual" = "$(entero "$objetivo")" ] && return 0

    if [ "$MODO" = "dry" ] || [ "$MODO" = "status" ]; then
        echo "panel-hz: [dry-run] pasaría de ${actual}Hz a ${objetivo}Hz"
        return 0
    fi

    if hyprctl eval "hl.monitor({ output = \"$SALIDA\", mode = \"${RESOLUCION}@${objetivo}\", position = \"$POSICION\", scale = $ESCALA })" >/dev/null 2>&1; then
        echo "panel-hz: ${actual}Hz -> ${objetivo}Hz (AC: $(ac_enchufado && echo sí || echo no), perfil: $(perfil))"
        notify-send -a "Pantalla" -u low "Pantalla" \
            "Panel a ${objetivo%.*} Hz" 2>/dev/null || true
    else
        echo "panel-hz: hyprctl eval falló; el panel sigue a ${actual}Hz" >&2
    fi
}

# --- Modos de una sola pasada -------------------------------------------------
if [ "$MODO" = "status" ]; then
    echo "AC enchufado : $(ac_enchufado && echo sí || echo no)"
    echo "perfil       : $(perfil)"
    echo "$SALIDA        : $(hz_actual) Hz (actual)"
    echo "debería estar: $(entero "$(hz_deseado)") Hz"
    aplicar
    exit 0
fi

if [ "$MODO" = "once" ]; then
    aplicar
    exit 0
fi

# --- Demonio ------------------------------------------------------------------
# Una sola instancia: hyprland.lua lo lanza al iniciar sesión, y reiniciar solo
# la sesión gráfica no debe dejar dos demonios peleándose por el modo.
CERROJO="${XDG_RUNTIME_DIR:-/tmp}/panel-hz.lock"
exec 9>"$CERROJO"
if ! flock -n 9; then
    echo "panel-hz: ya hay un demonio en marcha, salgo"
    exit 0
fi

SOCK2="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# Un único canal para las tres fuentes. Se abre en lectura+escritura y se borra
# del sistema de archivos enseguida: el FIFO vive solo mientras vivan los fds.
TUBO="${XDG_RUNTIME_DIR:-/tmp}/panel-hz.fifo.$$"
mkfifo -m 600 "$TUBO"
exec 3<>"$TUBO"
rm -f "$TUBO"

udevadm monitor --udev --subsystem-match=power_supply >&3 2>/dev/null &
PID_UDEV=$!

dbus-monitor --system \
    "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/net/hadess/PowerProfiles'" \
    >&3 2>/dev/null &
PID_DBUS=$!

# El socket2 escupe TODOS los eventos de Hyprland (cada cambio de ventana, de
# workspace...). Se filtra aquí, en la fuente, para no despertar el bucle —y con
# él a hyprctl— cientos de veces por sesión.
PID_HYPR=""
if [ -S "$SOCK2" ]; then
    ( socat -u "UNIX-CONNECT:$SOCK2" - 2>/dev/null \
        | while IFS= read -r ev; do
              case "$ev" in configreloaded*) echo "configreloaded" ;; esac
          done ) >&3 &
    PID_HYPR=$!
else
    echo "panel-hz: sin socket2 de Hyprland; no vigilaré los 'hyprctl reload'" >&2
fi

# `pkill -P` remata a los nietos (socat cuelga de la subshell, no de aquí).
limpiar() {
    pkill -P "$PID_HYPR" 2>/dev/null || true
    kill "$PID_UDEV" "$PID_DBUS" ${PID_HYPR:+"$PID_HYPR"} 2>/dev/null || true
}
trap 'limpiar; exit 0' EXIT INT TERM

echo "panel-hz: en marcha (${HZ_ALTO}Hz / ${HZ_BAJO}Hz, respaldo cada ${SONDEO}s)"
aplicar

while true; do
    if IFS= read -r -t "$SONDEO" linea <&3; then
        # Un reload re-aplica hyprland.lua; se le deja terminar antes de
        # corregir el modo, o la corrección se pisa con la propia recarga.
        case "$linea" in configreloaded*) sleep 0.5 ;; esac
    else
        rc=$?
        # >128 es el timeout de `read` (el sondeo de respaldo, que es el caso
        # normal). 1 o 0 significan EOF: las tres fuentes han muerto.
        if [ "$rc" -le 128 ]; then
            echo "panel-hz: se cerraron las fuentes de eventos, salgo" >&2
            exit 1
        fi
    fi
    aplicar || true
done
