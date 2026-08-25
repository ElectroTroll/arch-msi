#!/usr/bin/env bash
#
# Añade un fondo de pantalla a ~/Wallpapers ajustándolo al panel de este equipo.
# Funciona como usuario normal (sin sudo).
#
# Uso: scripts/add-wallpaper.sh IMAGEN [NOMBRE_DESTINO]
#   IMAGEN          archivo de origen, de cualquier tamaño y proporción.
#   NOMBRE_DESTINO  opcional; por defecto, el nombre del origen con extensión
#                   .jpg. Se le añade .jpg si no la lleva.
#
# QUÉ HACE Y POR QUÉ (detalle completo en docs/PROJECT_CONTEXT.md §17):
#
#   - Escala a 2560x1600 recortando desde el centro, sin deformar. Es la
#     resolución NATIVA del panel: la escala 1.60 de Hyprland es del lado del
#     compositor, el búfer sigue siendo de píxeles físicos. Poner una imagen
#     más pequeña se ve borrosa.
#   - Convierte a JPEG calidad 92. Comparado el 2026-08-25 mirando la zona de
#     cielo oscuro al 300%: q92 no muestra artefactos, WebP q90 sí (bloques),
#     y PNG/WebP sin pérdida triplican el peso sin diferencia observable.
#   - Lo deja en ~/Wallpapers, que es UN ENLACE al directorio del repo, así que
#     el archivo aterriza en el repositorio y aparece en `git status`.
#
# NO es imprescindible pasar por aquí: hyprpaper recorta solo con
# `fit_mode = cover`, así que cualquier imagen funcionaría tal cual. Esto existe
# por PESO, no por compatibilidad — la carpeta está versionada en un repositorio
# público y git guarda cada binario entero y para siempre. Un original de
# 6000x3000 son ~3 MB; procesado, ~530 KB.

set -Eeuo pipefail

ancho=2560
alto=1600
calidad=92
destino_dir="$HOME/Wallpapers"

if [[ $# -lt 1 || $# -gt 2 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '3,12p' "$0" | sed 's/^# \?//'
  exit $(( $# == 0 ? 1 : 0 ))
fi

origen="$1"

if ! command -v magick >/dev/null 2>&1; then
  echo "error: falta 'magick' (paquete imagemagick)" >&2
  exit 1
fi

if [[ ! -f "$origen" ]]; then
  echo "error: no existe el archivo '$origen'" >&2
  exit 1
fi

# ~/Wallpapers debe ser el enlace que crea `stow -d dotfiles -t ~ wallpapers`.
# Si es un directorio real, las imágenes NO se versionan y el fallo es
# silencioso: el fondo funciona igual y nadie se entera hasta la siguiente
# reinstalación. Ver §17.
if [[ ! -e "$destino_dir" ]]; then
  echo "error: no existe $destino_dir. Créalo con:" >&2
  echo "         stow -d dotfiles -t ~ wallpapers" >&2
  echo "       NO lo crees a mano con mkdir: ver docs/PROJECT_CONTEXT.md §17." >&2
  exit 1
fi
if [[ ! -L "$destino_dir" ]]; then
  echo "aviso: $destino_dir NO es un enlace simbólico, sino un directorio real." >&2
  echo "       Las imágenes que añadas ahí NO se versionarán en el repo." >&2
  echo "       Ver docs/PROJECT_CONTEXT.md §17 para arreglarlo." >&2
fi

# Nombre de destino: el dado, o el del origen con extensión .jpg.
if [[ $# -eq 2 ]]; then
  nombre="$2"
else
  nombre="$(basename "${origen%.*}").jpg"
fi
[[ "$nombre" == *.jpg || "$nombre" == *.jpeg ]] || nombre="$nombre.jpg"

destino="$destino_dir/$nombre"

if [[ -e "$destino" ]]; then
  echo "error: ya existe '$destino'. Elige otro nombre o bórralo antes." >&2
  exit 1
fi

# Datos del origen, para poder avisar de un reescalado hacia arriba.
leer_dim() { magick identify -format "$1" "$origen" 2>/dev/null; }
o_ancho="$(leer_dim '%w')" || true
o_alto="$(leer_dim '%h')" || true

if [[ -z "${o_ancho:-}" || -z "${o_alto:-}" ]]; then
  echo "error: '$origen' no parece una imagen que imagemagick sepa leer" >&2
  exit 1
fi

# El recorte 'cover' escala por el lado que se queda corto. Si tras ese escalado
# alguna dimensión hay que AMPLIARLA, la imagen se verá borrosa: avisar, pero
# dejar decidir a la persona.
factor_w=$(( ancho * 1000 / o_ancho ))
factor_h=$(( alto  * 1000 / o_alto ))
factor=$(( factor_w > factor_h ? factor_w : factor_h ))
if (( factor > 1000 )); then
  echo "AVISO: '$origen' es de ${o_ancho}x${o_alto} y hay que AMPLIARLA para" >&2
  echo "       llenar ${ancho}x${alto}. Se verá borrosa. Busca una mayor." >&2
  read -r -p "¿Continuar de todos modos? [s/N] " respuesta
  [[ "$respuesta" == [sS] ]] || { echo "cancelado."; exit 1; }
fi

magick "$origen" \
  -resize "${ancho}x${alto}^" \
  -gravity center \
  -extent "${ancho}x${alto}" \
  -quality "$calidad" \
  -strip \
  "$destino"

peso="$(du -h "$destino" | cut -f1)"
echo "Añadido: $destino"
echo "  origen  : ${o_ancho}x${o_alto}"
echo "  destino : ${ancho}x${alto}  JPEG q${calidad}  $peso"
echo
repo="$(readlink -f "$destino_dir")"; repo="${repo%/dotfiles/*}"
echo "El archivo está ya dentro del repo ($repo)."
echo "Compruébalo con:  git -C $repo status --short"
echo
echo "El fondo cambia en el siguiente arranque de la sesión (timeout = 0)."
echo "Para verlo ahora:  systemctl --user restart hyprpaper.service"
