# 2026-09-13 · Todo el sistema en oscuro, y WhatsApp Web con la paleta del escritorio

Punto de partida: *todas las aplicaciones abren en claro*. El escritorio llevaba
siendo oscuro desde la tarea 3.0 —matugen lo pinta a partir de
`mode = "dark"`—, pero eso solo cubre el **shell**: Waybar, rofi, kitty, dunst,
wlogout, hyprlock, yazi. Las aplicaciones van por otro camino y nadie les estaba
diciendo nada.

De ahí salieron dos trabajos encadenados: poner el sistema entero en oscuro, y
después meter WhatsApp Web —que es una página web dentro de un envoltorio— en la
misma paleta que el resto.

---

## 1. No hay un interruptor, hay tres

| Capa | Quién la lee | Dónde se fija |
|---|---|---|
| Portal `org.freedesktop.appearance color-scheme` | Firefox, Electron (VS Code, Obsidian, ZapZap), GTK4/libadwaita, Qt 6 | clave gsettings, la pone `theme-apply` |
| `~/.config/gtk-{3,4}.0/settings.ini` | GTK3 que no consulta el portal | paquete Stow `gtk` |
| `QT_QPA_PLATFORMTHEME` | Dolphin y demás Qt 6 | `hl.env` en `hyprland.lua` |

La preferencia del portal la deduce `xdg-desktop-portal-gtk` de la clave
gsettings `org.gnome.desktop.interface color-scheme`. Esa clave vive en **dconf**,
una base de datos binaria: no hay archivo que enlazar con Stow. Por eso la pone
`theme-apply` en cada arranque **derivándola de `matugen.mode`**, que ya estaba
declarado en `tokens.toml`. Una sola fuente de verdad; no un segundo sitio donde
decir si el sistema es oscuro.

### Trampa: la opción evidente para Qt es la equivocada

`QT_QPA_PLATFORMTHEME=gtk3` devuelve `ColorScheme.Dark`, igual que la buena. Y
pinta el fondo de ventana en **`#faf9f8`**, que es blanco. El motivo: en este
sistema no hay ningún tema Adwaita-dark de GTK3 en `/usr/share/themes` —solo
`Default` y `Emacs`—, así que el puente Qt→GTK no tiene de dónde sacar los
colores oscuros.

El valor correcto es **`xdgdesktopportal`**: `#323232` de fondo y `#f0f0f0` de
texto. Ambos plugins vienen en `qt6-base`; no hacen falta `qt6ct`, `breeze` ni
`kvantum`.

**La comprobación que vale es mirar la PALETA, no el nombre del esquema.** Si se
valida por `colorScheme`, las dos opciones parecen correctas y se entrega Dolphin
en claro dando el trabajo por bueno.

### Trampa: validar el `reload` de Hyprland cuesta más de lo que parece

El historial ya avisaba de que el `ok` del parser Lua no demuestra nada. Aquí se
confirmó por partida doble: con la configuración en Lua, `hyprctl dispatch exec
<ruta>` **no vale** —el parser se atraganta con las comillas, con las rutas que
llevan números y con los puntos—, y la sintaxis buena es
`hyprctl dispatch 'hl.dsp.exec_cmd("/ruta")'`.

Por eso la validación final no fue «recargué y salió ok», sino un proceso
lanzado de verdad por Hyprland enseñando su propio entorno y su paleta.

---

## 2. WhatsApp Web: dos capas de color superpuestas

ZapZap tiene «personalización avanzada»: inyecta CSS y JS del usuario en la
página. Parecía la vía directa para darle los colores del escritorio. Lo fue,
pero no antes de tres callejones.

### Callejón 1: el JavaScript está bloqueado

La inyección de JS crea un `<script>` **inline** y lo añade al `<head>`. La CSP
de WhatsApp Web lo bloquea en silencio. El CSS usa `<style>`, que sí pasa.

Se comprobó con marcadores visibles en vez de deducirlo del código: una banda
roja por CSS —se veía— y una verde por JS —no se veía—. Sin esa prueba, el resto
del trabajo se habría hecho sobre una suposición.

### Callejón 2: pisar `:root` no hacía nada

El primer CSS ponía ~90 variables en `:root` con nombres plausibles
(`--app-background`, `--teal`…). Resultado: **cero cambios visibles**. Y sin
embargo, al consultar esas variables en el `<html>`, tenían el valor nuevo.

La explicación es que WhatsApp Web define su tema **en dos niveles**:

1. Tokens **WDS** (`--WDS-surface-default`, `--WDS-accent`…) sobre el `<html>`,
   con selectores de clase ofuscados y doblados (`.x1umy8rd.x1umy8rd`).
2. ~188 variables heredadas (`--panel-background`, `--teal`…) definidas en
   `.dark`, que es una clase del **`<body>`**.

Las variables CSS **heredan**, así que la definición más cercana al elemento
gana. Lo escrito en `:root` (el html) lo tapaba `.dark` (el body) por cercanía,
**por mucha especificidad que se le pusiera arriba**. Hay que escribir en los dos
niveles: `:root:root:root` y `body.dark.dark`.

Y los nombres antiguos que se habían adivinado eran, además, la **capa vieja**:
la que pinta hoy es WDS.

### Callejón 3: cómo averiguar los nombres reales

Sin JavaScript no se puede preguntar a la página. Se intentó, y se descartó:

- **La red**: `web.whatsapp.com` devuelve una página de error a cualquier
  petición que no venga de un navegador con sesión.
- **La caché del Service Worker**: solo guarda preferencias y **archivos
  multimedia cifrados** del usuario. Nada de CSS, y ningún motivo para seguir
  hurgando ahí.
- **Los addons de ZapZap**: son solo JS, y el paquete no trae ninguno.

La vía buena es que **Qt WebEngine soporta depuración remota**, y el protocolo de
DevTools evalúa JavaScript *desde fuera* de la página, así que **la CSP no le
afecta**:

```
QTWEBENGINE_REMOTE_DEBUGGING=127.0.0.1:9222 zapzap
curl -s http://127.0.0.1:9222/json
```

No había cliente de WebSocket instalado, así que se escribió uno mínimo en
Python puro (handshake, enmascarado y framing; unas 70 líneas).

Con eso a mano, el truco que resolvió el problema: **no buscar las variables por
nombre, sino por su valor actual**. Pedir las que hoy valen el verde de WhatsApp
devuelve la lista exacta de lo que hay que remapear, sin adivinar nada. De 1406
variables, 19 llevaban el verde y 30 los grises del tema oscuro.

---

## 3. Cómo quedó

El CSS **no es un archivo escrito a mano**: es una plantilla de matugen más.

```
theme/tokens.toml  →  theme-apply  →  matugen
                                        └─ templates/zapzap-waweb.css
                                             └─ ~/.local/share/ZapZap/.../arch-msi.css
                                                  └─ ZapZap lo inyecta con <style>
```

La salida vive en los datos de la aplicación, **no** en una ruta de Stow, así que
la regla de oro de §18 se cumple. Y al ser plantilla, no hay un solo hexadecimal
escrito a mano: si cambia el fondo de pantalla, WhatsApp cambia con el resto del
escritorio.

La plantilla **no usa las clases ofuscadas**. Usa `:root:root:root` —0,3,0 con
nombres estándar, que gana al 0,2,0 de Meta— y `prefers-color-scheme`, de modo
que si el escritorio vuelve a claro la hoja se aparta sola en vez de forzar
colores oscuros sobre un tema claro.

### Lo que se dejó en verde a propósito

Seis tokens. Cuatro son entradas de la escala cruda que ningún token semántico
usa hoy, uno tiene semántica poco clara, y el sexto es
`--WDS-components-profile-photo-content-green`: el verde de la paleta de
**avatares**, que debe seguir siendo verde porque es uno de los colores con los
que WhatsApp pinta las fotos de perfil.

### Lista de chats colapsable

De regalo, una `@media (max-width: 900px)` que reduce `#pane-side` a 76 px —la
columna de avatares— cuando la ventana es estrecha. No es función de WhatsApp ni
de ZapZap.

**El primer intento colapsaba lo que no era, y se vio en pantalla.** `#pane-side`
es SOLO la lista: el buscador y los filtros son hermanos suyos dentro de `#side`,
y por encima hay una columna con `flex: 0 0 45%` que es la que fija el ancho de
verdad. Colapsando solo la lista, la columna seguía reservando su 45%: la lista
se encogía a un avatar recortado, la cabecera se quedaba ancha y entre medias
aparecía un socavón negro. Medir por DevTools decía que `#pane-side` valía 76 px
y era cierto — pero la pregunta correcta no era esa. **Hizo falta mirar una
captura de la pantalla para verlo.**

La versión buena colapsa la columna entera, señalada con `:has(> #side)` para no
depender de las clases ofuscadas, y oculta título, buscador y filtros, cuyas
funciones están en la barra de iconos que sigue visible. Las filas no se tocan
por selector: se les fuerza un `min-width` al grid para que **se recorten** en
vez de reorganizarse. `overflow-x` y no `overflow`, porque `#pane-side` es el
contenedor con scroll vertical de la lista.

**De paso apareció un defecto que no era nuestro:** por debajo de ~750 px,
WhatsApp Web desborda su propio contenedor y saca una barra de scroll horizontal
con una franja muerta a la derecha. Pasa con o sin el colapso. Se corrige con
`.two { min-width: 0 }` — y `.two` es una clase real y estable de WhatsApp, no de
las ofuscadas.

### Y dos defectos más que solo se vieron mirando

Con la columna ya colapsada quedaban dos cosas feas, ninguna deducible de las
mediciones. Las dos salieron de volver a mirar una captura.

**Las fotos se cortaban por la derecha.** La barra de scroll vertical de la lista
se comía **10 px** de los 76: `#pane-side` medía 76 de ancho pero solo 66 de
`clientWidth`, y el avatar —48 px, a 24 del borde— se recortaba 5 px. La primera
reacción fue ensanchar a 96 px, y entonces asomaba la primera letra de cada
nombre. El valor correcto es **76 con la barra de scroll oculta**: 24 + 48 = 72,
y el texto del nombre empieza exactamente en 76. Un píxel más y asoma la letra;
uno menos y se corta el avatar. La lista se sigue recorriendo con la rueda.

**Una línea gris vertical flotando en mitad del chat.** Cruzaba por encima de las
burbujas, así que no era un borde de la conversación. Localizarla costó: buscarla
por coordenadas no funcionó —el `devicePixelRatio` es 1.6 y las cuentas no
salían— y hubo que encontrar el x exacto **midiendo el brillo por columnas de la
captura** con ImageMagick, y luego buscar el elemento por su forma (muy estrecho,
muy alto) en vez de por posición.

Resultó ser una **capa de superposición vacía** dentro de `.two` —solo `span`s
sin contenido— cuyo único cometido es dibujar los separadores entre paneles, y
que mantenía la división original `flex: 0 0 45%`. Al colapsar la columna real,
esa capa se quedó donde estaba: su segundo panel empezaba en x=403 y pintaba ahí
su borde izquierdo, sobre la conversación, además de reservar 275 px muertos.

Se arregla colapsándola también. Se la señala con `.two > div > div:first-child`,
que es estructura pura y no depende de clases ofuscadas; comprobado en la página
que coge exactamente 2 elementos, el fantasma y otro de ancho cero.

---

## 4. Lo que se va a romper, y cómo arreglarlo

**Los tokens WDS no son una API.** No están documentados y Meta los renombra
cuando quiere. El día que lo haga, volverá el verde por partes, en silencio y sin
que nada falle de forma visible.

El arreglo no es adivinar: es repetir el método de la sección 2 —depuración
remota, buscar por valor— y actualizar la plantilla. Queda escrito en su
cabecera y en §27.

**Y hay cuatro claves que no se versionan**, porque viven en
`~/.config/ZapZap/ZapZap.conf` junto a la geometría de ventana y el estado de
sesión: `theme=auto`, `custom/global/css/enabled=true`, `menubar=true` y
`sidebar=true`. Tras una reinstalación hay que reponerlas a mano; sin la segunda,
la hoja se genera pero no se inyecta.

> ⚠️ Desactivar la barra lateral **y** la superior deja la ventana sin ningún
> elemento visible que lleve a los ajustes. **`Ctrl+P` los abre igualmente**
> (`ui/components/main_window.py:144`), y esa es la vía de recuperación normal;
> el atajo va dentro de `_()`, o sea que es traducible y podría depender del
> idioma de la interfaz. La vía de emergencia es editar `menubar` y `sidebar` en
> el `.conf` **con la aplicación cerrada**, porque QSettings reescribe el archivo
> al salir y se llevaría el cambio por delante.
