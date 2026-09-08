#!/usr/bin/env bash
#
# Datos de la dGPU y de las temperaturas para Waybar, en JSON.
# Funciona como usuario normal (sin sudo).
#
# Uso: waybar-monitor gpu     uso de la RTX 4060 (VRAM y temperatura en el tooltip)
#      waybar-monitor temps   temperaturas de CPU y GPU
#
# POR QUÉ HACE FALTA UN SCRIPT. Waybar no trae módulo de GPU, y el driver
# propietario de NVIDIA **no expone hwmon**: bajo el dispositivo PCI no hay ni
# temperatura ni un `gpu_busy_percent` como el que sí publican las Radeon. La
# única fuente de uso, VRAM y temperatura es `nvidia-smi`. CPU y RAM, en cambio,
# los cubren los módulos nativos `cpu`, `memory` y `temperature`, que no
# necesitan nada de esto.
#
# ⚠️ LO IMPORTANTE: `nvidia-smi` DESPIERTA LA TARJETA. Este equipo funciona con
# PRIME offload + Runtime D3 —invariante del proyecto, ver CLAUDE.md—, o sea que
# la RTX 4060 se suspende sola cuando nadie la usa. Un módulo que la sondeara
# cada pocos segundos la dejaría encendida de forma permanente y se comería la
# batería sin que nadie estuviera usando la gráfica.
#
# Por eso aquí se lee PRIMERO el `runtime_status` del dispositivo PCI, que es
# sysfs puro y no toca el hardware, y solo se llama a `nvidia-smi` si ya está
# `active`. Ese estado es exactamente el criterio que se quería: pasa a `active`
# tanto con el monitor externo por HDMI —que cuelga de la dGPU, §6— como en
# cuanto una aplicación la usa con `prime-run`. Con la gráfica dormida el módulo
# lo dice y no la molesta.
#
# POR QUÉ HAY CACHÉ. `gpu` y `temps` necesitan la MISMA consulta y Waybar los
# invoca por separado, así que sin caché habría dos llamadas a `nvidia-smi` por
# intervalo, descoordinadas. El archivo vive en $XDG_RUNTIME_DIR (tmpfs, se
# borra al cerrar sesión) y se escribe de forma atómica porque los dos módulos
# pueden coincidir en el tiempo.

set -Eeuo pipefail

GPU_PCI="0000:01:00.0"
RUNTIME_STATUS="/sys/bus/pci/devices/${GPU_PCI}/power/runtime_status"

# La temperatura de la CPU se resuelve por el DISPOSITIVO, no por
# /sys/class/hwmon/hwmonN: esos números se reparten por orden de registro de los
# drivers y cambian de un arranque a otro (aquí hoy es hwmon5, mañana puede no
# serlo). La ruta de la plataforma sí es estable. `temp1_input` es «Package id
# 0», la del paquete entero, que es la que interesa; los `temp2..N` son núcleos
# sueltos.
CPU_HWMON="/sys/devices/platform/coretemp.0/hwmon"

CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-monitor-gpu.csv"
CACHE_TTL=2

# Umbrales de aviso, en grados. Solo pintan la clase CSS; no hacen nada más.
CPU_AVISO=85
GPU_AVISO=80

emitir() { # texto  tooltip  clase
    jq -cn --arg t "$1" --arg tt "$2" --arg c "$3" \
        '{text:$t, tooltip:$tt, class:$c}'
}

temp_cpu() {
    local f
    for f in "$CPU_HWMON"/hwmon*/temp1_input; do
        [ -r "$f" ] || continue
        echo $(( $(cat "$f") / 1000 ))
        return 0
    done
    return 1
}

gpu_activa() {
    [ -r "$RUNTIME_STATUS" ] && [ "$(cat "$RUNTIME_STATUS")" = "active" ]
}

datos_gpu() {
    local ahora mtime salida
    ahora="$(date +%s)"
    if [ -s "$CACHE" ]; then
        mtime="$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)"
        if [ "$(( ahora - mtime ))" -lt "$CACHE_TTL" ]; then
            cat "$CACHE"
            return 0
        fi
    fi
    salida="$(nvidia-smi \
        --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name \
        --format=csv,noheader,nounits 2>/dev/null)" || return 1
    [ -n "$salida" ] || return 1
    printf '%s\n' "$salida" > "$CACHE.$$" && mv -f "$CACHE.$$" "$CACHE"
    printf '%s\n' "$salida"
}

# Deja en las variables g_* los campos del CSV. El nombre lleva espacios, así
# que se corta por comas y se recortan los bordes uno a uno.
parsear_gpu() {
    local linea="$1"
    IFS=',' read -r g_uso g_vram_usada g_vram_total g_temp g_nombre <<< "$linea"
    g_uso="$(echo "$g_uso"               | tr -d ' ')"
    g_vram_usada="$(echo "$g_vram_usada" | tr -d ' ')"
    g_vram_total="$(echo "$g_vram_total" | tr -d ' ')"
    g_temp="$(echo "$g_temp"             | tr -d ' ')"
    g_nombre="$(echo "$g_nombre"         | sed 's/^ *//; s/ *$//')"
}

case "${1:-}" in
    gpu)
        if ! gpu_activa; then
            emitir "󰤄" "dGPU suspendida (RTD3)
No se consulta para no despertarla.
Vuelve sola al conectar el monitor externo
o al lanzar algo con prime-run." "dormida"
            exit 0
        fi
        if ! linea="$(datos_gpu)"; then
            emitir "?" "La dGPU está activa pero nvidia-smi no responde." "error"
            exit 0
        fi
        parsear_gpu "$linea"
        pct_vram=$(( g_vram_usada * 100 / g_vram_total ))
        clase="normal"
        [ "$g_temp" -ge "$GPU_AVISO" ] && clase="aviso"
        emitir "${g_uso}%" "${g_nombre}
Uso ${g_uso} % · ${g_temp} °C
VRAM ${g_vram_usada} MiB / ${g_vram_total} MiB (${pct_vram} %)
RTD3: active" "$clase"
        ;;

    temps)
        if ! c_temp="$(temp_cpu)"; then
            emitir "?" "No se encuentra el sensor de la CPU en $CPU_HWMON" "error"
            exit 0
        fi
        clase="normal"
        [ "$c_temp" -ge "$CPU_AVISO" ] && clase="aviso"

        if gpu_activa && linea="$(datos_gpu)"; then
            parsear_gpu "$linea"
            [ "$g_temp" -ge "$GPU_AVISO" ] && clase="aviso"
            emitir "${c_temp}°/${g_temp}°" "CPU (paquete): ${c_temp} °C
GPU: ${g_temp} °C" "$clase"
        else
            # Guion en vez de un 0 engañoso: la GPU no está a 0 grados, es que
            # no se ha preguntado.
            emitir "${c_temp}°/–" "CPU (paquete): ${c_temp} °C
GPU: dormida (RTD3), no se consulta" "$clase"
        fi
        ;;

    -h|--help|"")
        sed -n '2,7p' "$0"
        exit 0
        ;;
    *)
        echo "waybar-monitor: subcomando desconocido «$1» (gpu | temps)" >&2
        exit 1
        ;;
esac
