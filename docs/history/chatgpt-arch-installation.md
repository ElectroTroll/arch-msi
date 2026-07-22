# Cronología de la instalación

Historia resumida del proyecto. La secuencia de instalación de paquetes se
reconstruye a partir de los snapshots de Snapper (pre/post de `snap-pac`), que
registran timestamps reales. Las decisiones de diseño se anotan aparte.

## Línea temporal (según snapshots Snapper)

- **2026-07-20 23:11** — Snapshot #2: *"Sistema base limpio"*. Punto de partida.
- **07-20 23:14** — `pacman -Syu` (primera actualización).
- **07-20 23:20** — `cargo` (rust, como dependencia).
- **07-20 23:23** — instalación de `paru` (helper de AUR).
- **07-21 00:59** — `github-cli`.
- **07-21 01:04** — `openssh`.
- **07-21 01:33** — `zram-generator`.
- **07-21 02:02** — `reflector`.
- **07-21 02:16 / 02:19** — utilidades base: `less`, `man-db`, `man-pages`,
  `bat`, `fd`, `ripgrep`, `tree`, `wget`, `curl`, `unzip`, `7zip`, `dmidecode`,
  `dosfstools`, `fastfetch`, …
- **07-21 03:22** — **`nvidia-open-dkms`** + `linux-headers` + `linux-lts-headers`.
- **07-21 03:38** — `power-profiles-daemon`.
- **07-21 03:49** — `python-gobject`.
- **07-21 04:18** — **`hyprland`** + `xdg-desktop-portal(-hyprland)` + `waybar` + …
- **07-21 04:25** — **`uwsm`** (gestor de sesión Wayland).
- **07-21 13:30 / 13:39** — `firefox`, `dolphin`, `ark`, `kio-admin`,
  thumbnailers KDE.
- **07-21 13:41** — `btop`, `lazygit`.
- **07-21 13:44 / 16:24** — **`stow`**.
- **07-21 14:00** — **`visual-studio-code-bin`** (AUR).
- **07-21 14:04** — `gnome-keyring` + `libsecret` + `seahorse`.
- **07-21 14:05** — `nodejs` + `npm`.
- **07-21 23:52** — **`claude-desktop`** (AUR).
- **2026-07-22 00:00** — snapshots de timeline continúan.

> Codex CLI (npm global) y Claude Code (instalador nativo en `~/.local/bin`) se
> instalaron por fuera de pacman, por lo que no aparecen en esta cronología de
> snapshots. Ver `../PROJECT_CONTEXT.md` §9.

## Decisiones de diseño

- **Arch directo**, no CachyOS: sistema limpio y controlado.
- **Btrfs + zstd** con subvolúmenes `@` / `@home`; snapshots con Snapper +
  `snap-pac` + `grub-btrfs`. El layout de snapshots resultó ser el estándar
  **anidado** (`.snapshots` dentro de `@`), no un `@snapshots` de nivel superior.
- **GRUB** en vez de systemd-boot, por la ESP pequeña compartida con Windows.
- **`nvidia-open-dkms`** con **PRIME offload** y **Runtime D3** para uso híbrido
  bajo demanda.
- **Hyprland** como compositor tiling, con configuración **Lua** (0.55+).
- **SDDM → uwsm → Hyprland** como cadena de sesión.
- Terminal **Kitty**, gestor gráfico **Dolphin**, gestor de terminal **yazi**,
  lanzador **Rofi**.
- Preferencias: teclado **español**, **natural scrolling**, `bat` sobre `cat`.

## Problemas resueltos

- **`SUPER + R`** no lanzaba Rofi: ejecutaba una variable `menu` sin resolver.
  Se sustituyó por `rofi -show drun` directo. Resuelto (cambio en vivo, pendiente
  de migrar a dotfiles).
- **Aviso de keyring en VS Code**: resuelto instalando `gnome-keyring`,
  `libsecret` y `seahorse`.
- **`claude` no encontrado**: `~/.local/bin` no estaba en `PATH`. Se añadió un
  bloque idempotente en `~/.bash_profile`; verificado que una shell de login
  lo incluye y `bash -n` da sintaxis OK.

## Decisión de organizar dotfiles

Se decidió crear el repositorio `arch-msi` como fuente de verdad, con GNU Stow
para desplegar la configuración mediante enlaces simbólicos, migrando un
componente cada vez y verificando tras cada paso. Primer objetivo de migración:
Hyprland, luego el shell.
