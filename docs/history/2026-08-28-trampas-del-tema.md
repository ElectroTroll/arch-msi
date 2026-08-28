# 2026-08-28 · Trampas encontradas montando el tema centralizado

Registro de los fallos que costaron tiempo durante la tarea 3.0. Casi todos
comparten una característica: **no dan error**. La configuración se acepta, el
proceso arranca, el journal calla — y el resultado no es el esperado.

Se anotan aquí porque la mitad no son específicos de este proyecto: reaparecerán
al configurar Rofi, yazi o el tema GTK.

La arquitectura del tema está en `PROJECT_CONTEXT.md` §18; esto es solo el
anecdotario técnico.

---

## 1. `transparency` de dunst es «(X11 only)»

Las notificaciones seguían opacas con `transparency = 25`. La clave **se acepta
sin protestar y no hace nada** en Wayland; su propio manual la marca como
*(X11 only)* y remite a poner el canal alfa en el color (`#RRGGBBAA`).

**Lección**: cuando algo no se ve, releer el manual buscando el paréntesis de la
plataforma antes de dudar del resto de la cadena.

## 2. El `source` de hyprlock no puede ser relativo

`source = theme.conf` fallaba con `globbing error: found no match`, dejando
TODAS las variables sin definir. Motivo: `hyprlock.conf` es un **enlace de
Stow**, y hyprlang resuelve la ruta contra el archivo real —dentro del
repositorio—, donde no hay ningún `theme.conf`.

Contraste que conviene retener: en Waybar el `@import` relativo **sí** funciona,
porque allí `style.css` es un artefacto real y no un enlace. Y en Kitty también,
porque resuelve los `include` respecto al directorio de la config.

**Lección**: con Stow, «relativo a este archivo» significa relativo al destino
del enlace, que casi nunca es lo que uno quiere.

## 3. `require` de Lua no sirve para cargar el tema de Hyprland

Mismo problema que el anterior: `require` busca por `package.path`, que no
incluye `~/.config/hypr`. Se usa `dofile` con la ruta construida desde `$HOME`.

## 4. Firefox ignora las variables de tema desde `userChrome.css`

Definir `--lwt-accent-color`, `--toolbar-bgcolor` y compañía en `:root` con
`!important` —lo que recomienda medio internet— **no hace absolutamente nada** en
Firefox 154. Mozilla las alimenta desde el objeto del tema, no desde el CSS del
usuario. Estilar los elementos concretos (`#nav-bar`, `#navigator-toolbox`…) sí
funciona.

Y el atributo `selected` de las pestañas **lo lleva el `<tab>`, no su fondo**:
`.tab-background[selected]` no aplica nunca; hay que escribir
`.tabbrowser-tab[selected] .tab-background`.

La transparencia del chrome resultó inalcanzable: el alfa es válido, pero la
ventana se pinta opaca, y `widget.wayland.opaque-region.enabled = false` tampoco
cambió nada. **La tarea de Firefox se abandonó y se revirtió por completo.**

## 5. `-gtk-outline-radius` lleva prefijo

GTK **no** aplica `border-radius` al `outline`: es una propiedad aparte. En GTK
3.24 se llama `-gtk-outline-radius`; `outline-radius` a secas no existe y se
descartaría en silencio. Sin ella, el anillo de foco del teclado se dibuja
cuadrado dentro de un botón redondeado.

## 6. wlogout acepta CSS inválido sin rechistar

Se lanzó desde terminal con `background-color: ESTO-NO-ES-COLOR` a propósito:
**ni un aviso**. En wlogout, la ausencia de errores no prueba nada. La única
verificación válida es mirar el resultado — en la práctica, capturar la pantalla
con `grim` y muestrear píxeles.

Su rejilla GTK reparte además el espacio sobrante de forma asimétrica, así que
el último botón salía más ancho. Se corrige fijando `min-width` y `min-height`
al mismo valor.

## 7. El peso de una fuente no se pega al nombre

`"JetBrainsMono Nerd Font Bold"` **no es una familia**: fontconfig no la
encuentra y cae en **Noto Sans Mono** sin decir nada. Los nombres reales son
`JetBrainsMono NF Medium`, `NF SemiBold`, `NF ExtraBold`. Se comprueba con
`fc-match "nombre"` antes de usarlo.

## 8. Waybar por señal se rompe bajo systemd

`kill -SIGUSR2 waybar` hace que Waybar se RE-EJECUTE; systemd lo cuenta como
muerte del proceso principal, salta `Restart=on-failure` y a la tercera recarga
se agota `StartLimitBurst`: la unidad queda en `failed` **y te quedas sin
barra**. El manual tiene razón sobre la señal, pero no contempla que Waybar
arranque como servicio. Se recarga con `systemctl --user restart waybar.service`.

Y `height` en `config.jsonc` es la altura de la SUPERFICIE: con la barra
flotante, el margen del CSS se descuenta por dentro. Quedarse corto no da error,
Waybar agranda la superficie por su cuenta y la isla deja de estar centrada.

## 9. Dos bugs propios que ensuciaron el repositorio

- **El enlace rompía el script.** Invocado como `theme-apply` (desde
  `~/.local/bin`), `BASH_SOURCE` es el enlace, así que el repo se calculaba como
  `~/.local`. Resuelto con `readlink -f`. Sin eso, el arranque automático no
  habría funcionado.
- **Colisión de variables.** La ruta de la reserva se llamaba `FALLBACK`, igual
  que la variable donde un `read` posterior recoge `seed_fallback`, que es un
  COLOR. `--save-fallback` creó un directorio llamado `#7aa2f7` en la raíz del
  repositorio.

## 10. Medir, no mirar

Dos veces se dio por roto algo que funcionaba, por juzgar colores a ojo:

- El tema de Firefox se creía sin aplicar; el muestreo de píxeles demostró que
  los colores eran los declarados. `#1d252c` (nuestro gris azulado) y `#2b2a33`
  (el de Firefox Dark) son indistinguibles a simple vista.
- Un primer muestreo usó la geometría equivocada de la ventana y midió **la
  terminal de al lado**. Se detectó porque un punto devolvió `#1e293b`, un color
  de hoja de estilos web.

El método que sí funciona:

```
hyprctl clients -j | jq '.[] | select(.class=="X") | {at, size}'
grim captura.png
magick captura.png -format '%[pixel:p{X,Y}]' info:
```

Recordando que las coordenadas de Hyprland son **lógicas** y las de la captura
**físicas**: en este panel hay que multiplicar por la escala 1.6.
