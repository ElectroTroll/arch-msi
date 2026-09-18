# arch-msi

Configuración reproducible, versionada y documentada de una instalación de
**Arch Linux** sobre un portátil **MSI Summit E16 AI Studio A1VFTG** en dual boot
con Windows.

El objetivo es que este repositorio sea, gradualmente, la **fuente de verdad**
de la configuración: documentada, modular, auditable y restaurable tras una
reinstalación. La configuración se despliega con **GNU Stow** (enlaces
simbólicos), migrando un componente cada vez y verificando después de cada paso.

## Hardware objetivo

MSI Summit E16 AI Studio A1VFTG · Intel Core Ultra 7 155H · Intel Arc + NVIDIA
RTX 4060 (híbrido) · 16 GB LPDDR5 · NVMe 1 TB · Wi-Fi 7. Detalle completo en
[`docs/hardware.md`](docs/hardware.md).

## Estado del repositorio

En construcción. La documentación de base ya refleja una auditoría no
destructiva completa del sistema real (2026-07-22). La migración de dotfiles a
Stow **está en curso**: son 18 los paquetes ya migrados y validados. Ver el
estado detallado en [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).

## ⚠️ Advertencia de dual boot

El equipo comparte disco con Windows. La partición **EFI es compartida** y las
particiones de Windows/MSI (`nvme0n1p1`–`p5`) **no deben tocarse**. No formatear,
redimensionar ni reparticionar sin un plan aprobado y copia de seguridad. No
cambiar el bootloader (GRUB) ni la disposición de subvolúmenes Btrfs sin lo
mismo.

## Auditar antes de aplicar

El estado real del equipo tiene prioridad sobre cualquier documento. Antes de
aplicar cambios: inspeccionar, explicar el estado actual, proponer un plan,
mostrar el diff, validar y saber cómo revertir. Los cambios se hacen pequeños,
específicos y reversibles. Ver las reglas operativas en [`CLAUDE.md`](CLAUDE.md)
y [`AGENTS.md`](AGENTS.md).

## Componentes gestionados

| Área          | Estado                                              |
|---------------|-----------------------------------------------------|
| Documentación | `docs/` — contexto, hardware, cronología            |
| Inventarios   | `packages/` — pacman, AUR, npm, servicios           |
| Dotfiles      | `dotfiles/` — 18 paquetes Stow desplegados          |
| Scripts       | `scripts/` — mantenimiento y utilidades de sesión   |
| Sistema       | `system/` — fuera de `$HOME` (SDDM, perfil UCM)     |
| Obsidian      | `obsidian/` — 3 plugins propios, enlazados al vault |

## Restauración (alto nivel)

1. Instalar Arch base con la misma disposición Btrfs (`@`, `@home`) y GRUB.
2. Reinstalar paquetes desde `packages/`.
3. Rehabilitar servicios (ver `packages/services-enabled.txt`).
4. Clonar este repo en `~/Projects/arch-msi` y desplegar dotfiles con Stow,
   componente a componente.
5. Reinstalar herramientas de IA (Codex, Claude Code) como usuario normal.

## Estructura

```
arch-msi/
├── README.md
├── CLAUDE.md          # reglas operativas para Claude Code
├── AGENTS.md          # reglas operativas para Codex (referencia a CLAUDE.md)
├── .gitignore
├── docs/
│   ├── PROJECT_CONTEXT.md
│   ├── roadmap.md
│   ├── hardware.md
│   ├── keybindings.md
│   ├── obsidian-latex-suite.md   # abreviaturas LaTeX en Obsidian (§26)
│   └── history/       # cronología: incidentes y trampas, un archivo por episodio
├── dotfiles/          # paquetes GNU Stow, uno por componente
│   ├── bin/        claude/     dolphin/    dunst/
│   ├── hypr/       icons/      kitty/      matugen/
│   ├── minecraft/  nvim/       rofi/       shell/
│   ├── spotify/    swappy/     waybar/     wlogout/
│   ├── yazi/
│   └── wallpapers/    # -> ~/Wallpapers (imágenes de fondo, ver PROJECT_CONTEXT §17)
├── packages/
│   ├── pacman-explicit.txt
│   ├── aur.txt
│   ├── npm-global.txt
│   └── services-enabled.txt
├── system/            # lo que NO vive en $HOME: se COPIA, no se enlaza
│   ├── sddm/arch-msi/     # tema del greeter -> /usr/share/sddm/themes/
│   ├── etc/sddm.conf.d/   # drop-in que lo activa -> /etc/sddm.conf.d/
│   └── alsa/ucm2/         # perfil UCM parcheado de la SSL 2+ Mk II (§22)
├── obsidian/          # el vault NO se versiona; esto sí, y se enlaza a mano
│   └── plugins/       # propios: subrayar, subindice, superindice (§26)
├── streamdeck/        # proyecto propio, NO es paquete Stow (§30)
│   ├── firmware/      # sketches Arduino del Pro Micro
│   └── host/          # mezclador en Python + servicio de usuario
│                      # necesita ~/StreamDeckDIY -> este directorio
└── scripts/
    ├── update-inventories.sh   # regenera los 4 archivos de packages/ con cabecera
    ├── add-wallpaper.sh        # ajusta una imagen a 2560x1600 y la añade a ~/Wallpapers
    ├── theme-apply.sh          # aplica el tema con matugen a todos los componentes (§18)
    ├── vpn-autoconnect.sh      # conecta ProtonVPN al iniciar sesión (§9)
    ├── kb-layout.sh            # alterna es/us en el teclado que pulsa el atajo (§20)
    ├── audio-salida.sh         # rota la salida: altavoces → USB → Bluetooth (§22)
    ├── simbolos.sh             # selector de símbolos griegos y matemáticos (§31)
    ├── waybar-monitor.sh       # CPU/RAM/GPU y temperaturas para la barra (§23)
    ├── greeter-apply.sh        # instala el tema del greeter de SDDM (§24) — con sudo
    └── alsa-ucm-apply.sh       # parchea el perfil UCM de la SSL 2+ (§22) — con sudo
```

**Todo script ejecutable vive en `scripts/` con extensión `.sh`.** Los que
además deben poder invocarse por nombre desde la sesión (bindings de Hyprland,
autostart) NO se duplican: el paquete Stow `bin` contiene un **symlink relativo**
`dotfiles/bin/.local/bin/<nombre>` → `../../../../scripts/<nombre>.sh`, y Stow
enlaza eso en `~/.local/bin`. Relativo y no absoluto por dos razones: Stow
**rechaza los symlinks absolutos dentro de un paquete** («source is an absolute
symlink») y un enlace absoluto ataría el repo a una ruta de clonado concreta.
Hoy están así `theme-apply`, `vpn-autoconnect`, `kb-layout`, `audio-salida` y
`waybar-monitor`;
`update-inventories.sh` y `add-wallpaper.sh` se ejecutan desde el repo y no
necesitan enlace.

**`system/` es la excepción a Stow.** Guarda lo que va fuera de `$HOME` —el tema
del greeter de SDDM y el perfil UCM parcheado de la SSL 2+ Mk II— con la ruta de
destino reflejada en su estructura. No se enlaza: lo **copian** `greeter-apply`
y `alsa-ucm-apply` con sudo. Un enlace al repositorio dentro de `/usr/share`
dejaría al sistema dependiendo de que el home esté montado y de una ruta de
clonado concreta. Ver PROJECT_CONTEXT §24 y §22.

Los dotfiles se despliegan desde la raíz del repo, un paquete cada vez:

```
stow -n -v -d dotfiles -t ~ <paquete>   # simular: revisar CONFLICT antes de nada
stow    -v -d dotfiles -t ~ <paquete>   # enlazar
```

⚠️ **`wallpapers` tiene una particularidad**: despliega `~/Wallpapers` como **un
único enlace de directorio**, y eso es deliberado — es lo que hace que una imagen
dejada ahí aterrice en el repositorio. **No crear `~/Wallpapers` a mano antes de
invocar a Stow**: si el directorio ya existe, Stow enlaza archivo por archivo y
las imágenes nuevas dejan de versionarse, en silencio. Ver `PROJECT_CONTEXT` §17.

## Archivos de terceros

Dos archivos de este repositorio no son propios:

| Archivo | Origen | Licencia |
|---|---|---|
| `dotfiles/matugen/.config/matugen/templates/kvantum-theme.svg` | [HyDE](https://github.com/Hyde-project/hyde) | GPL-3.0 |
| `dotfiles/matugen/.config/matugen/templates/kvantum-theme.kvconfig` | [HyDE](https://github.com/Hyde-project/hyde) | GPL-3.0 |

Son el tema de Kvantum `wallbash`, adaptado el 2026-09-16: las formas de los
widgets son suyas y solo se han sustituido los colores por las variables de
`theme/tokens.toml`. La atribución completa está en la cabecera de cada archivo
y el porqué en `docs/PROJECT_CONTEXT.md` §34.
