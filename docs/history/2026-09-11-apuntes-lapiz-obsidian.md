# Apuntes con teclado y lápiz: por qué Obsidian + Ink

**Fecha:** 2026-09-11
**Estado:** resuelto · en uso

## El encargo

Una forma de tomar apuntes escribiendo con el teclado y **dibujando con el
lápiz en el mismo documento**, sin cambiar de aplicación. En corto: "Google
Docs, pero pudiendo dibujar dentro".

## Punto de partida: el hardware ya estaba entero

Antes de buscar aplicaciones se auditó el digitalizador, porque toda la decisión
dependía de qué era capaz de reportar. `ELAN9024:00 04F3:4297`, expuesto por
Hyprland 0.56.2 en dos secciones de `hyprctl devices` a la vez: `Tablets`
(sufijo `-stylus`) y `Touch`.

De `/proc/bus/input/devices`, `ABS=1000d000003` y `KEY=1c03` decodifican a:

| Capacidad | Bit | Significado |
|-----------|-----|-------------|
| `ABS_PRESSURE` | 0x18 | presión |
| `ABS_TILT_X` / `ABS_TILT_Y` | 0x1a / 0x1b | inclinación |
| `BTN_TOOL_PEN` | 0x140 | punta |
| `BTN_TOOL_RUBBER` | 0x141 | **goma trasera** |
| `BTN_STYLUS` / `BTN_STYLUS2` | 0x14b / 0x14c | dos botones |

Más `PROP=2` = `INPUT_PROP_DIRECT`: el lápiz apunta sobre el propio panel, no
sobre una superficie remota. **No hubo que instalar ni configurar ningún
driver.**

## El hallazgo que cambió el plan: Firefox miente

La primera idea fue medir el comportamiento del lápiz con una página de prueba
(`PointerEvent.pointerType`, `pressure`, `tiltX/Y`) abierta en el navegador ya
instalado. **Habría dado un falso negativo**: Firefox bajo Wayland reporta el
lápiz como `"mouse"`, sin inclinación ([Bugzilla 1606832][moz]). Chromium sí lo
reporta como `"pen"`.

Conclusión que se queda: **el stack web solo es evaluable en Chromium**. Y como
corolario práctico, cualquier app de dibujo web hay que abrirla ahí.

[moz]: https://bugzilla.mozilla.org/show_bug.cgi?id=1606832

## Alternativas consideradas

| Opción | Por qué no |
|--------|------------|
| **Xournal++** | Lápiz impecable y GTK3 nativo, pero el texto son cajas colocadas sobre página fija: no fluye ni se reajusta. **Se instaló igualmente**, como plan B y para PDF. |
| **Rnote** | Mejor motor de trazo y lienzo infinito, pero su herramienta de texto es demasiado pobre para apuntes tecleados. |
| **AFFiNE** | Doc y pizarra en el mismo archivo, pero el modo *edgeless* es un lienzo aparte, y arrastra el mismo riesgo de Electron con mucho más peso. |
| **Obsidian + Ink** | **Elegida.** Es la única que mete el dibujo *entre párrafos* de un documento de texto que fluye. |

Se instaló también **Excalidraw** junto a Ink: cubre el caso distinto de los
diagramas grandes, y es el plugin más maduro de los dos (7,6k ★ frente a 1,4k, y
release cuatro días antes de la instalación).

## El riesgo que no se materializó

Había un bug documentado de lápiz en Electron/Wayland que afecta justo a estos
plugins ([obsidian-excalidraw-plugin#1914][ex1914]), así que se dio por probable
tener que forzar XWayland. Se comprobó que Obsidian arranca en **Wayland
nativo** (`"xwayland": false`) y **aun así el lápiz dibuja**.

La hipótesis de por qué: los reportes del bug son con tabletas externas
*indirectas*; aquí el digitalizador es `INPUT_PROP_DIRECT`. No se ha verificado
que esa sea la causa.

Por si una actualización de `electron43` lo rompe, queda preparado
`~/.config/obsidian/user-flags.conf` con `--ozone-platform=x11` comentado.

[ex1914]: https://github.com/zsviczian/obsidian-excalidraw-plugin/issues/1914

## Secuela inmediata

Al conectar el monitor externo, el lápiz y el táctil aparecieron descalibrados.
No tiene nada que ver con Obsidian —es el mapeo de entrada de Hyprland— y se
trata en `2026-09-12-lapiz-dos-pantallas.md`.

## Estado final

- Obsidian 1.13.7-2 + Ink 0.5.6 + Excalidraw 2.27.3, vault en
  `~/Documentos/Apuntes` (no versionado).
- Xournal++ 1.3.7-1 instalado como alternativa para página fija y PDF.
- Detalle técnico vigente en `PROJECT_CONTEXT.md` §26.
