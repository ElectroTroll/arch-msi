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
#   Y desde la tarea 3.2 se calcula para TODAS las opacidades, no solo para
#   `surface`: el lenguaje .rasi de rofi no tiene la función `alpha()` de GTK
#   CSS, así que la única forma de que use las mismas transparencias que Waybar
#   es pegarles el alfa al color. `opacity_surface_hex` sigue llamándose igual,
#   así que las plantillas que ya existían no se enteran.
for _k, _v in list(flat.items()):
    if _k.startswith("opacity_") and isinstance(_v, (int, float)):
        flat[f"{_k}_hex"] = f"{round(_v * 255):02X}"

#   hyprlang (hyprlock, Hyprland) escribe los colores SIN almohadilla:
#   `rgb(58b4ef)`, no `rgb(#58b4ef)`. Se añade una versión `_stripped` de cada
#   color para poder pegarla dentro de rgb()/rgba() sin trucos en la plantilla.
for k in list(flat):
    v = flat[k]
    if isinstance(v, str) and v.startswith("#") and len(v) == 7:
        flat[f"{k}_stripped"] = v[1:]

#   GTK no expande `~` dentro de las url() de una hoja de estilos, así que las
#   plantillas necesitan la ruta absoluta del home.
import os
flat["home"] = os.path.expanduser("~")

#   GTK quiere el NOMBRE de un tema instalado, no el modo. `matugen.mode` dice
#   dark/light/smart y de ahí salen las dos claves que necesita settings.ini.
#   El tema es adw-gtk-theme (repositorio `extra`), que instala DOS temas
#   distintos, adw-gtk3 y adw-gtk3-dark: la variante oscura es un tema propio y
#   no un modificador del claro.
#   `smart` deja la decisión a cada aplicación, así que no se impone oscuro.
#   El SVG de Kvantum mide la opacidad en 0-1 y el resto del tema en
#   hexadecimal (#AARRGGBB). El token se declara UNA vez, en hexadecimal, y la
#   conversión se hace aquí en vez de repetir el número en otra unidad.
_alfa = flat.get("apps_selection_alpha")
if isinstance(_alfa, str):
    flat["selection_opacity"] = round(int(_alfa, 16) / 255, 3)

_modo = d.get("matugen", {}).get("mode", "dark")
flat["gtk_theme_name"]  = "adw-gtk3-dark" if _modo == "dark" else "adw-gtk3"
flat["gtk_prefer_dark"] = 1 if _modo == "dark" else 0

json.dump(flat, open(sys.argv[2], "w"), ensure_ascii=False)
PY

read -r TYPE CONTRAST TONE IDX MODE BLUE PINK MAGENTA FALLBACK ALTFAM ALTTONE ICONOS CURSOR SELTONE SELALPHA <<<"$(
python3 - "$TOKENS" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
m, i = d["matugen"], d["colors"]["identity"]
a = d["apps"]
print(m["type"], m["contrast"], m["accent_tone"], m["source_color_index"],
      m["mode"], i["blue"], i["pink"], i["magenta"], i["seed_fallback"],
      m["accent_alt_family"], m["accent_alt_tone"],
      a["icon_theme"], a["cursor_theme"], a["selection_tone"], a["selection_alpha"])
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
# Color de la SELECCIÓN (filas de Dolphin y demás). Sale de la misma paleta
# primaria que el acento pero de un tono más bajo, o sea más saturado: como
# bloque grande, el acento claro quedaba pálido. Ver [apps] en tokens.toml.
ACCENT_SEL="$(printf '%s' "$PAL" | jq -er ".palettes.primary.\"$SELTONE\".color")" \
    || die "no hay tono $SELTONE en la paleta primaria"
# `wallpaper` es la ruta de la imagen en uso: hyprlock la pinta desenfocada como
# fondo del bloqueo. Va vacía si el tema se generó desde una semilla, y entonces
# hyprlock cae a su color liso.
jq --arg a "$ACCENT" --arg s "${ACCENT#\#}" --arg w "${WP:-}" \
   --arg a2 "$ACCENT_ALT" --arg s2 "${ACCENT_ALT#\#}" \
   --arg sel "$ACCENT_SEL" --arg sels "${ACCENT_SEL#\#}" --arg sela "$SELALPHA" \
   '. + {accent:$a, accent_stripped:$s, wallpaper:$w, accent_alt:$a2, accent_alt_stripped:$s2, accent_sel:$sel, accent_sel_stripped:$sels, selection_alpha:$sela} + (to_entries|map(select(.value|type=="string" and startswith("#")))|map({key:(.key+"_stripped"), value:(.value[1:])})|from_entries)' \
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

# --- 5b. Iconos de wlogout ----------------------------------------------------
# Los iconos que trae el paquete son PNG de color lila (#d3bdf7), un tono que no
# sale de ninguna parte del tema. GTK3 NO sabe teñir una imagen de fondo desde
# CSS, así que la única vía es generar copias recoloreadas.
#
# Es el único punto de todo el tema que produce un BINARIO en vez de texto. Van
# a ~/.config/wlogout/icons/, que no existe en el repositorio, así que la regla
# de oro se sigue cumpliendo.
WL_ICONS="$HOME/.config/wlogout/icons"
if command -v magick >/dev/null && [ -d /usr/share/wlogout/icons ]; then
    mkdir -p "$WL_ICONS"
    for icono in lock suspend reboot shutdown logout hibernate; do
        origen="/usr/share/wlogout/icons/$icono.png"
        [ -f "$origen" ] || continue
        # -colorize 100 sustituye el color conservando el canal alfa, que es lo
        # que mantiene el icono recortado en vez de un cuadrado de color.
        magick "$origen" -fill "$ACCENT" -colorize 100 "$WL_ICONS/$icono.png" 2>/dev/null || true
    done
    echo "theme-apply: iconos de wlogout teñidos con $ACCENT"
fi

# --- 5e. Iconos teñidos con el acento -----------------------------------------
# Tela-circle (el tema de iconos de HyDE) viene en dieciséis colores FIJOS, y
# ninguno es el acento de este escritorio: el más azul, `blue`, es un índigo
# #5677fc bastante más oscuro. Como el acento sale del fondo de pantalla y
# cambia con él, ninguna variante fija iba a casar nunca.
#
# Así que se genera una: se copia la variante azul a ~/.local/share/icons y se
# sustituye su azul por el acento. Es el mismo recurso que ya se usa con los
# iconos de wlogout (5b), a otra escala.
#
# ⚠️ CUESTA MENOS DE LO QUE PARECE, y se midió antes de escribirlo: el tema son
# 110 MB aparentes pero solo 44 MB reales —16 752 de sus 27 000 entradas son
# symlinks— y el azul aparece en apenas 177 SVG. La copia y el reemplazo tardan
# 0,55 s.
#
# Aun así NO se rehace en cada arranque: se guarda el acento usado en un archivo
# marca y solo se regenera cuando cambia. Con el mismo fondo, esto no hace nada.
ICO_BASE="/usr/share/icons/Tela-circle-blue"
ICO_DST="$HOME/.local/share/icons/Tela-circle-arch-msi"
ICO_AZUL="#5677fc"
if [ -d "$ICO_BASE" ]; then
    if [ "$(cat "$ICO_DST/.acento" 2>/dev/null)" != "$ACCENT" ]; then
        rm -rf "$ICO_DST"
        mkdir -p "$(dirname "$ICO_DST")"
        # `-a` conserva los symlinks: sin él, la copia pasaría de 44 MB a 110 MB.
        cp -a "$ICO_BASE" "$ICO_DST"
        sed -i "s/^Name=.*/Name=Tela-circle-arch-msi/" "$ICO_DST/index.theme"
        grep -rl "${ICO_AZUL#\#}" "$ICO_DST" --include='*.svg' 2>/dev/null \
            | xargs -r sed -i "s/$ICO_AZUL/$ACCENT/gI"
        printf '%s' "$ACCENT" > "$ICO_DST/.acento"
        # El caché de iconos de GTK guarda el tema por nombre; tocar el
        # directorio evita que una app recién abierta siga viendo los viejos.
        touch "$ICO_DST"
        echo "theme-apply: iconos regenerados con el acento $ACCENT"
    fi
else
    echo "theme-apply: falta $ICO_BASE (¿falta tela-circle-icon-theme-all-git?)" >&2
fi

# --- 5c. Esquema de color de KDE (Dolphin) ------------------------------------
# Dolphin es KF6 y sus colores NO salen de la paleta de Qt: los pone
# KColorScheme, que lee ~/.config/kdeglobals. Por eso el tema de las apps Qt no
# se arregla eligiendo un `QT_QPA_PLATFORMTHEME` —se intentó con qt6ct el
# 2026-09-16 y salió peor, ver §33—, sino escribiendo ese esquema.
#
# ⚠️ kdeglobals NO SE PUEDE GENERAR ENTERO. Ahí escribe también Dolphin, que
# guarda [KFileDialog Settings] con el tamaño de la barra lateral y el orden de
# las columnas. Sobrescribirlo borraría esos ajustes en cada arranque. Se funden
# SOLO las secciones de color, y el resto del archivo se conserva tal cual.
#
# La conversión de hex a "R,G,B" se hace aquí y no en la plantilla: el artefacto
# se lee mejor en hex al revisarlo, y KDE escribe siempre en decimal.
KDE_SRC="$HOME/.config/kdeglobals-arch-msi.conf"
KDE_DST="$HOME/.config/kdeglobals"
if [ -f "$KDE_SRC" ]; then
    if [ -L "$KDE_DST" ]; then
        echo "theme-apply: $KDE_DST es un ENLACE de Stow, no lo toco" >&2
    else
        python3 - "$KDE_SRC" "$KDE_DST" <<'PYKDE'
import configparser, sys

def leer(ruta):
    c = configparser.ConfigParser(strict=False, interpolation=None)
    c.optionxform = str
    try:
        c.read(ruta, encoding="utf-8")
    except FileNotFoundError:
        pass
    return c

def a_rgb(v):
    # KDE escribe los colores en decimal. Acepta tres componentes (R,G,B) y
    # tambien cuatro (R,G,B,A), que es lo que hace falta para que la fila
    # seleccionada de Dolphin sea translucida: en hexadecimal ese alfa va
    # DELANTE (#AARRGGBB), como en Qt, y aqui pasa al final.
    v = v.strip()
    if not v.startswith("#"):
        return v
    if len(v) == 7:
        return "{},{},{}".format(int(v[1:3], 16), int(v[3:5], 16), int(v[5:7], 16))
    if len(v) == 9:
        return "{},{},{},{}".format(int(v[3:5], 16), int(v[5:7], 16), int(v[7:9], 16), int(v[1:3], 16))
    return v

src, dst = leer(sys.argv[1]), leer(sys.argv[2])
for sec in src.sections():
    if not dst.has_section(sec):
        dst.add_section(sec)
    for k, v in src.items(sec):
        dst.set(sec, k, a_rgb(v))

with open(sys.argv[2], "w", encoding="utf-8") as f:
    dst.write(f, space_around_delimiters=False)
PYKDE
        echo "theme-apply: esquema de color de KDE fundido en kdeglobals"
    fi
fi

# --- 5c. Modo claro/oscuro de las APLICACIONES --------------------------------
# El escritorio (Waybar, rofi, kitty, dunst, hyprlock...) ya toma el modo de
# `matugen.mode` en tokens.toml, porque lo pinta matugen. Las APLICACIONES no:
# van por un camino distinto y, sin esto, se quedaban todas en claro sobre un
# escritorio oscuro.
#
# QUIÉN LEE QUÉ. Firefox, Electron (VS Code, Obsidian, ZapZap), GTK4/libadwaita
# y Qt 6 no miran ningún archivo de tema: consultan la preferencia
# `org.freedesktop.appearance color-scheme` que publica xdg-desktop-portal-gtk,
# y ESE portal la deduce de la clave gsettings que se fija aquí. Las apps GTK3
# que no consultan el portal quedan cubiertas por los settings.ini de GTK3 y
# GTK4, que desde la tarea 3.5 los GENERA matugen desde esta misma tokens.toml
# (antes eran el paquete Stow `gtk`, retirado el 2026-09-16).
#
# POR QUÉ AQUÍ Y NO EN UN ARCHIVO DEL REPOSITORIO. La clave vive en dconf, una
# base de datos binaria: no hay archivo que enlazar con Stow. Ponerla en cada
# arranque desde el `mode` ya declarado en tokens.toml mantiene una sola fuente
# de verdad, en vez de un segundo sitio donde decir si el sistema es oscuro.
if command -v gsettings >/dev/null; then
    # ⚠️ EL NOMBRE DEL TEMA CAMBIÓ EN LA 3.5. Antes se fijaba `Adwaita-dark`, que
    # NO EXISTE como tema instalado: /usr/share/themes solo tenía Default y
    # Emacs. No estaba roto —GTK cae a su Adwaita interno y quien oscurecía era
    # `gtk-application-prefer-dark-theme`—, pero el nombre mentía y habría
    # cambiado el aspecto solo si alguien llegaba a instalar un tema con ese
    # nombre. Ahora se nombra un tema real, de `adw-gtk-theme`.
    case "$MODE" in
        dark)  ESQUEMA="prefer-dark";  GTK_TEMA="adw-gtk3-dark" ;;
        light) ESQUEMA="prefer-light"; GTK_TEMA="adw-gtk3" ;;
        # `smart` deja que decida cada app: no se impone nada.
        *)     ESQUEMA=""; GTK_TEMA="" ;;
    esac
    if [ -n "$ESQUEMA" ]; then
        # Sin `|| true` una sesión sin dconf accesible (por ejemplo un TTY
        # suelto) abortaría el script entero por el `set -e`.
        gsettings set org.gnome.desktop.interface color-scheme "$ESQUEMA" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_TEMA" 2>/dev/null || true
        # Iconos y cursor: los MISMOS valores que la plantilla escribe en los
        # settings.ini, para que no haya dos respuestas según a quién pregunte
        # cada aplicación. Salen de [apps] en tokens.toml.
        gsettings set org.gnome.desktop.interface icon-theme "$ICONOS" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR" 2>/dev/null || true
        echo "theme-apply: aplicaciones en $ESQUEMA ($GTK_TEMA · $ICONOS · cursor $CURSOR)"
    fi
    # ⚠️ LA FUENTE SÍ HAY QUE FIJARLA AQUÍ, y esto se midió en vez de suponerse.
    # Escribirla solo en los settings.ini NO FUNCIONA: con la plantilla ya
    # aplicada, `gtk-query-settings` —que enseña los valores EFECTIVOS, no el
    # archivo— seguía devolviendo "Adwaita Sans 11" mientras el archivo decía
    # "JetBrainsMono Nerd Font 10". El motivo es que en esta sesión GTK3 toma
    # esas claves de GSettings, y `font-name` ni siquiera estaba en dconf: gana
    # el DEFAULT DEL ESQUEMA de GNOME. O sea que settings.ini pierde contra un
    # valor que nadie ha elegido.
    #
    # Por eso la fuente se lee aparte y no con el `read -r` posicional de más
    # arriba: "JetBrainsMono Nerd Font" lleva ESPACIOS y aquel read la partiría
    # en trozos.
    FUENTE_UI="$(python3 - "$TOKENS" <<'PYFONT'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
print(f'{d["font"]["family"]} {d["font"]["size_base_pt"]}')
PYFONT
)"
    gsettings set org.gnome.desktop.interface font-name "$FUENTE_UI" 2>/dev/null || true
    echo "theme-apply: fuente de las aplicaciones -> $FUENTE_UI"
fi

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
