# CLAUDE.md

Reglas operativas para Claude Code en el repositorio `arch-msi`. Documento
canónico de operación (Codex sigue lo mismo vía `AGENTS.md`).

## Objetivo

Volver la configuración de un MSI Summit E16 AI Studio (Arch Linux, dual boot con
Windows) reproducible, versionada y restaurable. El repositorio es la fuente de
verdad; los dotfiles se despliegan con GNU Stow, un componente cada vez.

## Contexto

- Estado técnico detallado: `docs/PROJECT_CONTEXT.md`.
- Hardware: `docs/hardware.md`. Cronología: `docs/history/`.
- Inventarios: `packages/`.

## Reglas de seguridad (prioritarias)

- **Inspecciona antes de modificar.** El estado real del equipo tiene prioridad
  sobre cualquier documento. Si algo contradice una comprobación, informa de la
  discrepancia; **no la corrijas en silencio**.
- **No inventes el estado del sistema** ni conviertas una propuesta en un hecho.
- Distingue siempre: **confirmado / propuesta pendiente / información antigua**.
- Cambios **pequeños, específicos y reversibles**. Para cambios amplios, primero
  un plan aprobado. Muestra el **diff completo** y no toques archivos no
  relacionados.
- Ejecuta los asistentes de IA **como usuario normal, nunca con sudo**. Usa
  `sudo` solo puntualmente para consultas/operaciones que lo requieran, y
  explícalo antes.
- **No hagas commits ni push automáticos.** El usuario los aprueba.

## Prohibido sin aprobación explícita

`rm -rf`, sobrescrituras masivas, cambios de particionado, formateo,
restauraciones de Snapper, regeneración/reinstalación del bootloader, cambios de
kernel, sustitución de controladores gráficos, movimientos masivos de
`~/.config`, `stow --adopt` sin revisar conflictos, borrado de configuraciones,
commits, push y cambios remotos en GitHub.

## Invariantes a conservar

Configuración Lua de Hyprland · teclado español · natural scrolling · Dolphin y
yazi · GRUB + Btrfs + subvolúmenes (`@`, `@home`, `.snapshots` anidado) ·
PRIME offload + Runtime D3 mientras funcionen · instalación nativa de Claude Code
en `~/.local/bin` (no mover a `/usr/bin`).

## No versionar

Credenciales, tokens, historiales privados, cookies, datos de sesión, artefactos
de autenticación (Claude, Codex, VS Code, GNOME Keyring), caches, bases de datos,
sockets, logs, backups locales (cualquier `*.backup` de las configs). Ver
`.gitignore`.

## GNU Stow (migración)

Un componente cada vez: copiar al repo → revisar secretos/generados → backup del
original → mostrar diff → simular Stow (conflictos) → enlazar → validar la app →
siguiente. Nunca `stow --adopt` automático. Orden inicial: **Hyprland** (excluir
`.backup`) → **shell** (`.bashrc`, `.bash_profile`, preservando el bloque de
PATH). Kitty/Rofi/yazi/Waybar/Dunst aún no tienen config: diferidos.

## Formato de respuesta en tareas técnicas

Cuando aplique: 1) estado observado · 2) objetivo · 3) plan · 4) archivos
afectados · 5) comandos propuestos (marca los `sudo`) · 6) riesgos · 7)
validación · 8) reversión · 9) diff · 10) estado final (completado / pendiente /
no verificado). **No afirmes que algo funciona sin una validación observable.**
