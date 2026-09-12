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
Stow **está en curso**: son 15 los paquetes ya migrados y validados. Ver el
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
| Dotfiles      | `dotfiles/` — 15 paquetes Stow desplegados          |
| Scripts       | `scripts/` — mantenimiento y utilidades de sesión   |
| Sistema       | `system/` — lo que va fuera de `$HOME` (SDDM)       |
| Obsidian      | `obsidian/` — plugin propio, enlazado al vault      |

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
│   └── history/       # cronología: incidentes y trampas, un archivo por episodio
├── dotfiles/          # paquetes GNU Stow, uno por componente
│   ├── bin/        claude/     dunst/      hypr/
│   ├── icons/      kitty/      matugen/    minecraft/
│   ├── rofi/       shell/      swappy/     waybar/
│   ├── wlogout/    yazi/
│   └── wallpapers/    # -> ~/Wallpapers (imágenes de fondo, ver PROJECT_CONTEXT §17)
├── packages/
│   ├── pacman-explicit.txt
│   ├── aur.txt
│   ├── npm-global.txt
│   └── services-enabled.txt
├── system/            # lo que NO vive en $HOME: se COPIA, no se enlaza
│   ├── sddm/arch-msi/     # tema del greeter -> /usr/share/sddm/themes/
│   └── etc/sddm.conf.d/   # drop-in que lo activa -> /etc/sddm.conf.d/
├── obsidian/          # el vault NO se versiona; esto sí, y se enlaza a mano
│   └── plugins/subrayar/  # plugin propio: Ctrl+U subraya con <u> (§26)
└── scripts/
    ├── update-inventories.sh   # regenera los 4 archivos de packages/ con cabecera
    ├── add-wallpaper.sh        # ajusta una imagen a 2560x1600 y la añade a ~/Wallpapers
    ├── theme-apply.sh          # aplica el tema con matugen a todos los componentes (§18)
    ├── vpn-autoconnect.sh      # conecta ProtonVPN al iniciar sesión (§9)
    ├── kb-layout.sh            # alterna es/us en el teclado que pulsa el atajo (§20)
    ├── audio-salida.sh         # alterna la salida de audio interfaz <-> altavoces (§22)
    ├── waybar-monitor.sh       # CPU/RAM/GPU y temperaturas para la barra (§23)
    └── greeter-apply.sh        # instala el tema del greeter de SDDM (§24) — con sudo
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

**`system/` es la excepción a Stow.** Guarda lo que va fuera de `$HOME` —hoy, el
tema del greeter de SDDM— con la ruta de destino reflejada en su estructura. No
se enlaza: lo **copia** `greeter-apply` con sudo. Un enlace al repositorio
dentro de `/usr/share` dejaría al sistema dependiendo de que el home esté
montado y de una ruta de clonado concreta. Ver PROJECT_CONTEXT §24.

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
