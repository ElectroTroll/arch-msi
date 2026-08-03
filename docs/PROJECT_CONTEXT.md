# PROJECT_CONTEXT

Estado técnico vigente del sistema `arch-msi`. Fuente de verdad detallada.
Última actualización: 2026-07-27, tras cerrar la tarea 2.3 (bloqueo de
pantalla e inactividad). Auditoría no destructiva completa: 2026-07-23.

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

- Arrancando `linux-lts` (**6.18.41-1-lts**, verificado 2026-08-01). También
  instalado `linux` (mainline, 7.1.5.arch1-2). La versión concreta del kernel
  deriva con cada actualización; lo estable aquí es **que se arranca la LTS**.
- `intel-ucode` presente. DKMS reconstruye `nvidia-open` para ambos kernels.
- **Tras actualizar el kernel hay que reiniciar antes de seguir trabajando.**
  Pacman borra `/usr/lib/modules/<versión-vieja>`, así que el kernel en
  ejecución se queda sin árbol de módulos: lo ya cargado sigue funcionando,
  pero **ningún módulo nuevo puede cargarse** hasta el reinicio (observado el
  2026-08-01 con 6.18.39 → 6.18.41).

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
- **[OK] Drop-in de NVIDIA para la suspensión** (verificado 2026-07-27):
  `/usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf`
  fija `Environment="SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false"`. Es propiedad
  del paquete `nvidia-utils` 610.43.03-3 (`pacman -Qo`), **no** una
  personalización local. Al vivir en `/usr/lib`, una actualización del paquete
  puede modificarlo o retirarlo sin aviso: si la suspensión empieza a fallar
  tras actualizar, comprobar este archivo primero.

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

> ⚠️ **Los dispatchers clásicos NO funcionan por IPC con configuración Lua.**
> **[OK]** verificado 2026-08-02. Hyprland envuelve lo que reciba en
> `hl.dispatch(...)` y lo evalúa como Lua, así que la sintaxis de toda la vida
> falla con un error de sintaxis:
>
> ```
> $ hyprctl dispatch workspace 2
> error: [string "return hl.dispatch(workspace 2)"]:1: ')' expected near '2'
> ```
>
> La forma válida es la del propio `hyprland.lua`:
> `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'` → `ok`.
>
> **Afecta a cualquier herramienta externa que hable por IPC**, no solo a las
> nuestras, y el fallo es **silencioso** para quien no comprueba la respuesta.
> Dos casos ya encontrados:
> - **DPMS** en hypridle (tarea 2.3, ver §9): además de fallar, el equivalente
>   Lua apagó la pantalla de forma irrecuperable. No usar dispatchers DPMS.
> - **Clic en los workspaces de Waybar** (tarea 2.1): Waybar 0.15 envía
>   `dispatch workspace N`, Hyprland lo rechaza y Waybar no mira la respuesta,
>   así que el clic no hace nada y no se registra ningún error. Waybar no
>   expone opción para cambiar lo que envía. **Se asume**: se navega con
>   `Super + N`, que sí usa la sintaxis Lua correcta.
>
> Al añadir cualquier integración con Hyprland, comprobar primero a mano que
> el dispatcher responde `ok`.

> **Realidad de configuración:** tienen config propia y versionada **Hyprland**
> (`hyprland.lua`), **hyprlock** (`hyprlock.conf`) e **hypridle**
> (`hypridle.conf`) en `dotfiles/hypr/`, y **Waybar** (`config.jsonc` +
> `style.css` + `claude-usage.sh`) en `dotfiles/waybar/`. Las carpetas de
> `kitty`, `rofi`, `yazi` y `dunst` siguen **vacías o inexistentes** (usan
> defaults).
> Ver §13 (Dotfiles y estado del repositorio).

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

## 9. Red y seguridad  **[OK]**

- **firewalld** activo y habilitado (`systemctl is-active` / `is-enabled` →
  `active` / `enabled`), instalado junto con sus dependencias
  `python-firewall` y `python-capng`.
- Zona por defecto **`public`**, activa con la interfaz Wi-Fi `wlp44s0f0`
  asignada (`firewall-cmd --get-default-zone`, `--list-all`).
- Política de entrada: **denegación por defecto** — solo se permite lo
  explícitamente listado en la zona. Único servicio permitido:
  `dhcpv6-client`, necesario para conectividad IPv6. **No se filtra tráfico
  saliente** (firewalld solo filtra entrada por defecto; no hay reglas de
  egress configuradas).
- Se retiró el servicio **`ssh`** de la zona `public` (venía permitido por
  defecto). Motivo: no hay servidor SSH escuchando — `sshd` está
  **deshabilitado e inactivo a propósito** (`openssh` se usa solo como
  cliente) — y dejarlo abierto sería una puerta entreabierta en redes
  públicas.
- **Contexto de la instalación:** medida preventiva, no correctiva. Antes de
  instalar firewalld, `ss -tulpn` no mostraba ningún socket escuchando: la
  superficie de ataque entrante ya era cero. Se instaló por el uso previsto
  del portátil en redes no confiables (viajes, cafeterías).
  **Verificado 2026-07-23.**
- **[PEND]** Las zonas de firewalld se asignan **por interfaz**. Al instalar
  ProtonVPN (o cualquier VPN) en el futuro, habrá que decidir explícitamente a
  qué zona pertenece su interfaz (p. ej. `tun0`/`proton0`) — no dar por hecho
  que hereda `public`. Pendiente de decidir cuando se instale la VPN.

### Bloqueo de pantalla e inactividad  **[OK]**

Tarea 2.3 completada (commits `887cfb3`, `03f4bc5`, `0d8a364`, `b99f62d`,
`c36e5c5`). Configuración en `dotfiles/hypr/`, enlazada con Stow.

- **hyprlock** (`hyprlock.conf`): pantalla de bloqueo, desbloqueo por contraseña
  vía PAM. **No se invoca nunca directamente**: siempre por dbus
  (`loginctl lock-session`), que hace que hypridle ejecute su `lock_cmd`.
  Tres caminos llegan a él: el atajo **`Super + L`**, el listener de 600 s y
  `before_sleep_cmd`. Ver `docs/keybindings.md` §Sesión.
- **hypridle** (`hypridle.conf`): bloque `general` + 3 listeners.
  - `lock_cmd = pidof hyprlock || hyprlock` (el `pidof` evita apilar
    instancias si llegan varios eventos de bloqueo).
  - `before_sleep_cmd = loginctl lock-session` — cierra el agujero "cerrar
    tapa → suspender → abrir → escritorio sin contraseña".
  - `inhibit_sleep = 2` (modo fuerte): retiene el inhibidor de logind hasta
    que el compositor confirma el bloqueo, así que no hay carrera entre
    bloqueo y suspensión. Se fija **explícitamente**, sin depender del default
    de ninguna versión. **No subir a 3**: rompe `on_lock_cmd` /
    `on_unlock_cmd`.
  - **Sin `after_sleep_cmd`** — ver la trampa del DPMS más abajo.
  - Listeners: **480 s** atenuar el brillo al 10%
    (`brightnessctl -s set 10%` / `on-resume: brightnessctl -r`), **600 s**
    bloquear (`loginctl lock-session`), **900 s** suspender **solo con
    batería** (`grep -qx 0 /sys/class/power_supply/ADP1/online &&
    systemctl suspend`).
- **Brillo:** `intel_backlight` con `max_brightness = 192000`. Usar siempre
  **porcentaje** (`set 10%`); un `set 10` crudo sería 0,005% → pantalla negra.
  Este equipo **no tiene `kbd_backlight`**.
- **Guarda de alimentación:** `ADP1/online` cubre toda la alimentación externa
  del equipo. No hay conector de corriente propio; ambos puertos USB-C dan
  `online=1` con `BAT1/status=Charging` (verificado 2026-07-27, confirmado vía
  `ucsi-source-psy-USBC000:001`, `usb_type = C [PD] PD_PPS`).
  ⚠️ **Ruta absoluta dependiente del hardware.**
  `/sys/class/power_supply/ADP1/online` es la única ruta frágil de la config.
  Si tras una reinstalación el kernel enumerase el conector como `ADP0`, el
  `grep` fallaría siempre, el `&&` cortocircuitaría y **el equipo dejaría de
  suspenderse con batería, sin ningún aviso**. Falla hacia el lado seguro (no
  afecta al bloqueo), pero es silencioso: al restaurar, comprobar con
  `ls /sys/class/power_supply/`.
- **Sin hibernación** (solo zram, sin swap en disco): la suspensión es a RAM.
  Si la batería se agota mientras está suspendido, se pierde lo no guardado.
- **`hypridle.service` habilitado** (unidad del paquete, con
  `WantedBy=graphical-session.target` y `ConditionEnvironment=WAYLAND_DISPLAY`).
  **Verificado tras reinicio 2026-07-27:** systemd lo arranca solo, el journal
  muestra `found 3 rules` con las tres reglas registradas y **sin**
  `[ERR] Config has errors`.
  **Reverificado en el arranque del 2026-07-31** (auditoría 2026-08-01):
  arranque del sistema 16:52, `hypridle` a las 16:53:20 dentro del cgroup
  `hypridle.service` (`Main PID 1085`), `enabled` y `active`. No es un
  lanzamiento manual heredado de la sesión de configuración.
- **Ciclo completo observado en el journal** (mismo arranque, sin provocarlo):
  `17:09:22` bloqueo por los 300 s (`Wayland session got locked`) →
  `17:19:22` `Got PrepareForSleep` con `before_sleep_cmd` → suspensión por los
  900 s estando con batería → `ago 01 13:42:20 System returned from sleep` →
  `13:42:37 auth: authenticated for hyprlock` → `Unlocking session`. Los tres
  listeners, el bloqueo previo a dormir y el desbloqueo por contraseña quedan
  verificados de extremo a extremo. **[OK]**
- **Revalidado tras subir a hypridle 0.1.8-1** (2026-08-01, arranque de las
  16:06 con kernel 6.18.41-1-lts y Hyprland 0.56.1). Servicio `enabled` y
  `active`, las tres reglas registradas, **sin** `Config has errors`, y el
  listener de 300 s se disparó solo a las `16:14:55` lanzando hyprlock 0.9.6.
  La configuración no necesitó ningún cambio. **[OK]**
  > **Cambia cómo se verifica `inhibit_sleep = 2`, no su comportamiento.** En
  > 0.1.7-10 se comprobó leyendo el binario (`mov esi,0x2`); en 0.1.8 ese
  > patrón ya no aparece porque cambió la generación de código, así que **el
  > default de esta versión no está verificado**. Es irrelevante: la config
  > fija el valor explícitamente. Lo que sí hay ahora es evidencia mejor,
  > observada en ejecución: el journal escribe `Sleep inhibition enabled -
  > inhibiting until the wayland session gets locked` al arrancar y
  > `Releasing the sleep inhibitor!` al bloquearse — la semántica del modo 2
  > descrita por el propio binario. El aviso de que el modo 3 rompe
  > `on_lock_cmd`/`on_unlock_cmd` sigue presente en 0.1.8.
- **El estado del servicio vive fuera de los dotfiles.** El `enable` crea
  `~/.config/systemd/user/graphical-session.target.wants/hypridle.service`,
  que no está versionado; solo queda constancia en
  `packages/services-enabled.txt`. **Al restaurar desde el repo hay que
  rehabilitarlo a mano**, o el bloqueo automático quedará silenciosamente
  inactivo.

> **Vías de rescate y trampas conocidas (2026-07-27).** Cada punto lleva su
> propio estado: **[OK]** observado en la máquina · **[VER]** deducido de la
> configuración, sin provocar.
>
> - **[OK] `Ctrl+Alt+F2` NO funciona bajo Hyprland**: el compositor captura la
>   combinación y no la traduce a un cambio de VT. La vía válida es **tty3**,
>   alcanzable con `sudo chvt 3` desde una terminal.
> - **[OK] tty2 tiene un Xorg huérfano** del greeter de SDDM (PID variable; en la
>   comprobación de referencia, PID 756 en `vt2` con
>   `-auth /run/sddm/xauth_*`). Su sesión `c1` ya fue eliminada:
>   `loginctl list-sessions` solo muestra la sesión de tty1 y el manager de
>   usuario. **No es un destino válido de rescate.**
> - **[OK] faillock es compartido** entre hyprlock y el login por TTY:
>   `/etc/pam.d/hyprlock` hace `auth include login`, y `login` encadena a
>   `system-auth`, que invoca `pam_faillock.so`. Cadena PAM verificada
>   leyendo los archivos.
>   `/etc/security/faillock.conf` está **enteramente comentado**, así que
>   rigen los valores por defecto que el propio archivo documenta:
>   `deny = 3`, `unlock_time = 600`. Según esa configuración vigente, tres
>   fallos bloquearían **ambos** caminos durante 10 minutos, incluida la vía
>   de rescate por TTY.
>   **[VER] El bloqueo NO se ha provocado nunca en esta máquina**: lo anterior
>   se deduce de la configuración leída, no de una observación. Tampoco se ha
>   comprobado que los defaults sigan vigentes tras una actualización de
>   `pam`, que podría descomentar o cambiar esos valores sin aviso.
>   **Este es el único escenario realista de quedarse fuera de la sesión en
>   este equipo**, y es justo el que inutiliza la vía de rescate descrita
>   arriba: si hyprlock ya ha consumido los tres intentos, `sudo chvt 3` lleva
>   a un login que también rechazará la contraseña. La salida es **esperar los
>   10 minutos**. No hay nada que cambiar en la configuración; debe constar.
>   **[OK] Reverificado 2026-08-01:** `/etc/security/faillock.conf` sigue
>   enteramente comentado (defaults vigentes) y `/etc/pam.d/hyprlock` sigue
>   siendo el del paquete, sin alterar (`pacman -Qkk hyprlock`: 0 archivos
>   alterados).
> - **[OK] DPMS descartado.** `hyprctl dispatch dpms on` (sintaxis hyprlang del
>   sample) no es válida en Hyprland 0.56 con configuración Lua. El
>   equivalente Lua `hyprctl dispatch 'hl.dsp.dpms("on")'` **apagó la pantalla
>   en lugar de encenderla** (2026-07-27), de forma irrecuperable: sin
>   respuesta a teclado, ratón, tapa ni cambio de VT. Solo se recuperó con
>   `systemctl reboot`. No hay sintaxis DPMS verificada para 0.56 + Lua.
>   **No usar dispatchers DPMS en este equipo.**

## 10. Herramientas de IA  **[OK]**

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

## 11. VS Code  **[OK]**

- `visual-studio-code-bin` 1.129.1 (AUR, no Code OSS) · `/usr/bin/code`.
- Keyring funcionando vía `libsecret` / `secret-tool`.

## 12. Capturas de pantalla  **[OK]**

- `grim` + `slurp` + `wl-clipboard` + `swappy` instalados. **[OK]**
- `grim -g "$(slurp)" - | wl-copy` funciona.
- Cuatro atajos de Hyprland aplicados: `Print` (región → portapapeles),
  `Ctrl+Print` (pantalla completa → portapapeles), `Shift+Print` (región →
  archivo en `~/Screenshots`) y `Super+Print` (región → swappy para anotar).
- `swappy` configurado (`dotfiles/swappy/.config/swappy/config`, enlazado vía
  Stow) para guardar en `~/Screenshots`.
- Referencia completa de atajos: [`docs/keybindings.md`](keybindings.md).

## 13. Dotfiles y estado del repositorio  **[EN CURSO]**

- Repo `~/Projects/arch-msi` con `git init`: creado.
- `stow` 2.4.1 instalado; migración **en curso**. Existe el paquete `dotfiles/`
  con los componentes `hypr/`, `shell/` y `swappy/` ya enlazados.
- Migrado y validado:
  - **Hyprland** → `dotfiles/hypr/` (commit `f2c9f4d`).
  - **Shell** → `dotfiles/shell/` (`.bashrc`, `.bash_profile`; commit
    `a4dbf92`).
  - **swappy** → `dotfiles/swappy/` (`config`; commit `0bc8922`).
  - **hyprlock + hypridle** → `dotfiles/hypr/` (`hyprlock.conf`,
    `hypridle.conf`; commits `887cfb3`, `03f4bc5`, `0d8a364`, `b99f62d`,
    `c36e5c5`). Detalle en §9.
  - **Waybar** → `dotfiles/waybar/` (`config.jsonc`, `style.css`,
    `claude-usage.sh`). Tarea 2.1 completada. `waybar.service` habilitado, así
    que arranca sola con la sesión gráfica.
  - **wlogout** → `dotfiles/wlogout/` (`layout`, `style.css`). Menú de apagado
    del botón de la barra. Sin botón de hibernar: este equipo no puede (ver
    §5). Los flags de disposición no están en el paquete porque wlogout solo
    los acepta por línea de comandos; viven en el `on-click` de Waybar.
  - **Claude Code (hook de línea de estado)** → `dotfiles/claude/`
    (`claude-statusline.sh`), enlazado a `~/.claude/claude-statusline.sh`.
    Alimenta el módulo de uso de Claude de Waybar. **El paquete debe contener
    solo ese script**: `~/.claude` guarda credenciales e historial. El
    `.gitignore` lo garantiza con una excepción de tres líneas sobre la regla
    `**/.claude/`, verificada con archivos señuelo.
- Sin config todavía: `kitty`, `rofi`, `yazi`, `dunst`. Se difieren hasta que
  existan (o se cree una config mínima como tarea propia).

## 14. Tareas pendientes (fases futuras)

Las tareas de la fase inicial están completadas. Posibles siguientes pasos:

- Configurar Dunst.
- Crear configs propias para Kitty, Rofi y yazi, y migrarlas a Stow.
- Limpiar la variable `menu = "hyprlauncher"` sobrante en `hyprland.lua` (no
  se usa en ningún bind).
- **Estado que vive fuera del repositorio y que una restauración NO recupera.**
  Son tres agujeros del mismo tipo: los archivos vuelven a su sitio, pero nada
  los activa, y el fallo es **silencioso** — nada avisa de que falta el paso.
  - `hypridle.service`: el `enable` solo deja rastro en
    `packages/services-enabled.txt`. Sin rehabilitarlo, la sesión no se
    bloquea sola nunca (ver §9).
  - `waybar.service`: habilitado el 2026-08-02. Sin rehabilitarlo tras una
    restauración, no hay barra: los archivos están, pero nadie los lanza.
  - `~/.claude/settings.json` → `statusLine.command`. El script está
    versionado y se enlaza con Stow, pero quien lo invoca es este archivo, que
    **no** se versiona porque contiene credenciales y estado de sesión. Sin él,
    el módulo de uso de Claude en Waybar se queda en `—` para siempre.
  Decidir cómo cubrirlos: encaja con `install/services.sh` de la fase 6 (ver
  roadmap 6.1, marcado como requisito bloqueante).

    ⚠️ **Dos valores dependen de este hardware y fallan sin dar error.** El
    módulo de batería fija `bat: BAT1` y `adapter: ADP1`, y el `on-click` del
    botón de apagado pasa a wlogout un margen de `400` px calculado a mano para
    1600x1000 lógicos (2560x1600 a escala 1.60). Si tras una reinstalación
    cambia la enumeración de `/sys/class/power_supply/`, el módulo de batería se
    queda **mudo sin registrar nada en el journal**; si cambia la resolución o
    la escala, el menú de apagado se deforma. Mismo patrón que el `ADP1` de
    `hypridle.conf` (§9). El módulo de red evita a propósito esta trampa: no
    fija `interface`, así que sigue a la ruta por defecto.
## 15. Información sin verificar

- Estado de autenticación de Claude Code (no comprobado; no exponer credenciales).
- **[VER]** hyprlock registra `Starting fade in` pese a tener
  `animations { enabled = false }` en `hyprlock.conf`. Cosmético: no se ha
  observado efecto sobre el bloqueo ni sobre el desbloqueo. Sin resolver
  (2026-07-27).
