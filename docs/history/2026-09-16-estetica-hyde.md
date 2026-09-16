# 2026-09-16 · La estética de HyDE con nuestros colores, y tres trampas silenciosas

El encargo: *que Dolphin, y el tema en general, sigan la estética de
github.com/Hyde-project/hyde, manteniendo el esquema de colores y transparencias
que ya usamos*. O sea, sus formas y nuestra paleta.

Lo primero fue clonar su repositorio —163 MB— y leer el original, en vez de ir
de memoria sobre un proyecto conocido.

---

## 1. Qué había que traer, y qué ya coincidía

| Aspecto | HyDE | Aquí, antes |
|---|---|---|
| Config de Hyprland | **Lua** | Lua — ya coincidía |
| Radio de esquinas | 10pt | 10 — ya coincidía |
| Iconos | Tela-circle | Papirus-Dark |
| Cursor | Bibata-Modern-Ice | Adwaita |
| Opacidad de ventanas | 0.90 / 0.75 | 1.0 / 1.0 |
| Widgets Qt | Kvantum | ninguno (paleta del portal) |

Las dos primeras filas ahorraron trabajo: el repositorio ya había llegado por su
cuenta a las mismas decisiones.

## 2. Los iconos no se eligen: se generan

Tela-circle viene en dieciséis colores **fijos**, y ninguno es el acento del
escritorio. El más azul, `blue`, es un índigo `#5677fc` bastante más oscuro que
el `#58b4ef` que sale del fondo de pantalla. Y como el acento cambia con el
wallpaper, ninguna variante fija iba a casar nunca.

Así que se genera una. Antes de escribir nada, se midió si era viable:

```
tema Tela-circle-blue   110 MB aparentes · 44 MB reales
                        10 673 archivos · 16 752 symlinks
SVG con el azul                        177
copia + reemplazo                    0,55 s
```

Con esos números la decisión es fácil: `theme-apply` copia la variante azul a
`~/.local/share/icons/Tela-circle-arch-msi` y sustituye el índigo por el acento.
No se rehace en cada arranque —guarda el acento usado en un archivo marca— y si
mañana el fondo tira a rojo, las carpetas se vuelven rojas solas.

## 3. Transparencia: el brillo importa más que el radio

Las opacidades de HyDE (0.90/0.75) entraron tal cual y el usuario las afinó
después a **0.92/0.75**. Pantalla completa se queda opaca, como en el original:
un vídeo con el escritorio transparentándose detrás se ve mal.

El desenfoque se subió de `size 3 / passes 1` —donde casi no se notaba— y ahí
apareció lo interesante:

> **Bajar `brightness` hace más por la legibilidad que subir el desenfoque.**
> Con 0.80, lo que queda detrás se oscurece y el texto claro del tema gana
> contraste. Difuminar más solo emborrona; oscurecer separa.

Los valores finales, tras un par de ajustes del usuario: `size 4`, `passes 3`,
`brightness 0.80`.

⚠️ Al añadir la sección `[blur]` a `tokens.toml` se partió `[opacity]` por la
mitad y **ocho de sus claves acabaron dentro de la nueva sección**. Matugen se
negó a renderizar y `theme-apply` no tocó nada: la protección hizo su trabajo y
el escritorio no llegó a quedarse a medias.

## 4. Kvantum sí, pero por la otra puerta

La paleta de una app Qt la pone el `platformtheme`, y el del portal —el único
que da la señal de modo oscuro, como enseñó la 3.5— no lee `kdeglobals`. Por eso
Dolphin salía gris aunque su esquema de color estuviera bien escrito.

HyDE lo resuelve con Kvantum, que es un **QStyle**: pinta los widgets él mismo.
Pero lo activa con `QT_QPA_PLATFORMTHEME=qt6ct`, que es justo el plugin que en
este equipo dejó a ZapZap en claro.

La salida es que Kvantum no necesita ese plugin:

```
QT_QPA_PLATFORMTHEME = xdgdesktopportal   (sigue dando la señal de modo)
QT_STYLE_OVERRIDE    = kvantum            (pinta los widgets)
```

Medido antes de aplicarlo, que es lo que evitó repetir el error de la víspera:

```
                      sin Kvantum        con Kvantum
colorScheme           Dark               Dark        <- ZapZap a salvo
Window                #323232            #0c141b
Highlight             #308cc6            #58b4ef
```

## 5. Por qué hubo que traerse su SVG

Un tema de Kvantum son dos archivos: el INI con los colores y **un SVG con las
formas**. Se empezó copiando el SVG de un tema del sistema, y ahí se estrelló la
primera tanda de intentos: los 37 temas instalados llevan su arte con **colores
cableados**. La cabecera de columnas salía gris `(59,64,78)` y la barra de
herramientas con un degradado de `(67,71,76)` a `(3,12,22)` que no venía de
ningún token, dijera lo que dijera el `.kvconfig`.

Se probaron cinco bases midiendo píxeles, y esa comparación **resultó
inválida**: con varias de ellas la ventana se volvía casi transparente y lo que
se estaba midiendo era el wallpaper a través de Dolphin, no la aplicación.
Anotado aquí porque el error era fácil de no ver: los números salían, parecían
razonables, y describían otra cosa.

El SVG de HyDE está hecho para lo contrario: todo su color entra desde fuera,
por diez marcadores `<wallbash_*>`. Se trajo y se convirtió en plantilla de
matugen.

**El mapeo se dedujo, no se adivinó.** Comparando su plantilla `.dcol` con el
SVG ya generado, línea a línea, cada marcador resultó tener un único color:

```
pry1 -> surface              1xa1 -> surface_container_lowest
1xa2 -> surface_container    1xa3 -> surface_container_high
1xa4 -> outline              1xa9 -> on_surface
4xa6/4xa9 -> accent          4xa7 -> state_crit    4xa8 -> tertiary
```

⚠️ **Licencia**: ese SVG y su `.kvconfig` son obra de HyDE bajo **GPL-3.0**. Se
conservan la atribución y el aviso en la cabecera de ambos archivos. Este
repositorio no tiene licencia propia; si algún día se le pone una, tendrá que
ser compatible.

## 6. Las tres trampas silenciosas

**`##RRGGBB`.** Los marcadores del original venían precedidos de `#`, así que la
sustitución generó **597 colores con doble almohadilla en el SVG y 52 en el
INI**. Qt no los parsea y no dice nada: la ventana se veía casi transparente y
parecía que el tema era translúcido por diseño. No se pintaba nada.

**`reduce_window_opacity=10`.** Kvantum resta ese porcentaje por su cuenta, y se
sumaba al 0.92 que ya aplica Hyprland: Dolphin quedaba invisible. Puesto a 0.

**`itemview-toggled` sin opacidad.** La siguiente.

## 7. La selección: tres pintores y solo uno manda

El usuario lo describió con precisión: *«cuando pasas el ratón por encima está
perfecto, pero una vez lo seleccionas es de un azul bastante claro y opaco»*.
Esa frase era el diagnóstico entero, porque **hover y selección son dos dibujos
distintos del mismo SVG**:

```
itemview-focused   opacity:0.2  fill:accent   <- el hover, que gustaba
itemview-toggled                fill:accent   <- la seleccion, a pelo
```

Antes de encontrarlo se tocaron los dos sitios que **no** mandan: el
`highlight.color` de Kvantum (ignorado) y `[Colors:Selection]` de `kdeglobals`,
al que de paso se le añadió soporte de alfa —la fusión solo sabía escribir
`R,G,B` y ahora escribe también `R,G,B,A`—, pero que tampoco es quien pinta.

La selección pasa a un tono **más saturado** de la misma paleta primaria, con
alfa. El acento del escritorio es el tono 70; la selección usa el 50:

```
40 #006492 · 50 #007eb6 (seleccion) · 60 #3799d2 · 70 #58b4ef (acento) · 80 #8aceff
```

⚠️ El alfa se declara **una vez y en hexadecimal**, y `theme-apply` lo convierte
a las dos unidades que hacían falta: `0-1` para el SVG y `R,G,B,A` para KDE.

## 8. Dolphin

Su distribución entró casi entera: barra de herramientas de 16 px solo iconos y
no movible, sin barra de selección, Places a 16, preview 112 con una línea de
texto, y sus quince miniaturizadores —**verificados uno a uno** contra los
plugins presentes en el sistema, en vez de copiar su lista a ciegas—.

Dos cosas no se copiaron:

- **Su `dolphinui.rc`**, que es XML de kxmlgui atado a una versión concreta (el
  suyo declara `version="40"`) y que Dolphin reescribe solo.
- **`ShowStatusBar=false`**, que ellos usan: con la barra oculta, Dolphin dibuja
  el recuento como un recuadro **flotante encima de la lista**. Darle sitio fijo
  abajo lo quita de en medio.

Y su `kdeglobals` traía un regalo: **`TerminalApplication=kitty`**, que cierra el
pendiente que la 3.4 dejó abierto. No era de Dolphin, era de KDE entero.

## 9. Lo que no se pudo

**El rayado de filas de Dolphin.** Se descartaron con sondas de color chillón
—que nunca aparecieron— `alt.base.color` y `button.color` de Kvantum, y
`[Colors:View]`, `[Colors:Window]` y `[Colors:Button]` de `kdeglobals`,
verificando que la sonda quedaba escrita. Tampoco bastó quitarle el `inherits`
al `[ItemView]`. La paleta Qt efectiva tiene `Base` y `AlternateBase`
**idénticos** y aun así las filas alternan.

Se intentó disimularlo subiendo el fondo de la vista al mismo tono: las bandas
bajaron de 23 a 5 puntos de diferencia, pero seguían viéndose y la lista quedaba
de un gris opaco. El usuario prefirió el fondo oscuro de antes, y se revirtió.
Queda anotado en §15 como limitación conocida.

## 10. Un susto: Dolphin borró un archivo versionado

Al revisar el árbol antes de commitear apareció `view_properties/global/.directory`
**vacío en el repositorio y sin enlace** en `~/.local/share`. Es el archivo que
la 3.4 dejó atado con `Version=4` precisamente para que Dolphin no lo borrase.

Se restauró con `git checkout` y `stow`, pero **no se ha averiguado qué lo
provocó**: pudo ser el cierre a `pkill` mientras escribía —esta sesión abrió y
cerró Dolphin más de veinte veces— o algún cambio de modo de vista. Anotado en
§15 para vigilarlo.

## 11. Método

Casi todo lo de arriba se comprobó **midiendo píxeles de capturas reales** con
`grim` e ImageMagick, no mirando la pantalla: el degradado de la barra, el gris
de la cabecera, el periodo de las bandas —92 px, o sea dos filas de 46—, y el
color exacto de la selección. Cuando el ojo y los números discreparon, mandaron
los números; y cuando los números describían el wallpaper en vez de la ventana
(apartado 5), fue el ojo el que lo destapó.
