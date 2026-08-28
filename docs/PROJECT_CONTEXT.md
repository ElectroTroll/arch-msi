# PROJECT_CONTEXT

Estado técnico vigente del sistema `arch-msi`. Fuente de verdad detallada.
Última actualización: 2026-08-28 (**tema centralizado con matugen** — §18 nueva,
y §13 al día con los paquetes Stow que entran y salen; trampas del proceso en
`history/2026-08-28-trampas-del-tema.md`). Antes: 2026-08-27 (**corrección de las
vías de rescate**: tres
afirmaciones falsas en §9 (Red y seguridad) sobre el cambio de VT, el `tty2` y
faillock, más el registro de los dos bloqueos reales de faillock). Antes:
2026-08-24 (incidente de arranque por renumeración de
particiones y actualización completa posterior — §2 (Almacenamiento), §3
(Bootloader), §4 (Kernel) y §15 (Sin verificar)); 2026-08-04 (cierre de
la tarea 2.2, Dunst — §16 (Notificaciones)), 2026-08-03 (Spotify y escalado bajo
XWayland, §7 (Entorno gráfico)) y 2026-08-02 (cierre de la tarea 2.1, Waybar).
Auditoría no destructiva completa: 2026-07-23. Verificación post-incidente
completa (particiones, arranque, servicios, Stow, journal, RTD3): 2026-08-24.

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

- Partición Linux: **`/dev/nvme0n1p5`**, UUID `27a7d1f2-…-95611f71b5aa`
  (verificado 2026-08-24 con `findmnt` y `lsblk`).
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

> **La partición era `p6` hasta el 2026-08-24.** Una actualización de Windows
> renumeró el disco y la Btrfs de Linux pasó de `p6` a `p5` (la recovery de MSI
> hizo el camino inverso). **El UUID no cambió**, y ahí está la lección: como
> `/etc/fstab` monta por UUID y no por nombre de dispositivo, no necesitó ni un
> retoque — el sistema montó `/` y `/home` correctamente en cuanto GRUB
> consiguió cargar el kernel. El que sí se rompió fue el bootloader (ver §3).
>
> Verificado tras el incidente (2026-08-24): los subvolúmenes siguen intactos
> con los mismos IDs (`@` 256, `@home` 257, `.snapshots` 261 anidado), y
> `btrfs device stats /dev/nvme0n1p5` da los cinco contadores de error a **0**
> (`write`, `read`, `flush`, `corruption`, `generation`). No se lanzó un
> `scrub`: queda pendiente para una sesión dedicada, por ser 24 GB de E/S.
>
> Cronología completa en
> [`history/2026-08-24-incidente-arranque-grub.md`](history/2026-08-24-incidente-arranque-grub.md).

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
- Entradas EFI (`efibootmgr`): `Boot0001* GRUB` y `Boot0000* Windows Boot
  Manager`, ambas en la ESP, con `BootOrder 0001,0000` — GRUB primero.

### El incidente del 2026-08-24 y por qué no se repetirá

`grub-install` graba dentro del núcleo de GRUB la ubicación de `/boot/grub`
como **`(hd0,gptN)`**: una referencia **posicional**, no un UUID. Cuando Windows
renumeró las particiones, el `(hd0,gpt6)` que tenía grabado dejó de apuntar a la
raíz Btrfs y pasó a señalar la NTFS de recovery de MSI. Resultado:
`unknown filesystem` y caída a `grub rescue>`. **El sistema de archivos estaba
perfectamente; lo único roto era la referencia del bootloader.**

Se reparó desde un USB de Arch con `grub-install` + `grub-mkconfig` en chroot.

Comprobado el 2026-08-24, después de reparar **y** después de actualizar:

- `grep -c "hd0,gpt" /boot/grub/grub.cfg` → **0**. No queda ni una referencia
  posicional en el menú.
- `grep -c "search --no-floppy --fs-uuid" /boot/grub/grub.cfg` → **5**. Todo se
  resuelve por UUID.
- La entrada de Windows es `osprober-efi-DEFF-2D9C`, es decir, identificada por
  el **UUID de la ESP** y no por número de partición.

Es decir: ni la entrada de Linux ni la de Windows dependen ya de la numeración.
Si Windows vuelve a renumerar el disco, el menú seguirá funcionando.

> **Comprobación recomendada tras cada actualización grande de Windows:**
> `sudo grep -c "hd0,gpt" /boot/grub/grub.cfg` debe devolver **0**. Si devuelve
> otra cosa, el arranque es frágil y conviene regenerar antes de reiniciar.

`grub-mkconfig` reescribe **solo** el menú: no toca `grubx64.efi` ni la NVRAM
EFI. Por eso regenerar `grub.cfg` tras actualizar el kernel es seguro y no puede
deshacer una reparación previa (verificado: la NVRAM salió byte a byte idéntica
antes y después de la actualización de 221 paquetes).

**Ningún hook de pacman regenera `grub.cfg` en Arch.** Los hooks de `linux` y
`linux-lts` solo llaman a `mkinitcpio`. Hay que lanzarlo a mano:
`sudo grub-mkconfig -o /boot/grub/grub.cfg`.

## 4. Kernel y arranque  **[OK]**

- Arrancando `linux-lts` (**6.18.46-1-lts**, verificado 2026-08-24). También
  instalado `linux` (mainline, **7.1.9.arch1-2**). La versión concreta del kernel
  deriva con cada actualización; lo estable aquí es **que se arranca la LTS**.
- Que arranque la LTS no es casualidad: con `GRUB_DEFAULT=0`, `grub-mkconfig`
  encuentra `vmlinuz-linux-lts` antes que `vmlinuz-linux`, así que la entrada
  por defecto del menú es la LTS.
- `intel-ucode` presente. DKMS reconstruye `nvidia-open` para ambos kernels
  (**610.57.04-1** para `6.18.46-1-lts` y `7.1.9-arch1-2`, verificado
  2026-08-24 con `dkms status` y los cinco `.ko.zst` en cada
  `/usr/lib/modules/*/updates/dkms/`).
- El orden de los hooks de pacman importa y sale bien solo: `Install DKMS
  modules` (14/24) se ejecuta **antes** que `Updating linux initcpios` (16/24),
  así que los initramfs se construyen con los módulos NVIDIA ya compilados. Con
  `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` en `mkinitcpio.conf`,
  el orden inverso dejaría el arranque sin driver.
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

- `nvidia-open-dkms` **610.57.04** · `nvidia-utils` / `nvidia-settings` /
  `nvidia-prime` · `mesa` **26.2.1** · loader Vulkan 1.4. **[OK]**
  (versiones al 2026-08-24; antes 610.43.03 y mesa 26.1.5)
- Híbrido PRIME offload: Intel Arc (`i915`) como GPU primaria; NVIDIA bajo
  demanda (`prime-run`). Sin variables de entorno NVIDIA/GBM/LIBVA/WLR forzadas
  (setup limpio). **[OK]**
- Runtime D3 **fine-grained habilitado**. **[OK]**
- `power-profiles-daemon` activo (`intel_pstate`; driver de plataforma
  `placeholder`). Sin `tlp` → sin conflicto. **[OK]**
- **[OK] Drop-in de NVIDIA para la suspensión** (verificado 2026-07-27):
  `/usr/lib/systemd/system/systemd-suspend.service.d/10-nvidia-no-freeze-session.conf`
  fija `Environment="SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false"`. Es propiedad
  del paquete `nvidia-utils` (`pacman -Qo`), **no** una personalización local.
  Al vivir en `/usr/lib`, una actualización del paquete puede modificarlo o
  retirarlo sin aviso: si la suspensión empieza a fallar tras actualizar,
  comprobar este archivo primero.
  **Revisado el 2026-08-24 tras subir a `nvidia-utils` 610.57.04-1:** el archivo
  sigue presente, con el mismo contenido, y `pacman -Qo` lo asigna a la versión
  nueva. La actualización no se lo llevó por delante.

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
  (Hyprland ≥0.55 usa Lua; hyprlang/`.conf` está deprecado). **[OK]**
  Hubo un `hyprland.lua.backup` de la migración a Stow; se **borró el
  2026-08-27** por ser ruido: nunca estuvo versionado —así que no viajaba a una
  restauración— y su contenido no era único. Lo que aportaba queda registrado en
  [`history/2026-08-27-limpieza-fase2.md`](history/2026-08-27-limpieza-fase2.md).
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
>   **La necesidad quedó cubierta el 2026-08-25 con `wlopm`** (§9), que esquiva
>   el IPC y el parser Lua por completo. La advertencia sobre los dispatchers
>   sigue vigente: lo que cambió es que ya no hace falta usarlos.
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
> (`hypridle.conf`) en `dotfiles/hypr/`, **Waybar** (`config.jsonc` +
> `style.css` + `claude-usage.sh`) en `dotfiles/waybar/` y **dunst**
> (`dunstrc`) en `dotfiles/dunst/` (tarea 2.2, ver §16 (Notificaciones)). Las
> carpetas de `kitty`, `rofi` y `yazi` siguen **vacías o inexistentes** (usan
> defaults).
> Ver §13 (Dotfiles y estado del repositorio).

### Aplicaciones bajo XWayland y escalado fraccional

> ⚠️ **Con el monitor a escala 1.60, toda app que arranque en XWayland se ve
> borrosa.** XWayland renderiza a 1x y Hyprland estira el resultado. No es un
> fallo de la app, y **nada lo señala**: simplemente se ve mal. Primer caso
> encontrado y corregido: **Spotify** (2026-08-03).

- **Spotify** — instalado desde **AUR con `paru`** (paquete `spotify`,
  `1:1.2.92.147`, propietario). Binario en `/opt/spotify/spotify`, lanzado por
  el wrapper `/usr/bin/spotify`. Motor Chromium 146. **[OK]**
- Síntoma: ventana borrosa/pixelada. Causa verificada con
  `hyprctl clients` → `xwayland: True`. **[OK]**
- Corrección aplicada: forzar **Wayland nativo**, donde Chromium usa el
  protocolo `wp-fractional-scale` y renderiza directo a 1.60x. El wrapper
  `/usr/bin/spotify` pasa al binario lo que encuentre en
  `~/.config/spotify-flags.conf`, así que no hace falta tocar el `.desktop` ni
  nada del sistema:

  ```
  --ozone-platform=wayland
  --enable-features=UseOzonePlatform,WaylandWindowDecorations
  ```

- Verificado tras reiniciar la app: `hyprctl clients` → `xwayland: False`.
  **[OK]** · Nitidez a ojo: **[VER]** (pendiente de confirmación visual).
- **La clase de ventana cambia con el backend:** `Spotify` en X11 →
  `spotify` en Wayland. Ninguna `windowrule` de `hyprland.lua` ni módulo de
  Waybar la usaba, pero cualquier regla futura debe escribirse en minúscula.
- Alternativa **descartada**: `xwayland:force_zero_scaling = true` (global,
  hoy en `false`) más `--force-device-scale-factor` por app. Afectaría a todas
  las apps X11 y obligaría a escalar cada una a mano.
- ⚠️ **`~/.config/spotify-flags.conf` no está versionado** (no es paquete
  Stow todavía). Tras una restauración, Spotify vuelve a verse borroso. Ver
  §14.

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
  - `after_sleep_cmd = wlopm --on '*'` — reenciende la pantalla al volver de
    suspender. Es la segunda red bajo el `on-resume` del listener de 900 s;
    ambas son idempotentes. Hasta el 2026-08-25 esta directiva **no existía**,
    porque la única forma conocida de encender la pantalla era el dispatcher
    DPMS de Hyprland, que aquí es inutilizable (ver la trampa más abajo).
  - Listeners: **480 s** atenuar el brillo al 10%
    (`brightnessctl -s set 10%` / `on-resume: brightnessctl -r`), **600 s**
    bloquear (`loginctl lock-session`), **900 s** apagar la pantalla
    **siempre** y suspender **solo con batería**
    (`wlopm --off '*' ; grep -qx 0 /sys/class/power_supply/ADP1/online &&
    systemctl suspend`, con `on-resume: wlopm --on '*'`).
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

#### Apagado de pantalla con `wlopm`  **[OK]** (2026-08-25)

Hasta esta fecha **la pantalla no se apagaba nunca**, ni con batería ni
enchufado: la secuencia terminaba en el bloqueo de los 600 s, con hyprlock
dibujando un fondo casi negro pero **con la retroiluminación encendida**. No
era una avería, era una funcionalidad que faltaba — se descartó al montar la
tarea 2.3 tras el incidente del DPMS (ver «Vías de rescate y trampas
conocidas», más abajo) y no se sustituyó por nada.

Lo cubre **`wlopm`** (repo `extra`, 57 KiB instalado), cliente del protocolo
**`zwlr_output_power_manager_v1`**. La clave es **por dónde no pasa**: habla
con el compositor directamente por el protocolo estándar de Wayland, sin
`hyprctl`, sin el IPC de Hyprland y **sin el parser Lua**, que es donde reventó
el intento de 2026-07-27. Además `--on` y `--off` son rutas de código
distintas, así que no puede repetirse aquel fallo de "pedí encender y apagó".

Que Hyprland 0.56 anuncia el protocolo está verificado en el journal del propio
hypridle: `[LOG]   | got iface: zwlr_output_power_manager_v1 v1`.

**Comportamiento resultante a los 900 s:**

| | Pantalla | Suspensión |
|---|---|---|
| Enchufado | se apaga | **no** (la guarda de `ADP1` corta el `&&`) |
| Con batería | se apaga | sí, **después** de apagar la pantalla |

**[OK] Los dos caminos verificados por observación (2026-08-25)**, con la
config desechable que sustituye el `systemctl suspend` por un `echo`:

- **Enchufado:** tres disparos consecutivos (`17:55:34`, `17:55:42`,
  `17:56:01`) apagaron la pantalla y en ninguno se ejecutó la rama de
  suspensión — la guarda de `ADP1` hizo su trabajo.
- **Con batería:** un disparo (`18:05:14`) ejecutó **las dos** ramas en el
  mismo segundo, en el orden escrito, y el `on-resume` devolvió la pantalla.

⚠️ **Las comillas de `'*'` son obligatorias.** Verificado empíricamente con una
instancia desechable de hypridle (`hypridle -c` contra una config de usar y
tirar cuyo listener solo registraba sus argumentos): hyprlang **no** se come
las comillas y el shell recibe un `*` literal, pero **sin** comillas el shell
hace globbing contra el directorio de trabajo de hypridle y `wlopm --off`
acabaría recibiendo nombres de fichero. La misma medición demostró que el `;`
encadena y **respeta el orden escrito**, que es lo que garantiza "apaga la
pantalla y *luego* suspende" — un segundo listener con el mismo `timeout` no
daría esa garantía. El comodín `*` (todas las salidas) está documentado en
`wlopm(1)`, sección OUTPUT NAMES; se usa en vez de `eDP-1` para que un monitor
externo también se apague.

⚠️ **Trampa, de la misma familia que la del par `-s`/`-r` del brillo:** el
apagado vive en el **compositor**, no en hypridle. Si hypridle muriera o se
reiniciara con la pantalla ya apagada, el `on-resume` no llegaría nunca y la
pantalla se quedaría negra **sin error en ningún log**, con el equipo por lo
demás vivo. Se arregla con `wlopm --on '*'` a ciegas, o reiniciando hypridle.
**[NO VERIFICADO]** si un cambio de VT la recupera.

**[OK] Ocurrió el 2026-08-27, por una puerta que no estaba contemplada.** Se
probó un botón en hyprlock que ejecutaba `wlopm --off '*'`, y el equipo se quedó
a ciegas: **ni el teclado ni el ratón devolvieron la pantalla**. El supuesto
descrito arriba era «si hypridle muere»; aquí hypridle estaba perfectamente,
pero **quien apagó fue hyprlock**, así que hypridle no se enteró y su `on-resume`
nunca llegó. La regla real es más simple de lo que decía esta nota: **el apagado
vive en el compositor y quien apaga tiene que encender**. Se recuperó con
`wlopm --on '*'` desde otra sesión. El botón se retiró y queda el aviso en
`hyprlock.conf`.

**Nota para el futuro:** hypridle 0.1.8 expone un campo **`condition_cmd`** por
listener (visible en el log de arranque), que sería una forma más limpia de
expresar la guarda de batería que el `&&`. No se ha adoptado: el `&&` dentro de
un único listener es justamente lo que permite garantizar el orden.

> **Vías de rescate y trampas conocidas** (2026-07-27; **corregido a fondo el
> 2026-08-25**, ver los dos primeros puntos). Cada punto lleva su
> propio estado: **[OK]** observado en la máquina · **[VER]** deducido de la
> configuración, sin provocar.
>
> - **[OK] `Ctrl+Alt+F1/F2/F3` SÍ funcionan.** **Corregido el 2026-08-25**: la
>   versión anterior de esta sección afirmaba que Hyprland capturaba la
>   combinación sin traducirla a un cambio de VT. **Era falso, y el diagnóstico
>   apuntaba al sitio equivocado**: el problema estaba en el TECLADO del
>   portátil, no en el compositor.
>
>   La fila superior de este equipo trae las teclas multimedia como función
>   PRIMARIA, así que `F1`–`F12` exigen `Fn`, y la combinación de cuatro teclas
>   no llegaba bien. **Con Fn Lock activado funcionan sin problema**, igual que
>   con un **teclado externo**, donde las F son primarias y siempre
>   funcionaron — de hecho eso es lo que delató el error de diagnóstico.
>
>   ⚠️ **Fn Lock es, por tanto, un requisito práctico de la vía de rescate**
>   desde el teclado integrado. Un teclado externo es la alternativa fiable si
>   Fn Lock no está puesto o no se recuerda el estado.
>
>   `sudo chvt 3` sigue siendo válido, pero **ya no es la única vía** ni hace
>   falta privilegios para cambiar de VT con el atajo.
> - **[OK] Mapa real de VTs** (verificado 2026-08-25, reconfirmado 2026-08-27
>   con `loginctl` y `ps`):
>
>   | VT | Qué hay | Sirve de rescate |
>   |----|---------|------------------|
>   | `tty1` | La sesión de Hyprland (o hyprlock si está bloqueada) | — |
>   | `tty2` | El **greeter de SDDM** | Sí: permite iniciar una sesión nueva |
>   | `tty3` | Consola de texto (`getty`) | Sí |
>   | `tty4` | Consola de texto (`getty`) | Sí |
>
>   **Corrección importante:** la versión anterior describía el `tty2` como «un
>   Xorg huérfano» que «no acepta entrada» y «no es un destino válido». Es
>   falso: ese Xorg **es el greeter**, sigue vivo y bajo el `sddm` en marcha
>   (comprobado: `sddm` activo y `/usr/lib/Xorg … vt2 -auth /run/sddm/xauth_*`),
>   y desde ahí se puede iniciar sesión con normalidad.
> - **[OK] faillock es compartido** entre hyprlock y el login por TTY:
>   `/etc/pam.d/hyprlock` hace `auth include login`, y `login` encadena a
>   `system-auth`, que invoca `pam_faillock.so`. Cadena PAM verificada
>   leyendo los archivos.
>   `/etc/security/faillock.conf` está **enteramente comentado**, así que
>   rigen los valores por defecto que el propio archivo documenta:
>   `deny = 3`, `unlock_time = 600`. Según esa configuración vigente, tres
>   fallos bloquearían **ambos** caminos durante 10 minutos, incluida la vía
>   de rescate por TTY.
>   **[OK] YA NO ES TEÓRICO: ha pasado dos veces.** Esta parte decía «el bloqueo
>   NO se ha provocado nunca en esta máquina» y quedó desfasada:
>
>   - **2026-08-24, con `sudo`.** Se resolvió entrando como **root** con `su -`
>     y ejecutando `faillock --user elok --reset`.
>   - **2026-08-25, con hyprlock**, tras cinco intentos fallidos.
>
>   **`su - <usuario>` es el test que distingue los dos casos**, y es lo primero
>   que hay que hacer cuando una contraseña «correcta» deja de valer: si `su -`
>   con la contraseña buena tampoco entra, no es que la estés escribiendo mal,
>   es faillock.
>
>   **root tiene su PROPIO contador de faillock**, independiente del de `elok`.
>   Por eso hay salida sin esperar: iniciar sesión como root en una TTY (o
>   `su -` desde donde se pueda) y resetear el del usuario:
>
>   ```
>   faillock --user elok --reset
>   ```
>
>   Es decir, **esperar los 10 minutos ya no es la única opción**, como afirmaba
>   la versión anterior de esta sección.
>
>   Sigue siendo **el escenario más realista de quedarse fuera de la sesión en
>   este equipo**, y sigue afectando a los dos caminos a la vez: si hyprlock ha
>   consumido los intentos, el login por TTY rechazará también la contraseña
>   buena. Lo que cambia es que ahora hay una salida rápida y está probada.
>
>   Tampoco se ha comprobado que los defaults de `pam` sigan vigentes tras cada
>   actualización, que podría descomentar o cambiar esos valores sin aviso.
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
>   **[OK] Resuelto por otra vía el 2026-08-25:** el apagado de pantalla lo
>   hace ahora `wlopm` por el protocolo `zwlr_output_power_manager_v1`, sin
>   tocar el dispatcher (§9). Lo descartado sigue descartado; lo que se
>   recupera es la funcionalidad, no el método.

## 10. Herramientas de IA  **[OK]**

- **OpenAI Codex CLI 0.145.0** · `~/.local/bin/codex` →
  `~/.local/lib/node_modules/@openai/codex`. Instalado como global npm.
  `node` v26.7.0 / `npm` 12.0.2 (comprobado 2026-08-27; las versiones derivan
  con cada actualización — el inventario vivo es `packages/npm-global.txt`).
  **[OK] Prefix de npm migrado a `~/.local`:** instalaciones globales sin
  sudo. `~/.npmrc` contiene `prefix=/home/elok/.local`.
- **Anthropic Claude Code 2.1.247** (instalador nativo, comprobado 2026-08-27;
  se autoactualiza, así que el número envejece solo) ·
  `~/.local/bin/claude` → `~/.local/share/claude/versions/<versión>`.
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

> **Desde la tarea 3.0 hay dos clases de archivo en `~/.config`** y conviene no
> confundirlas: los **enlaces de Stow**, que apuntan al repositorio y se editan
> ahí, y los **artefactos generados** por `theme-apply`, que son archivos reales,
> no se versionan y se reescriben en cada arranque. Editar un artefacto es tirar
> el trabajo: la próxima regeneración lo pisa. La lista completa y el porqué del
> reparto, en §18.

- Repo `~/Projects/arch-msi` con `git init`: creado.
- `stow` 2.4.1 instalado; migración **en curso**. Existe el paquete `dotfiles/`
  con los componentes `hypr/`, `shell/` y `swappy/` ya enlazados.
- **Paquetes Stow añadidos por la tarea 3.0/3.1** (2026-08-27/28):
  - **matugen** → `dotfiles/matugen/` (`config.toml` y las plantillas de todos
    los componentes). Es la fuente del tema.
  - **kitty** → `dotfiles/kitty/` (`kitty.conf`; tarea 3.1).
  - **bin** → `dotfiles/bin/` (enlaza `theme-apply` en `~/.local/bin`, que está
    en el PATH de la sesión: así Hyprland lo invoca por nombre y no depende de
    dónde esté clonado el repo).
- **Paquete Stow añadido por la tarea 3.2** (2026-08-28):
  - **rofi** → `dotfiles/rofi/` (`config.rasi`). Décimo paquete. Nace dentro del
    tema: no llega a tener colores propios. **No añade ningún requisito a
    `install/services.sh`** (ver 6.1 del roadmap): no tiene servicio ni
    activación D-Bus, lo invoca un bind de `hyprland.lua` —que se versiona— y
    todo lo demás cae dentro de paquetes Stow. Es el segundo componente del
    proyecto, tras dunst, cuyo autoarranque se restaura solo. `rofi` ya
    figuraba en `packages/pacman-explicit.txt`, así que los inventarios no
    cambian.
- **Paquete Stow añadido al ampliar la 3.2** (2026-08-28):
  - **icons** → `dotfiles/icons/` (`com.anthropic.claude.png`). Undécimo
    paquete, y existe por un solo archivo: un ALIAS del icono de Claude con el
    nombre que rofi busca. **Es el segundo binario del repositorio**, tras el
    fondo de pantalla, y por el mismo tipo de razón: no se recupera con
    `pacman -S` porque no es un archivo de ningún paquete, es una decisión de
    nomenclatura de este equipo. Son 21 KB (la variante 128x128, de sobra para
    los 28 px que pide rofi). Se copió en vez de enlazar porque **Stow rechaza
    los symlinks absolutos dentro de un paquete** — avisa con «source is an
    absolute symlink» y aborta— y un symlink relativo a `/usr/share` dependería
    de dónde esté clonado el repositorio. Contrapartida asumida: si Claude
    cambia su icono, esta copia se queda con el antiguo.
- **Paquetes que dejaron de enlazar parte de su config**, porque su formato no
  admite incluir un fragmento y se genera entera (§18): `waybar` (conserva solo
  `claude-usage.sh`), `wlogout` (conserva solo `layout`) y `fastfetch` (que por
  eso ya no tiene paquete propio).
- ⚠️ **`wlogout` y `fastfetch` estaban enlazados como DIRECTORIO COMPLETO** y se
  reconvirtieron a enlaces por archivo (`stow -D X && stow --no-folding X`),
  porque si no cualquier artefacto habría acabado dentro del repositorio.
  **`swappy` sigue plegado**: hoy no genera nada, pero si algún día lo hiciera
  hay que reconvertirlo antes.
- Migrado y validado:
  - **Hyprland** → `dotfiles/hypr/` (commit `f2c9f4d`).
  - **Shell** → `dotfiles/shell/` (`.bashrc`, `.bash_profile`; commit
    `a4dbf92`).
  - **swappy** → `dotfiles/swappy/` (`config`; commit `0bc8922`).
  - **hyprlock + hypridle** → `dotfiles/hypr/` (`hyprlock.conf`,
    `hypridle.conf`; commits `887cfb3`, `03f4bc5`, `0d8a364`, `b99f62d`,
    `c36e5c5`). Detalle en §9.
  - **Waybar** → `dotfiles/waybar/` (solo `claude-usage.sh` desde la tarea 3.0:
    `config.jsonc` y `style.css` pasaron a ser PLANTILLAS y su salida es un
    artefacto generado, ver §18). Tarea 2.1 completada. `waybar.service` habilitado, así
    que arranca sola con la sesión gráfica.
    ⚠️ **Dos valores dependen de este hardware y fallan sin dar error.** El
    módulo de batería fija `bat: BAT1` y `adapter: ADP1`, y el `on-click` del
    botón de apagado pasa a wlogout un margen de `400` px calculado a mano para
    1600x1000 lógicos (2560x1600 a escala 1.60). Si tras una reinstalación
    cambia la enumeración de `/sys/class/power_supply/`, el módulo de batería se
    queda **mudo sin registrar nada en el journal**; si cambia la resolución o
    la escala, el menú de apagado se deforma. Mismo patrón que el `ADP1` de
    `hypridle.conf` (§9). El módulo de red evita a propósito esta trampa: no
    fija `interface`, así que sigue a la ruta por defecto.
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
  - **dunst** → `dotfiles/dunst/` (`dunstrc`). Tarea 2.2 completada. Detalle
    en §16 (Notificaciones). **A diferencia de Waybar e hypridle, NO añade
    ningún requisito a `install/services.sh`**: dunst arranca por activación
    D-Bus con un archivo que instala el propio paquete, y su unidad es
    `static` (no admite `enable`). Es el primer componente del proyecto cuyo
    autoarranque se restaura solo.
  - **hyprpaper** → `dotfiles/hypr/` (`hyprpaper.conf`) **+ paquete nuevo
    `dotfiles/wallpapers/`** (las imágenes). Tarea 2.4 completada. Detalle en
    §17. **Es el primer componente que versiona binarios**: decisión razonada
    en §17, no descuido. **Desde el 2026-08-27 NO añade ningún requisito a
    `install/services.sh`**: `hyprpaper.service` está deshabilitado y lo lanza
    `hyprland.lua`, que sí se versiona. Antes de esa fecha era el cuarto
    requisito. Ver §17.
    ⚠️ **Su config NO sigue la sintaxis de la wiki**, que en hyprpaper 0.8.x se
    ignora en silencio. Leer §17 antes de tocarla.
    ⚠️ **`~/Wallpapers` debe quedar como UN enlace de directorio**, no como un
    directorio real con enlaces dentro. Al restaurar, no crearlo a mano: solo
    así las imágenes nuevas caen dentro del repo. Ver §17.
- Sin config todavía: `kitty`, `rofi`, `yazi`. Se difieren hasta que existan
  (o se cree una config mínima como tarea propia).

## 14. Tareas pendientes (fases futuras)

Las tareas de la fase inicial están completadas. Posibles siguientes pasos:

- Crear configs propias para Kitty, Rofi y yazi, y migrarlas a Stow.
- **Estado que vive fuera del repositorio y que una restauración NO recupera.**
  **Cinco** agujeros con el mismo final: el fallo es **silencioso**, nada avisa
  de que falta el paso. En los dos primeros los archivos vuelven a su sitio pero
  nada los activa; en los tres últimos el archivo ni siquiera vuelve.
  - `hypridle.service`: el `enable` solo deja rastro en
    `packages/services-enabled.txt`. Sin rehabilitarlo, la sesión no se
    bloquea sola nunca (ver §9).
  - `waybar.service`: habilitado el 2026-08-02. Sin rehabilitarlo tras una
    restauración, no hay barra: los archivos están, pero nadie los lanza.
  - `~/.claude/settings.json` → `statusLine.command`. El script está
    versionado y se enlaza con Stow, pero quien lo invoca es este archivo, que
    **no** se versiona porque contiene credenciales y estado de sesión. Sin él,
    el módulo de uso de Claude en Waybar se queda en `—` para siempre.
  - `~/.config/spotify-flags.conf`: creado a mano el 2026-08-03 y **no
    versionado**. Sin él, Spotify arranca en XWayland y se ve borroso otra vez
    (ver §7). Se arregla haciéndolo paquete Stow (`dotfiles/spotify/`), no con
    `install/services.sh`.
  - `~/.npmrc` (`prefix=/home/elok/.local`): **detectado el 2026-08-27**, en la
    auditoría de la tarea 2.5. Es lo que permite instalar globales de npm **sin
    sudo** y lo que pone a Codex CLI en `~/.local/lib/node_modules` (§10). No
    está versionado, así que tras una restauración `npm -g` volvería a escribir
    en `/usr` pidiendo sudo y la ruta que documenta §10 dejaría de ser cierta,
    sin un solo aviso. Mismo patrón y misma solución que `spotify-flags.conf`:
    un paquete Stow, no `install/services.sh` (roadmap 3.7).
  Decidir cómo cubrirlos: encaja con `install/services.sh` de la fase 6 (ver
  roadmap 6.1, marcado como requisito bloqueante).

## 15. Información sin verificar

- Si un cambio de VT recupera una pantalla apagada con `wlopm` cuando nadie va a
  ejecutar el `--on` (ver la trampa en §9). Sigue sin probarse, pero el
  2026-08-27 se comprobó lo que **no** la recupera: ni teclado ni ratón. Ahora
  que se sabe que `Ctrl+Alt+F3` funciona con Fn Lock, la prueba es fácil de
  hacer la próxima vez que ocurra.
- Estado de autenticación de Claude Code (no comprobado; no exponer credenciales).
- **[VER]** hyprlock registra `Starting fade in` pese a tener
  `animations { enabled = false }` en `hyprlock.conf`. Cosmético: no se ha
  observado efecto sobre el bloqueo ni sobre el desbloqueo. Sin resolver
  (2026-07-27).
- **[VER] Bluetooth: el kernel falla al cargar el firmware, pero el
  controlador responde.** En cada arranque aparece
  `Bluetooth: hci0: FW download error recovery failed (-19)` (más
  `sending frame failed` y `Failed to read MSFT supported features`), y sigue
  apareciendo igual tras actualizar `linux-firmware` a 20260810. Aun así,
  `bluetoothctl show` devuelve el controlador `90:09:DF:FF:DC:AE`.
  **No se comprobó `bluetoothctl` antes de actualizar, así que se desconoce si
  esto es una mejora o si ya era así.** Pendiente: emparejar un dispositivo real
  para saber si el Bluetooth funciona de verdad o solo lo parece (2026-08-24).

> **Falso positivo descartado — el wifi está bien.** En el journal aparece
> `iwlwifi: Direct firmware load for iwlwifi-gl-c0-fm-c0-c99.ucode failed with
> error -2`, seguido de `loaded firmware version 101.6ef20b19.0
> gl-c0-fm-c0-101.ucode`. Es el sondeo normal del driver, que prueba versiones
> de API de mayor a menor hasta dar con la instalada. **No es un fallo y no hay
> nada que arreglar**; sigue apareciendo tras actualizar `linux-firmware`
> porque es el comportamiento esperado. Anotado para no volver a perseguirlo.

## 16. Notificaciones (dunst)  **[OK]**

Tarea 2.2 completada (2026-08-04). `dunst` 1.13.2-1. Configuración en
`dotfiles/dunst/`, enlazada con Stow.

### El autoarranque NO es un hueco aquí — al contrario que en waybar e hypridle

Es la diferencia importante con las tareas 2.1 y 2.3, y conviene que conste
para **no** añadir dunst por inercia a `install/services.sh` (roadmap 6.1):

- El paquete instala `/usr/share/dbus-1/services/org.knopwob.dunst.service`,
  que declara `Name=org.freedesktop.Notifications`, `Exec=/usr/bin/dunst` y
  `SystemdService=dunst.service`. **Lo reinstala pacman**, así que sobrevive a
  una reinstalación sin ningún paso manual.
- `dunst.service` es **`static`**: no tiene sección `[Install]` y por tanto
  **no admite `enable`**. Es `Type=dbus` con
  `BusName=org.freedesktop.Notifications`.
- Quien lo arranca es la **activación D-Bus**, no un `enable` ni un
  `exec-once`. Verificado en el arranque del 2026-08-04: cgroup
  `user@1000.service/session.slice/dunst.service`, padre `systemd --user`.
- **Consecuencia práctica:** dunst arranca **bajo demanda**, con la primera
  notificación de la sesión. Un `pgrep dunst` vacío recién iniciada la sesión
  **no significa que esté roto**.
- **Sin daemon competidor:** el único `.service` de D-Bus que reclama
  `org.freedesktop.Notifications` en todo el sistema es el de dunst.
  `knotifications` (KF6) es una librería, no registra el nombre. Propietario
  comprobado en vivo: `GetServerInformation` → `"dunst" "knopwob" "1.13.2"`.

> **[OK] El arranque automático CON esta configuración quedó observado el
> 2026-08-04** (arranque de las 02:09), en el mismo arranque y sin ninguna
> intervención manual. Era la última afirmación sin validar de la tarea 2.2.
>
> **Qué faltaba y por qué.** Los dos hechos estaban probados por separado,
> nunca juntos. En el primer arranque del 2026-08-04 dunst se activó solo por
> D-Bus, pero con **defaults** — el `dunstrc` aún no existía, y el journal lo
> decía: `MESSAGE: No configuration file found, using defaults`. El proceso que
> sí cargaba la config del repo vino después de un `systemctl --user restart`
> **manual**. Faltaba ver ambas cosas en el mismo arranque.
>
> **Evidencia observada (2026-08-04, arranque `7632da49`):**
>
> - **Journal del punto 1**, íntegro y sin nada más: un único par
>   `02:10:31 Starting Dunst notification daemon...` /
>   `02:10:32 Started Dunst notification daemon.`. Ni una línea
>   `Stopping`/`Stopped` previa, y **ninguna** `No configuration file found,
>   using defaults`.
> - **Punto 2, las tres señales a la vez:** PID 1322, cgroup
>   `…/user@1000.service/session.slice/dunst.service`; proceso arrancado a las
>   `02:10:31` frente a `02:09:07` del sistema (**84 s** después);
>   `NRestarts=0`, `Type=dbus`, `UnitFileState=static`.
> - **Punto 3, geometría real:** `hyprctl layers` →
>   `xywh: 1162 46 426 64 … namespace: notifications, pid: 1322`. Ancho **426**
>   e **y=46**, los de la config del repo; los defaults habrían dado ~300 y
>   y=84. El `pid` de la capa **es el mismo proceso del arranque**, así que la
>   geometría no viene de una instancia posterior.
> - **Sin errores ni avisos nuevos.** `journalctl --user -b _COMM=dunst` →
>   *No entries* (en particular, ninguno de los `WARNING: Icon … not found in
>   icon_path` del 2026-08-03). El único mensaje que menciona a dunst en todo
>   el arranque es un aviso de convención de nombres de `dbus-broker-launch`
>   sobre `org.knopwob.dunst.service`, **preexistente** (mismo recuento en los
>   arranques `-1` y `-2`) y análogo al que emite para
>   `org.kde.dolphin.FileManager1.service`. No es de dunst ni es nuevo.
>
> **Cómo repetirlo si hace falta. Reiniciar y ejecutar esto como usuario normal
> (sin sudo):**
>
> ```bash
> # 1. ¿Se activó solo y cargó la config del repo?
> journalctl --user -u dunst.service -b --no-pager
> ```
>
> Tiene que aparecer un único par `Starting Dunst notification daemon...` /
> `Started Dunst notification daemon.` y, sobre todo, **NO** puede aparecer
> `MESSAGE: No configuration file found, using defaults`. Esa ausencia es la
> prueba de que leyó `~/.config/dunst/dunstrc`: dunst solo escribe esa línea
> cuando no encuentra ninguna configuración.
>
> ```bash
> # 2. ¿El proceso viene del arranque y NO de un reinicio manual?
> PID=$(pgrep -x dunst)
> cat /proc/$PID/cgroup                       # …/session.slice/dunst.service
> ps -o lstart= -p $PID                       # hora de arranque del proceso
> who -b                                      # hora de arranque del sistema
> systemctl --user show dunst.service -p NRestarts
> ```
>
> Las tres señales que deben darse a la vez: el cgroup termina en
> `dunst.service` (lo lanzó systemd, no una terminal), la hora del proceso está
> **a pocos minutos** de la del sistema, y `NRestarts=0`. Además, en el journal
> del punto 1 **no debe haber ninguna línea `Stopping`/`Stopped` anterior** al
> `Started` vigente: si la hay, ese proceso es fruto de un reinicio y la prueba
> no vale.
>
> ```bash
> # 3. Prueba positiva: que la config cargada es la del repo, no los defaults
> notify-send "prueba" "config del repo"
> hyprctl layers | grep -A2 'namespace: notifications'
> ```
>
> Debe dar un ancho de **426** y **y=46**. Con los defaults daría ~300 de ancho
> e y=84 (offset 50 sobre los 34 px reservados por Waybar). Es la comprobación
> que no depende de interpretar un mensaje ausente.
>
> Los tres puntos se dieron el 2026-08-04 y por eso este bloque ya es **[OK]**.
> Las instrucciones se conservan para reproducir la comprobación tras un cambio
> en `dunstrc`, una reinstalación o una actualización de dunst.

### `/etc/dunst/dunstrc` existe pero NO se lee

El paquete instala esa plantilla de 514 líneas, y **no está en la ruta de
búsqueda de esta versión**: con `~/.config/dunst/` vacío, el journal registraba
`No configuration file found, using defaults` *teniendo ese archivo presente*.
Es documentación de los defaults, nada más. La ruta que sí se lee es
`~/.config/dunst/dunstrc`.

### Cómo validar la config sin tocar la sesión

`dunst --config <ruta>` **con dunst ya corriendo**: parsea, escribe
`WARNING: Setting <clave> ... doesn't exist` por cada clave desconocida y
aborta con `CRITICAL: Cannot acquire 'org.freedesktop.Notifications'`. Ese
fallo es la garantía de que no puede sustituir a la instancia viva (verificado:
PID intacto tras la prueba). Hace falta porque **dunst no falla al arrancar con
una clave desconocida: la ignora y sigue**, así que una errata como
`widht = 420` no dejaría rastro en ningún journal.

> ⚠️ `dunstctl reload` **sin argumentos recarga los archivos anteriores**. Si
> dunst arrancó sin config (como aquí), «los anteriores» son *ninguno* y la
> recarga no carga nada — el journal lo dice con un engañoso
> `Reloading settings (with the old files)`. Tras enlazar por primera vez hay
> que reiniciar el servicio o pasar la ruta explícita.

### Decisiones de configuración

- **Wayland nativo, sin la trampa de XWayland.** `hyprctl layers` →
  `namespace: notifications` en el nivel **overlay**; no aparece en
  `hyprctl clients`. Es un cliente `wlr-layer-shell`, así que **no le afecta el
  borrón por escala 1.60** que sufrió Spotify (§7). `force_xwayland = false`
  se fija explícitamente por ser justo esa la trampa del equipo.
- **Respeta la zona exclusiva de Waybar.** El offset vertical se cuenta desde
  el borde de la zona reservada (34 px), no desde el borde físico. Con
  `offset = (12, 12)` la capa queda en `xywh: 1162 46 426 204` — 12 px de aire
  bajo la barra. Verificado contra `hyprctl layers`.
- **Paleta heredada de Waybar** (`style.css`): fondo `#16181d` siempre; lo que
  codifica la urgencia es el **color del marco**, no un fondo distinto por
  nivel — gris `#2a2e37` (baja), acento `#7aa2f7` (normal), rojo `#f7768e`
  (crítica). Radio de 6 px, el mismo que los tooltips de la barra.
  > **[HISTÓRICO desde la tarea 3.0.]** Lo anterior describe los colores y
  > métricas que dunst tuvo **cableados en `dunstrc` hasta el 2026-08-27**. Ya
  > no es así: los pone un **drop-in generado**
  > (`~/.config/dunst/dunstrc.d/50-theme.conf`), salen del fondo de pantalla y
  > el radio es el común del escritorio, no 6 px. `dunstrc` conserva el
  > comportamiento —historial, atajos, reglas, urgencias— y ningún color. Ver
  > §18.
  >
  > Aquel `#2a2e37` era además un **derivado calculado a mano**: el equivalente
  > opaco del `rgba(200,204,212,0.08)` de Waybar resuelto sobre `#16181d`,
  > porque dunst no admite alfa en `frame_color`. Era justo el tipo de valor que
  > obligaba a recalcular a mano al tocar la paleta, y es una de las razones por
  > las que se centralizó el tema.
- **Fuente:** `JetBrainsMono Nerd Font 10`. Pango mide en **puntos**: 10 pt a
  96 dpi = 13,3 px lógicos, que es el `font-size: 13px` de Waybar. El nombre de
  familia es el exacto de `fc-list` (existen variantes `NF`, `NFM`, `NL` que
  **no** son esta).
- **Tiempos:** baja 5 s, normal 10 s, **crítica `timeout = 0` (no expira
  nunca)**. Verificado: la crítica sigue en pantalla pasados 20 s.
  La normal se cerró con 8 s el 2026-08-04 y se subió a 10 s el mismo día,
  tras probarla en uso real.
- **`follow = mouse` en lugar de `monitor = 0`**, a propósito: así no se fija
  ningún identificador de pantalla. Con un solo monitor el comportamiento es
  idéntico y evita la clase de trampa de `BAT1`/`ADP1` (§9, §13).
- **Historial de 20**, `sticky_history = yes`. **Vive en la memoria del
  proceso**: se pierde entero si dunst se reinicia o se cierra la sesión. No
  hay opción para hacerlo persistente.
- **Atajos:** `Super + N` (`history-pop`) y `Super + Shift + N` (`close-all`).
  Sin `locked = true` en ninguno: con la sesión bloqueada dunst está pausado a
  propósito. Ver `docs/keybindings.md`.

### Dos defaults rotos que se corrigen aquí

Ambos fallaban **en silencio** con la configuración por defecto:

- **`dmenu` no está instalado** en este equipo, y es lo que dunst invoca por
  defecto (`/usr/bin/dmenu -p dunst:`) para el menú contextual
  (`dunstctl context`). Tal cual, esa función no hacía nada y no informaba de
  por qué. Se apunta a `rofi`, que sí está y ya es el lanzador del sistema.
- **El `icon_path` por defecto apunta a `/usr/share/icons/gnome/…`, que no
  existe aquí.** No era teórico: el journal del arranque del 2026-08-03 tenía
  `WARNING: Icon 'nm-no-connection' not found in icon_path` y
  `'nm-signal-100'` — las notificaciones de NetworkManager salían sin icono.
  Con `enable_recursive_icon_lookup` e
  `icon_theme = "Papirus-Dark, Adwaita"` los tres iconos resuelven y el aviso
  desaparece del journal. **Verificado 2026-08-04.**

### Notificaciones con la sesión bloqueada

`hypridle.conf` gana `on_lock_cmd = dunstctl set-paused true` y
`on_unlock_cmd = dunstctl set-paused false` (existen en hypridle 0.1.8:
cadenas `general:on_lock_cmd` / `general:on_unlock_cmd` en el binario).

- **`set-paused true` encola, no descarta, y RETIRA lo que ya estaba visible.**
  Dos comprobaciones distintas, ambas sin bloquear la sesión:
  - *Notificaciones nuevas* — con la pausa activa, dos dieron `Waiting: 2 /
    Currently displayed: 0`; al despausar, `Waiting: 0 /
    Currently displayed: 2`. **No se pierde ninguna.**
  - *Notificación ya en pantalla* — una crítica visible pasó a `Waiting: 1 /
    Currently displayed: 0` al pausar, y **la capa desapareció por completo**
    de `hyprctl layers`. Cubre el caso peor: una crítica (que no expira nunca)
    presente en el instante exacto del bloqueo. Verificado 2026-08-04.
- **Motivo:** dunst dibuja en la capa `overlay` y hyprlock usa
  `ext-session-lock`. **[VER] No se ha comprobado** si Hyprland 0.56 pinta la
  superficie de bloqueo por encima de esa capa; probarlo exige bloquear la
  sesión. La pausa cierra el hueco de privacidad **sin depender** de esa
  respuesta.
- **Refuerza el aviso de `inhibit_sleep`:** hasta ahora, subirlo a 3 solo
  rompía algo hipotético, porque no se usaba ninguna de las dos directivas.
  Desde el 2026-08-04 **sí** dependen de él. Sigue fijado en **2**.
- ⚠️ **TRAMPA:** el estado de pausa vive en el proceso de **dunst**, no en
  hypridle. Si hypridle muriera o se reiniciara con la sesión ya bloqueada, el
  `on_unlock_cmd` nunca llegaría y **dunst se quedaría pausado para siempre,
  sin avisar**: ni notificaciones ni error en ningún journal. Se diagnostica
  con `dunstctl is-paused` (→ `true`) y se arregla con
  `dunstctl set-paused false`. En el otro sentido falla hacia el lado seguro:
  la pausa no sobrevive a un reinicio de dunst ni al cierre de sesión.
- **[OK] Validado de extremo a extremo (2026-08-04)**: bloqueo real con
  `Super + L` y desbloqueo por contraseña. hypridle dispara `on_lock_cmd` al
  bloquear y `on_unlock_cmd` al desbloquear; `dunstctl is-paused` vuelve a
  `false` tras el desbloqueo. No queda ningún paso sin observar en este camino.

## 17. Fondo de pantalla (hyprpaper)  **[OK]**

Tarea 2.4 completada (2026-08-25). Toca **dos** paquetes Stow: la config va en
`hypr/` (que ya existía) y las imágenes en un paquete nuevo, `wallpapers/`.

- **hyprpaper 0.8.4-6** sobre Hyprland 0.56.2.
- Config: `dotfiles/hypr/.config/hypr/hyprpaper.conf`.
- Imágenes: `dotfiles/wallpapers/Wallpapers/`, **versionadas en el repo**.
- Arranque: `hyprland.lua`, `hl.on("hyprland.start", ...)`.
  `hyprpaper.service` está **deshabilitado** desde el 2026-08-27 (antes era la
  única vía). El porqué, medido, más abajo.
- Comportamiento: **una imagen aleatoria de la carpeta en cada arranque**, sin
  rotación mientras la sesión está viva.

### ⚠️ La sintaxis de la wiki no funciona, y falla en silencio

**Es lo más importante de esta sección.** hyprpaper 0.8.x se reescribió sobre
`hyprtoolkit` y cambió el esquema de configuración. El que documenta la wiki de
Hyprland, y prácticamente todo tutorial que se encuentre, es el clásico:

```
preload   = /ruta/imagen.png          <- IGNORADO en 0.8.4
wallpaper = eDP-1,/ruta/imagen.png    <- IGNORADO en 0.8.4
```

**Verificado (2026-08-25):** con esa configuración el resultado es idéntico al
de un archivo **vacío**. El log dice solo

```
Monitor eDP-1 has no target: no wp will be created
```

y **ningún error**. El fallo es perfecto en su silencio: proceso vivo, servicio
activo, cero mensajes, cero fondo. Quien copie la wiki buscará la avería donde
no está.

La causa es una asimetría de hyprlang, también verificada: una clave
desconocida **dentro de una categoría conocida** sí da error —
`config option <wallpaper:image> does not exist` — pero una clave desconocida en
el **nivel superior se acepta sin decir nada**. `preload` y `wallpaper = ...`
caen en el segundo caso.

El esquema real se dedujo de las cadenas del binario y se confirmó probando cada
clave contra `hyprpaper -c` con una config de usar y tirar:

```
wallpaper {
    monitor   =           # vacío = todas las salidas
    path      = ~/...     # archivo O DIRECTORIO; admite ~ y $HOME
    fit_mode  = cover     # cover | contain | tile
    order     = default   # default | random | random-shuffle
    recursive = false
    timeout   = 0         # segundos; 0 = sin rotación
}
splash_offset  = 2        # ENTERO
splash_opacity = 0
```

⚠️ **`splash_offset` es un entero.** Un `2.0` aborta **toda** la config con
`cannot parse "2.0" as an int` y te deja sin fondo. Verificado.

### `~/Wallpapers` es UN enlace de directorio, y eso es deliberado

**El detalle que hay que respetar al restaurar.** Stow puede desplegar este
paquete de dos formas muy distintas, y solo una da el flujo que se quería:

| Estado previo de `~/Wallpapers` | Qué hace Stow | Consecuencia |
|---|---|---|
| **No existe** | `LINK: Wallpapers => .../dotfiles/wallpapers/Wallpapers` — **un solo enlace de directorio** | Toda imagen que se deje caer en `~/Wallpapers` **aterriza en el repo** y aparece en `git status`. Sin copiar nada a mano. |
| Existe como directorio real | Enlaza **archivo por archivo** dentro de él | Las imágenes nuevas se quedan **fuera** del repo, en el directorio real. Se pierden en la siguiente reinstalación. |

Por eso el directorio se eliminó (vacío, con `rmdir`) antes de enlazar.

> ⚠️ **Al restaurar en una máquina nueva: NO crear `~/Wallpapers` a mano.**
> Dejar que lo cree `stow -d dotfiles -t ~ wallpapers`. Crearlo antes rompe el
> flujo en silencio: todo parece funcionar, el fondo se ve, y las imágenes que
> añadas después simplemente no se versionan.

### Cambio en cada arranque, no por tiempo

Pedido explícitamente: como los fondos por defecto de Hyprland. Se consigue con
`timeout = 0` (sin rotación en caliente) más `order = random` (elección inicial
aleatoria).

**Medido con `inotifywait` sobre el directorio**, porque hyprpaper no registra
en el log qué imagen carga y la diferencia entre los dos modos aleatorios no
está documentada en ninguna parte:

- `order = random` → punto de partida **aleatorio** y después ciclo
  **secuencial**: `img3 img4 img5 img1 img2 img3...`
- `order = random-shuffle` → barajado real, admite repeticiones seguidas:
  `img3 img5 img1 img4 img2 img1 img3...`

Con `timeout = 0` solo cuenta la primera elección, así que ambos valdrían.

**Verificado con 8 arranques consecutivos** (5 imágenes, `timeout = 0`,
`order = random`): cada arranque abre **una sola** imagen y **varía** entre
ejecuciones. La aleatoriedad es de calidad modesta —en esos 8 arranques
aparecieron 3 de las 5 imágenes— pero varía, que es lo que se pedía.

También quedó verificado que la rotación **por tiempo sí funciona** si algún día
se quiere: con `timeout = 3` abría una imagen distinta cada 3 s.

### Contenido de la carpeta

**Archivos no-imagen: inofensivos.** Verificado que hyprpaper los abre para
husmear el tipo con `libmagic` pero **no los selecciona**. Con un `.eps` y un
`.txt` junto a imágenes válidas funciona sin un solo aviso. Solo falla si **no
hay ninguna** imagen válida, y entonces lo dice claro:
`Provided path(s) '...' does not contain a valid image`.

**Proporción: no hay que preprocesar.** `fit_mode = cover` escala y recorta sin
deformar, así que se puede dejar caer cualquier imagen. El panel es 16:10
(2560×1600): una 16:9 pierde franjas laterales, una 2:1 pierde un 20% del ancho.

**Peso: sí conviene preprocesar.** La carpeta está en un repo **público** y git
guarda cada versión de cada binario entera y para siempre. Una imagen ajustada a
2560×1600 pesa ~530 KB frente a ~3 MB del original de 6000×3000, y hyprpaper no
nota la diferencia porque de todos modos recorta:

```
magick original.jpg -resize x1600 -gravity center -extent 2560x1600 \
       -quality 92 ~/Wallpapers/nombre.jpg
```

**`scripts/add-wallpaper.sh` automatiza todo lo anterior.** Recibe una imagen de
cualquier tamaño y proporción, la ajusta a 2560×1600 recortando desde el centro,
la convierte a JPEG q92 y la deja en `~/Wallpapers`:

```
scripts/add-wallpaper.sh ~/Descargas/loquesea.png [nombre-destino]
```

Comprueba que `~/Wallpapers` existe y **avisa si no es un enlace simbólico**,
porque ese es el fallo silencioso descrito arriba. Si la imagen de origen es
demasiado pequeña y habría que ampliarla, avisa de que se verá borrosa y pide
confirmación en vez de hacerlo sin más. **Verificado** el 2026-08-25: procesando
el original de 6000×3000 produce un resultado con **RMSE 0** frente al recorte
hecho a mano — píxel a píxel idéntico.

**Formato.** Para la primera imagen se compararon alternativas mirando la zona
de cielo oscuro ampliada al 300%, que es donde la compresión con pérdida se
delata: JPEG q92 (533 KB) sin artefactos visibles; WebP q90 (199 KB) con
**bloques visibles**; WebP sin pérdida (1,1 MB) y PNG (1,5 MB) irreprochables
pero al triple de peso sin diferencia observable. Se usa **JPEG q92**.

> **Un EPS vectorial NO es mejor que un JPG grande si el rasterizador falla.**
> La primera imagen venía con un `.eps` de Adobe Illustrator además del JPG, y
> lo lógico habría sido renderizarlo a resolución nativa exacta. **Se comparó y
> se descartó:** ghostscript no resuelve bien sus degradados y produce azul
> eléctrico sobresaturado con bandeado horizontal visible, muy lejos del índigo
> del original. Los originales sin procesar viven en
> `~/Descargas/wallpaper-originales/`, **fuera del repo**.

### Autoarranque: de `hyprpaper.service` a `hyprland.lua` (2026-08-27)

Hasta el 2026-08-27 hyprpaper arrancaba con su unidad de systemd, y era el
**cuarto** requisito bloqueante de `install/services.sh` (como waybar e
hypridle): en `hyprland.lua` no había ningún `exec-once` de respaldo. Ahora el
servicio está **deshabilitado** y lo lanza la config de Hyprland:

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("hyprpaper")
end)
```

**El motivo fue la latencia, no la restauración.** Al arrancar se veía durante
un instante el fondo por defecto de Hyprland antes de que apareciera el propio.
Eso tuvo dos causas independientes, y hicieron falta dos arreglos:

1. `misc:force_default_wallpaper = -1` seguía con el valor de la plantilla, así
   que Hyprland pintaba su mascota. Corregido a `0` + `disable_hyprland_logo =
   true`. Eso cambia **qué** se ve en el hueco, no el hueco.
2. El hueco en sí: hyprpaper llegaba tarde.

Cronología **medida** en el arranque del 2026-08-27 (tiempo monotónico desde el
boot, `systemctl --user show -p ...TimestampMonotonic` y el journal):

| t (s) | Suceso |
|-------|--------|
| 23,185 | systemd lanza Hyprland (`wayland-wm@hyprland.desktop.service`) |
| 25,084 | Hyprland avisa «listo» a systemd (`uwsm finalize`) · **+1,90 s** |
| 25,537 | `graphical-session.target` activo · **+0,45 s** |
| 25,598 | systemd lanza hyprpaper · **+0,06 s** |
| 25,627 | «Welcome to hyprpaper!» |
| 25,683 | hyprpaper ya ve la salida eDP-1 · **+0,09 s** |

**Por qué no se podía arreglar dentro de systemd.** La sesión va por **uwsm**:
`wayland-wm@hyprland.desktop.service` es `Type=notify` y no se da por activo
hasta que el compositor hace `uwsm finalize`; solo entonces arranca
`graphical-session.target` y con él hyprpaper. Y no vale adelantar la unidad con
un drop-in, porque `hyprpaper.service` lleva
`ConditionEnvironment=WAYLAND_DISPLAY` y esa variable **solo entra en el entorno
de systemd en ese mismo `finalize`**. Por la vía de systemd, ese instante es el
suelo: los 0,5 s de la tabla son irreducibles.

`hyprland.start` se dispara antes de ese aviso, así que lanzarlo desde la config
se salta el suelo entero.

**Lo que esto NO arregla, y conviene no prometerlo.** El hueco no desaparece:
Hyprland tiene que pintar su primer fotograma antes de que exista el socket al
que hyprpaper se conecta, así que **siempre** hay unos instantes sin fondo. Lo
que queda ahí es el color liso de `misc:background_color`, fijado a negro puro
(`0xff000000`) por ser el color del que ya viene la pantalla al salir de SDDM.
Hyprland no tiene fondo propio con imagen; no hay forma de que el primer
fotograma sea ya el wallpaper.

**Contrapartida:** se pierde el `Restart=on-failure` de la unidad. Si hyprpaper
muere a mitad de sesión, no vuelve solo. Para revertir: comentar el bloque en
`hyprland.lua` y `systemctl --user enable --now hyprpaper.service`.

**[HISTÓRICO] Verificación del arranque por systemd (2026-08-25, arranque de
las 19:19).** Describe el montaje anterior, sustituido el 2026-08-27; se
conserva porque documenta cómo se comprobó, que sigue valiendo. Entonces no
bastaba con `enabled` + `active` en caliente: se comprobó que el arranque era de
systemd y no algo heredado de la sesión de configuración.

```
19:19:39  systemd[900]: Started Fast, IPC-controlled wallpaper utility for Hyprland.
19:19:39  hyprpaper[1048]: Welcome to hyprpaper!
19:19:39  hyprpaper[1048]: Found 1 output(s)
```

`MainPID=1048`, dentro de
`/user.slice/user-1000.slice/user@1000.service/session.slice/hyprpaper.service`,
y **cero** coincidencias de `Config has errors`, `no target`, `Failed to resolve`
o `does not contain a valid image`. El enlace `~/Wallpapers` sobrevivió intacto.
Los tres servicios del hueco 6.1 —`hypridle`, `waybar`, `hyprpaper`— quedaron
`enabled` + `active` en el mismo arranque.


## 18. Tema del escritorio (matugen)  **[OK]**

Tarea 3.0, completada el 2026-08-27/28. **Todo el aspecto del escritorio sale de
dos archivos y de la imagen de fondo.**

- **Fuente única de valores**: `theme/tokens.toml` — tipografía, métricas,
  opacidades, colores de estado, colores ANSI del terminal, identidad y la
  configuración de la propia generación.
- **Fuente única de textos**: `theme/strings.toml`. Separados porque cambian por
  otros motivos: redacción o idioma, no estética.
- **Colores que siguen al fondo**: los pone **matugen 4.2** (repositorio `extra`,
  NO el AUR: `matugen-bin` entra en conflicto con él).
- **Un solo comando**: `theme-apply` (paquete Stow `bin` → `~/.local/bin`).

### El problema que resolvió

Cada componente definía sus colores por su cuenta: **cinco colores duplicados en
unas 25 apariciones literales** y en dos notaciones (hex y `rgba()` descompuesto).
Y algo peor que la duplicación: **convivían dos temas**, porque Waybar, dunst y
wlogout usaban Tokyo Night mientras Hyprland y hyprlock seguían con los
cian/verde/naranja de la plantilla de fábrica — justo lo que más se ve.

### Regla de oro

> **matugen no escribe JAMÁS sobre una ruta gestionada por Stow.**

Los enlaces de `~/.config` apuntan DENTRO del repositorio: escribir sobre uno
metería la salida generada en el repo o rompería el enlace. Las salidas usan
nombres que no existen en el repo, y `theme-apply.sh` **aborta** si detecta que
un destino es un symlink.

**La prueba de aceptación es objetiva: `git status` queda limpio después de
regenerar el tema.**

⚠️ Dos paquetes estaban enlazados como DIRECTORIO COMPLETO (`wlogout` y
`fastfetch`), con lo que cualquier artefacto habría caído dentro del repo. Se
reconvirtieron a enlaces por archivo con `stow -D X && stow --no-folding X`.

**Siguen plegados DOS, no uno** (corregido el 2026-08-28: aquí antes solo se
citaba `swappy`, y era una omisión, no un descuido inocuo — quien leyera esto
buscando dónde podía filtrarse un artefacto se habría dejado el más importante):

- **`swappy`** — no genera nada.
- **`matugen`** — `~/.config/matugen` es un enlace al directorio del repositorio.
  Es lo que hace que una plantilla nueva se vea sin volver a ejecutar Stow, y hoy
  es inofensivo porque matugen **lee** de ahí y no escribe nunca dentro: sus
  salidas van a los `output_path`, que apuntan a otros directorios. Pero es el
  paquete con más papeletas de romper la regla de oro si algún día se le
  configurase una salida relativa a su propio directorio.

Si cualquiera de los dos empezara a generar algo, mismo paso: `stow -D X &&
stow --no-folding X`.

### Reparto: quién conserva su config y quién se genera entera

No es una preferencia, lo decide **lo que cada formato permite**:

| Componente | Formato | Patrón |
|---|---|---|
| dunst | drop-in `dunstrc.d/*.conf` | Config en Stow + fragmento generado |
| hyprlock | `source =` de hyprlang | Config en Stow + fragmento generado |
| Hyprland | `dofile` de Lua | Config en Stow + tabla generada |
| Kitty | `include` | Config en Stow + fragmento generado |
| rofi | `?import` de rasi | Config en Stow + fragmento generado |
| **Waybar** | GTK CSS | **Config generada entera** |
| **wlogout** | GTK CSS | **Config generada entera** (el `layout` sí sigue en Stow) |
| **fastfetch** | JSONC sin `include` | **Config generada entera** |

GTK CSS solo tiene `@define-color`, que sirve para colores y para nada más: sin
variables numéricas, la única forma de que el tamaño de fuente o el radio salgan
de `tokens.toml` es generar la hoja completa. Y fastfetch no admite un segundo
archivo — su ayuda dice que los config "are merged", pero al pasarle dos responde
`Error: only one config file can be loaded`.

#### rofi: por qué su `?import` no puede leer del repositorio

Se sumó con la tarea 3.2 (2026-08-28) y encaja en el patrón de dunst/kitty, pero
con dos verificaciones propias que conviene no repetir a ciegas:

- **La interrogante de `?import` no es una errata.** Hace la importación
  OPCIONAL: si el artefacto no existe —repo recién clonado, Stow hecho y matugen
  aún sin ejecutar—, rofi arranca con su tema de fábrica en vez de abortar. Es el
  equivalente del `pcall` de Hyprland. Un error de SINTAXIS dentro del archivo
  sigue siendo un error, que es lo que se quiere. Rofi **no
  dependería** de `theme/fallback/` para arrancar —a diferencia de Waybar,
  wlogout y fastfetch, conserva su config versionada y se degrada solo—, pero
  entra igualmente en la reserva porque `--save-fallback` la construye a partir
  de los `output_path` del `config.toml`, no de una lista escrita a mano. Es
  deliberado: así un repo recién clonado abre el lanzador ya con la paleta del
  proyecto en vez de con el tema CLARO de fábrica.
- **Un import se resuelve junto al ENLACE, no junto a su destino.** El manual
  dice que se busca primero «en el directorio del archivo que lo incluye», y
  `config.rasi` es un enlace de Stow que apunta al repositorio. Comprobado el
  2026-08-28 con un montaje de prueba: con el archivo junto al enlace lo
  encuentra; junto al destino **no lo encuentra y no protesta**. O sea que rofi
  NO resuelve el enlace — igual que kitty, y al revés que hyprlock, que exigió
  ruta absoluta. Aquí juega a favor: es imposible que ese import acabe leyendo
  algo de dentro del repositorio, ni aunque un día apareciera ahí un
  `theme.rasi`.

⚠️ **Y una cuarta, que costó dos intentos: en rofi hay que declarar los NUEVE
estados de fila, no solo los que quieres cambiar.** rofi cruza tres estados de
fila (`normal` / `alternate` / `selected`) con tres de entrada (`normal` /
`urgent` / `active`), y **rellena con su tema de fábrica —que es CLARO— todo lo
que la plantilla no sobrescriba**. En el primer intento se declaró solo
`text-color` y se olvidaron los `alternate.*`: el resultado fue una lista con el
fondo beige del tema por defecto y encima el texto casi blanco del tema propio,
o sea filas alternas legibles y filas normales invisibles. No es un fallo de
color, es un fallo de COBERTURA. Si se añade un color, se añade en los nueve.

⚠️ **Dos trampas de sintaxis del .rasi, las dos silenciosas para las
comprobaciones obvias:**

1. `border` es `{Distancia} {Estilo}` y **no admite el color detrás**:
   `border: 2px solid transparent` aborta el tema entero con
   `unexpected Transparent, expecting property close (';')`. El color va en
   `border-color`.
2. **No se puede concatenar `@variable` con un sufijo de alfa.** `@urgent` más
   `26` se lee como el nombre de variable `urgent26` y rofi arranca avisando de
   que no resuelve. Los colores translúcidos se declaran ya con su alfa en el
   bloque `*`, donde los compone la plantilla.

**Y ninguna de las dos la enseña `rofi -dump-theme`, que devuelve stderr vacío**;
la primera la caza `rofi -no-config -theme ~/.config/rofi/theme.rasi
-dump-theme`, y la segunda **solo se ve abriendo rofi**. La verificación buena
de un cambio de tema en rofi es abrirlo y mirarlo.

### El modo `window` de rofi: dos límites del propio rofi

Ampliación del 2026-08-28, después de mirar el modo en pantalla por primera vez.

**El icono.** rofi pide el icono por el `app_id` de la ventana, en minúsculas.
Para Claude eso es `com.anthropic.claude`, pero la aplicación instala el suyo
como `claude-desktop.png`: nombres distintos, así que la fila salía sin icono
—y con el texto corrido a la izquierda, desalineando la columna—. **rofi no
puede remapearlo**, así que se arregla en la raíz, dándole al tema de iconos el
nombre que busca: el paquete Stow `icons` (§13) deja un alias en
`~/.local/share/icons/hicolor/`. Verificado: cero avisos `Failed to load image`.

**El nombre.** El modo `window` NO consulta los `.desktop`. El nombre bonito
existe —`com.anthropic.Claude.desktop` declara `Name=Claude` y
`StartupWMClass=com.anthropic.Claude`—, pero los únicos campos de
`window-format` son `w`/`t`/`n`/`r`/`c` y ninguno lo devuelve. Medido pintando
los tres en pantalla a la vez:

| Campo | En Wayland (wlr-foreign-toplevel) |
|---|---|
| `{w}` desktop | **vacío** — el protocolo no expone el workspace |
| `{n}` name | **vacío** — tampoco lo expone |
| `{c}` class | el `app_id` CRUDO (`firefox`, `kitty`, `com.anthropic.Claude`) |
| `{t}` title | el título de la ventana |

Así que la clase se retira de la vista y el formato queda en `{t}`. **No se
pierde nada al buscar**: `window-match-fields` es independiente del formato y
sigue en `"all"`, de modo que teclear «kitty» o «claude» encuentra esas ventanas
aunque la clase ya no se pinte; quién es cada una lo dice el icono. Contrapartida
asumida: la fila muestra el título del momento — para Claude hoy es «Claude»,
pero si algún día pone el nombre del chat, eso será lo que se lea.

### La barra de modos hay que enumerarla, no solo darle estilo

`mainbox` **solo dibuja los hijos que se le enumeran**, así que el
`mode-switcher` no aparece por muy bien que se le dé estilo: hay que meterlo en
`children`. Va abajo, con los modos inactivos en el gris apagado y el activo con
el mismo acento al 15 % que la fila seleccionada. Existe porque con un solo bind
y el ciclo en `Ctrl+Tab` no había nada en pantalla que anunciara los otros dos
modos. Sus botones son además clicables.

⚠️ Y necesita `expand: false` **en la barra y en los botones**: por defecto se
reparten todo el ancho y la píldora del activo acaba midiendo un tercio de la
ventana. Queda alineada a la izquierda; `horizontal-align: 0.5` para centrar el
grupo no hace nada aquí y se retiró en vez de dejarlo aparentando un efecto.

### Las transparencias de rofi son las de Waybar, a propósito

`.rasi` **no tiene la función `alpha()` de GTK CSS**, así que donde Waybar
escribe `alpha(@accent, opacity_active)` aquí hay que pegar el alfa al color como
sufijo hexadecimal. Desde la tarea 3.2, `theme-apply.sh` calcula ese sufijo para
**todas** las opacidades de `tokens.toml` y no solo para `surface`
(`opacity_surface_hex` conserva su nombre, así que las plantillas anteriores no
se enteran). El reparto copia el de las píldoras de workspace de la barra, para
que «lo seleccionado» se vea igual en toda la sesión:

| Papel | Opacidad | Equivalente en Waybar |
|---|---|---|
| Superficie flotante | `surface` (0.80) | la isla de la barra |
| Fila seleccionada | `active` (0.15) | workspace en uso |
| Campo de búsqueda | `separator` (0.08) | hover / divisores |
| Barra de scroll | `hint` (0.35) | contorno de workspace con ventanas |

La fila seleccionada lleva además texto y borde de acento, exactamente como el
workspace en uso — que es el único elemento de la barra con fondo propio.

Y una tercera, que es la razón de que su fragmento lleve un bloque
`configuration { }` además de colores: **rofi honra la configuración que le
llega por `?import`**, verificado porque tras importarlo `rofi -dump-config`
devuelve la clave puesta y sin comentar. Eso permite que los rótulos de los
modos («Aplicaciones», «Ventanas», «Archivos») salgan de `theme/strings.toml`
como los de hyprlock, en vez de quedarse escritos a mano en un segundo sitio.

⚠️ **La unidad de la fuente de rofi es el PÍXEL, no el punto, y a propósito.**
Pango lee un número suelto como puntos, y el DPI que usaría rofi se lo calcula
él solo: divide los 2560 px del panel entre la escala ENTERA que ve —2, porque
redondea el 1.60 de Hyprland— y entre los 340 mm, lo que da 96 dpi. Hoy da igual
(medido: `13px` y `10` producen exactamente la misma altura, 146 px lógicos con
cinco filas), pero ese 96 es frágil: si la escala del panel bajara a 1.0, la
escala entera pasaría a 1, el DPI derivado saltaría a ~191 y los PUNTOS casi
duplicarían la letra. Los píxeles no se mueven, y además son la misma unidad que
las distancias del `.rasi`. Ver el bloque «Lanzador (rofi)» de `tokens.toml`.

### Artefactos (ninguno se versiona)

```
~/.config/waybar/style.css · config.jsonc      ~/.config/hypr/theme.conf · theme.lua
~/.config/dunst/dunstrc.d/50-theme.conf        ~/.config/kitty/theme.conf
~/.config/wlogout/style.css · icons/*.png      ~/.config/fastfetch/config.jsonc
~/.config/rofi/theme.rasi
```

`~/.config/wlogout/icons/` es **el único punto del tema que genera binarios**:
los iconos del paquete son PNG lila y GTK3 no sabe teñir una imagen de fondo
desde CSS, así que se recolorean con `magick -colorize 100`, que conserva el
canal alfa y por tanto el recorte.

### Regeneración

- **En cada arranque**, desde el `hl.on("hyprland.start")` de `hyprland.lua`,
  después de hyprpaper. Necesario porque hyprpaper sortea una imagen distinta
  cada vez (`order = random`) y si no el escritorio arrancaría con la paleta del
  fondo anterior.
- **Al cambiar de fondo**, desde `scripts/add-wallpaper.sh`.
- El fondo en uso se consulta con `hyprctl hyprpaper listactive`.

**Red de seguridad**: `theme/fallback/` guarda una copia congelada de los
artefactos (`--save-fallback` la actualiza, `--fallback` la instala). Existe
porque Waybar, wlogout y fastfetch NO tienen config versionada: un repo recién
clonado, con Stow hecho y matugen aún sin ejecutar, se quedaría sin barra y sin
menú de apagado.

> ⚠️ **La reserva se queda vieja en silencio si nadie la regenera.** Al añadir
> rofi (3.2, 2026-08-28) se descubrió que el `MANIFEST` **no incluía `wlogout`**
> —añadido en su día sin volver a ejecutar `--save-fallback`— y que la copia de
> fastfetch ya no coincidía con el artefacto. Nada avisaba: el fallo solo se
> habría visto el día de una restauración, que es justo el día en que no quieres
> descubrirlo. **Al añadir o cambiar una plantilla, toca `--save-fallback`.**

> ⚠️ **La reserva CONGELA rutas absolutas, y eso es inherente a lo que es.** Un
> artefacto puede llevar `/home/elok` dentro —`hypr__theme.conf` guarda la ruta
> del fondo, y `wlogout__style.css` las de sus cuatro iconos, porque GTK no
> expande `~` dentro de un `url()`—. En una restauración con otro nombre de
> usuario esas rutas no existirían: el fondo del bloqueo caería a color liso y
> los botones de apagado saldrían sin icono. **No se arregla, se sobrescribe**:
> a la primera ejecución de `theme-apply` los artefactos se regeneran con el
> home correcto. La reserva es un puente hasta esa primera ejecución, no una
> config portable. Hyprland tiene además su propio respaldo en un `pcall`, porque
si a él le falta el tema no te quedas sin colores: te quedas sin gestor de
ventanas configurado.

### Qué NO sigue al fondo de pantalla, y por qué

- **Colores de estado** (`crit`/`warn`/`ok`) y los **16 ANSI del terminal**: son
  información, no decoración. Una batería crítica o un `git diff` tienen que
  leerse igual con cualquier wallpaper.
- Los ANSI tienen además un motivo medido: **la paleta base16 de matugen es
  inservible para un terminal**. Con el fondo actual devuelve `base08 #0b001b`,
  `base09 #00061a`, `base0a #00091d` — "rojo", "amarillo" y "verde" son el mismo
  azul casi negro.

### Ajustes del generador

Todo en `[matugen]` de `tokens.toml`, y todo medido con `--dry-run`:

- **El "pastel de matugen" no es culpa del scheme sino del ROL**: `primary` en
  modo oscuro es siempre el tono 80, claro y desaturado. Los tonos crudos de la
  misma paleta sí tienen color, y de ahí sale el acento (`accent_tone`).
- **Subir `--contrast` DESATURA**: de 0.3 a 0.5 el acento pasa de sat 33 % a
  19 %. Para separar del fondo aclara, y al aclarar lava. Subirlo no aviva el
  tema, lo apaga.
- **`--source-color-index` es obligatorio**: sin fijarlo, matugen abre un prompt
  interactivo cuando la imagen ofrece varios candidatos, y en el arranque eso
  dejaría el script colgado en silencio.

### Trampas del motor de plantillas

1. **Las claves importadas van planas** (`state_crit`, no `colors.state.crit`):
   matugen toma lo que sigue al último punto por un FORMATO de color y aborta con
   `Parse Error: The format provided is not valid`.
2. **Los filtros solo aceptan literales**, no variables importadas, y
   `palettes.*` no existe en plantilla (solo `colors.*`). De ahí que
   `theme-apply.sh` haga **dos pasadas**: la primera resuelve el acento y
   armoniza las identidades, la segunda renderiza.
3. **Los comentarios no protegen nada**: escribir la sintaxis de llaves dobles
   dentro de un comentario rompe el render.

Cada aplicación mide a su manera y `tokens.toml` declara cada valor UNA vez y en
UNA unidad; las conversiones (alfa hexadecimal, colores sin almohadilla para
hyprlang, ruta absoluta del home) las hace el script.
