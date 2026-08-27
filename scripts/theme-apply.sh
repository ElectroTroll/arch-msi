#!/usr/bin/env bash
# theme-apply.sh — regenera el tema del escritorio · arch-msi (tarea 3.0)
#
# Único punto de entrada del tema. Lee theme/tokens.toml, saca los colores del
# fondo de pantalla en uso con matugen y reescribe los artefactos de cada
# componente.
#
#   theme-apply.sh                 → desde el fondo que hyprpaper tenga puesto
#   theme-apply.sh --seed "#hex"   → desde un color fijo, ignorando el fondo
#   theme-apply.sh --dry-run       → enseña qué haría, sin escribir ni recargar
#   theme-apply.sh --fallback      → instala la paleta de reserva, sin matugen
#   theme-apply.sh --save-fallback → congela el tema actual como reserva
#
# ⚠️ REGLA DE ORO: este script NUNCA escribe sobre una ruta gestionada por Stow.
# Los enlaces de ~/.config/{waybar,dunst,hypr} apuntan DENTRO del repositorio;
# escribir sobre uno metería la salida generada en el repo o rompería el enlace.
# Las salidas van a nombres que NO existen en el repo. La prueba de que se
# cumple es que `git status` queda limpio después de ejecutar esto.

set -euo pipefail

# ⚠️ `readlink -f` NO SOBRA. Este script se invoca de dos formas: por su ruta
# (./scripts/theme-apply.sh) y POR NOMBRE (`theme-apply`), porque el paquete Stow
# `bin` lo enlaza en ~/.local/bin —que es como lo llama Hyprland al arrancar—.
# Por la segunda vía, `BASH_SOURCE` es el enlace, así que sin resolverlo el repo
# se calculaba como ~/.local y el script moría con
#     theme-apply: no encuentro /home/elok/.local/theme/tokens.toml
# Verificado el 2026-08-27, y son además DOS enlaces encadenados
# (~/.local/bin → dotfiles/bin/… → scripts/), que `readlink -f` resuelve enteros.
REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
TOKENS="$REPO/theme/tokens.toml"
STRINGS="$REPO/theme/strings.toml"
MATUGEN_CFG="$HOME/.config/matugen/config.toml"
TEMPLATES="$HOME/.config/matugen/templates"

SEED=""
DRY=0
MODO=""
while [ $# -gt 0 ]; do
    case "$1" in
        --seed) SEED="${2:-}"; shift 2 ;;
        --dry-run) DRY=1; shift ;;
        --fallback) MODO="fallback"; shift ;;
        --save-fallback) MODO="save"; shift ;;
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "opción desconocida: $1" >&2; exit 2 ;;
    esac
done

die() { echo "theme-apply: $*" >&2; exit 1; }

# --- Paleta de reserva -------------------------------------------------------
# theme/fallback/ guarda una copia congelada de los artefactos. Existe porque
# Waybar y fastfetch NO tienen config versionada: la suya se GENERA entera, así
# que un repo recién clonado —con Stow hecho pero matugen todavía sin ejecutar—
# se quedaría literalmente sin barra y sin fastfetch. Los demás componentes
# sobreviven porque conservan su config y solo pierden el fragmento de tema.
#
# El MANIFEST se genera con `--save-fallback` a partir de los `output_path` del
# config.toml de matugen, para que la reserva no se desincronice cuando se añada
# un componente nuevo.
# ⚠️ SE LLAMA FALLBACK_DIR Y NO `FALLBACK` POR UNA RAZÓN. Más abajo hay un
# `read -r … FALLBACK …` que recoge `seed_fallback` de tokens.toml, o sea un
# COLOR. Cuando esta ruta se llamaba igual, el read la pisaba y `--save-fallback`
# creaba un directorio llamado "#7aa2f7" en la raíz del repositorio. Ocurrió el
# 2026-08-27; no volver a juntar los dos nombres.
FALLBACK_DIR="$REPO/theme/fallback"

instalar_fallback() {
    [ -r "$FALLBACK_DIR/MANIFEST" ] || { echo "theme-apply: no hay paleta de reserva en $FALLBACK_DIR" >&2; return 1; }
    local origen destino n=0
    while read -r archivo rel; do
        case "$archivo" in ''|'#'*) continue ;; esac
        origen="$FALLBACK_DIR/$archivo"
        destino="$HOME/.config/$rel"
        [ -f "$origen" ] || continue
        if [ -L "$destino" ]; then
            echo "theme-apply: $destino es un ENLACE de Stow, no se toca" >&2
            continue
        fi
        mkdir -p "$(dirname "$destino")"
        cp "$origen" "$destino" && n=$((n+1))
    done < "$FALLBACK_DIR/MANIFEST"
    echo "theme-apply: instalados $n artefactos de reserva"
}

if [ "$MODO" = "fallback" ]; then
    instalar_fallback || exit 1
    exit 0
fi
command -v matugen >/dev/null || die "matugen no está instalado (pacman -S matugen)"
command -v jq >/dev/null      || die "jq no está instalado"
[ -f "$TOKENS" ]              || die "no encuentro $TOKENS"
[ -f "$MATUGEN_CFG" ]         || die "no encuentro $MATUGEN_CFG (¿falta 'stow matugen'?)"

# --- 1. Tokens ---------------------------------------------------------------
# El TOML se aplana a claves de un solo nivel (state_crit, font_family…). NO es
# cosmético: matugen interpreta lo que sigue al último punto de una variable
# como un FORMATO de color, así que una clave anidada aborta la plantilla con
# "Parse Error: The format provided is not valid".
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$TOKENS" "$TMP/tokens.json" "$STRINGS" <<'PY'
import json, sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
flat = {}

# Los TEXTOS viven aparte, en theme/strings.toml, porque cambian por motivos
# distintos que los valores: redacción o idioma, no estética. Llegan a las
# plantillas con prefijo `str_` (lock.placeholder → str_lock_placeholder).
try:
    for sec, vals in tomllib.load(open(sys.argv[3], "rb")).items():
        for k, v in vals.items():
            flat[f"str_{sec}_{k}"] = v
except FileNotFoundError:
    pass
for sec, vals in d.items():
    if sec == "matugen":
        continue
    if sec == "colors":
        for sub, cols in vals.items():
            for k, v in cols.items():
                flat[f"{sub}_{k}"] = v
    else:
        for k, v in vals.items():
            flat[f"{sec}_{k}"] = v

# Derivados: cada aplicación mide a su manera y tokens.toml declara UNA sola vez
# y en UNA sola unidad. Las conversiones se hacen aquí, no repetidas a mano en
# cada plantilla.
#
#   dunst EN WAYLAND no admite la clave `transparency`: su manual la marca como
#   "(X11 only)" y remite a poner el canal alfa en el propio color (#RRGGBBAA).
#   Se entrega el alfa como sufijo hexadecimal de dos dígitos, listo para pegar
#   detrás del color en la plantilla.
flat["opacity_surface_hex"] = f"{round(flat['opacity_surface'] * 255):02X}"

#   hyprlang (hyprlock, Hyprland) escribe los colores SIN almohadilla:
#   `rgb(58b4ef)`, no `rgb(#58b4ef)`. Se añade una versión `_stripped` de cada
#   color para poder pegarla dentro de rgb()/rgba() sin trucos en la plantilla.
for k in list(flat):
    v = flat[k]
    if isinstance(v, str) and v.startswith("#") and len(v) == 7:
        flat[f"{k}_stripped"] = v[1:]

json.dump(flat, open(sys.argv[2], "w"), ensure_ascii=False)
PY

read -r TYPE CONTRAST TONE IDX MODE BLUE PINK MAGENTA FALLBACK ALTFAM ALTTONE <<<"$(
python3 - "$TOKENS" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
m, i = d["matugen"], d["colors"]["identity"]
print(m["type"], m["contrast"], m["accent_tone"], m["source_color_index"],
      m["mode"], i["blue"], i["pink"], i["magenta"], i["seed_fallback"],
      m["accent_alt_family"], m["accent_alt_tone"])
PY
)"

# --- 2. Origen del color -----------------------------------------------------
# hyprpaper elige una imagen AL AZAR en cada arranque, así que hay que
# preguntarle cuál puso: `listactive` la devuelve. (`listloaded` no existe en
# 0.8.4: responde "invalid hyprpaper request".)
if [ -n "$SEED" ]; then
    SRC=(color hex "$SEED")
    echo "theme-apply: semilla fija $SEED"
else
    WP=""
    for _ in $(seq 1 20); do
        WP="$(hyprctl hyprpaper listactive 2>/dev/null | head -1 | sed 's/^[^:]*: //')"
        [ -n "$WP" ] && [ -f "$WP" ] && break
        WP=""; sleep 0.25
    done
    if [ -z "$WP" ]; then
        echo "theme-apply: hyprpaper no responde; uso la semilla de reserva $FALLBACK" >&2
        SRC=(color hex "$FALLBACK")
    else
        SRC=(image "$WP")
        echo "theme-apply: fondo $WP"
    fi
fi

COMMON=(-t "$TYPE" --contrast "$CONTRAST" --source-color-index "$IDX" -m "$MODE"
        --fallback-color "$FALLBACK")
# `--source-color-index` es OBLIGATORIO: sin él matugen abre un prompt
# interactivo cuando la imagen ofrece varios candidatos, y en el arranque eso
# deja el script colgado sin que nadie lo vea.

# --- 3. Pasada 1: resolver acento e identidades ------------------------------
# Dos cosas que la plantilla NO puede hacer por sí sola:
#   · `palettes.*` no está disponible en las plantillas (solo `colors.*`), y el
#     acento sale de un TONO de paleta, no de un rol.
#   · los filtros (`harmonize`) solo aceptan literales, no variables importadas.
# Por eso se resuelven aquí y se pasan ya hechos como render data.
cat > "$TMP/harmonize.tmpl" <<TPL
{"ident_blue":"{{ "$BLUE" | to_color | harmonize: {{ colors.source_color.default.hex | to_color }} }}","ident_pink":"{{ "$PINK" | to_color | harmonize: {{ colors.source_color.default.hex | to_color }} }}","ident_magenta":"{{ "$MAGENTA" | to_color | harmonize: {{ colors.source_color.default.hex | to_color }} }}"}
TPL
cat > "$TMP/pass1.toml" <<CFG
[config]
[templates.h]
input_path  = "$TMP/harmonize.tmpl"
output_path = "$TMP/resolved.json"
CFG

# Si matugen falla y encima NO hay artefactos (repo recién restaurado), se
# instala la reserva antes de rendirse: vale más un escritorio con la paleta de
# ayer que uno sin barra.
if ! PAL="$(matugen "${SRC[@]}" -c "$TMP/pass1.toml" "${COMMON[@]}" -j hex 2>/dev/null)"; then
    if [ ! -f "$HOME/.config/waybar/style.css" ]; then
        echo "theme-apply: matugen falló y no hay tema instalado; uso la reserva" >&2
        instalar_fallback || true
    fi
    die "matugen falló al resolver la paleta"
fi
ACCENT="$(printf '%s' "$PAL" | jq -er ".palettes.primary.\"$TONE\".color")" \
    || die "no hay tono $TONE en la paleta"
# Segundo color del degradado del borde activo de Hyprland. Sale TAMBIÉN de la
# paleta del fondo (familia y tono en tokens.toml), no de un color de identidad:
# el marco de la ventana enfocada tiene que venir del wallpaper entero.
ACCENT_ALT="$(printf '%s' "$PAL" | jq -er ".palettes.\"$ALTFAM\".\"$ALTTONE\".color")" \
    || die "no hay $ALTFAM tono $ALTTONE en la paleta"
# `wallpaper` es la ruta de la imagen en uso: hyprlock la pinta desenfocada como
# fondo del bloqueo. Va vacía si el tema se generó desde una semilla, y entonces
# hyprlock cae a su color liso.
jq --arg a "$ACCENT" --arg s "${ACCENT#\#}" --arg w "${WP:-}" \
   --arg a2 "$ACCENT_ALT" --arg s2 "${ACCENT_ALT#\#}" \
   '. + {accent:$a, accent_stripped:$s, wallpaper:$w, accent_alt:$a2, accent_alt_stripped:$s2} + (to_entries|map(select(.value|type=="string" and startswith("#")))|map({key:(.key+"_stripped"), value:(.value[1:])})|from_entries)' \
   "$TMP/resolved.json" > "$TMP/render.json"

# --- 4. Contraste ------------------------------------------------------------
# Si la paleta sale ilegible se conserva la anterior. Vale más un tema viejo que
# una barra que no se lee.
BG="$(printf '%s' "$PAL" | jq -r '.colors.surface.dark.color')"
FG="$(printf '%s' "$PAL" | jq -r '.colors.on_surface.dark.color')"
# El umbral lo comprueba el propio python (sale con código 1 si no llega), para
# no depender de `bc`, que no está instalado en este equipo.
if ! RATIO="$(python3 - "$FG" "$BG" <<'PY'
import sys
def lum(h):
    h = h.lstrip('#'); c = [int(h[i:i+2], 16)/255 for i in (0, 2, 4)]
    c = [x/12.92 if x <= .03928 else ((x+.055)/1.055)**2.4 for x in c]
    return .2126*c[0] + .7152*c[1] + .0722*c[2]
a, b = lum(sys.argv[1]), lum(sys.argv[2])
r = (max(a, b)+.05)/(min(a, b)+.05)
print(round(r, 2))
sys.exit(0 if r >= 4.5 else 1)
PY
)"; then
    notify-send -u critical "Tema no aplicado" \
        "Contraste insuficiente (${RATIO}:1). Se conserva la paleta anterior." 2>/dev/null || true
    die "contraste texto/fondo ${RATIO}:1 < 4.5:1; no se aplica"
fi
echo "theme-apply: acento $ACCENT · contraste ${RATIO}:1"

# --- 5. Pasada 2: render atómico ---------------------------------------------
# `--prefix` manda toda la salida a un temporal. Solo si TODO sale bien se
# mueven los archivos a su sitio: así un fallo a mitad no deja el escritorio a
# medio pintar.
if [ "$DRY" = "1" ]; then
    echo "theme-apply: --dry-run, no se escribe nada"
    matugen "${SRC[@]}" -c "$MATUGEN_CFG" "${COMMON[@]}" \
        --import-json "$TMP/tokens.json" --import-json "$TMP/render.json" --dry-run
    exit 0
fi

matugen "${SRC[@]}" -c "$MATUGEN_CFG" "${COMMON[@]}" \
    --import-json "$TMP/tokens.json" --import-json "$TMP/render.json" \
    --prefix "$TMP/out" >/dev/null 2>&1 || die "matugen falló al renderizar; no se toca nada"

mapfile -t OUTPUTS < <(grep -oP '^output_path\s*=\s*"\K[^"]+' "$MATUGEN_CFG")
for o in "${OUTPUTS[@]}"; do
    dest="${o/#\~/$HOME}"
    src="$TMP/out${dest}"
    [ -f "$src" ] || die "matugen no generó $dest; no se aplica nada"
    if [ -L "$dest" ]; then
        die "$dest es un ENLACE de Stow: abortado para no escribir en el repo"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "theme-apply: escrito $dest"
done

# --- 6. Recargas -------------------------------------------------------------
# Cada aplicación necesita un trato distinto.
#
# ⚠️ Waybar por `systemctl restart`, NO por SIGUSR2. La señal hace que Waybar se
# RE-EJECUTE, systemd lo cuenta como muerte del proceso principal, salta
# Restart=on-failure y a la tercera recarga se agota StartLimitBurst: la unidad
# queda en `failed` y te quedas sin barra. Verificado el 2026-08-27.
if systemctl --user is-active --quiet waybar.service; then
    systemctl --user restart waybar.service && echo "theme-apply: waybar reiniciado"
fi
# dunst relee sin reiniciar; el historial vive en memoria y así no se pierde.
command -v dunstctl >/dev/null && dunstctl reload 2>/dev/null && echo "theme-apply: dunst recargado"
# Hyprland relee su config; hyprlock la lee al lanzarse, así que no necesita nada.
command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 && echo "theme-apply: hyprland recargado"

if [ "$MODO" = "save" ]; then
    # Congela los artefactos recién generados como paleta de reserva. Los
    # destinos salen del config.toml de matugen, no de una lista escrita a mano,
    # para que no se olvide ninguno al añadir un componente.
    mkdir -p "$FALLBACK_DIR"
    : > "$FALLBACK_DIR/MANIFEST.tmp"
    printf '%s\n' "# Generado por theme-apply.sh --save-fallback. NO editar a mano." \
                   "# <archivo en esta carpeta>  <ruta relativa a ~/.config>" >> "$FALLBACK_DIR/MANIFEST.tmp"
    for o in "${OUTPUTS[@]}"; do
        dest="${o/#\~/$HOME}"
        rel="${dest#"$HOME"/.config/}"
        plano="${rel//\//__}"
        if [ -f "$dest" ]; then
            cp "$dest" "$FALLBACK_DIR/$plano"
            printf '%s  %s\n' "$plano" "$rel" >> "$FALLBACK_DIR/MANIFEST.tmp"
        fi
    done
    mv "$FALLBACK_DIR/MANIFEST.tmp" "$FALLBACK_DIR/MANIFEST"
    echo "theme-apply: paleta de reserva actualizada en theme/fallback/"
fi

echo "theme-apply: listo"
