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
- **[OK]** `snapper-cleanup.timer` habilitado y activo (verificado con
  `systemctl is-enabled` / `is-active` → `enabled` / `active`). Política real
  de la config `root`: `NUMBER_LIMIT=50` (`NUMBER_LIMIT_IMPORTANT=10`),
  timeline con 10 horarios / 10 diarios / 10 mensuales / 10 anuales (semanal y
  trimestral en 0), y `MIN_AGE=3600` (`NUMBER_MIN_AGE` y `TIMELINE_MIN_AGE`).
- El snapshot **#2** ("Sistema base limpio") no tiene algoritmo de limpieza
  asignado (columna "Limpieza" vacía en `snapper -c root list`), por lo que
  queda **protegido de forma permanente** frente a la purga automática.
  Metadatos de usuario: `motivo=punto-base-instalacion`, `proteger=si`.

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

> **[OK] Runtime PM verificado (2026-07-22, solo sysfs, sin `nvidia-smi`):**
> `runtime_status = suspended`, `control = auto` en ambas funciones PCI
> (`0000:01:00.0` y `0000:01:00.1`); `power_state = D3cold`.
> `runtime_suspended_time` avanza 1:1 con el reloj (≈43 min acumulados en la
> comprobación de referencia; reconfirmado en esta revisión con ~48 min
> suspendida sobre 49 min de uptime). `Video Memory: Off` — el RTD3
> fine-grained apaga también la VRAM (`/proc/driver/nvidia/gpus/.../power`).
> Que Xorg/XWayland, Hyprland y `claude-desktop` tengan descriptores abiertos
> en `/dev/nvidia*` (confirmado con `lsof`: Hyprland y `claude-desktop`
> mantienen `/dev/nvidiactl`/`/dev/nvidia0` abiertos con la GPU ya suspendida;
> Xwayland solo tiene libs NVIDIA mapeadas en memoria) **no impide la
> suspensión**. Funciona sin parámetros de kernel ni configuración en
> `/etc/modprobe.d/` (ninguna presente): con `nvidia-open` 610+ el RTD3 va
> habilitado por defecto. Solo está la regla udev `60-nvidia.rules` de
> `nvidia-utils` (creación de nodos de dispositivo, no relacionada con RTD3).
> `nvidia-persistenced` está **deshabilitado e inactivo** y debe seguir así
> (activarlo impediría la suspensión).
>
> **Importante para futuras comprobaciones:** no usar `nvidia-smi`, porque
> despierta la GPU y falsea la lectura. Usar sysfs
> (`/sys/bus/pci/devices/0000:01:00.*/power/`) y
> `/proc/driver/nvidia/gpus/*/power`.

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
- **[OK]** `rtkit` y `upower` instalados. Ambos se activan por D-Bus bajo
  demanda; quedan `disabled` en systemd (es lo correcto, no requieren
  `enable`). Los avisos de RTKit (`RTKit error: ServiceUnknown`) han
  desaparecido del journal de PipeWire tras el reinicio del servicio. `upower`
  reporta la batería correctamente (capacidad real 70,86 Wh). `upower` será
  necesario para el módulo de batería de Waybar.
- **[OK] `sof-firmware` es imprescindible en este hardware.** El driver
  `snd-sof-pci-intel-mtl` (DSP de audio de Meteor Lake) necesita los
  firmwares/topologías del paquete `sof-firmware` para inicializar la tarjeta.
  Sin él, el driver falla al arrancar el DSP (`sof_probe_work failed err: -2`
  en `dmesg`) y el sistema se queda sin salida de audio: `aplay -l` solo
  muestra el HDMI de la NVIDIA (sin altavoces), PipeWire únicamente ofrece un
  sink ficticio "Dummy Output" en estado `MUTED`, y `speaker-test` falla con
  "no such file or directory". Es el síntoma a reconocer si el audio
  desaparece tras una reinstalación o una limpieza de paquetes. Solución:
  `sudo pacman -S sof-firmware` + reinicio.
  **Verificado 2026-07-22:** tras instalar `sof-firmware` aparece la tarjeta
  `sofhdadsp` (`sof-hda-dsp`) con altavoces, micrófono digital, micrófono
  estéreo y salidas HDMI (`aplay -l`, `wpctl status`). Altavoces, micrófono y
  webcam funcionan correctamente.

## 9. Herramientas de IA  **[OK]**

- **OpenAI Codex CLI 0.145.0** · `~/.local/bin/codex` →
  `~/.local/lib/node_modules/@openai/codex`. Instalado como global npm.
  `node` v26.4.0 / `npm` 12.0.1.
  **[OK] Prefix de npm migrado a `~/.local`:** instalaciones globales sin
  sudo. `~/.npmrc` contiene `prefix=/home/elok/.local`.
- **Anthropic Claude Code 2.1.217** (instalador nativo) ·
  `~/.local/bin/claude` → `~/.local/share/claude/versions/2.1.217`.
  PATH corregido con bloque idempotente en `~/.bash_profile` (verificado
  `bash -n` OK). **No mover a `/usr/bin`.**
- **Claude Desktop** (AUR `claude-desktop`) también instalado.
- Ambos asistentes se ejecutan **como usuario normal, nunca con sudo**.

## 10. VS Code  **[OK]**

- `visual-studio-code-bin` 1.129.1 (AUR, no Code OSS) · `/usr/bin/code`.
- Keyring funcionando vía `libsecret` / `secret-tool`.

## 11. Capturas de pantalla  **[OK]**

- `grim` + `slurp` + `wl-clipboard` + `swappy` instalados. **[OK]**
- `grim -g "$(slurp)" - | wl-copy` funciona.
- Cuatro atajos de Hyprland aplicados: `Print` (región → portapapeles),
  `Ctrl+Print` (pantalla completa → portapapeles), `Shift+Print` (región →
  archivo en `~/Screenshots`) y `Super+Print` (región → swappy para anotar).
- `swappy` configurado (`dotfiles/swappy/.config/swappy/config`, enlazado vía
  Stow) para guardar en `~/Screenshots`.
- Referencia completa de atajos: [`docs/keybindings.md`](keybindings.md).

## 12. Dotfiles y estado del repositorio  **[EN CURSO]**

- Repo `~/Projects/arch-msi` con `git init`: creado.
- `stow` 2.4.1 instalado; migración **en curso**. Existe el paquete `dotfiles/`
  con los componentes `hypr/`, `shell/` y `swappy/` ya enlazados.
- Migrado y validado:
  - **Hyprland** → `dotfiles/hypr/` (commit `f2c9f4d`).
  - **Shell** → `dotfiles/shell/` (`.bashrc`, `.bash_profile`; commit
    `a4dbf92`).
  - **swappy** → `dotfiles/swappy/` (`config`; commit `0bc8922`).
- Sin config todavía: `kitty`, `rofi`, `yazi`, `waybar`, `dunst`. Se difieren
  hasta que existan (o se cree una config mínima como tarea propia).

## 13. Tareas pendientes (fases futuras)

Las tareas de la fase inicial están completadas. Posibles siguientes pasos:

- Configurar Waybar.
- Configurar Dunst.
- Crear configs propias para Kitty, Rofi y yazi, y migrarlas a Stow.
- Limpiar la variable `menu = "hyprlauncher"` sobrante en `hyprland.lua` (no
  se usa en ningún bind).

## 14. Información sin verificar

- Estado de autenticación de Claude Code (no comprobado; no exponer credenciales).
