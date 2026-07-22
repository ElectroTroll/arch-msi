# Atajos de teclado (Hyprland)

> Este archivo se genera a partir de
> [`dotfiles/hypr/.config/hypr/hyprland.lua`](../dotfiles/hypr/.config/hypr/hyprland.lua)
> y debe actualizarse cada vez que cambien los binds de esa config. Contrastado
> con `hyprctl binds` el 2026-07-22: todos los atajos documentados coinciden con
> los cargados en la sesión actual.

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

## Sesión

| Atajo      | Acción                                                                                          |
|------------|----------------------------------------------------------------------------------------------------|
| Super + M  | Salir de Hyprland: ejecuta `hyprshutdown` si está disponible; si no, cierra la sesión de Hyprland. |
