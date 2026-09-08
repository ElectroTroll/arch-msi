#!/usr/bin/env bash
#
# Instala el tema del greeter de SDDM (arch-msi), a juego con hyprlock.
#
# Uso:  sudo /ruta/a/scripts/greeter-apply.sh            instala y activa el tema
#       sudo /ruta/a/scripts/greeter-apply.sh --revert   vuelve al de fábrica
#       greeter-apply --status                           qué hay (sin root)
#
# ⚠️ CON SUDO HAY QUE DAR LA RUTA COMPLETA, no `sudo greeter-apply`. sudo no
# hereda el PATH de la sesión: usa el `secure_path` de /etc/sudoers, que trae
# /usr/bin y compañía pero NO ~/.local/bin, donde está el enlace. Por eso
# `sudo greeter-apply` responde "command not found" aunque `greeter-apply`
# funcione. Los demás scripts del repositorio no se topan con esto porque
# ninguno se ejecuta como root.
#
# ⚠️ ESTE ES EL ÚNICO COMPONENTE DEL TEMA QUE NO SE ACTUALIZA SOLO, y es a
# propósito. El resto del escritorio lo reescribe `theme-apply` sin sudo en cada
# arranque; el greeter no puede, por dos motivos que van juntos:
#
#   1. El tema tiene que vivir en /usr/share/sddm/themes/, que es de root.
#   2. El usuario `sddm` (uid 965) NO puede leer /home/elok, que es drwx------,
#      así que ni el QML ni el fondo pueden quedarse en el home.
#
# La alternativa era dejar el directorio del tema a nombre del usuario para que
# theme-apply lo reescribiera solo. Se descartó: ese QML lo ejecuta el greeter
# ANTES del login, así que hacerlo escribible sin root convierte la pantalla de
# acceso en algo que puede modificar cualquier cosa que corra como el usuario.
#
# Consecuencia asumida: al cambiar de fondo de pantalla, el greeter se queda con
# el anterior hasta que se ejecute esto. Ver PROJECT_CONTEXT §24.

set -Eeuo pipefail

TEMA="arch-msi"
DESTINO="/usr/share/sddm/themes/$TEMA"
DROPIN="/etc/sddm.conf.d/10-arch-msi.conf"

# El repositorio, resuelto desde el propio script. `readlink -f` es obligatorio:
# esto se invoca por el enlace de ~/.local/bin, no por su ruta real.
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
ORIGEN="$REPO/system/sddm/$TEMA"

# Resolución a la que se prepara el fondo. Es el panel interno, que es donde
# sale el greeter al encender. Un monitor externo mayor lo recorta
# PreserveAspectCrop, así que no hace falta generar una imagen por pantalla.
RES="2560x1600"

msg() { echo "greeter-apply: $*"; }
die() { echo "greeter-apply: $*" >&2; exit 1; }

# El artefacto lo genera matugen para el USUARIO, no para root. Con sudo, $HOME
# es el de root, así que hay que resolver el home del invocador.
home_usuario() {
    local u="${SUDO_USER:-$USER}"
    getent passwd "$u" | cut -d: -f6
}

ARTEFACTO="$(home_usuario)/.config/sddm-arch-msi/theme.conf"

case "${1:-}" in
    --status|-s)
        echo "  tema instalado : $([ -d "$DESTINO" ] && echo "sí ($DESTINO)" || echo no)"
        echo "  drop-in        : $([ -f "$DROPIN" ] && echo "sí ($DROPIN)" || echo no)"
        # ⚠️ El valor se calcula ANTES y con `|| true`, no con un `||` al final
        # del pipe. Con `pipefail` —que está activo arriba—, el `grep` sobre
        # /etc/sddm.conf, que normalmente NO existe, marca como fallido todo el
        # pipeline aunque `cut` ya haya escrito el nombre del tema: la versión
        # anterior imprimía el tema Y "(ninguno)" en dos líneas.
        activo="$(grep -h '^Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | tail -1 | cut -d= -f2- || true)"
        echo "  tema activo    : ${activo:-(ninguno: greeter de fábrica)}"
        echo "  artefacto      : $([ -f "$ARTEFACTO" ] && echo "sí ($ARTEFACTO)" || echo 'NO — ejecuta theme-apply primero')"
        exit 0
        ;;
    -h|--help)
        sed -n '2,8p' "$0"
        exit 0
        ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    # Se imprime la ruta REAL y no `sudo greeter-apply`, que falla con
    # "command not found" por el secure_path de sudo (ver la cabecera).
    echo "greeter-apply: hace falta root. Ejecuta:" >&2
    echo "    sudo $(readlink -f "$0") ${*:-}" >&2
    exit 1
fi

if [ "${1:-}" = "--revert" ]; then
    # Se quita el drop-in y SDDM vuelve solo a su greeter de fábrica. El
    # directorio del tema se deja: no estorba y evita reinstalarlo si se vuelve.
    rm -f "$DROPIN"
    msg "drop-in eliminado; SDDM vuelve al greeter de fábrica en el próximo arranque"
    msg "(el tema sigue en $DESTINO; bórralo a mano si quieres)"
    exit 0
fi

[ -f "$ARTEFACTO" ] || die "no encuentro $ARTEFACTO — ejecuta antes theme-apply (sin sudo)"
[ -d "$ORIGEN" ]    || die "no encuentro $ORIGEN"
command -v magick >/dev/null || die "falta imagemagick"

# Valores que necesita ESTE script (no el QML): la imagen original y cómo
# procesarla. Se leen del mismo artefacto para no tener dos fuentes.
leer() { grep -m1 "^$1=" "$ARTEFACTO" | cut -d= -f2-; }
WALLPAPER="$(leer wallpaperSrc)"
SIGMA="$(leer blurSigma)"
BRILLO="$(leer brightness)"

install -d -m 755 "$DESTINO"
install -m 644 "$ORIGEN/Main.qml"          "$DESTINO/Main.qml"
install -m 644 "$ORIGEN/metadata.desktop"  "$DESTINO/metadata.desktop"
install -m 644 "$ARTEFACTO"                "$DESTINO/theme.conf"

# EL FONDO SE PROCESA AQUÍ, no en el QML. La primera versión desenfocaba con
# MultiEffect y la imagen solo cubría 1600x1000 de una ventana de 2560x1600:
# MultiEffect resuelve la textura en píxeles lógicos y la pinta sin escalar por
# el devicePixelRatio. Hacerlo con ImageMagick evita el problema de raíz y de
# paso el greeter arranca sin trabajo de GPU.
#
# `-blur 0xSIGMA` es una gaussiana y NO las pasadas encadenadas de hyprlock: la
# equivalencia se calibró a ojo (ver [greeter] en theme/tokens.toml).
# `-modulate` toma el brillo en PORCENTAJE, que es como se declara allí.
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    magick "$WALLPAPER" \
        -resize "${RES}^" -gravity center -extent "$RES" \
        -blur "0x${SIGMA}" -modulate "$BRILLO" \
        "$DESTINO/background.jpg"
    chmod 644 "$DESTINO/background.jpg"
    msg "fondo procesado desde $WALLPAPER (blur ${SIGMA}, brillo ${BRILLO}%)"
else
    # Sin imagen —el tema se generó con `--seed`— el QML cae al color liso de
    # colorBg, igual que hace hyprlock.
    rm -f "$DESTINO/background.jpg"
    msg "sin fondo de pantalla: el greeter usará el color liso del tema"
fi

install -d -m 755 "$(dirname "$DROPIN")"
install -m 644 "$REPO/system/etc/sddm.conf.d/10-arch-msi.conf" "$DROPIN"

msg "tema instalado en $DESTINO"
msg "activado con $DROPIN"
# ⚠️ `sddm-greeter`, NO `sddm-greeter-qt6`. El daemon lanza el de Qt5 y el de
# Qt6 acepta cosas que aquel rechaza: recomendar el binario equivocado fue lo
# que dejó pasar un tema roto hasta el primer arranque (§24).
msg "pruébalo sin reiniciar:  sddm-greeter --test-mode --theme $DESTINO"
