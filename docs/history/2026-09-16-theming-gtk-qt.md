# 2026-09-16 · Las apps entran en el tema: un tema que no existía y un archivo que no mandaba

Tarea 3.5, paso A de cuatro. El encargo era «theming GTK/Qt coherente», y lo
primero que hizo falta fue averiguar qué había de verdad, porque la tabla del
roadmap describía una tarea sin empezar y no lo estaba.

---

## 1. La tarea tenía la mitad hecha, y en otro sitio

| Pieza | Estado real |
|---|---|
| Paquete Stow `gtk` (`settings.ini` de GTK3 y GTK4) | existía — **solo modo oscuro** |
| `QT_QPA_PLATFORMTHEME=xdgdesktopportal` | fijado en `hyprland.lua:196` |
| `gsettings color-scheme` + `gtk-theme` | los ponía `theme-apply` en cada arranque |
| `nwg-look`, `papirus-icon-theme` | instalados |
| `qt5ct`, `qt6ct`, `kvantum`, `adw-gtk3` | no instalados |

Todo eso venía de la tarea del modo oscuro (2026-09-13), no de la 3.5. O sea que
el problema pendiente no era que las aplicaciones fueran oscuras —ya lo eran—,
sino que **no seguían el tema**: iconos Adwaita mientras rofi usaba Papirus-Dark
desde la 3.2, fuente la que decidiera fontconfig, cursor `default` y colores de
un Adwaita genérico que no tiene nada que ver con el fondo de pantalla.

## 2. `Adwaita-dark` no existe en este equipo

El paquete Stow escribía `gtk-theme-name=Adwaita-dark` y `theme-apply` fijaba el
mismo nombre por gsettings. `/usr/share/themes` contenía exactamente esto:

```
Default  Emacs
```

Y `~/.themes` no existía. O sea que **el tema que el repositorio nombraba en dos
sitios no estaba instalado**. No estaba roto: GTK lleva Adwaita compilado dentro
y quien oscurecía de verdad era `gtk-application-prefer-dark-theme=1`. Pero el
nombre mentía, y si algún día se instalara un tema llamado así, el aspecto
cambiaría solo.

Lo más incómodo es que ya estaba escrito: el aviso de §18 sobre
`QT_QPA_PLATFORMTHEME=gtk3` dice literalmente que *no hay ningún tema
Adwaita-dark de GTK3 en `/usr/share/themes`*, mientras el archivo de al lado lo
seguía escribiendo. Dos documentos del mismo repositorio, uno contradiciendo al
otro.

## 3. El paquete no se llama como creía todo el mundo

```
$ pacman -Si adw-gtk3
error: no se pudo encontrar el paquete «adw-gtk3»
```

Eso parecía mandar la tarea al AUR. No: el paquete existe en **`extra`** con
otro nombre.

```
extra/adw-gtk-theme 6.5-1    Unofficial GTK 3 port of the libadwaita theme
```

E instala **dos** temas, no uno con variantes: `adw-gtk3` y `adw-gtk3-dark`. La
oscura es un tema propio.

## 4. Dos decisiones que cambiaban el trabajo

**La fuente.** `tokens.toml` declara UNA SOLA FAMILIA para todo el escritorio, y
esa familia es monoespaciada (JetBrainsMono Nerd Font). Para menús y diálogos de
aplicaciones lo habitual es una sans. Se decidió **mantener la regla literal**:
la misma familia también en las aplicaciones, sin añadir una familia de interfaz
aparte.

**El archivo.** Los `settings.ini` podían seguir siendo un paquete Stow con
valores literales, pero el tema, los iconos y la fuente iban a quedar escritos
en dos sitios —el archivo y el `gsettings` de `theme-apply`—, que es justo lo
que `tokens.toml` llama error en su cabecera. Se convirtieron en **plantilla de
matugen**, el mismo camino que siguió `style.css` de Waybar en la 3.0.

## 5. El orden importa: `stow -D` antes de declarar la plantilla

`theme-apply` aborta si un destino de matugen es un enlace de Stow —es la regla
de oro de §18, y existe para no escribir dentro del repositorio—. Así que la
secuencia fue:

1. Copia de seguridad del contenido real (`settings.ini.backup`, fuera del repo
   y cubierto por `.gitignore`).
2. `stow -n -D` para ver qué iba a deshacer: dos `UNLINK`, nada más.
3. `stow -D` de verdad.
4. Solo entonces, declarar `[templates.gtk3]` y `[templates.gtk4]`.
5. `theme-apply`, que escribe los dos archivos ya como archivos reales.

Al terminar, `git status` limpio de generados. Esa es la prueba de que la regla
de oro se cumple, y se comprobó explícitamente.

**Una plantilla, dos salidas.** GTK3 y GTK4 leen el mismo formato y todas las
claves valen para las dos, así que declarar dos plantillas gemelas habría sido
la duplicación que la tarea venía a quitar.

## 6. ⚠️ El hallazgo del día: `settings.ini` no manda

Con la plantilla ya aplicada y el archivo diciendo lo correcto, la comprobación
se hizo con `gtk-query-settings`, que devuelve lo que GTK ve de verdad y no lo
que pone el archivo:

```
             gtk-theme-name: "adw-gtk3-dark"          <- bien
        gtk-icon-theme-name: "Papirus-Dark"           <- bien
      gtk-cursor-theme-name: "Adwaita"                <- bien
              gtk-font-name: "Adwaita Sans 11"        <- ???
```

El archivo decía `JetBrainsMono Nerd Font 10`. La fuente **no se estaba
aplicando**.

El motivo, buscado en dconf:

```
$ dconf dump /org/gnome/desktop/interface/
color-scheme='prefer-dark'
cursor-size=24
cursor-theme='Adwaita'
gtk-theme='adw-gtk3-dark'
icon-theme='Papirus-Dark'          <- font-name NO está aquí
```

`font-name` ni siquiera estaba fijada: `Adwaita Sans 11` es el **default del
esquema** de GNOME. O sea que `settings.ini` perdía contra un valor que nadie
había elegido, sencillamente porque en esta sesión GTK3 toma esas claves de
GSettings antes que del archivo.

Las otras tres coincidían por casualidad: las fija `theme-apply` por `gsettings`
con los mismos valores que la plantilla.

El arreglo es fijar también `font-name` por `gsettings`. Y hubo que leerla
aparte, no con el `read -r` posicional que recoge el resto de tokens, porque
«JetBrainsMono Nerd Font» lleva espacios y aquel `read` la partía en trozos.

El `settings.ini` se sigue generando: es lo único que hay en una sesión sin
dconf, y ahí sí manda.

## 7. Dos cosas que aparecieron de rebote

**Un bug en la paleta de reserva, anterior a esta tarea.** Al regenerarla con
`--save-fallback` entró un artefacto que no estaba: el CSS de ZapZap. Su ruta no
cuelga de `~/.config`, y el `MANIFEST` la guarda ABSOLUTA mientras
`instalar_fallback()` compone el destino como `$HOME/.config/$rel`. Restaurar
dejaría ese archivo en `~/.config/home/elok/.local/share/...`. **No lo causa la
3.5**: viene de §27, y solo se vio ahora porque la reserva no se había
regenerado desde entonces. Anotado en §15, sin tocar el generador: es otra
tarea.

**El recuento del README, cuadrado.** Retirar el paquete `gtk` bajaba el total
de 18 a 17. El árbol del README, además, no listaba `dolphin/` —discrepancia ya
señalada en el commit de Spotify y dejada para más adelante—. Como había que
reescribir esa misma lista, se corrigieron las dos cosas a la vez: 17 en el
texto y 17 en el árbol.

## 8. Validación

`gtk-query-settings` tras el arreglo, que es lo efectivo y no lo escrito:

```
             gtk-theme-name: "adw-gtk3-dark"
        gtk-icon-theme-name: "Papirus-Dark"
              gtk-font-name: "JetBrainsMono Nerd Font 10"
      gtk-cursor-theme-name: "Adwaita"
```

Los cuatro salen de `tokens.toml`. Además: `stow -n -D` limpio, `theme-apply`
escribe sus 15 artefactos sin abortar y `git status` no muestra ningún generado
dentro del repositorio.

**Lo que no se afirma:** que una ventana GTK recién abierta se vea como debe.
Eso lo confirma el usuario abriendo una. Las que ya estaban lanzadas
—`nm-applet`, `blueman`— leen esto al arrancar y no se enteran hasta que se
reinicien.

## 9. Paso B: cambiarle las constantes al tema

El paso A dejó las aplicaciones oscuras y coherentes, pero con los colores de un
Adwaita cualquiera. El B los ata al fondo de pantalla, como el resto del
escritorio desde la 3.0.

La vía no es reescribir el tema, que sería inmantenible: tanto libadwaita como
adw-gtk3 construyen su aspecto sobre **un puñado de colores con nombre**, y
redefinirlos con `@define-color` en el `gtk.css` del usuario los sustituye en
todo el tema sin tocar un widget.

Lo que hizo falta averiguar primero fue qué roles ofrece matugen de verdad, en
vez de suponerlos. Hubo que reconstruir a mano la invocación del script —con
`--source-color-index`, sin el cual matugen abre un prompt interactivo— para
sacar la lista: 52 roles, de `surface_container_lowest` a `inverse_on_surface`.

La escala de contenedores de Material You resultó encajar casi uno a uno con la
jerarquía de superficies de libadwaita:

| libadwaita | matugen |
|---|---|
| `window_bg_color` | `surface` |
| `view_bg_color` | `surface_container_lowest` |
| `headerbar_bg_color` · `popover_bg_color` | `surface_container` |
| `sidebar_bg_color` · `card_bg_color` | `surface_container_low` |
| `dialog_bg_color` | `surface_container_high` |

Dos decisiones que no son obvias:

- **El acento no es `colors.primary`.** Es el mismo `accent` que pinta la barra,
  rofi y el borde de la ventana activa: sale de un TONO de la paleta primaria, y
  lo resuelve `theme-apply` porque las plantillas no ven `palettes.*`.
- **Los estados no se derivan del fondo.** `success`, `warning` y `error` vienen
  de `[colors.state]`, porque un aviso amarillo tiene que ser el mismo amarillo
  en la barra, en una notificación y en un diálogo.

## 10. Validación del paso B: preguntarle a GTK, no leer el archivo

Mirar el `gtk.css` generado solo prueba que matugen sabe escribir. La pregunta
era si GTK **los usa**, así que se abrió una ventana de prueba en cada versión y
se le preguntó por `lookup_color()`:

```
                      plantilla      GTK3        GTK4
window_bg_color        #0c141b      #0c141b     #0c141b
view_bg_color          #040b11      #040b11     #040b11
headerbar_bg_color     #1d252c      #1d252c     #1d252c
accent_bg_color        #58b4ef      #58b4ef     #58b4ef
theme_bg_color         #0c141b      #0c141b     #0c141b
theme_selected_bg_col  #58b4ef      #58b4ef     #58b4ef
```

Los seis coinciden en las dos versiones, y el CSS se carga **sin un solo aviso
de parseo**. `#58b4ef` es, además, exactamente el acento que lleva el resto del
escritorio.

## 11. Paso C, primer intento: la paleta perfecta que rompió dos aplicaciones

Las dos aplicaciones Qt del equipo son Dolphin (KF6) y ZapZap (PyQt6). El plan
era el evidente: `QT_QPA_PLATFORMTHEME=qt6ct`, que lee una **paleta completa**
donde el portal solo sabe decir «oscuro o claro».

Se hizo, y las comprobaciones salieron todas bien. Una `QApplication` de PyQt6
con la variable puesta devolvía exactamente los colores del tema, rol por rol:

```
Window     #0c141b     = window_bg_color de GTK
Base       #040b11     = view_bg_color
Button     #1d252c     = headerbar_bg_color
Highlight  #58b4ef     = accent_bg_color
estilo qt6ct-style · fuente JetBrainsMono Nerd Font 10pt
```

Formato correcto, orden posicional correcto, fuente correcta, variable llegando
a los procesos nuevos. Y aun así estaba roto, porque **ninguna de esas
comprobaciones miraba lo que importaba**.

El usuario lo vio en cuanto abrió las aplicaciones:

- **Dolphin, claro con trozos oscuros.**
- **ZapZap había perdido el tema de WhatsApp Web** (§27).

## 12. El diagnóstico: faltaba una señal, no un color

Lo primero fue descartar lo evidente: el CSS de ZapZap seguía en su sitio,
regenerado esa misma tarde, y `[custom] global\css\enabled=true`. No se había
borrado nada.

La pista estaba en su ajuste `[system] theme=auto`, que significa «seguir al
sistema». Y el sistema había dejado de contestar:

```
PLATFORMTHEME=xdgdesktopportal -> colorScheme=Dark     Window=#323232
PLATFORMTHEME=qt6ct            -> colorScheme=Unknown  Window=#0c141b
```

**`qt6ct` 0.11 no implementa `colorScheme()`.** Da una paleta magnífica y no
sabe decir si el sistema es oscuro.

Qué hace ZapZap con eso, leído en su código y no supuesto
(`zapzap/core/theme/theme_manager.py`):

```python
def _get_effective_system_color_scheme(self) -> Qt.ColorScheme:
    color_scheme = self._system_theme_monitor.get_current_color_scheme()
    if color_scheme == Qt.ColorScheme.Dark:
        return Qt.ColorScheme.Dark
    return Qt.ColorScheme.Light
```

`Unknown` no es `Dark`, así que **claro**. Y con WhatsApp Web en claro, el CSS
del tema —escrito contra `prefers-color-scheme: dark`— deja de aplicar. De ahí
lo de «perdió los cambios»: no se perdió nada, dejó de encajar.

Dolphin tenía la otra mitad del mismo problema: sus widgets tomaban la paleta de
qt6ct, pero todo lo que pinta **`KColorScheme`** caía a Breeze **claro**, porque
sin señal de modo y sin esquema en `kdeglobals` esos son sus valores por
defecto. De ahí el «claro con trozos oscuros».

> **La lección, que es la que vale para la próxima:** se validó la paleta —lo
> que se había cambiado— y no la señal de modo, que era lo que las aplicaciones
> preguntaban. Las cuatro comprobaciones del primer intento eran correctas y
> ninguna miraba el sitio donde estaba el fallo.

## 13. La vía buena: el platformtheme no era el sitio

Dolphin es KF6, y sus colores **no salen de la paleta de Qt**: los pone
`KColorScheme`, que lee `~/.config/kdeglobals`. O sea que el problema nunca fue
elegir bien el platformtheme.

Así que la variable **vuelve a `xdgdesktopportal`**, que es quien sí da la señal
—ZapZap y Dolphin vuelven a saber que el sistema es oscuro—, y los colores del
tema entran por un esquema KDE fundido en `kdeglobals`: siete conjuntos
(`Window`, `View`, `Button`, `Selection`, `Tooltip`, `Header`, `Complementary`)
con el mismo mapeo que GTK, `View` ← `surface_container_lowest` y `Selection` ←
el acento del escritorio. Las doce claves de cada conjunto se sacaron del propio
binario con `strings /usr/lib/libKF6ColorScheme.so`.

⚠️ **Fundir, no generar.** En `kdeglobals` escribe también Dolphin
(`[KFileDialog Settings]`: ancho de la barra lateral, orden de columnas).
Generarlo entero los borraría en cada arranque. `theme-apply` sustituye solo las
secciones de color; comprobado que las 15 claves de Dolphin siguen **idénticas**
tras la fusión. Los colores se convierten a `R,G,B` decimal al fundir: `#58b4ef`
acaba como `88,180,239`.

## 14. La transparencia, que no es cosa del tema

Dolphin translúcido no se consigue con Qt sino con Hyprland, y con la **misma
opacidad que la barra y las notificaciones** (`[opacity].surface`). El token
viaja por `theme.lua`, el único camino que tiene `hyprland.lua` para leer
`tokens.toml` sin repetir el número a mano.

Dos cosas que costaron un intento cada una:

- La clase **no es `dolphin`** sino `org.kde.dolphin`, leída de `hyprctl
  clients` con la ventana abierta.
- **`opacity` es una CADENA**, con los dos valores separados por espacio. Con
  una tabla, el parser responde `field 'opacity': string type requires a
  string` y tira la regla entera. No lo dice el `reload`, que responde `ok`: lo
  dice `hyprctl configerrors`, que es el que hay que mirar.

## 15. El paso D (Kvantum), descartado con datos

Antes de emprenderlo se comprobó qué es Kvantum en realidad: un **`QStyle`**
(`/usr/lib/qt6/plugins/styles/libkvantum.so`), no un platformtheme. Se activaría
con `QT_STYLE_OVERRIDE` o desde qt6ct, y sus temas traen **sus propios colores
en SVG**, que pisarían el esquema KDE que el paso C acababa de resolver.

Aportaría forma de widgets a cambio de romper el color, para las dos únicas
aplicaciones Qt del equipo, una de las cuales es una ventana web. Se descarta.

`qt6ct` y `kvantum` se instalaron para esta tarea y quedan **sin usar**.

## 16. Lo que queda

Reiniciar ZapZap: el que estaba abierto arrancó con el entorno viejo
—comprobado en `/proc/<pid>/environ`: `QT_QPA_PLATFORMTHEME=qt6ct`— y uno nuevo
recibe ya `xdgdesktopportal`.

Y las confirmaciones visuales, que ninguna comprobación de consola sustituye
—esa es justo la lección del apartado 12—: que Dolphin se vea oscuro, con el
azul del escritorio y translúcido, y que ZapZap vuelva a verse como antes.
