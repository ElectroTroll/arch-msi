#!/usr/bin/env bash
#
# Conecta ProtonVPN al servidor más rápido nada más iniciar sesión.
# Funciona como usuario normal (sin sudo).
#
# Uso: vpn-autoconnect            (lo lanza hyprland.lua en hyprland.start)
#      vpn-autoconnect --now      salta la espera de red y conecta ya
#      vpn-autoconnect --dry-run  dice qué haría, sin conectar
#
# POR QUÉ ESTE SCRIPT Y NO UNA UNIDAD DE SYSTEMD. El repo no versiona ninguna
# unidad, y el autoarranque de la sesión gráfica ya vive en `hyprland.lua`
# (§17: hyprpaper y theme-apply se movieron ahí). Se sigue esa convención en vez
# de abrir una vía nueva. Además aquí no hace falta lo que systemd aportaría
# —orden y reintentos—: la espera de red la hace este script explícitamente, y
# así se puede razonar sobre ella leyendo un solo archivo.
#
# ⚠️ EL PORTAL CAUTIVO ES LA RAZÓN DE LA MITAD DE ESTE CÓDIGO.
# Conectar el VPN a ciegas al iniciar sesión rompe cualquier red con portal
# (residencias, hoteles, aeropuertos): el túnel no puede establecerse porque
# todavía no hay salida a internet, y de paso el portal se vuelve inalcanzable.
# Por eso NO se conecta a ciegas: se espera a que NetworkManager declare
# conectividad `full`. NM trae la comprobación activada de serie
# (/usr/lib/NetworkManager/conf.d/20-connectivity.conf, contra
# ping.archlinux.org) y distingue estos estados:
#
#   full     hay internet de verdad          -> conectamos
#   portal   hay un portal cautivo esperando -> NO conectamos, avisamos
#   limited  red sin salida                  -> seguimos esperando
#   none     sin red                         -> seguimos esperando
#
# Con `portal` el script se aparta y manda una notificación: primero pasas el
# login del portal, y luego conectas tú con `protonvpn connect`.

set -Eeuo pipefail

ESPERA_MAX=90        # segundos que se espera a tener conectividad
INTERVALO=3          # segundos entre sondeos
APP=""               # se rellena si detectamos el GUI abierto

NOW=0; DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --now) NOW=1; shift ;;
        --dry-run) DRY=1; shift ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) echo "opción desconocida: $1" >&2; exit 2 ;;
    esac
done

avisar() {
    # -a agrupa las notificaciones bajo una misma app en dunst (§16).
    notify-send -a "ProtonVPN" -u "${2:-low}" "ProtonVPN" "$1" 2>/dev/null || true
    echo "vpn-autoconnect: $1"
}

# --- 1. No pelearse con el GUI -----------------------------------------------
# La CLI y el GUI son MUTUAMENTE EXCLUYENTES: la CLI se niega a arrancar si
# detecta la app de escritorio en el bus de sesión. Si el GUI está abierto, él
# se encarga de conectar y aquí no hay nada que hacer.
if busctl --user list 2>/dev/null | grep -q 'proton.vpn.app'; then
    echo "vpn-autoconnect: el GUI está abierto, no hago nada"
    exit 0
fi

# --- 2. ¿Ya conectado? --------------------------------------------------------
# Tras un `hyprctl reload` o al reiniciar solo la sesión gráfica, el túnel puede
# seguir en pie. Reconectar por encima sería un corte gratuito.
if ip link show proton0 >/dev/null 2>&1; then
    echo "vpn-autoconnect: proton0 ya existe, no hago nada"
    exit 0
fi

# --- 3. Esperar a tener internet DE VERDAD ------------------------------------
if [ "$NOW" -eq 0 ]; then
    transcurrido=0
    while [ "$transcurrido" -lt "$ESPERA_MAX" ]; do
        estado="$(nmcli -t networking connectivity 2>/dev/null || echo unknown)"
        case "$estado" in
            full)
                break
                ;;
            portal)
                avisar "Portal cautivo detectado. Pasa el login del navegador y luego conecta con: protonvpn connect" normal
                exit 0
                ;;
        esac
        sleep "$INTERVALO"
        transcurrido=$(( transcurrido + INTERVALO ))
    done

    if [ "$estado" != "full" ]; then
        avisar "Sin conectividad tras ${ESPERA_MAX}s (estado: $estado). No se conecta el VPN." normal
        exit 0
    fi
fi

# --- 4. Conectar --------------------------------------------------------------
if [ "$DRY" -eq 1 ]; then
    echo "vpn-autoconnect: --dry-run, aquí ejecutaría 'protonvpn connect'"
    exit 0
fi

# Sin argumentos = servidor más rápido a nivel global (ver `protonvpn connect --help`).
if salida="$(protonvpn connect 2>&1)"; then
    servidor="$(protonvpn status 2>/dev/null | awk -F': ' '/^Server:/ {print $2; exit}')"
    avisar "Conectado a ${servidor:-servidor desconocido}"
else
    # El fallo típico si el llavero no está desbloqueado o la sesión caducó.
    avisar "No se pudo conectar: ${salida##*$'\n'}" critical
    exit 1
fi
