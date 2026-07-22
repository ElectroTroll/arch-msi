# PROJECT_CONTEXT

Estado técnico vigente del sistema `arch-msi`. Fuente de verdad detallada.
Última actualización: 2026-07-22, tras auditoría no destructiva completa.

Convención de estado: **[OK]** verificado en la máquina · **[PEND]** pendiente ·
**[VER]** afirmado pero sin verificar.

---

## 1. Resumen

Instalación de Arch Linux limpia en dual boot con Windows sobre un MSI Summit
E16 AI Studio A1VFTG. Raíz Btrfs con snapshots (Snapper + grub-btrfs + snap-pac),
GRUB como bootloader, gráficos híbridos Intel Arc + NVIDIA RTX 4060 con
`nvidia-open-dkms` y PRIME offload, y escritorio Wayland Hyprland (config Lua)
lanzado por SDDM vía uwsm. El objetivo del repositorio es volver esta
configuración reproducible, versionada y restaurable (ver `../README.md`).

Ver hardware completo en [`hardware.md`](hardware.md) y la cronología en
[`history/chatgpt-arch-installation.md`](history/chatgpt-arch-installation.md).

## 2. Almacenamiento y Btrfs  **[OK]**

- Partición Linux: `/dev/nvme0n1p6`, UUID `27a7d1f2-…-95611f71b5aa`.
- Opciones de montaje: `rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`.
- Subvolúmenes:
  - `@` (ID 256) → `/`
  - `@home` (ID 257) → `/home`
  - `.snapshots` (ID 261, **anidado dentro de `@`**) → `/.snapshots`
  - `var/lib/portables` (259), `var/lib/machines` (260) — creados por systemd.
- `fstab` monta solo `@`, `@home` y la ESP. `/.snapshots` no necesita entrada
  propia por estar anidado dentro de `@`.

> **Corrección histórica:** no existe un subvolumen `@snapshots` de nivel
> superior (como se creía). Snapper usa el layout estándar con `.snapshots`
> anidado. Los snapshots funcionan correctamente.

### Snapshots

- Snapper config `root` activa, con 64+ snapshots (`snap-pac` genera pre/post
  en cada operación de pacman; `snapper-timeline.timer` genera los horarios).
- `grub-btrfsd` vigila `/.snapshots` y regenera el menú de GRUB. **[OK]**
- **[PEND]** `snapper-cleanup.timer` NO está habilitado → los snapshots no se
  purgan automáticamente. Tarea futura: habilitarlo.

## 3. Bootloader  **[OK]**

- **GRUB** (elegido sobre systemd-boot: la ESP es pequeña y compartida con
  Windows; GRUB mantiene kernels/initramfs en la raíz Btrfs y deja poca huella
  en la ESP).
- `os-prober` para detectar Windows · `grub-btrfs` para arrancar snapshots.
- ESP FAT32 en `/dev/nvme0n1p1` → `/boot/efi` (~300 MB, ~12 % usada).

## 4. Kernel y arranque  **[OK]**

- Arrancando `linux-lts` (6.18.39-1-lts). También instalado `linux` (mainline).
- `intel-ucode` presente. DKMS reconstruye `nvidia-open` para ambos kernels.

## 5. Memoria y swap  **[OK]**

- 16 GB LPDDR5 (soldada).
- **zram**: `/dev/zram0`, zstd, ~7,6 GB, swap prioridad 100 (`zram-generator`).
- Sin swap en disco → **sin hibernación**.

## 6. Gráficos y energía

- `nvidia-open-dkms` 610.43.03 · `nvidia-utils` / `nvidia-settings` /
  `nvidia-prime` · `mesa` 26.1.5 · loader Vulkan 1.4. **[OK]**
- Híbrido PRIME offload: Intel Arc (`i915`) como GPU primaria; NVIDIA bajo
  demanda (`prime-run`). Sin variables de entorno NVIDIA/GBM/LIBVA/WLR forzadas
  (setup limpio). **[OK]**
- Runtime D3 **fine-grained habilitado**. **[OK]**
- `power-profiles-daemon` activo (`intel_pstate`; driver de plataforma
  `placeholder`). Sin `tlp` → sin conflicto. **[OK]**

> **[PEND] Observación de energía:** en la auditoría la dGPU estaba en P3
> (~10 W) con XWayland (`/usr/lib/Xorg`) enganchado, es decir **no suspendida**.
> Choca con el objetivo de "dGPU dormida bajo demanda". Investigar en fase
> futura (no urgente); posible causa: XWayland atado a la NVIDIA.

## 7. Entorno gráfico

- Sesión Wayland: **SDDM → uwsm → Hyprland**. **[OK]**
  (`XDG_SESSION_TYPE=wayland`, `DESKTOP_SESSION=hyprland-uwsm`).
- **Hyprland 0.56**, configuración **Lua**: `~/.config/hypr/hyprland.lua`
  (Hyprland ≥0.55 usa Lua; hyprlang/`.conf` está deprecado). Existe también
  `hyprland.lua.backup` (**no versionar**). **[OK]**
- Teclado **español** · **natural scrolling** activado. **[OK]**
- Corrección aplicada en vivo: `SUPER + R` ejecuta `rofi -show drun`
  directamente (antes fallaba por una variable `menu` sin resolver). **[OK]**
- Ecosistema instalado: `hypridle`, `hyprlock`, `hyprpaper`, `waybar`,
  `dunst`, `rofi`, `kitty`, `yazi`, `dolphin`, `firefox` (Wayland),
  `xdg-desktop-portal-hyprland`. **[OK]**

> **Realidad de configuración:** solo Hyprland tiene config propia. Las carpetas
> de `kitty`, `rofi`, `yazi`, `waybar` y `dunst` están **vacías o inexistentes**
> (usan defaults). Ver §12.

## 8. Audio, Bluetooth y sesión  **[OK]**

- PipeWire + `pipewire-pulse` + `wireplumber` (activados por socket).
- Bluetooth (`bluez`) habilitado + `blueman`.
- GNOME Keyring (`gnome-keyring` + `libsecret` + `seahorse`) — resolvió el aviso
  de keyring de VS Code.
- NetworkManager para la red.
- **[PEND] Menores:** `rtkit` ausente (PipeWire sin prioridad RT) y `upower`
  ausente (WirePlumber no obtiene estado de batería). Opcional a futuro.

## 9. Herramientas de IA  **[OK]**

- **OpenAI Codex CLI 0.144.6** · `/usr/bin/codex` →
  `/usr/lib/node_modules/@openai/codex`. Instalado como global npm.
  `node` v26.4.0 / `npm` 12.0.1.
  **[PEND] Deuda técnica:** `npm prefix -g = /usr` (territorio de pacman;
  las globales requieren sudo). Considerar prefix de usuario.
- **Anthropic Claude Code 2.1.217** (instalador nativo) ·
  `~/.local/bin/claude` → `~/.local/share/claude/versions/2.1.217`.
  PATH corregido con bloque idempotente en `~/.bash_profile` (verificado
  `bash -n` OK). **No mover a `/usr/bin`.**
- **Claude Desktop** (AUR `claude-desktop`) también instalado.
- Ambos asistentes se ejecutan **como usuario normal, nunca con sudo**.

## 10. VS Code  **[OK]**

- `visual-studio-code-bin` 1.129.1 (AUR, no Code OSS) · `/usr/bin/code`.
- Keyring funcionando vía `libsecret` / `secret-tool`.

## 11. Capturas de pantalla

- `grim` + `slurp` + `wl-clipboard` + `swappy` instalados. **[OK]**
- `grim -g "$(slurp)" - | wl-copy` funciona.
- **[PEND]** No hay atajos de Hyprland para `Print` (comprobado, vacío).
  Diseño de atajos sin aplicar.

## 12. Dotfiles y estado del repositorio  **[PEND]**

- **[PEND]** `~/Projects/arch-msi` y `git init`: aún no creados.
- `stow` 2.4.1 instalado; migración **no iniciada**.
- Superficie real a versionar hoy:
  - `hypr/` → `hyprland.lua` (excluyendo `.backup`).
  - `shell/` → `.bashrc` y `.bash_profile` (10 líneas cada uno; preservar el
    bloque de PATH).
- Sin config todavía: `kitty`, `rofi`, `yazi`, `waybar`, `dunst`. Se difieren
  hasta que existan (o se cree una config mínima como tarea propia).

## 13. Tareas pendientes (fases futuras)

1. Crear repo `~/Projects/arch-msi` + `git init` y colocar esta documentación.
2. Migrar Hyprland a Stow (excluyendo `.backup`), validar recarga.
3. Migrar shell a Stow preservando el bloque de PATH.
4. Habilitar `snapper-cleanup.timer`.
5. Investigar suspensión de la dGPU (XWayland / RTD3).
6. Decidir estrategia de prefix de npm.
7. (Opcional) `rtkit`, `upower`.
8. Definir y aplicar atajos de captura de pantalla y el mapa de teclas.
9. Verificar panel: QHD+ / 165 Hz / táctil.

## 14. Información sin verificar

- Resolución/refresco/táctil del panel (según documentación, no auditado).
- Estado de autenticación de Claude Code (no comprobado; no exponer credenciales).
