#!/usr/bin/env bash
#
# Regenera los cuatro inventarios de packages/ conservando su cabecera.
# Todos los comandos usados funcionan como usuario normal (sin sudo).
#
# Uso: scripts/update-inventories.sh   (ejecutar desde la raíz del repo)
#
# Cada bloque de abajo mezcla dos tipos de línea, marcadas con comentarios:
#   [manual]    texto fijo escrito por una persona (avisos, notas de
#               contexto). No lo genera ningún comando: si el estado real
#               cambia y lo desmiente, hay que editarlo o borrarlo a mano.
#   [generado]  sale de ejecutar un comando en cada regeneración; refleja
#               siempre el estado real del sistema en el momento de correr
#               el script.

set -Eeuo pipefail

packages_dir="packages"

if [[ ! -f "CLAUDE.md" || ! -d "$packages_dir" ]]; then
  echo "error: ejecuta este script desde la raíz del repo arch-msi: ./scripts/update-inventories.sh" >&2
  exit 1
fi

for cmd in pacman npm systemctl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: falta el comando '$cmd', necesario para regenerar los inventarios" >&2
    exit 1
  fi
done

fecha="$(date +%Y-%m-%d)"
host="$(uname -n)"

# --- packages/pacman-explicit.txt ---
{
  # [manual] cabecera fija
  echo "# Paquetes instalados explícitamente (pacman -Qqe)"
  echo "# Fuente: auditoría $fecha en $host"
  echo "# Regenerar con: pacman -Qqe > packages/pacman-explicit.txt"
  echo "# AVISO: al regenerar, esta cabecera se pierde. Debe volver a añadirse a mano"
  echo "# (o usar scripts/update-inventories.sh, que la conserva)."
  echo
  # [generado] pacman -Qqe
  pacman -Qqe
} > "$packages_dir/pacman-explicit.txt"

# --- packages/aur.txt ---
{
  # [manual] cabecera fija
  echo "# Paquetes extranjeros / AUR (pacman -Qqm)"
  echo "# Fuente: auditoría $fecha en $host"
  echo "# Helper de AUR en uso: paru"
  echo "# Regenerar con: pacman -Qqm > packages/aur.txt"
  echo
  # [generado] pacman -Qqm
  pacman -Qqm
} > "$packages_dir/aur.txt"

# --- packages/npm-global.txt ---
node_v="$(node --version 2>/dev/null || echo 'node no encontrado')"
npm_v="$(npm --version)"
npm_prefix="$(npm prefix -g)"
npm_pkgs="$(npm list -g --depth=0 2>/dev/null | tail -n +2 | sed -E 's/^[├└]── //' | sed '/^$/d')"
{
  # [manual] etiquetas fijas + [generado] versiones/prefix insertados en la misma línea
  echo "# Paquetes npm globales (npm list -g --depth=0)"
  echo "# Fuente: auditoría $fecha en $host"
  echo "# node $node_v / npm $npm_v / npm prefix -g = $npm_prefix"
  echo "#"
  # [manual] nota de contexto sobre la migración del prefix; no la genera ningún comando
  echo "# NOTA: el prefix global se migró a ~/.local (sin sudo). Las instalaciones"
  echo "# globales caen en ~/.local/lib/node_modules con binarios en ~/.local/bin,"
  echo "# que ya está en PATH."
  echo "#"
  echo "# Paquetes instalados por el usuario:"
  # [generado] npm list -g --depth=0
  if [[ -n "$npm_pkgs" ]]; then
    echo "$npm_pkgs"
  else
    echo "(ninguno)"
  fi
  echo
  # [manual] nota de contexto sobre por qué no aparecen dependencias internas
  echo "# Dependencias propias de npm/node (no instaladas manualmente):"
  echo "# npm list -g solo muestra lo anterior al leer el prefix nuevo (~/.local); las"
  echo "# dependencias internas de npm/node quedan bajo el prefix del sistema (/usr)"
  echo "# y no aparecen aquí."
} > "$packages_dir/npm-global.txt"

# --- packages/services-enabled.txt ---
sistema="$(systemctl list-unit-files --state=enabled --no-legend --plain | awk '{print $1}')"
usuario="$(systemctl --user list-unit-files --state=enabled --no-legend --plain | awk '{print $1}')"
{
  # [manual] cabecera fija
  echo "# Servicios y timers habilitados"
  echo "# Fuente: auditoría $fecha en $host"
  echo "# Regenerar con:"
  echo "#   systemctl list-unit-files --state=enabled"
  echo "#   systemctl --user list-unit-files --state=enabled"
  echo
  # [generado] systemctl list-unit-files --state=enabled
  echo "## Sistema (systemctl)"
  echo "$sistema"
  echo
  # [generado] systemctl --user list-unit-files --state=enabled
  echo "## Usuario (systemctl --user)"
  echo "$usuario"
  # Si se necesita anotar algo pendiente/manual sobre estos servicios, añadir
  # aquí una sección "## Pendiente / a revisar" [manual] — revisar que siga
  # siendo cierta cada vez que el estado real cambie.
} > "$packages_dir/services-enabled.txt"

echo "Inventarios regenerados en $packages_dir:"
echo "  - pacman-explicit.txt ($(grep -vcE '^(#|$)' "$packages_dir/pacman-explicit.txt") paquetes)"
echo "  - aur.txt ($(grep -vcE '^(#|$)' "$packages_dir/aur.txt") paquetes)"
echo "  - npm-global.txt"
echo "  - services-enabled.txt"
