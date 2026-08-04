# Atajos de teclado (Hyprland)

> Este archivo se genera a partir de
> [`dotfiles/hypr/.config/hypr/hyprland.lua`](../dotfiles/hypr/.config/hypr/hyprland.lua)
> y debe actualizarse cada vez que cambien los binds de esa config. Contrastado
> con `hyprctl binds` el 2026-07-22, el 2026-08-01 (53 binds) y el 2026-08-04
> (**55 binds**, tras los dos de dunst): todos los atajos documentados coinciden
> con los cargados en la sesión actual.

`Super` es la tecla `mainMod` de la config (`SUPER`, la tecla "Windows").

## Aplicaciones

| Atajo      | Acción                                              |
|------------|------------------------------------------------------|
| Super + Q  | Abrir terminal (`kitty`)                              |
| Super + E  | Abrir gestor de archivos (`dolphin`)                  |
| Super + R  | Abrir lanzador de aplicaciones (`rofi -show drun`)    |

## Gestión de ventanas

| Atajo               | Acción                                                        |
|----------------------|----------------------------------------------------------------|
| Super + C            | Cerrar la ventana activa                                       |
| Super + V            | Alternar ventana flotante / anclada                             |
| Super + P            | Alternar modo pseudo-tiling                                     |
| Super + J            | Alternar orientación del split (layout dwindle)                 |
| Super + clic izq. + arrastrar  | Mover la ventana con el ratón                          |
| Super + clic der. + arrastrar  | Redimensionar la ventana con el ratón                  |

## Foco y navegación

| Atajo             | Acción                              |
|--------------------|--------------------------------------|
| Super + ←          | Mover el foco a la ventana de la izquierda |
| Super + →          | Mover el foco a la ventana de la derecha   |
| Super + ↑          | Mover el foco a la ventana de arriba        |
| Super + ↓          | Mover el foco a la ventana de abajo         |

## Workspaces

| Atajo                  | Acción                                                          |
|--------------------------|--------------------------------------------------------------------|
| Super + 1…0              | Cambiar al workspace 1–10 (la tecla `0` corresponde al workspace 10) |
| Super + Shift + 1…0      | Mover la ventana activa al workspace 1–10 (`0` = workspace 10)       |
| Super + rueda ↓           | Ir al siguiente workspace existente                                |
| Super + rueda ↑           | Ir al workspace existente anterior                                  |
| Super + S                | Alternar el workspace especial (scratchpad) `magic`                 |
| Super + Shift + S         | Mover la ventana activa al workspace especial (scratchpad) `magic`  |

## Capturas de pantalla

| Atajo             | Acción                                                                                                                    |
|--------------------|------------------------------------------------------------------------------------------------------------------------------|
| Print              | Seleccionar una región (`slurp`) y copiarla al **portapapeles**. No se guarda ningún archivo.                                |
| Ctrl + Print        | Capturar la **pantalla completa** y copiarla al portapapeles. No se guarda ningún archivo.                                   |
| Shift + Print       | Seleccionar una región y **guardarla como archivo** en `~/Screenshots/AAAAMMDD-HHMMSS.png`. No toca el portapapeles.         |
| Super + Print       | Seleccionar una región y abrirla en **swappy** para anotarla. Al guardar dentro de swappy (`Ctrl+S`), escribe en `~/Screenshots/swappy-AAAAMMDD-HHMMSS.png`, según [`dotfiles/swappy/.config/swappy/config`](../dotfiles/swappy/.config/swappy/config). |

Durante la selección de región con `slurp` (Print, Shift+Print, Super+Print), la
captura se cancela con `Esc` o clic derecho.

## Multimedia y hardware

Todos los atajos de esta sección tienen `locked = true`: funcionan también con
la sesión bloqueada.

> ⚠️ **Es una decisión consciente, no un descuido.** Con hyprlock en pantalla,
> cualquiera que esté delante del equipo puede subir y bajar el volumen y el
> brillo, silenciar el micrófono y controlar la reproducción (pausa, pista
> siguiente y anterior) **sin introducir la contraseña**. No dan acceso a datos
> ni a la sesión. Si alguna vez se quiere cerrar ese hueco, basta con quitar
> `locked = true` del bind correspondiente en `hyprland.lua`.

| Atajo                    | Acción                                          |
|----------------------------|----------------------------------------------------|
| XF86AudioRaiseVolume       | Subir volumen 5% (límite superior 100%, `wpctl`)    |
| XF86AudioLowerVolume       | Bajar volumen 5% (`wpctl`)                          |
| XF86AudioMute              | Alternar silencio de la salida de audio             |
| XF86AudioMicMute           | Alternar silencio del micrófono                     |
| XF86MonBrightnessUp        | Subir brillo de pantalla 5% (`brightnessctl`)       |
| XF86MonBrightnessDown      | Bajar brillo de pantalla 5% (`brightnessctl`)       |
| XF86AudioNext              | Siguiente pista (`playerctl`)                       |
| XF86AudioPause             | Pausar/reanudar reproducción (`playerctl`)          |
| XF86AudioPlay              | Pausar/reanudar reproducción (`playerctl`)          |
| XF86AudioPrev              | Pista anterior (`playerctl`)                        |

## Notificaciones (dunst)

| Atajo             | Acción                                                                          |
|--------------------|------------------------------------------------------------------------------------|
| Super + N          | Recuperar la última notificación cerrada (`dunstctl history-pop`).                  |
| Super + Shift + N  | Cerrar todas las notificaciones en pantalla (`dunstctl close-all`).                 |

Una notificación recuperada con `Super + N` se queda **fija** hasta cerrarla
(`sticky_history = yes`), en vez de volver a expirar a los 5–10 segundos. El
historial guarda **20** y **vive en la memoria del proceso**: se pierde entero
si dunst se reinicia o se cierra la sesión.

Ninguno de los dos lleva `locked = true`: con la sesión bloqueada dunst está
**pausado a propósito** (ver `on_lock_cmd` en `hypridle.conf`), así que sacar
notificaciones del historial sobre hyprlock sería justo lo contrario de lo que
se busca. Detalle en `docs/PROJECT_CONTEXT.md` §16 (Notificaciones).

Con el ratón: **clic izquierdo** cierra la notificación bajo el puntero, **clic
derecho** las cierra todas y **clic central** ejecuta su acción por defecto (por
ejemplo, abrir el mensaje en la aplicación que lo envió).

## Sesión

| Atajo      | Acción                                                                                          |
|------------|----------------------------------------------------------------------------------------------------|
| Super + L  | Bloquear la pantalla (`loginctl lock-session` → hypridle lanza hyprlock).                          |
| Super + M  | Salir de Hyprland: ejecuta `hyprshutdown` si está disponible; si no, cierra la sesión de Hyprland. |

`Super + L` va por dbus y **no** invoca `hyprlock` directamente: así hypridle
recibe el evento y ejecuta su `lock_cmd`, el mismo camino que usan el bloqueo
por inactividad (600 s) y `before_sleep_cmd`. No lleva `locked = true`: con la
sesión ya bloqueada no debe hacer nada. Detalle en
`docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) → «Bloqueo de pantalla e
inactividad».

## Acciones de ratón (Waybar)

> Este documento es de atajos de **teclado**, así que esta sección es una
> excepción deliberada. Se incluye aquí porque **no hay ningún otro sitio
> consultable donde consten**: las acciones viven repartidas por las claves
> `on-click` de
> [`dotfiles/waybar/.config/waybar/config.jsonc`](../dotfiles/waybar/.config/waybar/config.jsonc),
> y sin esto la única forma de saber qué hace cada módulo es leerse la config.
> Verificadas contra `config.jsonc` el 2026-08-02.

| Módulo | Acción | Efecto |
|---|---|---|
| Reloj | Clic izquierdo | Alterna entre `HH:MM` y la vista larga con día y fecha (`format-alt`). El tooltip muestra el calendario del mes. |
| Volumen | Clic izquierdo | Abre **pavucontrol**. |
| Volumen | Clic derecho | Silencia / desilencia la salida (`wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`). |
| Red | Clic izquierdo | Abre **nmtui** en una ventana de kitty (`kitty -e nmtui`). |
| Perfil de energía | Clic izquierdo | **Rota** entre `performance`, `balanced` y `power-saver`. Es comportamiento nativo del módulo por D-Bus; no hay `on-click` definido. |
| ⏻ Apagado | Clic izquierdo | Abre **wlogout** (`wlogout -b 4 -m 400 -s`): bloquear, salir, reiniciar, apagar. Sin hibernar — este equipo no puede (`PROJECT_CONTEXT.md` §5). |
| Bluetooth | Clic izquierdo | Abre **blueman-manager**. |

**Rueda sobre el volumen** — sube y baja en pasos del **1 %**, con tope al
100 %. El paso es de 1 y no de 5 a propósito: el touchpad emite muchísimos más
eventos que la rueda para el mismo gesto y con 5 el volumen se disparaba.

> ⚠️ **Con el touchpad, la dirección va invertida.** No es un fallo: Hyprland
> tiene `natural_scroll` desactivado para la rueda y activado para el touchpad,
> así que ambos envían direcciones **opuestas**. Waybar solo recibe «arriba» o
> «abajo» y no puede distinguir el origen, de modo que cualquier elección deja
> uno de los dos al revés. Se conserva el comportamiento por defecto: **la
> rueda queda correcta**. Corregir el touchpad rompería la rueda, y tocar el
> natural scrolling no es opción (invariante del proyecto, `CLAUDE.md`).

> ⚠️ **El clic en los workspaces NO cambia de workspace.** Es el único control
> de la barra que no responde, y falla **en silencio**: no pasa nada y no se
> registra ningún error. Waybar 0.15 envía por IPC la sintaxis clásica
> `dispatch workspace N`, que Hyprland 0.56 con configuración Lua rechaza.
> No tiene arreglo desde la configuración y **está asumido**: se navega con
> `Super + N`. Detalle en `docs/PROJECT_CONTEXT.md` §7 (Entorno gráfico).
