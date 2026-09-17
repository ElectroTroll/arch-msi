# PROJECT_CONTEXT

Estado técnico vigente del sistema `arch-msi`. Fuente de verdad detallada.
Última actualización: 2026-09-17 (**suite ofimática y visor de PDF** — §35
nueva: el equipo no tenía ninguna suite, y el PDF lo abría Xournal++ **sin que
nadie lo hubiera elegido** —no había línea en `mimeapps.list`, así que mandaba
el orden de `mimeinfo.cache`, donde figuraba el primero—. Ahora el PDF es de
Firefox por preferencia explícita. Se instala `libreoffice-fresh` con los
diccionarios de inglés, castellano y catalán, y la elección de suite la decidió
el formato: para **`.xls`** —el binario de Excel 97-2003, no `.xlsx`— ONLYOFFICE
no vale, porque lo abre convirtiendo pero **no escribe en ese formato**. Tres
trampas del catalán: **`hunspell-ca` no está en los repos** sino en el AUR —solo
hay `aspell-ca`, que LibreOffice no usa—; **no existe guionado catalán** en
ningún sitio; y el tesauro `mythes-ca` del AUR **está roto desde 2015**, con el
PKGBUILD apuntando a una URL de Softcatalà que da 404 porque el proyecto se mudó
a GitHub. Se resuelve con la extensión `.oxt` oficial instalada con `unopkg` a
nivel de usuario, que además es **2.3.1 en vez de la 1.5.0** del AUR — pero al
no controlarla pacman queda como **quinto agujero** de §14. Diagnóstico en
`history/2026-09-17-libreoffice-y-pdf.md`).
Antes: 2026-09-16, de madrugada (**la estética de HyDE, con
nuestros colores** — §34 nueva: se adopta el aspecto de
github.com/Hyde-project/hyde —iconos, tamaños, distribución, transparencias—
manteniendo la paleta de este repositorio. Los iconos no se eligen sino que se
**generan**: Tela-circle viene en dieciséis colores fijos y ninguno es el
acento, así que theme-apply recolorea la variante azul con él (medido: 177 SVG,
0,55 s). Las ventanas pasan a 0.92/0.75 con blur, y el desenfoque enseña que
bajar `brightness` hace más por leer que subir el radio. Los widgets Qt los pinta
**Kvantum**, activado con `QT_STYLE_OVERRIDE` y NO con el `qt6ct` que usa HyDE,
que es justo lo que rompía ZapZap (§33). Su SVG entra en el repositorio como
plantilla, **con licencia GPL-3.0 y atribución**, porque los temas del sistema
llevan sus colores cableados. Tres trampas silenciosas por el camino:
**597 colores `##RRGGBB`** que Qt no parsea y hacían parecer translúcida la
ventana, un `reduce_window_opacity` que se sumaba al de Hyprland, y la
selección, que no la pinta ni Kvantum ni kdeglobals sino el elemento
`itemview-toggled` del SVG. Queda sin resolver el rayado de filas de Dolphin
(§15). Diagnóstico en `history/2026-09-16-estetica-hyde.md`).
Antes, el mismo día: (**las aplicaciones entran en el tema** — §33 nueva, tarea 3.5, **pasos A y B de cuatro**: hasta hoy las apps GTK solo
sabían que eran oscuras. Ahora el tema es `adw-gtk3-dark` de verdad, los iconos
son los `Papirus-Dark` que ya usaba rofi, el cursor deja de ser `default` y la
fuente es la del escritorio. Dos hallazgos que conviene tener escritos: el
paquete **no se llama `adw-gtk3`** en los repos sino `adw-gtk-theme`, en `extra`
y no en el AUR; y **`Adwaita-dark`, que el repo llevaba tiempo escribiendo en
dos sitios, NO EXISTE** en este sistema —funcionaba por `prefer-dark`, pero el
nombre mentía—. El paquete Stow `gtk` se retira y sus dos `settings.ini` pasan a
plantilla de matugen, con lo que los paquetes bajan de 18 a 17 y el interruptor
de claro/oscuro deja de tener la excepción que arrastraba (§18). Y una trampa
medida, no supuesta: **GSettings gana a `settings.ini`**, así que la fuente no
se aplicaba hasta fijarla también por `gsettings`. **El paso B** lleva además
los colores del fondo a las aplicaciones GTK, redefiniendo con `@define-color` las
constantes sobre las que libadwaita y adw-gtk3 construyen todo su aspecto;
comprobado preguntándole a GTK con `lookup_color()`, no mirando el archivo, y
los seis colores coinciden en GTK3 y en GTK4. **El paso C dio un rodeo que vale
la pena tener escrito**: se intentó con `QT_QPA_PLATFORMTHEME=qt6ct`, la paleta
entró perfecta y aun así rompió las dos apps Qt —ZapZap se puso en CLARO y se
llevó por delante el tema de WhatsApp Web, y Dolphin salió claro con trozos
oscuros—, porque **qt6ct 0.11 no implementa `colorScheme()`** y quien pregunta
por el modo se queda sin respuesta y asume claro (medido con QStyleHints:
`Dark` con el portal, `Unknown` con qt6ct). La variable vuelve a
`xdgdesktopportal` y los colores de Dolphin entran por donde de verdad los lee
KF6: un esquema KDE que theme-apply **funde** en `kdeglobals` —fundir y no
generar, porque ahí escribe también Dolphin—. Dolphin gana además la
transparencia de la barra por una regla de Hyprland. Y el **paso D (Kvantum)
queda descartado** tras comprobar que es un `QStyle` y que sus SVG pisarían ese
esquema.
Diagnóstico en `history/2026-09-16-theming-gtk-qt.md`).
Antes, el mismo día: (**la pantalla a 60 Hz con batería** — §32
nueva: la pregunta era a qué frecuencia va el panel en power-saver sin enchufar,
y la respuesta resultó ser **a 165 Hz igual que enchufado**, comprobado con el
equipo ya en ese perfil: ni el perfil ni nada del escritorio tocaban el modo de
vídeo. Ahora un demonio de sesión lo baja a 60 Hz con batería **y**
power-saver, y lo devuelve a 165 en cuanto se enchufa o se cambia de perfil. El
hallazgo que cambió el diseño: `theme-apply` termina con un `hyprctl reload`,
que re-aplica la regla de eDP-1 y **deshacía el ahorro en silencio**, así que se
escucha también `configreloaded` además del enchufe (uevent del kernel, no
UPower) y del `ActiveProfile` de power-profiles-daemon. Se descarta la regla de
udev, que correría como root y fuera de la sesión. Queda **sin medir** cuánto
ahorra. El cable salió de verdad pocos minutos después, y el panel **bajó solo a
60 Hz**, aunque no se pudo distinguir si lo disparó el uevent o el sondeo de
respaldo. De paso cayó una suposición escrita en esta misma actualización:
**esta batería no expone `power_now`**, solo `current_now` y `voltage_now`, y la
potencia hay que calcularla (§15). Con el monitor externo aún conectado el
equipo tiraba **23,74 W** y la dGPU estaba **`active`**, que es el otro
sospechoso de la autonomía corta (§6) y con diferencia el mayor de los dos.
Diagnóstico en `history/2026-09-16-panel-60hz-bateria.md`).
Antes: 2026-09-15 (**escribir Δ y γ sin tenerlas en el teclado**
— §31 nueva: selector de símbolos en `Super + G`, 96 entradas buscables por
nombre en castellano. Las otras tres vías se evaluaron con el sistema delante y
perdieron. La de la tecla Compose por un motivo que conviene tener escrito: el
archivo `Compose` **ya trae 67 combinaciones griegas**, pero todas cuelgan de
`<dead_greek>`, que solo existe en `us(altgr-weur)` y no en las dos
distribuciones de este equipo — están en el disco y son **inalcanzables**. La
tercera distribución `gr` se descarta porque `Super+Espacio` rota entre las
cargadas y pasaría a tres paradas. Y LaTeX sirve para fórmulas, no para un
carácter suelto en prosa: guarda `\Delta`, no `Δ`, así que no es buscable —el
mismo razonamiento de §26 con los subíndices—. Anotado que **`Ctrl+Shift+U` no
funciona aquí**: lo aporta ibus y no hay método de entrada. Quedaba **sin
comprobar** que `wtype` llegue a Obsidian, la misma incógnita del teclado
virtual que dejó abierta Compose — **cerrado el mismo día**: `wtype 0.4-2` entra
en `packages/`, `wtype ""` sale con código 0 (Hyprland expone el protocolo) y el
usuario confirma que `Super + G` escribe en Obsidian **tecleando**, comprobado
aparte de la copia: el carácter aparece sin tocar `Ctrl+V`. Diagnóstico en
`history/2026-09-15-simbolos-griegos.md`).
El mismo día se investigó, sin tocar el sistema, que **Arch no siempre arranca a
la primera**: se congela en la carga de GRUB y hay que apagar a botonazo. §4
gana un **[PEND]** con la medida y la anomalía —un initramfs de **221 MB** por el
firmware de NVIDIA—; la corrección queda **propuesta y sin aplicar**, y la causa
**sin probar**. En `history/2026-09-15-cuelgue-arranque-initramfs.md`.
Antes: 2026-09-14, al final del día (**Spotify se subía el volumen
solo** — §30 gana el apartado de `OBJETIVOS_MPRIS`: al cambiar de canción el
volumen volvía al 100 %, y **el mezclador no tenía la culpa** —pasa igual con el
servicio parado—. La primera hipótesis, que Spotify recreaba su flujo, resultó
**falsa**: `pactl subscribe` da 27 eventos `change` y ningún `new`. Lo que a
veces lo arreglaba era el ruido del potenciómetro, que reescribía el volumen por
casualidad. El arreglo es pedirle el volumen a la propia aplicación por MPRIS
(`playerctl`), que es la dueña del flujo. La curva no cambia, y eso se midió:
MPRIS usa la misma escala cruda de PulseAudio. Queda escrito el intento
descartado de medirla grabando audio, que dio exponentes de 1,51 a 2,94 y no
servía. Diagnóstico en `history/2026-09-14-spotify-volumen-mpris.md`).
Antes, el mismo día: (**el StreamDeck casero entra
en el repositorio** — §30 nueva: hardware propio (Pro Micro, 12 teclas y 5
sliders) traído del sobremesa con Windows. Es **el primer componente que es un
proyecto entero y no configuración de un programa ajeno**, así que no es paquete
Stow. Las teclas van por USB HID y no necesitan nada; toda la dificultad estaba
en los sliders, cuyo backend de Linux nunca se había ejecutado. Lo que parecía
una copia fuera del repositorio resultó ser un **symlink**
(`~/StreamDeckDIY -> Projects/arch-msi/streamdeck`) que **no crea Stow ni ningún
script**: sin él, el servicio de usuario no arranca. La curva de volumen se
midió en vez de suponerse —fader lineal en dB, −5,00 dB por cada 10 % de
recorrido, deshaciendo la cúbica de PipeWire— y la identificación de apps mira
tres propiedades porque Spotify no publica el binario. Pendientes: Discord sin
confirmar, OBS sin instalar y F17–F21 sin asignar, que además necesitan
`hl.bind(...)` y no el `bind =` del README. Detalle en
`history/2026-09-14-streamdeck.md`).
Antes, el mismo día: (**Minecraft con instancias**
— §29 nueva: `multimc-bin` del AUR, que **no contiene el launcher**: instala un
bootstrapper de 27 KiB que se descarga MultiMC 0.7.0 en `~/.local/share/multimc`
la primera vez que se abre, con lo que eso implica al restaurar el equipo. A
diferencia del launcher oficial (§13), MultiMC **sí necesita Java del sistema**
y entran `jre8`, `jre17` y `jre21-openjdk`, sin que eso levante el veto a
`jre-openjdk` a secas, que va por Java 26. La expectativa de que la ventana Qt5
iría bajo XWayland y borrosa a escala 1,6 resultó **falsa** —el launcher es
Wayland nativo—, pero el juego que lanza sí sale por X11, porque
`UseNativeGLFW=false` usa el GLFW empaquetado de LWJGL. §13 se matiza y §15 gana
el `[VER]` de en qué GPU se está jugando —**cerrado el mismo día**: con
`WrapperCommand=prime-run` puesto a mano, `nvidia-smi` lista el `java` del juego
con 187 MiB en la RTX 4060 y la GPU sube de 2,35 W a ~10 W, así que la dGPU
queda configurada y **medida**, no supuesta—. Detalle en
`history/2026-09-14-multimc.md`).
Antes, el mismo día: (**AnyDesk para controlar
otros equipos** — §28 nueva: `anydesk-bin` del AUR, con el servicio de acceso
desatendido deliberadamente sin habilitar. Los dos fallos que vinieron detrás
señalaban a culpables falsos: el `result_relay_offline` no era la red del campus
ni el `NXDOMAIN` de `crl.anydesk.com` —que sale igual cuando funciona—, sino un
relay que dijo «no reconectes» y un cliente que obedece y no reintenta nunca; se
cura reiniciándolo. Y la imagen deformada era un 16:9 remoto dentro de una
ventana casi cuadrada sobre una pantalla a escala 1,6: se arregla llevándola al
monitor externo, que es 16:9 a escala 1. §9 gana la segunda trampa del parser
Lua, peor que la primera porque **falla en silencio**: `hl.dsp.*` construye la
acción y solo `hyprctl dispatch` la ejecuta, así que `eval` responde `ok` sin
hacer nada. §25 se corrige: el descarte de AnyDesk valía solo para el iPad.
Diagnóstico en `history/2026-09-14-anydesk.md`).
Antes, el mismo día: (**subíndice, superíndice, y el
texto que se volvía naranja** — §26 gana dos plugins propios más, `subindice` y
`superindice` (`Ctrl+Alt+,` y `Ctrl+Alt+.`), clonados de `subrayar`, y la
explicación de por qué estructurar una nota con tabuladores y líneas en blanco
la rompe: una línea de solo tabulador es una línea en blanco, cierra el párrafo,
y lo que viene detrás empieza en la columna 4, que es un bloque de código
indentado. La estructura pasa a hacerse con citas `>`. Queda anotado que
`Super+,` no llegó a funcionar y que **la causa no se ha verificado**.
Diagnóstico en `history/2026-09-14-obsidian-subindices-y-citas.md`).
Antes, el mismo día: (**el Bluetooth entra en `Super + Z`** — §22
pasa de un interruptor de dos posiciones a una rotación *altavoces → USB →
Bluetooth*, construida al pulsar con las salidas que existen en ese momento. El
criterio queda escrito: los `bluez_output.*` entran porque solo existen mientras
el aparato está conectado, y los HDMI siguen fuera porque están siempre, haya o
no algo enchufado. §15 cierra el `[VER]` del firmware Bluetooth —hoy el arranque
no da ni un error y hay tres aparatos emparejados—, pero **queda anotado que la
causa no se ha verificado**: `linux-firmware` es la misma versión con la que
fallaba. Diagnóstico en `history/2026-09-14-audio-bluetooth-rotacion.md`).
Antes: 2026-09-13, al final del día (**WhatsApp Web con la
paleta del escritorio** — §27 gana el tema de la página: resulta que WhatsApp
define su color en DOS niveles, tokens WDS sobre el `<html>` y ~188 variables
heredadas en `.dark` sobre el `<body>`, y pisar solo `:root` no hace nada porque
las variables heredan y gana la definición más cercana. El CSS pasa a ser una
plantilla de matugen más, así que sigue al fondo de pantalla. Se añade la lista
de chats colapsable en ventanas estrechas y quedan anotadas las cuatro claves de
ZapZap que no se versionan, incluida la que deja la app sin acceso a sus
ajustes. Diagnóstico en `history/2026-09-13-modo-oscuro-y-tema-de-whatsapp.md`).
Antes, el mismo día: (**todo el sistema en oscuro** —
§18 gana el reparto de modo claro/oscuro de las APLICACIONES, que iban en claro
sobre un escritorio oscuro porque matugen solo pinta el shell. Son tres caminos
—portal, `settings.ini` de GTK y `QT_QPA_PLATFORMTHEME`— y el modo se sigue
declarando una sola vez, en `matugen.mode`. Queda anotada la trampa de que
`QT_QPA_PLATFORMTHEME=gtk3` dice ser oscuro y pinta blanco. Paquete Stow `gtk`
nuevo).
Antes, el mismo día: (**WhatsApp en el escritorio** —
§27 nueva: `zapzap` como envoltorio de WhatsApp Web, con los clientes de
terminal descartados por el riesgo de baneo que traen los que reimplementan el
protocolo. El lanzador normal se cerraba a los dos segundos: Qt WebEngine no
puede usar GBM y cae a Vulkan, y a esta máquina le faltaba `vulkan-intel` — un
hueco de la máquina, no de la app. Diagnóstico en
`history/2026-09-13-zapzap-whatsapp.md`).
Antes, el mismo día: (**el rótulo `[ALSA UCM error]` de la SSL 2+,
resuelto** — §22 explica que el perfil UCM declaraba 4+4 canales donde el
hardware expone 6+8, y que los «canales que faltaban» eran 6 retornos de
loopback y un par de reproducción que no suena: no había nada que recuperar. Se
aplica en local el PR #837 de `alsa-ucm-conf`, abierto y sin revisar upstream,
con `scripts/alsa-ucm-apply.sh`; §15 pierde ese `[VER]`. De paso se corrige el
número de tarjeta ALSA, que no es fijo. Diagnóstico en
`history/2026-09-13-ssl2-ucm-canales.md`).
Antes: 2026-09-12, más tarde (**subrayar con `Ctrl+U`** — §26
gana los atajos de deshacer/rehacer leídos del `obsidian.asar` y el plugin
propio `subrayar`, primer y único componente del vault que se versiona, enlazado
por symlink y no por Stow. Queda anotado que el comando de deshacer es
`mobileOnly` y por eso no aparece en la lista de atajos, y que `Ctrl+U` llevaba
`undoSelection`, que es lo que lo hacía parecer un deshacer errático).
Antes, el mismo día: (**el lápiz y el táctil, anclados a `eDP-1`** —
§7 gana la subsección: sin salida asignada, Hyprland reparte las coordenadas
absolutas del digitalizador sobre el área de TODOS los monitores, y el toque se
descalibra en cuanto hay un externo; más las dos trampas del parser Lua, que
`hyprctl keyword` ya no vale y que el `ok` de `eval` no demuestra el remapeo.
Cierra la tarea 4.1 del roadmap y deja la 4.3 en parcial. Diagnóstico en
`history/2026-09-12-lapiz-dos-pantallas.md`).
Antes: 2026-09-11 (**apuntes con teclado y lápiz** — §26 nueva:
Obsidian con los plugins Ink y Excalidraw para dibujar dentro de una nota de
texto, y las dos trampas del lápiz en el escritorio: que Firefox lo reporta como
ratón bajo Wayland, y que Obsidian corre en Wayland nativo sin que eso rompa el
trazo, al contrario de lo previsto. Alternativas descartadas en
`history/2026-09-11-apuntes-lapiz-obsidian.md`).
Antes: 2026-09-09 (**TeamViewer para ver la pantalla del iPad** —
§25 nueva: solo visión porque iPadOS no permite control por terceros, y el
paquete AUR no declara `minizip`, lo que deja el demonio en `status=127`; §15
gana la captura de la sesión Wayland como pendiente de probar. Diagnóstico en
`history/2026-09-09-teamviewer-ipad.md`).
Antes: 2026-09-08 (**greeter de SDDM a juego con hyprlock** —
§24 nueva: el primer componente del repositorio que vive fuera de `$HOME`, con
su convención `system/` y el instalador que hay que ejecutar con sudo).
Antes, el mismo día: (**la barra en cajas** — §18 documenta que
Waybar deja de ser una isla de lado a lado y pasa a seis cajas con `group/`, y
que los tooltips pasan a llevar el estilo exacto de las notificaciones de
dunst: fondo translúcido, marco de acento de 2 px y el mismo relleno).
Antes, el mismo día: (**monitorización en la barra** — §23 nueva:
CPU, RAM, uso de la dGPU y temperaturas en Waybar, con el guardado de RTD3 que
impide que el módulo despierte la RTX 4060). Antes, el mismo día:
(**interfaz de audio SSL 2+ Mk II** — §22
nueva: la interfaz funciona sin drivers, el script `audio-salida` y el atajo
`Super+Z` para alternar la salida de todo el sistema, y el aviso de UCM. §13
gana la convención «dónde vive un script ejecutable», que hasta ahora solo
existía en la práctica; de paso se corrigen tres desfases de documentación
—el contenido del paquete Stow `bin`, dos filas caducadas del README y un
enlace roto de `keybindings.md` a la config de Waybar que dejó de existir con
matugen—). Antes, el mismo día: (**toolchain C/C++** — §21 nueva: `g++`
16.2.1 ya estaba instalado como dependencia de `base-devel`, por qué no figura
en `packages/pacman-explicit.txt` y los defectos verificados C++20 / C23).
Antes, el mismo día: (**Minecraft en la dGPU** — §13 añade el
paquete Stow `minecraft`: una entrada de escritorio que arranca el launcher
oficial con `prime-run`, y la trampa de plegado de Stow bajo `~/.local`).
Antes: 2026-09-07 (**dos pantallas** — §7 documenta el reparto de
escritorios 1–5 / 6–10, la colocación del externo a la izquierda y las dos
trampas de `persistent-workspaces`). Antes: 2026-09-06 (**monitor externo por
HDMI** — §6 documenta que
el puerto HDMI cuelga de la dGPU y qué le cuesta eso al RTD3, §15 la ruta USB-C
sin comprobar; medidas en `history/2026-09-06-monitor-externo-hdmi.md`). Antes:
2026-08-28 (**tema centralizado con matugen** — §18 nueva,
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
- **[PEND] Arranque intermitente sin resolver (2026-09-15).** Cada cierto tiempo,
  al elegir Arch en GRUB el equipo **se congela en el texto de carga del
  bootloader** y solo sale manteniendo pulsado el botón de encendido y
  reintentando varias veces. Medido: un hueco de **10 min 40 s** donde un
  reinicio normal tarda **16–18 s**, y **cero traza en el journal**. La anomalía
  señalada es el tamaño del initramfs —**221 MB**, porque ese mismo
  `MODULES=(nvidia …)` arrastra los **112 MB** de firmware GSP que declara
  `modinfo nvidia`—, que obliga a GRUB a leer **~252 MB** por Btrfs `zstd:3`
  antes de que el kernel imprima una letra. **La causa no está probada** (GRUB no
  deja log) y **no se ha corregido nada**: la propuesta es vaciar `MODULES`, y
  está sin aplicar. Si se aplicara, la frase del punto anterior sobre el orden de
  los hooks dejaría de aplicar. Medidas, descartes y comandos de comprobación en
  [`history/2026-09-15-cuelgue-arranque-initramfs.md`](history/2026-09-15-cuelgue-arranque-initramfs.md).
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

### Monitor externo por HDMI: el puerto cuelga de la NVIDIA

Verificado el 2026-09-06 con un LG UltraGear conectado por HDMI.

**El reparto de conectores lo decide la placa, no el software:**

| Nodo de render | GPU | Conectores |
|---|---|---|
| `renderD128` | Intel Arc (`i915`) `00:02.0` | `eDP-1` (panel interno) + `DP-1`, `DP-2`, `DP-3` |
| `renderD129` | NVIDIA RTX 4060 (`nvidia`) `01:00.0` | `HDMI-A-1` |

> ⚠️ **El número de `cardN` NO es fijo.** Esta tabla decía `card1` (Intel) y
> `card2` (NVIDIA) hasta el 2026-09-13, cuando se comprobó que la NVIDIA era
> **`card0`** y la Intel `card1`. Depende del orden de registro y cambia entre
> arranques; el nodo de render y la dirección PCI sí son estables. El log citado
> más abajo conserva los números que tenía aquella sesión: es una transcripción,
> no una referencia. Ver `hardware.md`.

`HDMI-A-1` **solo existe bajo la NVIDIA**. No hay MUX ni opción de BIOS que lo
reencamine a la iGPU: es una pista de PCB. Conectar un monitor por HDMI obliga a
despertar la dGPU y **la mantiene fuera de RTD3 mientras el cable esté puesto**.

**Lo que NO cambia: el renderizado sigue siendo Intel.** Hyprland compone los
dos monitores en la iGPU y solo delega el *scanout* del HDMI en la NVIDIA. Del
log de aquamarine:

```
drm: gpu /dev/dri/card1 becomes primary drm
drm: Starting backend for /dev/dri/card2, with driver nvidia-drm with primary /dev/dri/card1
CDRMRenderer(drm): Using device /dev/dri/card1     <- composición (Mesa Intel Arc)
GBM: Buffer is marked as multigpu, forcing linear  <- copia entre GPUs
CDRMRenderer(drm): Using device /dev/dri/card2     <- scanout del HDMI
```

`glxinfo -B` sigue devolviendo `Mesa Intel(R) Arc(tm) Graphics (MTL)`: PRIME
offload intacto, sin variables de entorno forzadas. El precio de la pantalla
externa es la copia lineal entre GPUs, no un cambio de GPU de render.

**Coste medido:**

| Estado | Consumo dGPU | Estado PCI |
|---|---|---|
| Sin HDMI (RTD3) | 0 W | `suspended` · `D3cold` |
| Con HDMI, escritorio en reposo | **~2,1–2,3 W** | `active` · `D0` · P8 · 210 MHz · 45 °C |

Los contadores de la propia sesión lo confirman sin ambigüedad: sobre 42 min de
uptime, `runtime_suspended_time` marcaba 27,0 min (todo el rato antes de
enchufar el cable) y `runtime_active_time` 15,8 min (desde que se enchufó). La
correlación es exacta.

`/proc/driver/nvidia/gpus/*/power` pasa de `Video Memory: Off` a
`Video Memory: Active`. La función de audio `01:00.1` **sí** sigue suspendida
(`D3hot`) mientras no se use el audio por HDMI.

Sobre una batería de 71 Wh son ~2 W extra permanentes: perceptible en autonomía
a lo largo de una jornada, irrelevante enchufado a la corriente. Temperaturas
sin novedad (dGPU 45 °C, CPU package 55 °C, ventiladores 2774 RPM, que son el
perfil por defecto de MSI y no una respuesta a la dGPU). **No es un problema que
merezca tocar la configuración.**

**[VER] Posible ruta por la iGPU: USB-C.** La Intel expone `DP-1`, `DP-2` y
`DP-3` desconectados, que apuntan a las salidas DisplayPort alt-mode de los
puertos Type-C (`port0` y `port1` en `/sys/class/typec/`, más un dominio
Thunderbolt). Si el monitor entrase por uno de ellos y apareciese como
bajo la Intel, la NVIDIA volvería a D3cold y desaparecería la copia entre GPUs.
**Sin comprobar** — no se descarta que alguno de los Type-C esté también
cableado a la dGPU. Ver §15.

> **La trampa de `nvidia-smi` se reprodujo el 2026-09-06.** La primera lectura
> del comando dio `9,49 W` y `24 %` de uso; un muestreo sostenido justo después
> (26 lecturas en 32 s) dejó el valor real en `2,1 W` y `0 %`. El pico es el
> propio `nvidia-smi` despertando y consultando la GPU. Con el HDMI conectado el
> comando ya no impide medir —la GPU está despierta de todas formas—, pero **la
> primera lectura sigue sin servir**: hay que muestrear varios segundos, o
> quedarse en sysfs como dice el aviso de arriba.

**Configuración de Hyprland:** el monitor externo lo recoge la regla genérica
`output = ""` (`mode = preferred`, `position = auto`, `scale = 1`) de
`hyprland.lua`. No tiene entrada propia y no hace falta que la tenga.

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
>
> ⚠️ **Y `ok` NO significa que se haya hecho nada.** Descubierto el 2026-09-14
> peleándose con la ventana de AnyDesk (§28): `hl.dsp.window.move({...})` y
> `hl.dsp.window.fullscreen()` devolvían `ok` por `hyprctl eval` sin mover ni
> agrandar nada, con cualquier forma de los argumentos. La razón es que
> **`hl.dsp.*` CONSTRUYE una acción para asociarla a una tecla, no la
> ejecuta** —es exactamente para lo que la usa `hl.bind(...)`—. Quien la
> ejecuta es `hl.dispatch(...)`, y a él se llega con `hyprctl dispatch`, que
> envuelve lo que reciba:
>
> ```
> hyprctl eval     'hl.dsp.window.move({ workspace = 8 })'   → ok, y no pasa nada
> hyprctl dispatch 'hl.dsp.window.move({ workspace = 8 })'   → ok, y la ventana se mueve
> ```
>
> O sea que hay **dos** trampas encadenadas: la sintaxis clásica falla con
> error visible, y la sintaxis Lua correcta por la vía equivocada falla **en
> silencio**. La única comprobación que vale es mirar el estado después
> (`hyprctl clients`, `hyprctl monitors`), nunca la respuesta.
>
> Para descubrir la API sin documentación, `hl.dsp` es una tabla y se puede
> volcar desde el propio Lua, ya que `eval` no devuelve valores:
> `hyprctl eval '(function() local f=io.open("/tmp/dsp.txt","w") for k in pairs(hl.dsp) do f:write(k.."\n") end f:close() return 1 end)()'`.
> Así salieron `hl.dsp.window.*` (`move`, `fullscreen`, `float`, `resize`,
> `center`, `close`…) y `hl.dsp.workspace.*`.

> **Realidad de configuración:** tienen config propia y versionada **Hyprland**
> (`hyprland.lua`), **hyprlock** (`hyprlock.conf`) e **hypridle**
> (`hypridle.conf`) en `dotfiles/hypr/`, **Waybar** (`config.jsonc` +
> `style.css` + `claude-usage.sh`) en `dotfiles/waybar/` y **dunst**
> (`dunstrc`) en `dotfiles/dunst/` (tarea 2.2, ver §16 (Notificaciones)). Las
> carpetas de `kitty`, `rofi` y `yazi` siguen **vacías o inexistentes** (usan
> defaults).
> Ver §13 (Dotfiles y estado del repositorio).

### Dos pantallas: reparto de escritorios y colocación  **[OK]**

Hecho el **2026-09-07** con el LG UltraGear por HDMI conectado, validado por
captura de las dos barras.

| | Salida | Escritorios | Atajos |
|---|---|---|---|
| Principal | `eDP-1` (portátil) | **1–5** | `Super+1..5` |
| Secundaria | `HDMI-A-1` (externo) | **6–10** | `Super+6..9`, `Super+0` |

El reparto lo fijan diez `hl.workspace_rule` en `hyprland.lua` (`monitor`, y
`default` en el 1 y el 6). Los binds `Super+N` no cambiaron: como cada número
tiene ya su pantalla, el atajo salta de monitor además de escritorio y no hace
falta un bind aparte para moverse entre pantallas.

Las reglas **no** son `persistent`: con el HDMI desenchufado, del 6 al 10 solo
existen los que tengan ventanas y Hyprland los recoge en el portátil. Los diez
botones fijos los pone Waybar.

**Colocación:** `HDMI-A-1` tiene entrada propia con
`position = "auto-center-left"` — a la izquierda del portátil y centrado en
vertical. Antes lo recogía la regla genérica `output = ""` con
`position = "auto"`, que encadena hacia la **derecha**, así que el puntero salía
por el borde contrario al físico.

El `-center-` es la segunda mitad del arreglo. Con `auto-left` a secas la Y
queda clavada en 0 —alineados por el borde **superior**—, y como el externo es
mucho más alto en píxeles lógicos el ratón no cruzaba a la misma altura:

| | Alto lógico | Banda vertical | |
|---|---|---|---|
| | | `auto-left` | `auto-center-left` |
| `eDP-1` | 1000 px | 0 … 1000 | 0 … 1000 |
| `HDMI-A-1` | 1440 px | 0 … 1440 | −220 … 1220 |

Todo relativo **a propósito**: la regla es del **puerto**, no de este LG.
`position = "-2560x-220"` da hoy el mismo resultado exacto —comprobado— pero ata
la regla a un externo de 2560×1440. Las direcciones válidas salen del propio
binario: `auto`, `auto-{up,down,left,right}`, `auto-center-{up,down,left,right}`.

> ⚠️ **Para calibrar un monitor en vivo NO vale `hyprctl keyword`.** Con config
> Lua responde `keyword can't work with non-legacy parsers. Use eval.` La vía
> buena es `hyprctl eval`, que sí acepta la llamada entera y aplica al instante:
>
> ```bash
> hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "-2560x-220", scale = 1 })'
> ```
>
> No persiste nada: `hyprctl reload` lo deshace. Es el modo de tantear valores
> sin editar `hyprland.lua` en cada intento. Encaja con el aviso general de
> arriba sobre los dispatchers clásicos por IPC.

#### Dos trampas de `persistent-workspaces` (Waybar)

1. **`{"*": 10}` no son diez en total.** Waybar crea diez persistentes **por
   salida** y los numera por índice de monitor: con dos pantallas, la barra del
   externo mostraba **11–20** —números que ningún atajo alcanza, porque
   `Super+N` llega al 10— más los que existieran de verdad. Ese era el síntoma
   original: *1–3 y 11–20*.
2. **La clave del mapa es el NOMBRE DE LA SALIDA, no el escritorio.** Escrito al
   revés (`"1": ["eDP-1"]`) Waybar lee `"1"` como nombre de monitor, no casa con
   ninguno y la barra se queda **sin persistentes**: solo salen los que tienen
   ventanas. Falla en silencio, sin nada en el journal. La forma buena está en
   los EXAMPLES de `waybar-hyprland-workspaces(5)`:

```jsonc
"persistent-workspaces": {
    "eDP-1":    [1, 2, 3, 4, 5],
    "HDMI-A-1": [6, 7, 8, 9, 10]
},
"all-outputs": false
```

`all-outputs` pasó a `false`: cada barra enseña solo lo suyo. Con `true` las dos
listaban los diez y el número dejaba de decir en qué pantalla está la ventana.

### El lápiz y el táctil van anclados a `eDP-1`  **[OK]**

Hecho el **2026-09-12**, al aparecer el síntoma: con el monitor externo
conectado, el trazo del lápiz y el toque del dedo caían **desplazados**
respecto al punto tocado. Sin el externo, perfectos.

**Causa.** El digitalizador reporta coordenadas **absolutas** sobre su propia
superficie. Sin `output`, Hyprland las estira sobre el **área combinada de
todas las salidas**, no sobre el panel que estás tocando:

| | Posición | Tamaño lógico |
|---|---|---|
| `eDP-1` | `0x0` | 1600×1000 (2560×1600 ÷ escala 1,6) |
| `HDMI-A-1` | `-2560x-220` | 2560×1440 |
| **Combinada** | | **~4160×1220** |

O sea que el lápiz quedaba mapeado a una superficie **2,6 veces más ancha** que
el panel. Con una sola salida las dos áreas coinciden exactamente, y por eso el
fallo solo aparece con el externo puesto.

**Arreglo**, en `hyprland.lua` junto a los demás `hl.device`:

```lua
for _, puntero in ipairs({
    "elan9024:00-04f3:4297-stylus", -- lápiz (sección Tablets)
    "elan9024:00-04f3:4297",        -- táctil (sección Touch)
}) do
    hl.device({ name = puntero, output = "eDP-1" })
end
```

Son **dos** entradas porque `hyprctl devices` los lista por separado, en
`Tablets` y en `Touch`. Anclar solo el lápiz deja el dedo descalibrado.

### ⚠️ Con el parser Lua, `hyprctl keyword` ya no vale

El intento natural de probar esto en caliente falla:

```
$ hyprctl keyword 'device[elan9024:00-04f3:4297-stylus]:output' 'eDP-1'
keyword can't work with non-legacy parsers. Use eval.
```

El equivalente es `hyprctl eval` con la llamada Lua, que sí responde `ok`:

```
$ hyprctl eval 'hl.device({ name = "elan9024:00-04f3:4297-stylus", output = "eDP-1" })'
ok
```

**Pero ese `ok` no confirma que el dispositivo se haya remapeado**: solo dice
que la llamada Lua se ejecutó sin error. Y `hyprctl getoption` sobre esa misma
clave devuelve `no such option`, así que **el mapeo de un device no se puede
leer de vuelta por software**. La única validación posible es tocar la pantalla.

Por eso el cambio fue directo al archivo más `hyprctl reload`, que re-aplica la
configuración entera desde cero, en vez de quedarse en el `eval` en caliente.

Diagnóstico completo: `history/2026-09-12-lapiz-dos-pantallas.md`.

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
  **[OK]** · Nitidez a ojo: **[OK]**, confirmada visualmente el 2026-09-16.
- **La clase de ventana cambia con el backend:** `Spotify` en X11 →
  `spotify` en Wayland. Ninguna `windowrule` de `hyprland.lua` ni módulo de
  Waybar la usaba, pero cualquier regla futura debe escribirse en minúscula.
- Alternativa **descartada**: `xwayland:force_zero_scaling = true` (global,
  hoy en `false`) más `--force-device-scale-factor` por app. Afectaría a todas
  las apps X11 y obligaría a escalar cada una a mano.
- **[OK] `~/.config/spotify-flags.conf` está versionado** desde el 2026-09-16:
  paquete Stow `dotfiles/spotify/` (roadmap 3.6). Tras una restauración basta
  `stow -d dotfiles -t ~ spotify` **desde la raíz del repo**. Ya no es uno de
  los agujeros silenciosos de §14.

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
  - **bin** → `dotfiles/bin/` (enlaza en `~/.local/bin`, que está en el PATH de
    la sesión, para que Hyprland invoque por nombre y no dependa de dónde esté
    clonado el repo: `theme-apply`, `vpn-autoconnect`, `kb-layout`,
    `audio-salida` (§22) y `waybar-monitor` (§23), los dos últimos añadidos el
    2026-09-08). **El paquete no
    contiene los scripts, solo symlinks relativos a `scripts/`**: ver la
    convención abajo.
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
- **Paquete Stow añadido por la tarea 3.3** (2026-08-28):
  - **yazi** → `dotfiles/yazi/` (`yazi.toml` y `keymap.toml`). Duodécimo
    paquete. Nace dentro del tema: no llega a tener colores propios. **No
    añade ningún requisito a `install/services.sh`**: no tiene servicio ni
    activación D-Bus,
    se invoca desde una terminal y todo lo demás cae dentro de paquetes Stow.
    Y **no añade ningún paquete a `packages/`**: todas las herramientas que usa
    para previsualizar —`ffmpeg`, `poppler`, `imagemagick`, `7zip`, `fd`,
    `ripgrep`, `fzf`, `zoxide`— ya estaban instaladas. Comprobado regenerando
    los inventarios: solo cambia la fecha de las cabeceras.
    ⚠️ **Enlazado con `--no-folding`, y no es opcional**: `~/.config/yazi` es
    donde matugen escribe `theme.toml`. Con un `stow yazi` normal, Stow enlaza
    el DIRECTORIO entero —lo dijo la simulación: `LINK: .config/yazi => …`— y
    el artefacto habría caído dentro del repositorio. Es la misma trampa que
    hubo que deshacer en `wlogout` y `fastfetch` (§18).
    ⚠️ **La tarea 3.3 toca además el paquete `shell`**, que es la primera vez
    que un componente de la fase 3 sale de su propio paquete: `.bashrc` gana
    `export EDITOR=vim` y la función `y`. Las dos razones, abajo en §19.
- **Paquete Stow añadido fuera de las tareas de la fase 3** (2026-09-08):
  - **minecraft** → `dotfiles/minecraft/`
    (`.local/share/applications/minecraft-launcher.desktop`). Es el primer
    paquete que no versiona la configuración de una aplicación sino una
    **entrada de escritorio que oculta a la del paquete de sistema**: misma
    ruta relativa bajo `~/.local/share`, que gana a `/usr/share` por
    precedencia XDG. Lo único que cambia frente a la de `minecraft-launcher`
    es el `Exec`, que antepone `prime-run`: así el proceso `java` del juego
    hereda `__NV_PRIME_RENDER_OFFLOAD`, `__GLX_VENDOR_LIBRARY_NAME` y
    `__VK_LAYER_NV_optimus`, y renderiza en la RTX 4060 en vez de en la iGPU
    (§6). El launcher se autoactualiza y se relanza con `--chainLoad`, pero
    las variables sobreviven a ese salto: comprobado con `nvidia-smi`, el
    `java-runtime-epsilon` del juego aparece en la GPU 0.
    **No añade ningún requisito a `install/services.sh`**: no tiene servicio
    ni activación D-Bus, lo lanza el menú de aplicaciones.
    **A `packages/` solo añade `minecraft-launcher`** (AUR 1:2.1.3-3): no hace
    falta Java del sistema porque el launcher descarga su propio JRE bajo
    `~/.minecraft/runtime`. Instalar `jre-openjdk` sería además
    contraproducente — va por Java 26 y el juego no arranca con JRE demasiado
    nuevo.
    ⚠️ **Desde el 2026-09-14 sí hay Java del sistema, y no lo trajo este
    paquete**: MultiMC (§29) no descarga runtime propio y usa los JRE
    instalados, así que entraron `jre8`, `jre17` y `jre21-openjdk`. Eso **no
    contradice el párrafo de arriba**: lo que sigue sin instalarse es
    `jre-openjdk` a secas, que es el que va por Java 26. El launcher oficial
    sigue usando el suyo de `~/.minecraft/runtime` y los tres JRE numerados no
    le afectan.
    ⚠️ **Está enlazado por archivo, pero solo porque el directorio destino ya
    existía.** Aquí funcionó porque `~/.local/share/applications` ya contenía
    `claude-code-url-handler.desktop`, que no se versiona. **Al restaurar en un
    equipo limpio hay que crear ese directorio ANTES de invocar a Stow**: Stow
    pliega en el nivel más alto que no exista en el destino, y sobre un `$HOME`
    recién creado enlaza `~/.local` ENTERO al repositorio (comprobado: `LINK:
    .local => .../minecraft/.local`). Un directorio que existe pero está vacío
    ya basta para evitarlo. Es la misma trampa de `yazi`, `wlogout` y
    `fastfetch` (§18), y la inversa de la de `~/Wallpapers` (§17), que sí
    quiere el plegado. Afecta igual a `bin/` e `icons/`, que también cuelgan
    de `~/.local`.
- **Paquete Stow añadido por la tarea 3.4** (2026-09-16):
  - **dolphin** → `dotfiles/dolphin/` (`.config/dolphinrc`,
    `.local/share/dolphin/view_properties/global/.directory` y
    `.local/share/user-places.xbel`). Decimoséptimo paquete. **No añade ningún
    requisito a `install/services.sh`** ni ningún paquete a `packages/`:
    Dolphin ya estaba instalado y la tarea no instaló nada.
    ⚠️ **Los ajustes de vista de Dolphin NO se guardan en ningún archivo por sí
    solos.** Medido el 2026-09-16: cambiar el modo de vista y mostrar los
    ocultos no escribe ni `dolphinrc` ni ningún `.directory`; lo único que
    cambia es `~/.config/session/dolphin_dolphin_dolphin`, el estado de sesión
    (`RememberOpenedTabs` viene en `true`). Por eso los ajustes PARECEN
    persistir aunque no exista nada que versionar. El archivo que sí manda hay
    que escribirlo a mano, y entonces Dolphin lo lee y lo obedece.
    ⚠️ **`Version=4` es obligatorio en ese `.directory`: sin esa clave, Dolphin
    lo BORRA al cerrarse.** Una sonda sin ella (valor por defecto `-1`, versión
    desconocida) se aplicó bien al arrancar y desapareció al salir. Enlazado con
    Stow eso es grave: el borrado se lleva el symlink, así que la configuración
    aplicaría UNA vez por cada `stow` y luego nada, en silencio. Con `Version=4`
    sobrevive intacto — mismo md5 y mismo inodo tras una sesión real.
    ⚠️ **`HiddenFilesShown` va en el grupo `[Settings]`** y todo lo demás en
    `[Dolphin]`. La fuente de los valores es
    `/usr/share/config.kcfg/dolphin_directoryviewpropertysettings.kcfg`, y ahí
    consta que `ViewMode` es 0 iconos, **1 detalles** y 2 columnas.
    ⚠️ **Enlazado con `--no-folding`**, para que
    `~/.local/share/dolphin/view_properties/global` siga siendo un directorio
    real: si Stow lo plegara, lo que Dolphin escribiera dentro caería en el
    repositorio. Misma trampa que en `yazi`, `wlogout` y `fastfetch` (§18), y
    con el mismo aviso que `minecraft`: en un equipo limpio hay que crear los
    directorios ANTES de invocar a Stow.
    **Los dos motores de escritura respetan los symlinks**, verificado con el
    proceso real de Dolphin: KConfig (`dolphinrc`) y KBookmarkManager
    (`user-places.xbel`) escriben a través del enlace y lo dejan intacto, aunque
    reemplacen el archivo de destino. Por eso es un paquete Stow normal.
    **`GlobalViewProps` ya vale `true` por defecto** en Dolphin 26.08, así que
    no hay que activarlo y Dolphin NO esparce archivos `.directory` por el
    `$HOME`: cero en todo el árbol, comprobado. La advertencia contraria que
    llevaba el roadmap era de versiones antiguas.
    **Fuera del paquete a propósito**: `kdeglobals` y `kiorc`, que son de todo
    Qt/KDE y no de Dolphin — `kdeglobals` es además donde escribirá la 3.5. El
    doble clic no necesitó configuración: `SingleClick` está ausente, que ya es
    el defecto. **El panel de terminal (`F4`) se descartó**: necesita
    `konsolepart.so`, del paquete `konsole`, que no está instalado.
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
- **Ya no queda ninguno sin config.** Esta línea decía «sin config todavía:
  `kitty`, `rofi`, `yazi`» y se quedó vieja sin que nada avisara: kitty se
  configuró en la 3.1, rofi en la 3.2 y yazi en la 3.3, los tres con paquete
  Stow propio. Dolphin se configuró en la 3.4, también con paquete propio. De la
  fase 3 quedan el theming GTK/Qt (3.5) y npm (3.7); Spotify (3.6) se cerró el
  2026-09-16 con `dotfiles/spotify/`.

### Dónde vive un script ejecutable (convención del repositorio)

**Todo script ejecutable vive en `scripts/`, con extensión `.sh`, y solo ahí.**
El paquete Stow `bin` **no contiene ningún script**: contiene *symlinks
relativos* que apuntan al de `scripts/`, y Stow enlaza esos symlinks en
`~/.local/bin`. La cadena queda en dos saltos:

```
~/.local/bin/audio-salida
  -> ../../Projects/arch-msi/dotfiles/bin/.local/bin/audio-salida   (lo crea Stow)
      -> ../../../../scripts/audio-salida.sh                        (versionado en el repo)
```

Estado a 2026-09-08: enlazados `theme-apply`, `vpn-autoconnect`, `kb-layout`,
`audio-salida` y `waybar-monitor`. `update-inventories.sh` y `add-wallpaper.sh`
se ejecutan a mano desde el repo y no necesitan enlace.

**Por qué relativo y no absoluto.** Stow **rechaza los symlinks absolutos dentro
de un paquete** —aborta con «source is an absolute symlink», la misma razón por
la que el icono de `icons` se copió en vez de enlazarse— y un enlace absoluto
ataría el repositorio a una ruta de clonado concreta, que es justo lo que la
restauración no puede dar por hecho.

**Por qué un script no se guarda directamente en `dotfiles/bin/`.** Funcionaría,
pero partiría el repositorio en dos sitios donde buscar código ejecutable, y la
documentación quedaría citando rutas de las dos formas. Pasó el 2026-09-08 con
`audio-salida`, creado primero como archivo regular dentro del paquete Stow y
movido después a `scripts/`. Si un script nuevo aparece en `dotfiles/bin/` y no
es un symlink, está mal colocado.

## 14. Tareas pendientes (fases futuras)

Las tareas de la fase inicial están completadas. Posibles siguientes pasos:

- Crear configs propias para Kitty, Rofi y yazi, y migrarlas a Stow.
- **Decidir qué hacer con el arranque intermitente de §4.** El diagnóstico está
  hecho y la corrección es una línea de `mkinitcpio.conf`, pero **no se ha
  aplicado**: es decisión del usuario, y validarla exige una tanda larga de
  reinicios (tasa de fallo observada ≈ 1 de cada 6).
- **Estado que vive fuera del repositorio y que una restauración NO recupera.**
  **Cinco** agujeros con el mismo final: el fallo es **silencioso**, nada avisa
  de que falta el paso. En los dos primeros los archivos vuelven a su sitio pero
  nada los activa; en los tres últimos el archivo ni siquiera vuelve.
  (Eran cinco: `spotify-flags.conf` se cerró el 2026-09-16, roadmap 3.6.)
  - `hypridle.service`: el `enable` solo deja rastro en
    `packages/services-enabled.txt`. Sin rehabilitarlo, la sesión no se
    bloquea sola nunca (ver §9).
  - `waybar.service`: habilitado el 2026-08-02. Sin rehabilitarlo tras una
    restauración, no hay barra: los archivos están, pero nadie los lanza.
  - `~/.claude/settings.json` → `statusLine.command`. El script está
    versionado y se enlaza con Stow, pero quien lo invoca es este archivo, que
    **no** se versiona porque contiene credenciales y estado de sesión. Sin él,
    el módulo de uso de Claude en Waybar se queda en `—` para siempre.
  - `~/.npmrc` (`prefix=/home/elok/.local`): **detectado el 2026-08-27**, en la
    auditoría de la tarea 2.5. Es lo que permite instalar globales de npm **sin
    sudo** y lo que pone a Codex CLI en `~/.local/lib/node_modules` (§10). No
    está versionado, así que tras una restauración `npm -g` volvería a escribir
    en `/usr` pidiendo sudo y la ruta que documenta §10 dejaría de ser cierta,
    sin un solo aviso. Mismo patrón y misma solución que `spotify-flags.conf`:
    un paquete Stow, no `install/services.sh` (roadmap 3.7).
  - **El tesauro catalán de LibreOffice** (§35): es una extensión `.oxt`
    instalada con `unopkg`, no un paquete, así que **no aparece en
    `packages/`** por mucho que se regeneren los inventarios. Tras una
    restauración el corrector catalán volvería —ese sí es `hunspell-ca`— pero
    los sinónimos no, y nada lo avisaría. Detectado el 2026-09-17. No sirve un
    paquete Stow: hay que volver a descargar el `.oxt` y ejecutar `unopkg add`,
    así que encaja en `install/` (roadmap 3.9).
  Decidir cómo cubrirlos: encaja con `install/services.sh` de la fase 6 (ver
  roadmap 6.1, marcado como requisito bloqueante).

## 15. Información sin verificar

- Si un cambio de VT recupera una pantalla apagada con `wlopm` cuando nadie va a
  ejecutar el `--on` (ver la trampa en §9). Sigue sin probarse, pero el
  2026-08-27 se comprobó lo que **no** la recupera: ni teclado ni ratón. Ahora
  que se sabe que `Ctrl+Alt+F3` funciona con Fn Lock, la prueba es fácil de
  hacer la próxima vez que ocurra.
- Estado de autenticación de Claude Code (no comprobado; no exponer credenciales).
- **Los diccionarios de LibreOffice dentro de la interfaz** (§35). Están
  verificados en disco y con `unopkg list`, pero falta abrir Writer y confirmar
  que los tres idiomas salen en *Herramientas → Idioma* y que `Ctrl+F7` da
  sinónimos sobre una palabra en catalán. Requiere sesión gráfica.
- **[VER] El rayado de filas de Dolphin no se puede quitar por configuración.**
  Dolphin pinta el fondo de las filas alternas con un tono que **no expone en
  ninguna clave**, y lo hace pase lo que pase. Descartado el 2026-09-16 con
  sondas de color chillón que nunca aparecieron: `alt.base.color` y
  `button.color` de Kvantum, y `[Colors:View]`, `[Colors:Window]` y
  `[Colors:Button]` de kdeglobals —verificando que la sonda quedaba escrita—;
  tampoco bastó quitarle el `inherits` al `[ItemView]`. La paleta Qt efectiva
  tiene `Base` y `AlternateBase` **idénticos** y aun así alterna. Se probó a
  disimularlo subiendo el fondo de la vista al mismo tono: las bandas bajaron de
  23 a 5 puntos de diferencia pero seguían viéndose y la lista quedaba gris
  opaca, así que **se revirtió**. Queda como limitación conocida.
- **⚠️ Dolphin BORRÓ el `.directory` versionado el 2026-09-16.** El archivo de
  `view_properties/global` —el que la 3.4 dejó atado con `Version=4`— apareció
  **vacío en el repositorio y sin enlace** en `~/.local/share` tras una sesión de
  pruebas con Dolphin abriéndose y cerrándose muchas veces. Se restauró con
  `git checkout` + `stow`, pero **no se ha averiguado qué lo provoca**: puede ser
  el cierre a `pkill` mientras escribía, o un cambio de modo de vista. Es
  exactamente el fallo silencioso que la 3.4 describía, y conviene mirar el
  archivo de vez en cuando: si vuelve a vaciarse, se pierden el orden de
  carpetas, el modo de vista y los ocultos sin que nada avise.
- **[VER] La paleta de reserva guarda mal los artefactos que NO cuelgan de
  `~/.config`.** Destapado el 2026-09-16 al regenerarla en la tarea 3.5: el
  `MANIFEST` que escribe `--save-fallback` anota la ruta ABSOLUTA de la salida
  de ZapZap (`/home/elok/.local/share/ZapZap/...`), mientras que
  `instalar_fallback()` compone el destino como `$HOME/.config/$rel`. Al
  restaurar con `--fallback`, ese archivo acabaría en
  `~/.config/home/elok/.local/share/...`, una ruta absurda. **No es un fallo de
  la 3.5**: es del generador, y llevaba ahí desde que §27 añadió esa plantilla;
  solo que la reserva no se había regenerado desde entonces. Los 13 artefactos
  restantes, los dos nuevos de GTK incluidos, sí cuelgan de `~/.config` y se
  restauran bien. Arreglo pendiente de decidir: o el `MANIFEST` guarda rutas
  relativas a `$HOME`, o `instalar_fallback()` distingue las absolutas.
- **[VER] Cuánto ahorra bajar el panel de 165 Hz a 60 Hz.** El cambio automático
  ya está en marcha (§32) pero **el ahorro no se ha medido**: hace falta dejar el
  equipo quieto en batería y comparar el consumo entre los dos modos, forzándolos
  con `hyprctl eval` y con el demonio parado, para que el perfil no contamine la
  medida.
  > ⚠️ **Esta batería NO expone `power_now`.** `/sys/class/power_supply/BAT1/`
  > tiene `current_now` (µA) y `voltage_now` (µV), y la potencia hay que
  > calcularla: `current_now/1e6 * voltage_now/1e6` da los vatios. Comprobado el
  > 2026-09-16, después de haber escrito `power_now` en esta misma sección: el
  > archivo no existe.
- ~~**[VER] Que el uevent de desconexión de la corriente llegue al demonio de
  §32.**~~ **Observado el 2026-09-16**, minutos después de instalarlo y sin
  buscarlo: el usuario desenchufó y `panel-hz --status` daba `AC enchufado: no`,
  perfil `power-saver` y el panel **ya a 60 Hz**, con la línea correspondiente en
  el log del demonio. Lo que **no** se puede afirmar es cuál de los dos caminos
  lo disparó, el uevent o el sondeo de respaldo: el log no lleva marcas de
  tiempo y no se cronometró el momento de tirar del cable. Para la práctica da
  igual —el ahorro entra solo—, pero la distinción sigue sin comprobarse.
- **[VER] Si algún puerto USB-C saca vídeo por la iGPU.** La Intel expone
  `DP-1`, `DP-2` y `DP-3`, que deberían corresponder a las salidas DisplayPort
  alt-mode de los Type-C, pero **no se ha conectado nada por ahí**. Si
  funcionan, un monitor externo por USB-C→DisplayPort evitaría despertar la
  NVIDIA y ahorraría los ~2 W del HDMI (§6). Prueba: conectar y mirar si sale
  bajo la tarjeta del `i915` o la del `nvidia` (comprobar el driver con
  `grep DRIVER /sys/class/drm/cardN/device/uevent`, no fiarse del número) en
  `/sys/class/drm/card*-*/status`, y si
  `/sys/bus/pci/devices/0000:01:00.0/power/runtime_status` se queda en
  `suspended` (2026-09-06).
- ~~**[VER] En qué GPU renderiza Minecraft lanzado desde MultiMC.**~~
  **Resuelto el mismo 2026-09-14, y de paso medido**: se puso `prime-run` como
  *wrapper command* en `multimc.cfg` y con el juego abierto `nvidia-smi` lista
  el proceso `java` de la instancia con 187 MiB en la RTX 4060; las tres
  variables de PRIME están en su `/proc/PID/environ`
  (`__NV_PRIME_RENDER_OFFLOAD`, `__GLX_VENDOR_LIBRARY_NAME`,
  `__VK_LAYER_NV_optimus`) y la GPU pasa de 2,35 W en reposo a ~10 W con 27-73 %
  de uso. **Antes de esto la deducción era la contraria y habría sido falsa**:
  con el `WrapperCommand` vacío se dio por hecho que tiraba de la iGPU, pero no
  se había medido. Detalle en §29.
- **[VER] Compartir la pantalla de Hyprland con AnyDesk.** Salir hacia otro
  equipo funciona y está validado (§28), pero **no se ha probado la dirección
  contraria**: que este portátil sea el extremo controlado. El caso no es el
  mismo que el de TeamViewer de abajo: la ventana de AnyDesk es Wayland nativa
  mientras sus tripas leen geometría por X11, así que no se puede deducir el
  resultado de ninguno de los dos. Prueba: conectar desde otro equipo y mirar si
  se ve el escritorio o sale negro (2026-09-14).
- **[VER] Compartir la pantalla de Hyprland con TeamViewer.** La GUI funciona
  bajo XWayland y sirve para *ver* equipos remotos (§25), pero **no se ha
  intentado la dirección contraria**: que este portátil sea el extremo
  compartido. TeamViewer es un cliente de la era X11 y la captura de una sesión
  Wayland es otro asunto; se espera que falle o dé pantalla negra, pero es una
  suposición, no una comprobación. Prueba: conectar desde otro equipo y mirar
  si se ve el escritorio (2026-09-09).
- ~~**[VER] El perfil UCM de la SSL 2+ declara menos canales de los que tiene la
  revisión Mk II.**~~ **Resuelto el 2026-09-13**: no quedaba ningún canal físico
  sin exponer (los 8 de captura son 2 entradas + 6 de loopback; el par de
  reproducción 5/6 no suena por ninguna salida). El rótulo era un recuento mal
  declarado upstream, corregido con un parche local. Ver §22.
- **[VER]** hyprlock registra `Starting fade in` pese a tener
  `animations { enabled = false }` en `hyprlock.conf`. Cosmético: no se ha
  observado efecto sobre el bloqueo ni sobre el desbloqueo. Sin resolver
  (2026-07-27).
- ~~**[VER] Bluetooth: el kernel falla al cargar el firmware, pero el
  controlador responde.**~~ **Comprobado el 2026-09-14**: en el arranque actual
  (`linux-lts` 6.18.51-1) **no aparece ni una línea de error** en
  `journalctl -kb` —ni `FW download error recovery failed (-19)`, ni
  `sending frame failed`, ni `Failed to read MSFT supported features`—; el
  firmware `intel/ibt-0291-0291.sfi` carga entero (`Firmware timestamp 2026.26
  build 117936`, `Fseq status: Success`). Y ya hay aparatos reales emparejados,
  que era lo que faltaba: JBL Charge 5, OnePlus Buds Pro 3 y Pro 2. El JBL,
  conectado, expone el sink `bluez_output.F8_5C_7E_D3_B7_E3.1`, y `Super+Z` le
  pasa el predeterminado del sistema (§22). Ver
  `history/2026-09-14-audio-bluetooth-rotacion.md`.
  > **Discrepancia anotada, no corregida a ciegas:** `linux-firmware` sigue
  > siendo **20260810-2**, la misma versión con la que el error persistía el
  > 2026-08-24. Lo que ha cambiado desde entonces es el kernel, pero **no se ha
  > verificado** que sea esa la causa: lo único que consta es que hoy el error
  > no está.

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
| **yazi** | `theme.toml`, capa parcial | **Tema generado entero** (`yazi.toml` y `keymap.toml` siguen en Stow) |
| **ZapZap** | CSS inyectado en la página | **Hoja generada entera**, a los datos de la app, no a `~/.config` (§27) |

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
| Superficie flotante | `surface` (0.80) | las cajas de la barra y los tooltips |
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

### La barra son CAJAS, no una isla (2026-09-08)

Hasta esta fecha la barra era **una isla** de lado a lado: el fondo lo pintaba
`window#waybar > box` y todos los módulos vivían dentro. Ahora ese contenedor es
transparente y **el fondo lo lleva cada bloque**, así que sobre el fondo de
pantalla flotan seis cajas:

```
[ workspaces ] [ Claude ] [ CPU RAM GPU temp ]   [ reloj ]   [ sonido bt red vpn batería perfil ] [ ⏻ ]
```

Los módulos que comparten caja se agrupan con **`group/`** en `config.jsonc`
(`group/monitor` y `group/sistema`). Un `group/` no cambia el comportamiento de
sus módulos: solo los envuelve en un contenedor con id propio —`#monitor`,
`#sistema`— al que el CSS puede darle fondo y esquinas. Sin `drawer`, o sea que
se ven siempre desplegados; no son menús.

Dos detalles que costaron un intento cada uno:

- **El padding vertical va en la caja, no en los módulos de dentro.** Si lo
  llevara cada módulo, las cajas de un módulo y las de cuatro acabarían con
  alturas distintas.
- **La separación entre cajas es `pad_xs` (8 px entre dos), no `pad_2xs`.** Con
  `pad_2xs` —que es la separación de las píldoras de workspace— los bloques se
  tocaban y el conjunto volvía a leerse como una isla partida. Comprobado en
  captura.
- `#workspaces` **perdió su `margin-left` propio**: desde que es una caja, el
  margen se lo da la regla común, y mantener el suyo la dejaba desalineada
  respecto a las demás.

### Un tooltip es una notificación, y se estila como tal

Los tooltips de Waybar copian **punto por punto** el estilo de una notificación
de dunst con urgencia normal. No es parecido «a ojo»: los dos salen de los
mismos tokens, así que un cambio en `tokens.toml` los mueve a la vez.

| | dunst (`urgency_normal`) | tooltip (GTK CSS) |
|---|---|---|
| Fondo | `surface` + alfa `opacity_surface` | `alpha(@bg, opacity_surface)` |
| Radio | `corner_radius = radius` | `border-radius: radius` |
| Marco | `frame_width = border`, `frame_color = accent` | `border: border px solid @accent` |
| Relleno | `padding = pad_lg`, `horizontal_padding = pad_xl` | `padding: pad_lg pad_xl` |

El razonamiento es que cumplen el mismo papel —un bloque de texto que aparece
encima de todo y se va—, así que no había motivo para que se vieran distintos.
Antes el tooltip era `@bg` **opaco** con un filete de 1 px a `alpha(@fg, 0.18)`:
ni la transparencia ni el marco de acento de las notificaciones.

⚠️ **El marco va OPACO a propósito**, igual que en dunst: allí los fondos llevan
alfa y los marcos no, porque un borde translúcido se lee peor y el marco es lo
que delimita la pieza sobre el fondo de pantalla.

Sigue siendo obligatorio que el bloque `tooltip` exista: el `all: unset` del
reset borra también el estilo por defecto de GTK, incluido el fondo.

⚠️ **Pendiente de comprobación visual, y no por falta de intentos.** No hay
forma de provocar un tooltip desde el terminal en esta sesión: `hyprctl dispatch
movecursor` teletransporta el puntero sin generar los eventos de hover que GTK
necesita —probado con el reloj y con los módulos de monitorización, con
movimientos escalonados y esperas de hasta 3 s, capturando la pantalla
completa—, y no hay `wtype` ni `ydotool` instalados. Lo que sí se comprobó es
que el CSS generado en `~/.config/waybar/style.css` es exactamente
`background: alpha(@bg, 0.8)`, `border: 2px solid @accent`, `border-radius:
10px` y `padding: 12px 14px`, o sea los mismos valores que el artefacto de
dunst. **Queda verlo con el ratón.** Si el fondo saliera oscuro en vez de
translúcido, la causa sería que GTK3 no da ventana RGBA a los tooltips, y la
salida es volver a un fondo opaco.

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

### Modo oscuro de las APLICACIONES  **[OK]**

Añadido el 2026-09-13. Hasta entonces el escritorio era oscuro pero **todas las
aplicaciones abrían en claro**, que es una incoherencia fácil de pasar por alto:
matugen solo pinta los componentes del shell (Waybar, rofi, kitty, dunst,
wlogout, hyprlock, yazi). Las apps van por un camino totalmente distinto y
nadie les estaba diciendo nada.

**No hay un único interruptor: hay tres caminos, y cada familia usa el suyo.**

| Capa | Quién la lee | Dónde se fija |
|---|---|---|
| Portal `org.freedesktop.appearance color-scheme` | Firefox, Electron (VS Code, Obsidian, ZapZap), GTK4/libadwaita, Qt 6 vía plugin | clave gsettings, la pone `theme-apply` |
| `~/.config/gtk-{3,4}.0/settings.ini` | apps GTK3 que no consultan el portal | **plantilla de matugen** desde la 3.5 (antes: paquete Stow `gtk`) |
| `QT_QPA_PLATFORMTHEME` | Dolphin y demás Qt 6 | `hl.env` en `hyprland.lua` |

**La preferencia del portal la deduce `xdg-desktop-portal-gtk`** de la clave
gsettings `org.gnome.desktop.interface color-scheme`. Esa clave vive en
**dconf**, una base de datos binaria: no hay archivo que enlazar con Stow. Por
eso la fija `theme-apply` en cada arranque (sección 5c del script) **derivándola
de `matugen.mode`**, que ya está en `tokens.toml`. Así el modo se declara en un
solo sitio; no hay un segundo lugar donde decir si el sistema es oscuro.

> ⚠️ **TRAMPA: `QT_QPA_PLATFORMTHEME=gtk3` parece funcionar y no funciona.**
> Devuelve `ColorScheme.Dark` igual que la opción buena, pero la paleta real
> sale en `#faf9f8` — blanco—, porque en este sistema no hay ningún tema
> Adwaita-dark de GTK3 en `/usr/share/themes` (solo `Default` y `Emacs`). El
> valor correcto es **`xdgdesktopportal`**, que da `#323232` de fondo y
> `#f0f0f0` de texto. La comprobación válida es mirar la PALETA, no el nombre
> del esquema. Ambos plugins vienen en `qt6-base`; no hace falta instalar
> `qt6ct`, `breeze` ni `kvantum` — y el 2026-09-16 se comprobó que instalar
> `qt6ct` es además CONTRAPRODUCENTE: su plugin no implementa `colorScheme()`.
> Ver §33.

> **[HISTÓRICO] El paquete Stow `gtk` iba con `--no-folding`**, porque
> `~/.config/gtk-4.0` no existía y Stow lo habría enlazado como directorio
> completo, con lo que cualquier cosa que GTK escribiera dentro —los marcadores
> del selector de archivos, por ejemplo— habría aterrizado en el repositorio.
> **El paquete se retiró el 2026-09-16** (tarea 3.5): los dos `settings.ini` los
> genera ahora matugen y los directorios volvieron a ser reales, así que el
> problema que resolvía `--no-folding` ya no existe. Se conserva la nota porque
> el razonamiento sigue valiendo para `wlogout` y `fastfetch`.

**Validado el 2026-09-13** en las tres capas: el portal pasó de `0` a `1`;
`Gtk.Settings` devuelve `prefer-dark: True` y `Adwaita-dark`; y un proceso
lanzado por Hyprland tras el reload recibe la variable y Qt responde
`ColorScheme.Dark` con fondo `#323232`. Las apps ya abiertas necesitan
reiniciarse: leen la preferencia al arrancar.

> Para volver a claro no se toca ningún archivo de aplicación: basta cambiar
> `mode` en `theme/tokens.toml` y ejecutar `theme-apply`.
>
> **Esto último dejó de tener excepción el 2026-09-16.** Hasta la 3.5, el
> `settings.ini` del paquete `gtk` quedaba desfasado al cambiar de modo —era
> estático— y había que editarlo a mano. Ahora lo genera matugen desde el mismo
> `mode`, así que el interruptor es de verdad único. Ver §33.

---

## 19. Gestor de archivos de terminal (yazi)  **[OK]**

Tarea 3.3, completada el 2026-08-28. yazi **26.8.15** (repositorio `extra`),
duodécimo paquete Stow. Corría con los valores de fábrica desde la instalación:
`~/.config/yazi` no existía.

- **Config de comportamiento**: `dotfiles/yazi/.config/yazi/yazi.toml` y
  `keymap.toml` (enlazados por Stow).
- **Tema**: `~/.config/yazi/theme.toml`, ARTEFACTO generado por matugen desde
  `dotfiles/matugen/.config/matugen/templates/yazi-theme.toml`.
- **Atajos**: `docs/keybindings.md` → «Gestor de archivos (yazi)».

### Lo primero, porque invalida casi todo lo que se lee por ahí

**El paquete de Arch no instala ni un solo archivo de configuración de
ejemplo.** Los tres presets (`yazi.toml`, `keymap.toml`, `theme.toml`) van
COMPILADOS dentro del binario. `pacman -Ql yazi` solo devuelve binarios,
completions e iconos. La forma de leer los de la versión instalada es:

```
strings /usr/bin/yazi | grep -n '^\[mgr\]'      # y leer desde ahí
```

Y el nombre de la sección es **`[mgr]`, no `[manager]`**: se renombró río arriba
y prácticamente todo lo que circula usa el nombre viejo.

### El reparto: qué manda desde theme.toml y qué desde los ANSI de kitty

Es la pregunta que hubo que resolver ANTES de escribir nada, para no acabar con
el mismo color declarado en dos sitios — el problema que resolvió la 3.0.

**El preset de tema de yazi está escrito casi entero con NOMBRES ANSI**, no con
hexadecimales:

```
[mgr]      cwd = { fg = "cyan" }            border_style = { fg = "gray" }
[status]   perm_type = { fg = "green" }     perm_read = { fg = "yellow" }
[filetype] imagen amarillo · medios magenta · comprimido rojo · documento cian
           ejecutable verde · directorio azul
```

Solo los **iconos de archivo** llevan hexadecimales propios.

Y esos ANSI son los que kitty toma de `theme/tokens.toml` (§18). O sea que
**yazi ya estaba medio dentro del tema sin configurar nada**: no estaba «sin
tema», estaba **temado por herencia**. Lo que NO hacía era seguir al fondo de
pantalla, porque nada del preset usa el acento de matugen.

De ahí sale el reparto, que es el criterio de §18 aplicado tal cual:

| Elemento | De dónde sale | Por qué |
|---|---|---|
| Color por tipo de archivo, permisos del status | **ANSI de kitty** (fijos) | Es INFORMACIÓN, como `ls` y `git diff`. Un JPEG tiene que verse amarillo con cualquier fondo |
| Marcadores de copiar/cortar/seleccionar | **ANSI de kitty** (fijos) | El preset usa `lightgreen`/`lightred`/`lightyellow`, que en esta paleta **ya son** `state.ok`/`state.crit`/`state.warn`. Salen bien solos |
| Fondo y opacidad | **de kitty**, sin declarar nada | Ver abajo |
| Cromo: `cwd`, bordes, pestañas, indicador de modo, marcos y títulos de las cajas | **acento de matugen** | Es decoración, sigue al fondo. Mismo criterio que el cursor y la selección de kitty |
| Avisos y errores internos | **`[colors.state]`** | Un error se lee como error con cualquier fondo |

> ⚠️ **yazi NO pinta fondo propio: dibuja sobre el de kitty.** Por eso la
> opacidad de `[opacity].surface` y el translúcido le llegan solos y ya
> coherentes con la barra y las notificaciones. **Poner un `bg` en
> `[app].overall` lo rompería**, tapando la transparencia con un color liso. La
> plantilla no declara `[app]` a propósito.

### Por qué el tema se genera entero y no como fragmento

`theme.toml` de yazi es una **capa PARCIAL sobre el preset compilado**: solo hay
que declarar lo que cambia, no copiarlo entero. Eso lo pone en el grupo de
Waybar y fastfetch, pero por una razón distinta a la suya.

⚠️ **Y corrige un supuesto del roadmap.** Al planificar la 3.0 se anotó que
«rofi admite `@import` y yazi no». **Es falso**: yazi sí tiene una vía de
importación, `[flavor]`, que carga `flavors/<nombre>.yazi/flavor.toml`. Se
descartó igualmente, pero por otro motivo: **el `theme.toml` de yazi no contiene
NADA de comportamiento** —eso vive en `yazi.toml`—, así que no hay nada que
separar y un flavor solo añadiría un archivo puntero.

Consecuencia buena y gratis: si el artefacto falta —repo recién clonado, Stow
hecho y matugen aún sin ejecutar—, yazi arranca con el preset y **no se ve mal**,
porque el preset es ANSI y los ANSI de la sesión ya son los del proyecto. Es la
misma degradación elegante que el `?import` opcional de rofi, sin pedirla.

### Previsualizaciones: no hubo nada que habilitar

Todas son **plugins internos** del binario y **todas las herramientas ya estaban
instaladas**. Verificado leyendo el Lua embebido (`Command("ffmpeg")`,
`Command("pdftoppm")`, `Command("magick")`, `spawn_7z`):

| Tipo | Invoca | Paquete |
|---|---|---|
| Imagen (jpg/png/webp/gif) | — (Rust nativo) | — |
| AVIF · HEIC · JXL · SVG · fuentes | `magick` | imagemagick |
| PDF | `pdftoppm` | poppler |
| Vídeo | `ffmpeg` + `ffprobe` | ffmpeg |
| Comprimidos, ISO, AppImage, .deb/.rpm | `7z` / `7zz` | 7zip |
| Código, JSON | — (syntect interno) | — |

Medido el 2026-08-28, leyendo la cabecera que yazi manda al terminal:

| Archivo | Resultado |
|---|---|
| `.jpg` | imagen KGP `a=T,f=24,s=816,v=510` |
| `.pdf` | imagen KGP `s=816,v=1122` (proporción vertical correcta) |
| `.mp4` | imagen KGP `s=640,v=360` (fotograma extraído) |
| `.tar.gz` | listado de texto con el contenido |

**El protocolo gráfico de kitty (KGP) funciona de forma nativa**: 405 fragmentos
APC `_G` para una foto, cero sixel y cero `chafa`. No hacen falta `chafa` ni
`ueberzugpp`, y ninguno está instalado.

> **Tres correcciones a los supuestos de partida.** **`ffmpegthumbs` NO lo usa
> yazi**: es el thumbnailer de KDE, para Dolphin; yazi llama a `ffmpeg` y
> `ffprobe` directamente. **`unarchiver` tampoco**: usa 7z. Y **`mediainfo` sí,
> pero como opener** (`O` → «Show media info»), no como previsualizador.

Único ajuste: `image_quality` de 75 a **90** (el máximo que admite, lo valida el
propio binario) y la cota de la copia cacheada de 600x900 a **2560x1600**, que
es el tamaño del panel — o sea, el mayor tamaño que esta pantalla puede llegar
a pedir. Con 600 las fotos se veían blandas ya en el panel lateral, que mide el
36% del ancho de la ventana (medido, no supuesto: unos 930 px físicos a pantalla
completa).

> ⚠️ **La cota dejó de ser cosmética al añadir la vista a pantalla completa**
> (ampliación del 2026-08-28, más abajo). Maximizada, la previsualización pide
> el ancho entero y ahí la cota SÍ recorta, **sin avisar de nada**: no hay error,
> solo una imagen más blanda de lo que podría. Medido con la caché limpia entre
> pruebas: cota 900 → maximizado 900; cota 1200 → 1200; cota 2000 → 1200, que
> era ya la demanda real. La cota manda hasta que deja de mandar.

### Trampas verificadas

⚠️ **`keymap` SUSTITUYE el juego entero de atajos; `prepend_keymap` añade.** Con
la clave equivocada, yazi se queda solo con lo que haya en el archivo — ni `j`,
ni `k`, ni `q` para salir. Es un error de una palabra y no avisa. Lo mismo pasa
en `yazi.toml` con `rules` / `prepend_rules` de `[opener]`, `[open]` y
`[plugin]`.

⚠️ **yazi NO aplica el tema de usuario hasta terminar el handshake con el
terminal, y eso hace que las pruebas ingenuas MIENTAN.** Al arrancar manda una
batería de sondeos —`CSI ?996n` (esquema claro/oscuro), `OSC 11` (color de
fondo), `XTVERSION`, `DECRQSS`, `DA1`, tamaño de celda, protocolo gráfico— y
hasta que no los tiene contestados se queda con el preset compilado. Bajo
`script`, que no responde a nada, el resultado es que **`theme.toml` no se lee
en absoluto**: se puede dejar el archivo con TOML roto y yazi no protesta, ni
con `--debug` ni en `YAZI_LOG=debug`. Cuesta media hora concluir que la config
está mal cuando lo que está mal es el banco de pruebas. **La verificación buena
es abrir yazi en kitty y mirarlo**, exactamente como en rofi (§18). Para
comprobarlo sin abrir ventana hay que emular las respuestas del terminal en un
pty; así se verificó esta vez.

> Ojo con la diferencia: un `yazi.toml` roto **sí** aborta y con mensaje claro
> («Failed to parse config … Press \<Enter\> to continue with preset
> settings»). Un `theme.toml` roto, no. Los dos archivos no se tratan igual.

⚠️ **`stow yazi` a secas mete el artefacto DENTRO del repositorio.** Como
`~/.config/yazi` no existía, Stow enlaza el directorio entero (`LINK:
.config/yazi => …`, lo dice la simulación) y el `theme.toml` de matugen caería
en el repo. Hay que enlazar con **`--no-folding`**. Misma trampa que hubo que
deshacer en `wlogout` y `fastfetch`.

⚠️ **Los directorios de fábrica están en inglés y aquí no existen.** El preset
trae `g d` → `~/Downloads`; en este equipo es `~/Descargas`
(`~/.config/user-dirs.dirs`). Los cuatro atajos propios del `keymap.toml` no son
un capricho: son la corrección de un atajo roto y sus vecinos.

⚠️ **El orden alfabético de fábrica manda todo nombre acentuado al final de la
lista.** La comparación es por punto de código Unicode y la `á` (U+00E1) va
después de la `z`. Medido el 2026-08-28 con archivos de prueba:

```
sort_by = "alphabetical", translit = false   Alba  Bruno  Zoe  Ángel  Ávila
sort_by = "natural",      translit = true    Alba  Ángel  Ávila  Bruno  Zoe
```

En este equipo eso afecta a `Música`, `Imágenes`, `Vídeos` y `Público`, o sea a
cuatro de los directorios de `~`. De ahí `sort_translit = true`. `sort_by =
"natural"` va en el mismo lote por otra razón: ordena `archivo2` antes que
`archivo10`.

**`show_hidden = true` desde el 2026-09-17.** Lo que más se navega en este equipo
son dotfiles, y los paquetes Stow de este repositorio reproducen la ruta tal como
cuelga de `$HOME`: `dotfiles/hypr/` contiene **una sola entrada y es `.config`**.
Con los ocultos apagados, media docena de carpetas del repositorio parecen
vacías. La tecla `.` sigue alternándolos sobre la marcha —es el atajo de fábrica
de yazi, y el `keymap.toml` de este repo no lo toca—; el ajuste solo decide con
qué estado arranca.

### Lo que la 3.3 cambió fuera de su propio paquete

Es la primera tarea de la fase 3 que toca otro paquete Stow, `shell`, y las dos
razones son de peso:

- **`export EDITOR=vim`.** No es una preferencia: **arregla un fallo real**. El
  opener de texto de yazi es `${EDITOR:-vi} %s`, `EDITOR` estaba sin definir y
  **`/usr/bin/vi` NO EXISTE en este equipo** —comprobado, ningún paquete lo
  provee; solo está `vim`—, así que abrir un archivo de texto desde yazi
  fallaba. Definirlo en el shell lo arregla de raíz y de paso sirve a git,
  `systemctl edit` y a cualquier programa que respete la variable.
- **La función `y`.** Deja la shell en el directorio donde estabas al salir.
  Tiene que vivir en el shell porque **un proceso hijo no puede cambiar el
  directorio de su padre**: yazi escribe el suyo en un temporal (`--cwd-file`) y
  el `cd` lo hace la shell. Con `y` se salta, con `yazi` a secas no, y dentro
  del programa `q` guarda el directorio mientras que `Q` no.

### Ampliación (2026-08-28/29): ver la imagen a pantalla completa

Al usarlo se pidió que una imagen se pudiera ver grande, ocupando la terminal
entera, en vez de quedarse en el panel lateral. Lo hace **`M`**, y abre el visor
propio de kitty:

```toml
{ on = "M", run = 'shell --block -- kitten icat --hold --clear -- %s' }
```

`--hold` espera a que pulses una tecla; `--clear` retira las imágenes que ya
hubiera en pantalla. Es un VISOR, no un panel: mientras está abierto no se
navega con `j`/`k`.

> **De paso aclara un malentendido razonable: `v` NO es un visor.** Es el modo
> de selección VISUAL, estilo vim. Que no agrandase la imagen no era un fallo,
> era otra función. `v` se conserva intacto, y `M` está libre en el preset, así
> que **el proyecto no pisa ningún atajo de fábrica de yazi**.

#### Antes hubo un plugin que maximizaba el panel, y se retiró

La primera implementación era un plugin local que movía `rt.mgr.ratio` en
caliente —la palanca existe: es lo que hace el propio yazi al arrastrar el
separador entre paneles con el ratón— para que el panel de previsualización
ocupara toda la ventana. **Funcionaba, y aun así se tiró.** Merece quedar
escrito por qué, porque la idea es tentadora y volverá a parecer buena.

Mover el ratio obliga a pelearse con el repintado **diferencial** de ratatui
mientras el protocolo gráfico de kitty escribe celdas **por fuera** de su búfer.
Al encoger el panel esas celdas quedan huérfanas y nadie las sobrescribe. Dio
dos fallos seguidos, y **los dos los encontró el uso real, no las pruebas**:

1. Al volver, los paneles de archivos quedaban **en blanco** con los glifos de
   la imagen pintados por encima.
2. Arreglado eso (saliendo y volviendo a entrar en el directorio, que
   reconstruye el árbol de componentes), aparecieron **los separadores de
   columna borrados**.

Cada arreglo tapaba un trozo. Las variantes medidas, dos corridas de cada:

| Variante | Panel padre | Lista | Previsualización |
|---|---|---|---|
| `ui.render()` | vacío | vacía | ok |
| `+ arrow ±1` | **vacío** | ok | ok |
| `+ leave`/`enter` | ok | ok | ok — pero se fueron los separadores |
| `ui.hide()` + soltar permiso | ok | ok | **muerta para siempre** |

Hallazgos que conviene no repetir:

- **`ui.hide()` parece la respuesta y no lo es.** Es lo que usan fzf y zoxide
  para ceder la pantalla, y fuerza un repintado completo: arregla los paneles,
  pero deja la previsualización **muerta de forma permanente** — la imagen se
  retransmite y no se coloca nunca, ni siquiera navegando.
- **El plugin no puede ser asíncrono.** Sin el marcador `--- @sync entry`,
  escribir `rt.mgr.ratio` **no hace absolutamente nada**: medido, 4 de 4.
- **`leave`/`enter` necesita guarda en la raíz.** En `/` no se puede subir, así
  que `leave` no hacía nada pero `enter` sí entraba: la tecla te metía en el
  primer subdirectorio (el título pasaba de `/` a `bin`).

**Por qué el visor no puede tener esta clase de fallo.** `shell --block` es la
MISMA vía por la que yazi abre `$EDITOR` o fzf: suelta el terminal —verificado,
emite `ESC[?1049l` y desactiva ratón, *bracketed paste* y compañía—, deja correr
el programa y **se redibuja entero al volver**. Medido con un programa que borra
la pantalla y escribe encima: al regresar vuelven los paneles, la lista, la
previsualización y los 76 separadores, 3 corridas de 3. No hay repintado que
arreglar porque no se toca el repintado.

#### ⚠️ El archivo se pasa con `%s`, no con `$0`

Es lo que hizo fallar la primera versión del visor, y el error no ayudaba nada:

```
Error: Stat sh: stat sh: no such file or directory
exit=1 archivo=[sh]
```

`icat` había recibido el texto **`sh`** como nombre de archivo. La causa, medida
desde dentro del propio comando: **el `shell` de yazi no pasa parámetros
posicionales** —`$#` vale 0 y `$0` es `sh`, el nombre de la shell—. Lo que hace
es **sustituir `%s` dentro del texto del comando**, igual que las reglas de
`[opener]`. Y lo sustituye ya entrecomillado: verificado con un archivo llamado
«foto con espacios.jpg», que llega como UN solo argumento.

> ⚠️ **Y una trampa de medición que costó el error entero.** Antes de escribir
> nada comprobé cómo llegaba el archivo con una sonda que hacía
> `printf "0=[%s]" "$0"` … y devolvió la ruta correcta, así que di por bueno
> `$0`. **La sonda se estaba engañando sola**: el `%s` del formato del `printf`
> era justamente el marcador que yazi sustituye, de modo que la ruta que leí no
> venía de `$0` sino de la sustitución. Una sonda que contiene el marcador que
> intenta medir no mide nada. Se ve en cuanto se pregunta por `$#`, que vale 0.

#### La cota de la caché volvió a 1200

Estuvo un día en 2560x1600: mientras `M` maximizaba el PANEL, la previsualización
llegaba a pedir el ancho entero y la cota recortaba (medido con la caché limpia:
cota 1200 → maximizado 1200; cota 2000 → 1200, la demanda real). **El visor de
kitty lee el ARCHIVO ORIGINAL y no pasa por esta caché**, así que nada vuelve a
pedir más de los ~930 px del panel lateral y mantener 2560 solo engordaría la
caché sin verse en pantalla.


### Lo que se dejó fuera a propósito

- **Los rótulos de los botones de confirmación** (`[confirm].btn_labels`, hoy
  «[Y]es / (N)o») **no pasan a `strings.toml`**, al revés que los de hyprlock y
  rofi. Traducirlos sin tocar también las teclas del `[confirm]` de
  `keymap.toml` dejaría el rótulo diciendo una letra y el atajo esperando otra.
  Es un cambio de dos archivos, no de uno, y no entraba en esta tarea.
- **No se redefine ningún `[opener]`.** Redefinir uno obliga a copiar al repo
  una lista del preset, que se quedaría vieja en silencio cuando yazi la cambie
  río arriba. Es justo el patrón que este proyecto evita.


---

## 20. Distribución de teclado por dispositivo  **[OK]**

Añadido el 2026-09-07, al conectar un teclado USB externo con serigrafía
**americana** a un equipo cuyo teclado integrado es **español**. Cada teclado se
queda en su distribución, y `Super + Espacio` alterna la del teclado que pulsa
el atajo sin tocar la del otro.

- **Config**: `dotfiles/hypr/.config/hypr/hyprland.lua` (bloque `input`,
  `hl.device` de los endpoints del Semitek, y el bind).
- **Script**: `scripts/kb-layout.sh`, enlazado como `kb-layout` en
  `~/.local/bin` por el paquete Stow `bin`.
- **Atajo**: `docs/keybindings.md` → «Distribución de teclado».

### El estado de xkb es por dispositivo, no de la sesión

Esta es la pieza que lo hace posible y la que no se parece a X11. En Wayland
cada teclado lleva su propio índice de distribución activa, así que basta con
cargar la MISMA lista en todos y darle a cada uno un punto de partida distinto:

| Ámbito                        | `kb_layout` | `kb_variant` | Arranca en |
|-------------------------------|-------------|--------------|------------|
| Global (portátil incluido)    | `es,us`     | `,intl`      | es         |
| `semitek-usb-hid-gaming-keyboard` y `-1` | `us,es` | `intl,` | us    |

Las dos distribuciones tienen que estar en ambas listas: `switchxkblayout next`
**rota entre las ya cargadas**, no carga ninguna nueva. Con `kb_layout = "es"` a
secas el atajo no tendría a dónde ir.

`kb_variant` se empareja **posicionalmente** con `kb_layout`, de ahí que las dos
listas estén invertidas la una respecto a la otra: en ambos casos `us` lleva
`intl` y `es` va sin variante.

### `intl` vs `altgr-intl`: se probaron las dos

`us` a secas no da tildes, ñ ni ç, así que hace falta una variante
International. Hay dos, y **lo único que las separa es qué va en el nivel base y
qué detrás de AltGr** — `altgr-intl` hace literalmente `include "us(intl)"` en su
definición y solo mueve cinco teclas muertas:

| | `intl` | `altgr-intl` |
|---|---|---|
| Nombre xkb | English (US, intl., with dead keys) | English (intl., with AltGr dead keys) |
| `' " ` ~ ^` en el nivel base | **muertas** | literales |
| Tilde | `'` + vocal | AltGr + `'` + vocal |
| Carácter literal `'` | AltGr + `'` | `'` |

El 2026-09-07 se pasó por las dos, en este orden: `intl` → `altgr-intl` (al
perder las comillas) → **`intl`, que es lo que queda**. La decisión final es
deliberada y se apoya en un detalle que no salta a la vista:

> **En `intl` el nivel de AltGr sigue dando el carácter literal.** No se pierde
> ninguna tecla, solo cambia cuál cuesta una pulsación y cuál dos.

```
AltGr + '          '        AltGr + `          `
AltGr + Shift + '  "        AltGr + Shift + `  ~        AltGr + Shift + 6  ^
```

Como los acentos se escriben más a menudo que las comillas, sale a cuenta que lo
barato sean los acentos. Con `altgr-intl` sería justo al revés. La comparación
está en `/usr/share/X11/xkb/symbols/us`; ambas terminan con
`include "level3(ralt_switch)"`, o sea que **AltGr es el Alt DERECHO**.

| Carácter | Cómo se escribe en `us(intl)` |
|----------|-------------------------------|
| á é í ó ú | `'` y luego la vocal        |
| à è ì ò ù | `` ` `` y luego la vocal    |
| â ê î ô û | Shift + `6` y luego la vocal |
| ñ        | Shift + `` ` `` y luego `n`, o AltGr + `n` |
| ç        | `'` y luego `c`, o AltGr + `,` |
| ü        | `"` y luego `u`               |
| ¿ ¡      | AltGr + `/` y AltGr + `1`     |
| € §      | AltGr + `5` y AltGr + `;`     |

Para el carácter suelto de una tecla muerta también sirve pulsar **espacio**
detrás, además del AltGr de arriba.

### ⚠️ Un teclado USB puede ser VARIOS teclados

El Semitek expone dos endpoints HID y Hyprland los ve como dos teclados con
estado xkb independiente:

```
$ grep -A6 -i "Name=.*semitek" /proc/bus/input/devices
N: Name="SEMITEK USB-HID Gaming Keyboard"   ...input0   H: Handlers=sysrq kbd leds event29
N: Name="SEMITEK USB-HID Gaming Keyboard"   ...input2   H: Handlers=sysrq kbd event30 mouse4
```

Los dos llevan handler `kbd`, o sea que los dos emiten teclas. De ahí las dos
consecuencias del diseño:

1. **La `kb_layout` va en los dos** `hl.device`. Solo en el primero, parte de
   las teclas se seguiría interpretando en es.
2. **`hyprctl switchxkblayout current next` a secas NO vale.** `current` alterna
   solo el endpoint que mandó la pulsación y los DESINCRONIZA (comprobado:
   `-keyboard` en Spanish y `-keyboard-1` en English (US) a la vez). Por eso
   `kb-layout` compara el `active_layout_index` de antes y después, deduce qué
   dispositivo cambió y alinea a sus hermanos —los `<nombre>-N`— al mismo
   índice.

### Por qué el script no se fía de `main`

`hyprctl devices` marca un teclado como `main`, y la tentación es usarlo para
saber cuál acaba de cambiar. **No son lo mismo**: durante las pruebas `main` era
el Semitek mientras `current` resolvía a `at-translated-set-2-keyboard`, el
teclado del portátil. Comparar las dos instantáneas es lo único que identifica
con certeza el dispositivo afectado.

### Detalles que se comprobaron

- **El atajo se resuelve por código de tecla**, no por símbolo
  (`resolve_binds_by_sym` sigue en su valor por defecto), así que `Super +
  Espacio` cae en la misma tecla física en es y en us. `Super + Espacio` no
  estaba ocupado por ningún otro bind.
- **`switchxkblayout` acepta un índice numérico** además de `next`/`prev`; es lo
  que usa el script para alinear los hermanos.
- **No se usa la opción xkb `grp:win_space_toggle`**, que haría lo mismo sin
  script. Se descartó porque no resuelve el problema de los endpoints
  desincronizados, no puede avisar por notificación y deja el atajo invisible
  desde `hyprland.lua`, escondido en una cadena de opciones de xkb.
- El teclado externo declara también un endpoint de ratón
  (`semitek-usb-hid-gaming-keyboard-2`), que no aparece en la lista de teclados
  y no se toca.

## 21. Toolchain de compilación C/C++  **[OK]**

**No hubo nada que instalar.** El 2026-09-08 se pidió instalar `g++` y la
comprobación previa lo encontró ya presente y funcionando. Se documenta el
hallazgo en lugar de fabricar una instalación.

| Componente | Versión | Ruta | Motivo de instalación |
|------------|---------|------|-----------------------|
| `g++` / `gcc` | 16.2.1 20260810 (`gcc 16.2.1+r23+gd564253eb6c8-1`) | `/usr/bin/g++`, `/usr/bin/gcc` | **dependencia**, no explícito |
| `binutils`, `make`, `pkgconf` | — | `/usr/bin` | dependencia |
| `gdb` | 17.2-1 | `/usr/bin/gdb` | dependencia |
| `clang` | 22.1.8-1 | `/usr/bin/clang` | dependencia |

Target: `x86_64-pc-linux-gnu`. `gcc` se instaló el **2026-08-24**, en la
actualización completa posterior al incidente de arranque (§3).

**No instalados:** `cmake`, `ninja`, `valgrind`, `ccache`, `lldb`. Si alguno
hace falta, entra por su propia tarea y **sí** debe quedar explícito en
`packages/pacman-explicit.txt`.

### ⚠️ `gcc` no aparece en el inventario, y aun así la restauración lo recupera

Buscar `gcc` en `packages/pacman-explicit.txt` no da nada, y eso invita a
concluir que falta. No falta: el inventario se genera con `pacman -Qqe`, que
lista **solo lo explícito**, y `gcc` está marcado como dependencia. Quien lo
arrastra es **`base-devel`** (metapaquete que sí está explícito, y que depende de
`gcc`, `binutils`, `make`, `pkgconf` y compañía). Reinstalar desde `packages/`
devuelve el compilador por esa vía.

Esto **no** es uno de los agujeros silenciosos de §14: aquí el paquete sí vuelve.
Pero conviene no "arreglarlo" añadiendo `gcc` a mano al inventario — el archivo se
regenera con `scripts/update-inventories.sh` y la línea desaparecería en la
siguiente pasada. Si algún día se quiere que `gcc` sobreviva por sí mismo a un
`pacman -Qqe`, el cambio correcto es marcarlo explícito en el sistema
(`sudo pacman -D --asexplicit gcc`), no editar el `.txt`. Hoy no hace falta.

### Estándares por defecto: C++20 y C23, no C++17

Comprobado imprimiendo las macros, no leído de la documentación:

- `g++` sin `-std`: `__cplusplus` = `202002` → **gnu++20**.
- `gcc` sin `-std`: `__STDC_VERSION__` = `202311` → **gnu23**.

Los dos son más nuevos que los valores que suele dar por supuestos la
documentación de terceros (C++17 y C17). Un `-std=` explícito en cualquier
`Makefile` o `compile_flags.txt` del repositorio evita la sorpresa cuando GCC
vuelva a mover el defecto.

### Validación observada

```bash
g++ --version                       # g++ (GCC) 16.2.1 20260810
pacman -Qo /usr/bin/g++             # gcc 16.2.1+r23+gd564253eb6c8-1
g++ -std=c++23 -Wall -O2 prueba.cpp -o prueba && ./prueba
```

El programa de prueba usa `<ranges>` y `std::views::filter` (biblioteca de C++20
en adelante), compila sin avisos con `-Wall` y se ejecuta con salida correcta y
código de salida 0. Es decir: se validó el **compilador y la libstdc++**, no solo
la presencia del binario. El archivo de prueba se escribió fuera del repositorio
y no se versiona.

## 22. Interfaz de audio USB (SSL 2+ Mk II)  **[OK]**

Solid State Logic SSL 2+ Mk II conectada por USB (`ID 31e9:0009`, `bcdDevice
0116`), identificador ALSA **`II`**. **No hizo falta instalar ni un solo
controlador**: es *class-compliant* (USB Audio Class 2) y la maneja
`snd-usb-audio`, que ya viene en el kernel. Comprobado el 2026-09-08 con la
interfaz enchufada y sonando.

> **El NÚMERO de tarjeta no es fijo.** Esta sección decía «tarjeta ALSA `1
> [II]`» hasta el 2026-09-13, cuando se comprobó que era la **2** (`hw:2`): la 1
> es `sof-hda-dsp` y la 0 la NVIDIA. El número depende del orden de enumeración
> y cambia entre arranques y reconexiones. Lo estable es el **identificador**
> (`II`) y el nombre del sink, que es justamente por lo que `audio-salida`
> busca por nombre y no por ID.

**No existe SSL 360° para Linux y no se echa en falta.** `amixer -cII scontrols`
devuelve **cero controles**: esta interfaz no expone mezclador por software, todo
el control (ganancia, +4K, MONITOR MIX, 48V, auriculares) es físico y vive en el
panel frontal. Lo que en Windows haría el software aquí ya lo hacen los mandos.

### Salidas del sistema

| Sink | Descripción |
|------|-------------|
| `alsa_output.usb-Solid_State_Logic_SSL_2__Mk_II-00.HiFi__Line1__sink` | SSL, Line Outputs 1/L + 2/R (**el que usa WirePlumber por defecto**) |
| `alsa_output.usb-...HiFi__Line2__sink` | SSL, Line Outputs 3 + 4 |
| `alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink` | Altavoces del portátil |
| `...HiFi__HDMI1/2/3__sink` | HDMI/DP del iGPU Intel |
| `alsa_output.pci-0000_01_00.1.hdmi-stereo` | HDMI de la RTX 4060 (§6) |

Los **siete** sinks se pusieron al **100% y sin mute** el 2026-09-08 (venían
dispares: 40%, 60%, 85%, y HDMI2 al 125%).

### Rotar la salida: `audio-salida` + `Super+Z`

Script `scripts/audio-salida.sh`, enlazado como `audio-salida` en
`~/.local/bin` por el paquete Stow `bin`; atajo en `hyprland.lua`. Rota entre
los altavoces internos, la interfaz USB y **cualquier salida Bluetooth
conectada**, sin desenchufar nada; `audio-salida --status` lista las salidas,
marca la activa con `*` y con `·` las demás paradas de la rotación.

El orden es fijo —**internos → USB → Bluetooth → internos**— y solo entran las
salidas que existen en ese momento, así que sin interfaz ni Bluetooth el atajo
sigue siendo el ida y vuelta de siempre. Si hay varios aparatos Bluetooth
conectados a la vez, cada uno es una parada más, ordenados por nombre para que
la secuencia no cambie entre reconexiones.

- **Por qué no basta `pactl set-default-sink`**: cambiar el predeterminado solo
  afecta a los flujos nuevos y a los que no tengan destino fijado. Una app que ya
  esté sonando se queda donde estaba. El script mueve además todos los
  `sink-inputs` vivos, y por eso el atajo vale para *todo el sistema*.
- **Identificación por nombre, no por ID**: los IDs de `wpctl`/`pactl` se
  reasignan en cada arranque y en cada reconexión de la interfaz.
- **Los HDMI quedan fuera a propósito**: este equipo expone cuatro sinks HDMI/DP
  que aparecen aunque no haya nada enchufado; incluirlos llenaría la rotación de
  destinos mudos. Para esos casos, pavucontrol (clic izquierdo en el icono de
  volumen de Waybar). Si a pesar de todo un HDMI acaba siendo el predeterminado,
  `Super+Z` entra por los altavoces internos.
- **El Bluetooth sí entra, y no estorba cuando no está**: a diferencia de los
  HDMI, un `bluez_output.<MAC>.N` solo existe mientras el aparato está
  emparejado **y** conectado, de modo que la rotación se encoge sola. El nombre
  lleva la MAC, que es fija (la del JBL Charge 5 es `F8:5C:7E:D3:B7:E3`).
- El destino se **desmutea** al cambiar —puede venir silenciado de otra sesión—
  pero **el volumen no se toca**, para respetar el nivel de cada salida.

Verificado el 2026-09-08 en ambos sentidos: con Firefox reproduciendo, el flujo
saltó de la SSL a los altavoces y de vuelta. **Revalidado el 2026-09-14** con el
JBL Charge 5 conectado: vuelta completa `altavoces → SSL Line1 → JBL Charge 5 →
altavoces`, con `pactl get-default-sink` confirmando cada parada, y un
predeterminado forzado al HDMI de la NVIDIA volvió a los altavoces internos.
Lo verificado es el **enrutado**, no que el altavoz suene. Por qué una rotación
y no más ramas, en `history/2026-09-14-audio-bluetooth-rotacion.md`.

### El rótulo `[ALSA UCM error]`, resuelto  **[OK]**

Hasta el 2026-09-13 la tarjeta aparecía en todas partes —pavucontrol, Waybar, el
selector de salida— como `SSL 2+ Mk II [ALSA UCM error]`, y wireplumber
registraba en cada arranque:

```
spa.alsa: Error in ALSA UCM profile for _ucm0004.hw:II,0 (HiFi: Line2: sink): PlaybackChannels=4 < avail 6
spa.alsa: Error in ALSA UCM profile for _ucm0004.hw:II,0 (HiFi: Mic2: source): CaptureChannels=4 < avail 8
```

**Causa.** El perfil de `alsa-ucm-conf` (`ucm2/USB-Audio/SolidStateLabs/`)
declaraba 4 canales de reproducción y 4 de captura. El hardware expone **6 y 8**
(`/proc/asound/cardN/stream0`). PipeWire compara ambos en `libspa-alsa.so` y, si
no cuadran, cuelga la cadena literal `%s [ALSA UCM error]` de la descripción de
la tarjeta. El soporte de la MkII se añadió upstream **sin probarlo en un
aparato real**, heredando los 4/4 de la MkI.

**No faltaba ningún canal físico.** Según la documentación de SSL, los 8 de
captura son **2 entradas reales + 6 de loopback** (3 pares estéreo, que llegaron
por actualización de firmware); de los 6 de reproducción, 4 son los jacks
balanceados del panel trasero (salidas 1-4; la MkII sustituyó los RCA de la MkI)
y el par **5/6 no suena por ninguna salida**. Los auriculares A y B toman ambos
los buses 1/2 y 3/4 — el botón **3&4** conmuta B a 3-4 para dar una mezcla
independiente. `Line1`, `Line2`, `Mic1` y `Mic2` ya cubrían todo lo que tiene
conectores; no había nada que recuperar.

**Arreglo aplicado (parche local).** Es el PR **#837** de `alsa-ucm-conf` (Alan
Tran-Kiem, 2026-08-24), que añade una condición para `USB31e9:0009` con
`DirectPlaybackChannels 6` / `DirectCaptureChannels 8` y una rama `If.chn6` que
sabe partir un split de 6 canales. Su autor lo probó en una Mk II con el mismo
`bcdDevice 0116` que esta. Se aplica con `scripts/alsa-ucm-apply.sh`, que guarda
los originales en `/var/lib/arch-msi/alsa-ucm-orig/`.

> ⚠️ **El PR sigue ABIERTO y sin revisar** (comprobado el 2026-09-13: `state:
> open`, 0 comentarios, y la última etiqueta upstream es `v1.2.16.1`, la misma
> que hay instalada). Esto es un parche local sobre archivos de un paquete:
> **cada actualización de `alsa-ucm-conf` los devuelve en silencio y el rótulo
> vuelve.** Hay que reejecutar el script. No hay forma limpia de evitarlo:
> `alsa-lib` solo busca perfiles UCM en `/usr/share/alsa/ucm2`, sin ruta de
> override en `/etc` ni en `$HOME`.
>
> **Cuando el PR entre upstream esto sobra entero:** `--revert`, borrar
> `system/alsa/` y `scripts/alsa-ucm-apply.sh`, y quitar esta nota.
> https://github.com/alsa-project/alsa-ucm-conf/pull/837

**Validado el 2026-09-13** tras aplicar y reiniciar wireplumber: ninguna línea
de UCM en el journal, `device.description = "SSL 2+ Mk II"` sin sufijo, y los
sinks `HiFi__Line1__sink` / `HiFi__Line2__sink` intactos, de modo que
`audio-salida` y `Super+Z` siguen funcionando.

**Descartado: el perfil `pro-audio`.** Saca los 6+8 canales en crudo, pero sin
nombres (`aux0…aux5`) y **sin quitar el rótulo** —la cadena se fija al sondear
la tarjeta, no depende del perfil activo—, y además rompería `audio-salida`, que
busca el sink por el nombre `Line1`, inexistente en ese perfil.

## 23. Monitorización del equipo en Waybar  **[OK]**

Cuatro módulos a la izquierda de la barra, tras el de Claude: uso de CPU, uso de
RAM, uso de la dGPU y temperaturas de CPU y GPU. Cifra corta en la barra y
desglose en el tooltip; clic en cualquiera de los cuatro abre **btop**.

| Módulo | Tipo | Barra | Tooltip |
|--------|------|-------|---------|
| `cpu` | nativo | `󰻠 11%` | carga 1/5/15 min |
| `memory` | nativo | `󰘚 33%` | GiB usados/total y disponible |
| `custom/gpu` | script | `󰢮 25%` | modelo, VRAM usada/total, estado RTD3 |
| `custom/temps` | script | `󰔏 77°/60°` | CPU (paquete) y GPU por separado |

Intervalo de 5 s en los cuatro, el mismo que red y batería.

### ⚠️ El módulo de GPU no puede despertar la tarjeta

Es la pieza central del diseño, no un detalle. Waybar **no trae módulo de GPU**,
y el driver propietario de NVIDIA **no expone `hwmon`**: bajo
`/sys/bus/pci/devices/0000:01:00.0/` no hay temperatura ni un `gpu_busy_percent`
como el que publican las Radeon. La única fuente de uso, VRAM y temperatura es
`nvidia-smi` — **y `nvidia-smi` despierta la tarjeta**.

Este equipo va con PRIME offload + Runtime D3 (invariante del proyecto), o sea
que la RTX 4060 se suspende sola cuando nadie la usa. Un módulo que la sondeara
cada 5 s la dejaría encendida para siempre y se comería la batería sin que nadie
estuviera usando la gráfica.

La solución es leer **antes** `power/runtime_status`, que es sysfs puro y no toca
el hardware, y llamar a `nvidia-smi` solo si ya está `active`. Ese estado es
exactamente el criterio que se quería: pasa a `active` tanto con el monitor
externo por HDMI —que cuelga de la dGPU, §6— como en cuanto una aplicación la usa
con `prime-run`. Dormida, el módulo muestra `󰤄` y las temperaturas `77°/–`;
el guion, y no un `0`, porque la GPU no está a cero grados: es que no se ha
preguntado.

### Detalles que no se ven pero sostienen el módulo

- **Una sola consulta por intervalo.** `gpu` y `temps` necesitan los mismos
  datos y Waybar los invoca por separado, así que el script cachea la salida de
  `nvidia-smi` 2 s en `$XDG_RUNTIME_DIR` y la escribe de forma atómica. Sin eso
  serían dos consultas descoordinadas a la tarjeta cada 5 s.
- **El sensor de CPU se ancla al dispositivo, no a `/sys/class/hwmon/hwmonN`.**
  Esos números se reparten por orden de registro de los drivers y **cambian de un
  arranque a otro** (hoy `hwmon5`). La ruta estable es
  `/sys/devices/platform/coretemp.0/hwmon` + `temp1_input`, que es «Package id
  0», la del paquete entero; los `temp2..N` son núcleos sueltos. El módulo
  nativo `temperature` admite justo eso con `hwmon-path-abs` + `input-filename`,
  pero aquí la temperatura la sirve el script para poder juntarla con la de la
  GPU sin una segunda consulta.
- **El icono de RAM es 󰘚, no 󰍛.** Nerd Font llama «memory» al segundo,
  pero dibuja un chip cuadrado con patillas prácticamente idéntico al 󰻠 de la
  CPU, y los dos módulos van pegados. Comprobado renderizando ambos con
  JetBrainsMono Nerd Font al tamaño real de la barra: a 13 px no se distinguen.
  El DIMM es un rectángulo con bandas y se lee de un vistazo.
- **Umbrales de aviso**: 85 °C la CPU, 80 °C la GPU. Solo pintan la clase CSS
  `aviso` (ámbar); no hacen nada más.

### Validación observada

Contrastado con las fuentes, no con la propia barra:

| Barra | Fuente independiente |
|-------|----------------------|
| RAM 32 % | `free`: 4,9 GiB de 15 GiB = 32 % |
| GPU 24 % · VRAM 90 MiB | `nvidia-smi`: 24 %, 90 MiB / 8188 MiB |
| Temp CPU 71° | `sensors`: `Package id 0: +71.0°C` |
| Temp GPU 57° | `nvidia-smi`: 57 |

La rama de RTD3 se probó con el `runtime_status` simulado en `suspended`:
devuelve `󰤄` y `77°/–`, y **la caché de `nvidia-smi` no se toca**, o sea que
la consulta no llega a ejecutarse.

⚠️ **Falta comprobarlo con la tarjeta realmente dormida**, que requiere
desconectar el HDMI: con el monitor puesto, la dGPU está `active` de forma
permanente y esa rama no se alcanza. La prueba es mirar que
`power/runtime_suspended_time` siga creciendo con la barra en marcha.

### Archivos

- `scripts/waybar-monitor.sh`, enlazado como `waybar-monitor` en `~/.local/bin`
  por el paquete Stow `bin` (convención en §13).
- Plantillas `waybar-config.jsonc` y `waybar-style.css` de matugen. **La config
  de Waybar es un artefacto generado**: no se edita `~/.config/waybar/`, se edita
  la plantilla y se pasa `theme-apply` (§18).
- `theme/fallback/` regenerado con `theme-apply --save-fallback`. De paso quedó
  al día: **conservaba el `persistent-workspaces: {"*": 10}` viejo**, que la
  plantilla marca como «no volver a esto» desde el 2026-09-07 porque con dos
  pantallas crea los escritorios 11–20. Un `theme-apply --fallback` habría
  reintroducido ese fallo.

**A `packages/` no añade nada**: `jq` y `btop` ya estaban explícitos y
`nvidia-smi` lo trae `nvidia-utils`. Comprobado regenerando el inventario.

## 24. Greeter de SDDM  **[OK]**

La pantalla de inicio de sesión, a juego con hyprlock: mismo fondo desenfocado,
mismo reloj blanco arriba, mismo campo con contorno de acento y la misma fuente.

**Punto de partida (2026-09-08): no existía NINGUNA configuración de SDDM.** Ni
`/etc/sddm.conf` ni `/etc/sddm.conf.d/`, y `Current=` vacío, o sea el greeter de
fábrica desde la instalación. Es el estado que describía el usuario y se
confirmó antes de tocar nada.

| | |
|---|---|
| Gestor | SDDM 0.21.0-7. ⚠️ El daemon lanza **`sddm-greeter` (Qt5)**, no el binario Qt6 que también trae el paquete |
| Sesión del greeter | **Xorg** en `tty2` (§9), aunque la sesión de usuario sea Wayland |
| Tema | `arch-msi`, Theme-API 2.0 |
| Instalado en | `/usr/share/sddm/themes/arch-msi/` (root) |
| Activado por | `/etc/sddm.conf.d/10-arch-msi.conf` |

### Por qué estrena el directorio `system/`

Es **el primer componente que no vive en `$HOME`**, así que no puede ir por
Stow. `system/` guarda la copia versionada de lo que va fuera del home, con la
ruta de destino reflejada en su estructura:

```
system/sddm/arch-msi/{Main.qml, metadata.desktop}   → /usr/share/sddm/themes/arch-msi/
system/etc/sddm.conf.d/10-arch-msi.conf             → /etc/sddm.conf.d/
```

Nada de ahí se enlaza: lo **copia** `scripts/greeter-apply.sh` con sudo. Un
enlace a un archivo del repositorio dentro de `/usr/share` sería peor que una
copia: dejaría al greeter dependiendo de que el home esté montado y de una ruta
de clonado concreta.

### El reparto: estructura versionada, valores generados

Es el mismo patrón que hyprlock, y funciona porque **SDDM expone las claves de
`theme.conf` al QML como `config.<clave>`** (Theme-API 2.0). Así que no hace
falta generar el QML entero como la hoja de Waybar:

- `Main.qml` — versionado, no cambia al cambiar el fondo.
- `theme.conf` — plantilla de matugen → artefacto en `~/.config/sddm-arch-msi/`.
- `background.jpg` — lo genera el instalador a partir del fondo en uso.

### ⚠️ El único componente del tema que NO se actualiza solo

`theme-apply` deja el artefacto en el home y **ahí se queda**. Para que el
greeter cambie hay que ejecutar, a mano y con sudo:

```bash
theme-apply          # sin sudo, como siempre
sudo greeter-apply   # y esto, que es lo que llega al greeter
```

Dos hechos lo obligan: el tema tiene que estar en `/usr/share/sddm/themes/`, que
es de root, y **el usuario `sddm` (uid 965) no puede leer `/home/elok`**, que es
`drwx------`, así que ni el QML ni la imagen pueden quedarse en el home.

La alternativa era dejar el directorio del tema a nombre del usuario para que
`theme-apply` lo reescribiera solo. **Se descartó a propósito**: ese QML lo
ejecuta el greeter ANTES del login, así que hacerlo escribible sin root
convertiría la pantalla de acceso en algo modificable por cualquier cosa que
corra como el usuario. Consecuencia asumida: al cambiar de fondo, el greeter se
queda con el anterior hasta el siguiente `sudo greeter-apply`.

### ⚠️ Con sudo hay que dar la RUTA COMPLETA

`sudo greeter-apply` responde **`command not found`** aunque `greeter-apply`
funcione en la sesión. No es un fallo del enlace: sudo no hereda el PATH del
usuario, usa el `secure_path` de `/etc/sudoers`, que trae `/usr/bin` y compañía
pero **no `~/.local/bin`**. Hay que invocarlo así:

```bash
sudo /home/elok/Projects/arch-msi/scripts/greeter-apply.sh
```

Es el primer script del repositorio que se ejecuta como root, así que ninguno de
los otros se topa con esto. Desde el 2026-09-08 el propio script lo dice: al
llamarlo sin root imprime el comando con la ruta ya resuelta en vez de un «hace
falta root» a secas.

### Tres trampas que costaron un intento cada una

1. **El desenfoque NO se hace en el QML.** La primera versión usaba
   `MultiEffect` de `QtQuick.Effects` y la imagen **solo cubría 1600x1000 de una
   ventana de 2560x1600**: MultiEffect resuelve la textura de origen en píxeles
   LÓGICOS y la pinta sin escalarla por el `devicePixelRatio`, así que en un
   panel HiDPI el fondo se quedaba en un rectángulo en la esquina. Ahora la
   imagen se procesa con ImageMagick al instalar: sin shader, sin depender del
   DPI, y el greeter arranca sin trabajo de GPU. El coste —que el desenfoque se
   congela con la imagen— aquí da igual, porque el tema ya se refresca a mano.

2. **Las medidas del QML son proporcionales, no píxeles.** hyprlock dibuja en
   píxeles LÓGICOS (escala 1.6: 1600x1000) y el greeter va en FÍSICOS
   (2560x1600). Copiar el `clock_size = 160` tal cual habría dado un reloj
   mucho menor de lo esperado. `Main.qml` define `u = height / 1000` y expresa
   todo en múltiplos de esa unidad, así que los valores de `[lock]` se
   reutilizan sin conversión.

3. **El blur de hyprlock no se traduce multiplicando.** `blur_passes × blur_size`
   = 21 px de radio, imperceptible a lo ancho de 2560 px: la primera prueba salió
   con el paisaje nítido. hyprlock encadena pasadas —cada una sobre el resultado
   de la anterior—, así que su efecto crece mucho más rápido que una sola
   gaussiana equivalente. El `blur_sigma = 20` de `[greeter]` se eligió
   comparando tres renders (12, 20, 28) contra el criterio que ya fijaba
   `[lock]`: «el paisaje se reconoce pero no se distingue un detalle».

### ⚠️ Qt no resuelve las fuentes como fontconfig

El reloj salía con otra tipografía que el de hyprlock aunque los dos leen el
MISMO token. `[lock].clock_font` es `"JetBrainsMono NF ExtraBold"`, y eso
**fontconfig lo resuelve bien** —comprobado con `fc-match`: familia
`JetBrainsMono Nerd Font`, estilo `ExtraBold`, archivo
`JetBrainsMonoNerdFont-ExtraBold.ttf`—, que es como lo aplica hyprlock.

**Qt no consulta fontconfig de esa forma**: busca una familia que se llame
literalmente así, no la encuentra y cae a otra fuente **sin avisar**. El
resultado era un reloj en Regular donde el bloqueo enseña ExtraBold.

La solución es mandar la FAMILIA y el PESO por separado:

```
fontClock=JetBrainsMono Nerd Font     ← familia de verdad
fontClockWeight=81                    ← Font.ExtraBold en la escala de Qt5
```

⚠️ Ese 81 es la escala de **Qt5** (Thin 0 … Bold 75, ExtraBold 81, Black 87), no
la de CSS ni la de Qt6, que va de 100 a 900. Si algún día el daemon pasara a
lanzar el greeter de Qt6, este número habría que traducirlo.

Es la misma clase de trampa que ya avisaba `tokens.toml` para el nombre de la
fuente de Waybar: pegar el peso al nombre de la familia funciona en unos sitios
y en otros no, y cuando no funciona **falla en silencio**.

### Tres valores propios del greeter

hyprlock no tiene equivalentes, así que viven en `[greeter]` y no se derivan de
`[lock]`:

| Token | Valor | Qué hace |
|---|---|---|
| `clock_weight` | 81 | el peso de arriba, para el reloj y el nombre |
| `name_gap` | 28 | separación entre el nombre y el campo. Con los 12 iniciales el nombre parecía parte de la caja en vez de una etiqueta suya |
| `password_spacing` | 6 | `font.letterSpacing` de los puntos: los círculos de JetBrainsMono salen pegados a ese tamaño y se leen como una mancha |

El nombre de usuario comparte tipografía con el reloj —familia y peso— y no con
el campo: los dos se dibujan sobre la foto y forman un bloque, mientras que el
campo es un control.

### Se prueba SIN arriesgar el login

El greeter acepta `--test-mode`, así que el tema se puede abrir como una ventana
más en la sesión actual, sin tocar SDDM ni reiniciar:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/arch-msi
```

⚠️ **`sddm-greeter`, nunca `sddm-greeter-qt6`.** Es el error que dejó pasar un
tema roto hasta el primer arranque: el binario de Qt6 acepta imports sin
versión, tiene `QtQuick.Controls` y trae `QtQuick.Effects`, así que da por bueno
lo que el greeter real rechaza.

Es la vía por la que se validó todo lo de arriba. En modo de prueba no hay
logind detrás, así que `sddm.canPowerOff` y compañía son `false` y `lastUser`
está vacío: por eso el QML atenúa esos botones en vez de ocultarlos, y el
nombre de usuario cae a un texto de relleno.

### Estado

### ⚠️⚠️ El primer arranque con el tema puesto FALLÓ, y por qué

El tema se instaló, se activó y aun así el arranque enseñó el greeter de fábrica
con varios errores en rojo. **La validación previa no valía**: se había probado
con `sddm-greeter-qt6 --test-mode`, y ese no es el binario que usa el daemon.
El journal lo dijo claro:

```
Starting X11 session: "/usr/bin/sddm-greeter --theme /usr/share/sddm/themes/arch-msi"
Loading file:///usr/share/sddm/themes/arch-msi/Main.qml...
file:///usr/share/sddm/themes/arch-msi/Main.qml: Library import requires a version
Fallback to embedded theme
```

Tres cosas encadenadas, todas invisibles con el binario de Qt6:

1. **El daemon usa el greeter de Qt5.** El paquete `sddm` trae los dos
   (`sddm-greeter` y `sddm-greeter-qt6`) y **no hay ninguna opción para
   elegir**: `/usr/lib/sddm/sddm.conf.d/default.conf` no expone nada al
   respecto. Qt5 exige la VERSIÓN en cada import (`import QtQuick 2.15`) y sin
   ella aborta con «Library import requires a version».
2. **`QtQuick.Controls` no está instalado para Qt5.** Solo hay `qt5-base`,
   `qt5-declarative`, `qt5-translations` y `qt5-wayland`, y
   `/usr/lib/qt/qml/QtQuick/` no contiene `Controls`. El greeter lo dijo en
   rojo: `module "QtQuick.Controls" is not installed`. En vez de instalar
   `qt5-quickcontrols2` (8,9 MB) se reescribió el campo de contraseña con
   `TextInput` + `Rectangle`, que es QtQuick puro. **A `packages/` sigue sin
   añadirse nada.**
3. **Los iconos de apagado estaban VACÍOS.** Los glifos Nerd Font escritos como
   carácter literal se perdieron en una de las reescrituras del archivo y
   quedaron cadenas vacías, así que los tres botones desaparecían de la pantalla
   **sin un solo error en el log**: no fallaban, es que no tenían nada que
   dibujar. Ahora van como escapes `\uF011`, `\uF021` y `\uF186`, que
   sobreviven a cualquier copia.

**Regla que queda:** este tema se prueba con `sddm-greeter --test-mode`, **nunca
con `sddm-greeter-qt6`**. El de Qt6 acepta imports sin versión, tiene Controls y
trae `QtQuick.Effects`; o sea que da por bueno un tema que el greeter real
rechaza.

### Estado

**Instalado y activo el 2026-09-08**, comprobado con `greeter-apply --status`
y contra el sistema:

```
tema instalado : sí (/usr/share/sddm/themes/arch-msi)
drop-in        : sí (/etc/sddm.conf.d/10-arch-msi.conf)
tema activo    : arch-msi
```

El drop-in instalado es idéntico al versionado, los cuatro archivos del tema
están en su sitio y `sddm.service` siguió `active` durante todo el proceso: no
se reinició el servicio, así que la sesión abierta nunca estuvo en riesgo.

**Verificado en arranques reales el 2026-09-08**, incluidos los ajustes de
tipografía. Hicieron falta tres arranques y quedan en el journal:

| Arranque | Qué llevaba | Resultado |
|---|---|---|
| 17:39 | primera versión (imports sin versión, `QtQuick.Controls`) | **falló**: `Fallback to embedded theme` |
| 17:49 | versión Qt5 corregida | greeter con su tema, login correcto |
| 17:57 | + tipografía (peso, `name_gap`, `password_spacing`) | greeter con su tema, sin fallback ni errores QML |

El tercero se comprueba por las fechas: el tema con la tipografía nueva se
instaló a las **17:56:59** y ese arranque empezó a las **17:57:22**, 22 segundos
después, con `Loading theme configuration from
"/usr/share/sddm/themes/arch-msi/theme.conf"` y **ningún** mensaje de fallback ni
error QML en el journal.

⚠️ Para juzgar la tipografía en modo de prueba hay que **simular el nombre y la
contraseña**: `userModel.lastUser` viene vacío sin logind detrás y el campo
arranca sin texto, así que ni el nombre ni los puntos se ven. Se hace sobre una
COPIA del tema, nunca sobre el versionado.

⚠️ **La instalación se hizo dos veces, y la primera se quedó a medias.** Quedó
el tema completo pero sin drop-in, y la causa no fue el script: se ejecutó en el
mismo segundo (17:29:03) en que el archivo se estaba reescribiendo (17:29:02).
Bash lee los scripts por bloques guardando un desplazamiento, así que al cambiar
el tamaño del archivo bajo sus pies continuó desde un offset que ya no
correspondía y terminó antes de los dos `install` finales. **No editar un script
mientras se ejecuta**; si pasa, basta con repetirlo: esto es idempotente.

**Reversión**: `sudo greeter-apply --revert` borra el drop-in y SDDM vuelve solo
a su greeter de fábrica. Si el tema fallara al cargar, SDDM también cae al de
fábrica por su cuenta, así que no hay riesgo de quedarse sin login.

**A `packages/` no añade nada**: `sddm`, `qt6-declarative` e `imagemagick` ya
estaban.

## 25. Acceso remoto y pantalla del iPad (TeamViewer)  **[OK]**

`aur/teamviewer 15.79.4-1`, con `teamviewerd.service` habilitado y **activo**
desde el 2026-09-09 a las 17:17:06. La GUI corre **bajo XWayland**
(`hyprctl clients` → `"class": "TeamViewer"`, `"xwayland": true`).

**Para qué está**: ver la pantalla de un iPad desde el portátil. **Solo visión,
sin control** — iPadOS no expone ninguna API que permita a una app de terceros
controlar el dispositivo, así que no existe un equivalente a AnyDesk en ese
sentido. **AnyDesk se descartó por eso**: su app de iOS es solo cliente y no
puede ser el extremo compartido. Ese descarte vale **solo para el iPad**: para
controlar otros equipos AnyDesk sí sirve, y está instalado desde el 2026-09-14
(**§28**). TeamViewer sirve porque `QuickSupport`
comparte pantalla vía ReplayKit, que es el único mecanismo que Apple permite.

Cada sesión requiere pulsar *Iniciar transmisión* **a mano en el iPad**; no se
puede dejar autorizado de forma permanente.

**Alternativa para uso en LAN**: `aur/uxplay` (receptor AirPlay) da la misma
pantalla sin cuenta ni software propietario. TeamViewer solo gana si hace falta
alcance por Internet.

### ⚠️ El paquete AUR no declara `minizip`, y el demonio no arranca

Al primer intento, `teamviewerd` murió con `status=127`:

```
teamviewerd: error while loading shared libraries: libminizip.so.1:
cannot open shared object file: No such file or directory
```

No es un problema de configuración del equipo: el `PKGBUILD` declara solo
`hicolor-icon-theme qt5-x11extras qt5-quickcontrols qt5-svg`, y **`minizip` no
está en la lista**. Coherente con que el paquete esté marcado como
desactualizado en el AUR desde el 2026-07-23. Se resuelve con
`sudo pacman -S minizip` (`core`, `1:1.3.2-3`), que provee el soname exacto
`/usr/lib/libminizip.so.1 → libminizip.so.1.0.0`.

**Esto reaparecerá en una restauración desde cero**, porque `packages/` recupera
los paquetes pero no las dependencias que el AUR se deja: `minizip` figura en
`pacman-explicit.txt` precisamente para que la reinstalación no vuelva a
tropezar.

Diagnóstico rápido de cualquier `status=127` similar:
`ldd /opt/teamviewer/tv_bin/teamviewerd | grep "not found"` da la biblioteca, y
`pacman -Fx 'libminizip\.so\.1$'` el paquete (requiere `pacman -Fy` una vez).

### ⚠️ Un servicio en `failed` puede estar mostrando el error viejo

Tras instalar `minizip`, `systemctl status` seguía diciendo `failed` y parecía
que el arreglo no había servido. Conservaba el fallo **de la ejecución
anterior**: misma marca de tiempo y mismo `Invocation:`. El demonio no se
reinicia solo. Antes de dar un arreglo por fallido, **comparar la hora del
fallo con la hora del arreglo**.

### Qué no se versiona

El **ID de TeamViewer** y `~/.config/teamviewer/client.conf`: son artefactos de
acceso remoto y quedan fuera del repositorio por las reglas de `CLAUDE.md`.
`/opt/teamviewer/config/global.conf` no es legible como usuario normal, así que
`teamviewer --info` devuelve el campo del ID vacío sin que eso signifique nada;
el ID se lee en la ventana.

Historia y diagnóstico completo: `history/2026-09-09-teamviewer-ipad.md`.

---

## 26. Apuntes con teclado y lápiz (Obsidian)  **[OK]**

`extra/obsidian 1.13.7-2` (sobre `electron43`) con dos plugins de comunidad:
**Ink 0.5.6** y **Excalidraw 2.27.3**. Más `extra/xournalpp 1.3.7-1` como
herramienta aparte para PDF y página fija.

**Para qué está**: tomar apuntes escribiendo con el teclado y **dibujar con el
lápiz dentro del mismo documento**, sin cambiar de aplicación. Ink es el que da
eso: inserta un lienzo (tldraw) entre párrafo y párrafo de una nota Markdown, y
el texto sigue fluyendo por debajo. Excalidraw cubre el otro caso —diagramas
grandes con cajas y flechas— como dibujo embebido.

**Vault**: `~/Documentos/Apuntes`. **No se versiona**: son apuntes personales, y
los `main.js` de los dos plugins suman ~8,9 MB de código de terceros.

### El lápiz funciona en Wayland nativo, y eso NO era lo esperado

Obsidian arranca **sin XWayland** (`hyprctl clients -j` → `"xwayland": false`;
el paquete no pasa ningún flag, lo decide `electron43`). Eso importa porque hay
un bug documentado de lápiz en Electron/Wayland que afecta justo a estos
plugins ([obsidian-excalidraw-plugin#1914][ex1914]), y la previsión era tener
que caer a XWayland. **No hizo falta**: el lápiz dibuja en Wayland nativo.

La diferencia con los reportes del bug es probablemente que aquí el
digitalizador es **directo** (`INPUT_PROP_DIRECT`, integrado en el panel) y no
una tableta externa indirecta tipo Huion o Wacom.

Confirmado **en uso**, no con medición: no se llegaron a leer `pointerType` ni
`pressure` numéricamente dentro de Obsidian.

[ex1914]: https://github.com/zsviczian/obsidian-excalidraw-plugin/issues/1914

### La vía de escape a XWayland queda preparada

`/usr/bin/obsidian` es un wrapper que lee flags de
`~/.config/obsidian/user-flags.conf`. Ese archivo existe **con todo comentado**
—o sea, cero flags activos y comportamiento idéntico al de fábrica— y contiene
la línea `--ozone-platform=x11` lista para descomentar si una actualización de
`electron43` rompe el lápiz. Hay que cerrar y reabrir Obsidian, no basta con
recargar.

### ⚠️ Firefox no sirve para dibujar, y no es culpa del lápiz

Firefox bajo Wayland reporta el lápiz como **ratón**: `pointerType` sale
`"mouse"` y no hay inclinación ([Bugzilla 1606832][moz]). Chromium sí lo
reconoce como `pen`. Consecuencia práctica: cualquier herramienta de dibujo
**web** (Excalidraw en navegador, tldraw, etc.) hay que abrirla en un Chromium,
no en Firefox. No afecta a Obsidian, que trae su propio Electron.

Es una trampa cara de diagnosticar, porque el síntoma —"el lápiz va como un
ratón"— es idéntico al de un lápiz mal configurado.

[moz]: https://bugzilla.mozilla.org/show_bug.cgi?id=1606832

### Los plugins se instalaron a mano, y por qué

El vault se creó desde cero por script, así que no había interfaz por la que
pasar: los tres archivos de cada plugin (`main.js`, `manifest.json`,
`styles.css`) se bajaron de la **release oficial de GitHub** a
`.obsidian/plugins/<id>/`, y se habilitaron escribiendo `community-plugins.json`
con los dos `id`.

Dos comprobaciones que conviene repetir si algún día se reinstalan así:

- **El nombre de la carpeta debe ser exactamente el `id` del `manifest.json`**
  (`ink` y `obsidian-excalidraw-plugin`), o Obsidian no los carga.
- **Que hayan cargado de verdad se ve en que el plugin escribe su propio
  `data.json`** al arrancar. Que los archivos estén en disco no prueba nada.

### Deshacer y rehacer: dónde está cada tecla

El editor de Obsidian usa el `historyKeymap` de CodeMirror 6 tal cual, leído del
`obsidian.asar`:

| Tecla | Función |
|-------|---------|
| `Ctrl+Z` | `undo` |
| `Ctrl+Shift+Z` | `redo` — entrada **específica de Linux** en el keymap |
| `Ctrl+Y` | `redo` |
| `Ctrl+U` | `undoSelection` → **reasignado**, ver abajo |
| `Alt+U` | `redoSelection` |

⚠️ **Deshacer NO aparece en Ajustes → Atajos de teclado.** El comando existe,
pero está declarado `mobileOnly: true`, así que en escritorio no se registra y
no es asignable. Buscarlo ahí es perder el tiempo; funciona igualmente.

`Ctrl+U` era el más confuso: `undoSelection` recorre el mismo historial que
`Ctrl+Z` pero parándose en los cambios de selección, así que **parece un
deshacer errático**. Por eso se reasignó.

Dentro de un dibujo de Ink las mismas teclas funcionan, porque el plugin lleva
una **pila de deshacer unificada**: intercepta el teclado y, según dónde esté el
foco, deshace trazos del lienzo o texto de la nota. Si el foco no está en el
dibujo, `Ctrl+Z` deshace la nota — y si lo último fue insertar el lienzo, se lo
lleva entero.

### Subrayar: `Ctrl+U` y un plugin propio

Markdown no tiene sintaxis de subrayado, y Obsidian **no trae comando**: de los
`editor:toggle-*` existen `bold`, `italics`, `highlight`, `strikethrough`,
`code`, `blockquote`, `inline-math`… y ningún `underline`. La única vía es HTML
inline, `<u>palabra</u>`, que Obsidian sí renderiza.

Para no escribirlo a mano hay un plugin propio, **`subrayar`**, que registra el
comando *Subrayar / quitar subrayado* con `Ctrl+U` por defecto. Alterna: si la
palabra ya está envuelta —por dentro o por fuera de la selección— quita las
etiquetas en vez de anidarlas. **Sin selección opera sobre la palabra bajo el
cursor**, que es el caso normal.

### Subíndice y superíndice: `Ctrl+Alt+,` y `Ctrl+Alt+.`

El mismo hueco que el subrayado, y la misma solución. Para bajar o subir un
número Obsidian solo ofrece `editor:toggle-inline-math`, que mete una fórmula
LaTeX (`$1010_2$`) con su tipografía matemática. Cuando lo que se quiere es
texto normal, la vía es HTML inline: `<sub>` y `<sup>`.

Dos plugins gemelos clonados de `subrayar` — misma función de alternado, solo
cambian la etiqueta, el atajo y el nombre del comando:

| Plugin | Etiqueta | Atajo | Para qué |
|--------|----------|-------|----------|
| `subindice` | `<sub></sub>` | `Ctrl+Alt+,` | la base de un número: `1010₂` |
| `superindice` | `<sup></sup>` | `Ctrl+Alt+.` | exponentes y ordinales: `2¹⁰` |

La coma baja, el punto sube.

**Sin selección NO operan sobre la palabra bajo el cursor**, al contrario que
`subrayar`: dejan el par de etiquetas vacío con el cursor en medio. Es
deliberado — al acabar de teclear `1010`, la palabra bajo el cursor es el propio
número, y envolverlo entero sería lo contrario de lo que se busca. El gesto es
`1010` → atajo → `2` → `End`.

⚠️ **`Super+,` no llegó a funcionar** y fue el primer atajo que se probó.
Hyprland no tiene ningún bind con coma, así que el compositor no lo estaba
robando. **La causa no se ha verificado**: en ese momento el plugin tampoco
estaba activado en `community-plugins.json`, así que no está descartado que
`Super+,` sirva. Se cambió a `Ctrl+Alt+,`, que sí responde. `Ctrl+,` a secas no
vale: lo ocupan los ajustes de Obsidian.

### Griegas y símbolos matemáticos: `Super + G`, fuera de Obsidian

El mismo razonamiento de los subíndices lleva a la misma conclusión un escalón
más arriba. Para **fórmulas**, LaTeX: Obsidian renderiza MathJax de serie con
`$\Delta v$` y `$$…$$`. Para un **carácter suelto en prosa** —«la Δ de
temperatura», «rayos γ»— LaTeX desentona tipográficamente y, sobre todo, en el
`.md` guarda `\Delta` y no `Δ`, así que **buscar `Δ` en el vault no lo
encuentra**.

Por eso los símbolos sueltos no se resolvieron dentro de Obsidian sino en el
escritorio, con el selector de `Super + G` (**§31**), que inserta el carácter
Unicode de verdad y sirve igual en kitty o en el navegador.

Anotado al contrastarlo contra el bundle de Obsidian: el comando
`editor:toggle-inline-math` **viene sin atajo por defecto** —su `addCommand` no
declara `hotkeys`— y el `hotkeys.json` del vault está vacío, así que vive solo
en la paleta de comandos mientras no se le asigne uno.

### Los tres plugins propios: symlink, no Stow

`subrayar`, `subindice` y `superindice` son el **único componente del vault que
sí se versiona**, porque es código propio y son dos archivos pequeños cada uno.
Viven en `obsidian/plugins/` y llegan al vault por **symlink**, no por Stow: el
resto de `~/Documentos/Apuntes` está fuera del repositorio, así que no hay
ningún paquete Stow que pueda cubrirlo.

```
~/Documentos/Apuntes/.obsidian/plugins/<id>
  -> ~/Projects/arch-msi/obsidian/plugins/<id>
```

Al restaurar hay que rehacer los tres enlaces a mano y añadir los tres `id` a
`community-plugins.json`.

⚠️ **Obsidian no ve un plugin enlazado mientras está abierto.** Escanea la
carpeta al arrancar, así que un symlink creado después no aparece en la lista de
complementos hasta recargar (`Ctrl+P` → *Recargar la aplicación sin guardar*).
Que el enlace exista no prueba nada; que el plugin ha cargado se ve en que su
`id` aparece en `community-plugins.json` después de activarlo.

### ⚠️ Tabuladores y líneas en blanco: el texto que se vuelve naranja

Estructurar una nota **indentando con tabuladores** y separando los bloques con
líneas en blanco es una combinación rota en Markdown. El síntoma desconcierta:
de la línea en blanco hacia abajo, el texto sale **naranja y dentro de una
caja**.

No es un fallo de Obsidian ni del tema. Es un **bloque de código indentado**:

- Una línea que solo contiene un tabulador **es una línea en blanco** para
  Markdown, y cierra el párrafo.
- A partir de ahí, una línea que empieza con 4 columnas —y un tabulador son
  cuatro— ya no es continuación de nada: es código.
- El naranja es literalmente `--text-color-code` del tema Blue Topaz
  (`#d58000`); la caja es el `<pre>`.

Mientras no hay línea en blanco las líneas tabuladas son *continuación perezosa*
del párrafo anterior y se ven como texto normal. Por eso el problema aparece a
media nota y parece aleatorio.

**Lo que NO lo arregla**: bajar la indentación a 2 espacios. Funciona en el
primer nivel y vuelve a fallar en el segundo, donde 2+2 son otra vez 4.

**La estructura se hace con cita (`>`), no con indentación.** El segundo nivel
es `>>`. Tres ventajas: la barra vertical a la izquierda la pinta el tema, que
era el efecto que se buscaba; la línea de separación dentro del grupo es un `>`
suelto que **Obsidian escribe solo al pulsar Enter**; y sin indentación el
bloque de código no puede volver, por mucho que se anide.

Dos trampas al convertir tabuladores en citas, porque dentro de la cita el
contenido vuelve a la columna 0 y recupera su significado en Markdown: una línea
de `=` debajo de texto es un **título setext** —convierte la línea de arriba en
un `<h1>`— y una línea que empieza por `#` es un **encabezado**. Dentro del
bloque de código eran texto literal. Se escapan con `\`.

Y una consecuencia que se asume: **se pierde la alineación monoespaciada**. Una
tabla de bits cuadrada a base de espacios se veía alineada porque la caja era
monoespaciada; como texto normal, los espacios seguidos se colapsan. Si esa
alineación importa, el sitio correcto es un bloque de código **explícito**
delimitado por tres acentos graves, que sale con caja pero a propósito.

Comprobado con `markdown_py` sobre la nota real, que es lo que cierra el
diagnóstico: 4 bloques `<pre><code>` antes de convertir, 0 después.

### Qué no se versiona

El vault entero (`~/Documentos/Apuntes`), incluidos los plugins descargados, y
`~/.config/obsidian/obsidian.json`, que solo contiene la ruta del vault y un id
local. `user-flags.conf` sí sería versionable como paquete Stow —igual que el
`spotify-flags.conf` de la tarea 3.6— pero hoy está vacío de flags efectivos y
no se ha creado el paquete.

Investigación y alternativas descartadas:
`history/2026-09-11-apuntes-lapiz-obsidian.md`.

## 27. WhatsApp en el escritorio (ZapZap)  **[OK]**

`aur/zapzap 7.4.4-1`, instalado el 2026-09-13. **No existe cliente oficial de
WhatsApp para Linux**: todo lo que hay en AUR son envoltorios de
`web.whatsapp.com`. ZapZap (PyQt6 + PyQt6-WebEngine) se eligió por encajar con
el resto del escritorio Qt y por ser el que mejor mantenimiento lleva; el
clásico `wasistlos` (GTK) estaba marcado como desactualizado desde agosto.

Arrastra `qt6-webengine`, que no estaba en el sistema: 94 MiB de descarga y
282 MiB instalados. Es el grueso real de la instalación — el paquete de ZapZap
en sí es Python puro.

Configuración en `~/.config/ZapZap/ZapZap.conf`, **no versionada**: guarda
geometría de ventana, estado de la sesión y preferencias locales. La sesión de
WhatsApp vive en `~/.local/share/ZapZap/` y es un artefacto de autenticación,
así que queda fuera del repositorio por la regla de `.gitignore`.

### La trampa: se cerraba a los dos segundos  **[OK]**

El paquete instala **dos lanzadores**, `ZapZap` y `ZapZapNoGpu`. El normal
moría a los pocos segundos de abrir, siempre con la misma pila: aborto dentro de
`libgallium` (Mesa) bajando desde
`QtWebEngineCore::RenderWidgetHostViewQtDelegateItem::updatePaintNode`. Es
decir, moría **pintando** la vista web, no en red ni en WhatsApp.

**Causa.** Qt WebEngine lo dice él mismo en la primera línea de su salida:

```
GBM is not supported with the current configuration. Fallback to Vulkan rendering in Chromium.
```

No puede usar GBM para compartir búferes, así que **cae a la ruta Vulkan** — y
esta máquina no tenía driver Vulkan para la Intel. El único ICD instalado era
`nvidia_icd.json`: **faltaba `vulkan-intel`**, pese a que la Arc integrada es la
que pinta el escritorio. El lanzador `NoGpu` funcionaba porque pasa
`--disable-gpu --disable-vulkan --disable-features=Vulkan,VulkanFromANGLE`, es
decir, esquiva justamente esa ruta.

**Arreglo:** `sudo pacman -S vulkan-intel` (1:26.2.2-1, misma versión que
`mesa`). No sustituye ningún controlador: **añade** el ICD Vulkan de Mesa para
la Arc, que sencillamente no estaba. Tras instalarlo, `vulkaninfo --summary`
pasa a listar dos GPU —`Intel(R) Arc(tm) Graphics (MTL)` con
`DRIVER_ID_INTEL_OPEN_SOURCE_MESA` y la RTX 4060— y el lanzador normal arranca y
se queda.

> **Esto era un hueco de la máquina, no de ZapZap.** Cualquier cosa que pidiera
> Vulkan sobre la iGPU estaba en la misma situación. ZapZap solo fue lo primero
> que lo destapó.

**Descartado:** `--disable-vulkan` a secas, manteniendo la GPU. No sirve: es una
bandera de Chromium y para cuando se aplica, la capa de Qt WebEngine ya eligió
el camino. Se probó y murió con la pila idéntica.

**No era un problema de permisos:** `/dev/dri/renderD128` y `renderD129` están a
`0666`, accesibles sin pertenecer a `video` ni a `render`.

### Riesgo de baneo: por qué no hay cliente de terminal

Se valoraron y **descartaron** los clientes de terminal (`whatscli`, `wstui`, el
puente `mautrix-whatsapp`, `purple-gowhatsapp`). Todos usan `whatsmeow`:
**reimplementan el protocolo** en lugar de envolver la web, lo que entra en el
terreno de los clientes no oficiales que los Términos de Servicio prohíben. El
riesgo de suspensión es bajo para uso personal —lo que dispara baneos es el
comportamiento de spam, no el cliente en sí— pero **no es cero**, y recae sobre
el número de teléfono, con lo que eso arrastra (2FA, trabajo, familia).

Los envoltorios web como ZapZap **no tienen ese problema**: para los servidores
de Meta son WhatsApp Web, que es un producto suyo.

### Tema: WhatsApp Web con la paleta del escritorio  **[OK]**

Añadido el 2026-09-13. ZapZap tiene «personalización avanzada», que inyecta CSS
y JS del usuario desde `~/.local/share/ZapZap/customizations/global/{css,js}`.
El CSS que pinta WhatsApp Web con la paleta de matugen **es una plantilla más**:

| | |
|---|---|
| Plantilla | `dotfiles/matugen/.config/matugen/templates/zapzap-waweb.css` |
| Salida | `~/.local/share/ZapZap/customizations/global/css/arch-msi.css` |
| Declarada en | `[templates.zapzap]` de `config.toml` |

La salida vive en los datos de la app, **no** en una ruta de Stow, así que la
regla de oro de §18 se cumple. Y como es plantilla, los colores **siguen al
fondo de pantalla**: no hay ni un hexadecimal escrito a mano.

> ⚠️ **El JavaScript de esa función NO sirve en WhatsApp Web.** La inyección
> crea un `<script>` inline y la CSP de WhatsApp lo bloquea en silencio. Los
> `<style>` sí pasan. Comprobado el 2026-09-13 con marcadores visibles: la
> banda de prueba en CSS se veía, la de JS no.

**Dos capas de color, no una.** WhatsApp Web define su tema por partida doble, y
saberlo es lo único que hace que esto funcione:

1. Tokens **WDS** (`--WDS-surface-default`, `--WDS-accent`…) sobre el `<html>`,
   con selectores de clase ofuscados y **doblados** (`.x1umy8rd.x1umy8rd`).
2. Una capa **heredada** de ~188 variables (`--panel-background`, `--teal`…)
   definida en `.dark`, que es una clase del **`<body>`**.

> ⚠️ **TRAMPA: pisar solo `:root` no hace nada.** Las variables CSS heredan, así
> que una definición en `.dark` (el body) gana a otra en `:root` (el html) por
> cercanía al elemento, **por mucha especificidad que se le ponga**. El primer
> intento pisaba únicamente `:root` y el resultado fue *cero* cambios visibles,
> pese a que las variables sí tomaban el valor nuevo al consultarlas en el html.
> Hay que escribir en los dos niveles: `:root:root:root` para los WDS y
> `body.dark.dark` para la capa heredada.

La plantilla **no usa las clases ofuscadas** (`.x1umy8rd` y compañía): las
genera el compilador de Meta y cambian sin avisar. Usa `:root:root:root`
(especificidad 0,3,0 con nombres estándar) y `prefers-color-scheme`, de forma
que si el escritorio vuelve a claro la hoja se aparta sola.

### Cómo volver a inspeccionar WhatsApp Web

Cuando Meta renombre tokens y vuelva el verde por partes, **no hace falta
adivinar**. La CSP bloquea el JS inyectado, pero no al protocolo de DevTools,
que evalúa desde fuera de la página:

```
QTWEBENGINE_REMOTE_DEBUGGING=127.0.0.1:9222 zapzap
curl -s http://127.0.0.1:9222/json      # localizar la pestaña
```

Desde ahí se listan las ~1400 variables reales y, mejor aún, **se buscan por su
valor actual** en vez de por nombre: pedir las que hoy valen el verde de
WhatsApp da la lista exacta de lo que hay que remapear. Así se hizo.

### Lista de chats colapsable  **[OK]**

La misma plantilla lleva una `@media (max-width: 900px)` que reduce `#pane-side`
a 76 px —la columna de avatares— para dejarle el espacio al chat abierto. No es
función de WhatsApp ni de ZapZap.

No oculta nada por selector, a propósito: fija el ancho del panel y le fuerza un
`min-width` al grid interior, de modo que las filas **se recortan** en vez de
reorganizarse. Así no depende de las clases ofuscadas de las filas. Usa
`overflow-x`, no `overflow`: `#pane-side` es el contenedor con scroll vertical y
taparlo entero dejaría la lista sin poder recorrerse.

Tres detalles que costaron y que conviene no tocar a ciegas:

- **76 px es un valor exacto**, no redondo: la fila separa el avatar 24 px del
  borde y el avatar mide 48. El nombre empieza justo en 76. Más ancho y asoma la
  primera letra; más estrecho y se corta la foto.
- **La barra de scroll de la lista va oculta** (`scrollbar-width: none`). Sin
  eso se come 10 px de los 76 y vuelve a cortar el avatar. La lista se recorre
  con la rueda.
- **Hay que quitarle el borde a la capa de separadores.** `.two` lleva capas de
  superposición **vacías y `position: absolute`** que solo dibujan los
  separadores entre paneles, conservando la división original 45% / resto. Al
  ser absolutas **no ocupan espacio**: no empujan la conversación, solo dejan
  una línea gris flotando sobre ella. Basta con volver su borde transparente;
  **no hay que tocar su ancho**.

  > ⚠️ **NO señalarlas por posición.** Un intento con
  > `.two > div > div:first-child` funcionaba con la lista vacía y, **con un
  > chat abierto, cogía el panel de conversación** y lo comprimía a 76 px, con
  > el composer y los mensajes apilados sobre la lista. El selector bueno se
  > apoya en la firma del contenido —un `div` con un único `span` vacío—:
  > `.two div:has(> div > span:only-child:empty)`. Comprobado en la página que
  > coge 3 elementos y que ninguno es la lista ni la conversación.

Verificado el 2026-09-13 simulando anchos por DevTools y comprobando el
resultado en pantalla: a 800 px el panel mide 76 px y a 1400 px vuelve a 419.

### Ajustes de la app que NO se versionan

`~/.config/ZapZap/ZapZap.conf` lleva geometría y estado de sesión, así que queda
fuera del repositorio. Eso deja **cuatro claves que hay que reponer a mano** tras
una reinstalación:

| Clave | Valor | Para qué |
|---|---|---|
| `[system] theme` | `auto` | seguir el claro/oscuro del sistema (§18) |
| `[custom] global\css\enabled` | `true` | **activa la hoja de estilos**; sin esto se genera pero no se inyecta |
| `[system] menubar` | `true` | barra superior |
| `[system] sidebar` | `true` | barra lateral |

> ⚠️ **Si se desactivan la barra lateral y la superior, la ventana se queda sin
> ningún elemento visible que lleve a los ajustes.** No es un callejón sin
> salida: **`Ctrl+P` abre los ajustes igualmente**, esté la interfaz como esté
> (`ui/components/main_window.py:144`,
> `self.actionSettings.setShortcut(_("Ctrl+P"))`). Ese atajo es la vía normal de
> recuperación.
>
> El atajo está marcado como traducible —va dentro de `_()`—, así que en teoría
> podría cambiar con el idioma de la interfaz; con `interface_language=system` y
> el sistema en español sigue siendo `Ctrl+P`, comprobado el 2026-09-13.
>
> La vía de emergencia, si el atajo también fallara, es poner `menubar` y
> `sidebar` a `true` en el `.conf` **con la aplicación cerrada**: QSettings
> reescribe el archivo al salir y se llevaría por delante el cambio.

Historia y diagnóstico completo: `history/2026-09-13-zapzap-whatsapp.md` y
`history/2026-09-13-modo-oscuro-y-tema-de-whatsapp.md`.

## 28. Acceso remoto a otros equipos (AnyDesk)  **[OK]**

`aur/anydesk-bin 8.0.4-1`, instalado el 2026-09-14 con `paru`. **Para qué
está**: controlar otro equipo desde este portátil. Es la dirección contraria a
§25, que sirve para *ver* la pantalla de un iPad sin controlarla.

> **Corrección a §25.** Allí se lee «AnyDesk se descartó». Ese descarte valía
> **solo para el caso del iPad** —su app de iOS es únicamente cliente y no puede
> ser el extremo compartido—, no era un rechazo general de la herramienta.
> Para equipos de escritorio sirve, y es justo lo que se instaló.

**Las dependencias sí están declaradas**, al contrario que en TeamViewer (§25).
Se repasaron las 22 del `PKGBUILD` contra lo instalado antes de nada: solo
faltaba `lsb-release`, que pacman arrastró sola. `minizip` —la que el paquete de
TeamViewer se dejaba y tumbaba el demonio— **aquí sí figura**. Por eso
`lsb-release` **no** se añade a `pacman-explicit.txt`: una reinstalación de
`anydesk-bin` vuelve a traerla, que es justo lo que no pasaba con `minizip`.

El `PKGBUILD` no tiene `prepare()`, `build()` ni `.install`: descarga el tarball
oficial con sha256 fijado e instala archivos. No ejecuta nada durante el
empaquetado.

### El servicio se deja deliberadamente sin habilitar

`anydesk.service` queda **`disabled` e `inactive`**. El paquete imprime al
instalar un aviso sugiriendo `systemctl enable --now anydesk`: eso es el
**acceso desatendido**, y su unidad arranca `anydesk --service` con `User=root`,
dejando el equipo alcanzable sin que nadie acepte la conexión. Para salir hacia
otros equipos **no hace falta**, y por eso no está. No aparece en
`packages/services-enabled.txt`, que es lo correcto.

### ⚠️ `result_relay_offline`: un relay que dice «no reconectes», y el cliente se rinde

Al primer arranque, todos los intentos de conexión morían con
`Net socket error: result_relay_offline`, y `~/.anydesk/system.conf` guardaba
`ad.anynet.relay.fatal_result=1.19`, `relay.state=3`. La cadena real, en
`~/.anydesk/anydesk.trace`:

| Momento | Qué pasó |
|---|---|
| +0,4 s | Conecta a `boot.net.anydesk.com`, TLS 1.3 correcto |
| +0,6 s | `anynet_invalid_zone` → **normal**: el bootstrap solo entrega la lista de relays |
| +0,7 s | Conecta al relay asignado, TLS correcto, handshake protocolo 3 |
| +1,0 s | **`Connection terminated: anynet_19` · `Received "don't reconnect" from server`** |
| +1,0 s | `main_relay_conn - Connect failed` → **el fiber termina y no reintenta jamás** |

Ese es el punto: **un relay concreto rechazó al cliente y AnyDesk, al recibir el
«no reconectes», detiene el conector durante el resto de la vida del proceso.**
Todo lo que se intente después falla por falta de relay, no por la red.

**La cura es reiniciar el cliente** (`pkill -x anydesk && anydesk`), sin sudo y
sin borrar configuración. Al rearrancar pide lista nueva, le toca **otro relay**
y entra. Verificado el 2026-09-14: `Connection established`,
`Relay connection state changed: Connected`, `fatal_result` de **1.19 a 1.0**,
`relay.state` de **3 a 2** y `anydesk --get-status` → `online`.

**Lo que NO era la causa, descartado con pruebas** (importa, porque la traza
empuja a culpar a los tres):

- **No es la red del campus.** Desde `Mi Campus Alicante` resuelven los relays y
  los puertos **443 y 6568 están abiertos**; el TLS con el relay se completó.
  Sin proxy, sin portal cautivo, sin VPN activa.
- **No es el `firewalld` local**, activo pero sin estorbar a la salida.
- **No es el error de DNS que sale en rojo.** `crl.anydesk.com` da `NXDOMAIN`
  **de forma autoritativa desde los propios nameservers de AnyDesk**, no por
  filtrado. La prueba definitiva: **aparece igual en el arranque que sí
  funcionó**. Es ruido.

### La ventana es Wayland, pero las tripas son X11

`hyprctl clients` da `"xwayland": false` —la ventana es superficie Wayland
nativa—, pero el proceso **abre además una conexión X11 por Xwayland** para
enumerar monitores y construir la tabla xkb: su traza tiene un hilo `x11`
leyendo salidas XRandR, y registra `Could not find a primary monitor`. Es un
caso mixto, distinto del de TeamViewer, que corre entero bajo XWayland.

De ahí salen los dos defectos que se vieron en la primera sesión real.

**1. Imagen mal proporcionada.** El equipo remoto era **3840x2160 (16:9)** y la
ventana estaba flotando en `eDP-1`, que va a **escala fraccionaria 1,6** y es
**16:10**, con un tamaño de 1044x914 (ratio 1,14, casi cuadrado). Ahí un 16:9 no
cabe sin deformarse.

> **Arreglo: llevar la sesión a `HDMI-A-1` y ponerla a pantalla completa.** Ese
> monitor es **2560x1440 a escala 1**, o sea **16:9 exacto contra 16:9**:
> reducción limpia desde 3840x2160 y sin escalado fraccionario de por medio.
> Comprobado: la ventana pasa a `2560x1440` (ratio 1,778) y la sesión sobrevive
> al movimiento.

**2. El teclado no se traduce bien.** La traza dice
`Keyboard layouts differ (l:unknown != r:en_us_intl). Auto-mode is Translate`.
El teclado local es español (`at-translated-set-2-keyboard`, layout `es,us`,
activo `Spanish`), pero **AnyDesk lo ve como `unknown`** porque lo lee por la
vía X11, que no le devuelve la distribución de Hyprland. Con el origen
desconocido, la traducción de teclas va a ciegas. Se corrige **en la barra de la
sesión** (menú de teclado), no hay clave en `user.conf` mientras no se toque
desde la interfaz.

### Los atajos de Hyprland siguen funcionando dentro de la sesión

Comprobado en el log del compositor: **cero apariciones** del protocolo
`keyboard-shortcuts-inhibit`. Hyprland intercepta las combinaciones con `Super`
antes de que lleguen a AnyDesk, así que `Super + ←`, `Super + 1…9` y compañía
funcionan aunque la sesión esté a pantalla completa y con el foco. Al remoto va
todo lo demás.

**Hueco detectado: `hyprland.lua` no tiene ningún atajo de pantalla completa.**
Para entrar o salir hay que usar la barra de la propia AnyDesk (la pestaña del
borde superior) o el comando de abajo. Queda como posible mejora, sin decidir.

### Qué no se versiona

El **ID de AnyDesk** de esta máquina, el del equipo remoto y todo `~/.anydesk/`
(`system.conf`, `user.conf`, `service.conf`, `anydesk.trace`,
`connection_trace.txt`): son artefactos de acceso remoto y quedan fuera del
repositorio por las reglas de `CLAUDE.md`, igual que el ID de TeamViewer (§25).

Historia y diagnóstico completo: `history/2026-09-14-anydesk.md`.

## 29. Minecraft con instancias (MultiMC)  **[OK]**

`aur/multimc-bin 1.6-3`, instalado el 2026-09-14 con `paru`. **Para qué está**:
tener varias instalaciones de Minecraft separadas —cada una con su versión, su
cargador de mods y sus mundos— en vez de la única que gestiona el launcher
oficial de §13. Los dos conviven: MultiMC **no mira `~/.minecraft`** en ningún
momento, y la misma cuenta de Microsoft sirve para ambos.

### ⚠️ El paquete de AUR NO contiene el launcher

Pesa 27 KiB e instala cuatro archivos: `/opt/multimc/run.sh`, su icono, el
symlink `/usr/bin/multimc` y el `.desktop`. **No hay ningún binario de MultiMC
dentro.** `run.sh` es el bootstrapper oficial: la primera vez que se ejecuta se
descarga `mmc-stable-lin64.tar.gz` de `files.multimc.org` en
`~/.local/share/multimc` (3,4 MB), lo extrae y lo lanza; después solo comprueba
si el binario existe y va directo a ejecutarlo. Usa `zenity` para la barra de
progreso y `wget` para la descarga, ambas dependencias declaradas.

La versión instalada de verdad es **0.7.0-stable-3673** (git `d7b51bf`); el
`1.6` del nombre del paquete es la versión del *instalador*, no del programa.

**Al restaurar en un equipo limpio esto importa**: reinstalar `multimc-bin` no
deja MultiMC listo, deja un script que se bajará el launcher la primera vez que
se abra —hace falta red—. Y a la inversa: `pacman -Rns multimc-bin` **no borra
`~/.local/share/multimc`**, que es donde están las instancias, los mundos y la
cuenta. El launcher además se autoactualiza solo (`AutoUpdate=true`), así que su
versión no la fija el repositorio ni pacman.

### Java del sistema: tres versiones, y ninguna es `jre-openjdk`

Aquí §13 se queda corta y conviene leer las dos juntas. El launcher oficial no
necesita Java del sistema porque descarga el suyo en `~/.minecraft/runtime`;
**MultiMC sí lo necesita**, porque usa los JRE que encuentra instalados.

| Paquete | Versión | Cubre |
|---|---|---|
| `jre21-openjdk` | 21.0.12.1 | 1.20.5 en adelante, y 1.21.x |
| `jre17-openjdk` | 17.0.20.1 | 1.17 – 1.20.4 |
| `jre8-openjdk` | 1.8.0_504 | 1.16 y anteriores, modpacks viejos |

Los detectó solos, pasó `JavaCheck.jar` sobre cada uno con código 0 y escogió el
21 (`JavaPath=/usr/lib64/jvm/java-21-openjdk/bin/java`). Los tres conviven sin
pisarse; `archlinux-java status` los lista con `java-21-openjdk` por defecto.

**El aviso de §13 sobre `jre-openjdk` a secas sigue en pie**: ese paquete va por
Java 26 y el juego no arranca con un JRE tan nuevo. La regla no es «nada de Java
en el sistema», es «nada de Java sin número de versión en el nombre».

Dependencias opcionales que también entraron: `glfw` y `xorg-xrandr` (ver
abajo), y `openal`, que ya estaba.

### El launcher es Wayland nativo; el juego sale por XWayland

La expectativa era la contraria: MultiMC es Qt5 y depende de `qt5-x11extras`, así
que se esperaba una ventana bajo XWayland y borrosa en `eDP-1` por la escala
1,6, como le pasa a Spotify (§7). **No ocurre**: `hyprctl clients` da
`"xwayland": false` para `org.multimc.MultiMC`. No hay nada que corregir.

El proceso del juego, en cambio, sí va por X11:

```
[Render thread/ERROR]: 65547: X11: Standard cursor shape unavailable
```

La causa es `UseNativeGLFW=false` en `multimc.cfg`: la instancia usa el GLFW
empaquetado por LWJGL (3.3.3), que va por X11, en lugar del `glfw` del sistema.
Son **dos procesos por vías distintas**, no el caso mixto de AnyDesk (§28),
donde una sola ventana Wayland leía geometría por X11. El error es cosmético y
el juego funciona, así que `UseNativeGLFW` se deja como está: activarlo es de los
cambios que rompen el arranque de LWJGL según la versión, y hoy no arregla nada.

### Estado configurado

Idioma español, 4096 MB de RAM máxima, tema oscuro. Cuenta de tipo **MSA**
(Microsoft). Una instancia **1.21.11 con Fabric Loader 0.19.5**, con tiempo de
juego ya registrado: la cadena entera —cuenta, descarga de librerías, Fabric,
arranque— está validada de punta a punta.

### La dGPU se configura DENTRO de MultiMC, no con otro `.desktop`  **[OK]**

El launcher oficial arranca con `prime-run` desde el `.desktop` del paquete Stow
`minecraft` (§13). Aquí la vía es otra, y deliberadamente: una sola línea en
`multimc.cfg`, que es lo que escribe la GUI en Ajustes → Comandos
personalizados → *Wrapper command*.

```
WrapperCommand=prime-run
```

**Por qué el wrapper y no el `.desktop`**: el wrapper envuelve solo el proceso
del juego, así que el launcher Qt se queda en la Intel —no necesita la dGPU para
dibujar una lista de instancias— y la RTX 4060 despierta únicamente al entrar en
una partida. Con el truco del `.desktop` la heredarían los dos. Es lo que
respeta el Runtime D3 de §6.

**Medido, no deducido** (2026-09-14, instancia 1.21.11):

| Comprobación | Resultado |
|---|---|
| Árbol de procesos | `/usr/bin/prime-run … java -Xms512m -Xmx4096m …` |
| `/proc/PID/environ` del `java` | `__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `__VK_LAYER_NV_optimus=NVIDIA_only` |
| `nvidia-smi` con el juego abierto | el `java` aparece en la GPU 0 con **187 MiB** |
| Consumo | de **2,35 W** en reposo a **~10 W**, 27-73 % de uso |

Esto cierra el `[VER]` que §15 tenía abierto, y de paso **desmiente la
suposición de partida**: se había escrito que sin wrapper el juego *seguramente*
iba por la iGPU, pero eso nunca llegó a medirse y ya no se puede afirmar en un
sentido ni en otro.

⚠️ **Al editar `multimc.cfg` a mano, la aplicación tiene que estar cerrada**:
MultiMC reescribe el archivo entero al salir y se lleva por delante el cambio.
Puesto con la GUI cerrada, el valor **sobrevive** a los arranques siguientes
(comprobado tras lanzar y cerrar el juego).

> La dGPU aparece como `active` en `runtime_status` incluso sin juego, pero eso
> no es cosa de MultiMC: el HDMI cuelga de la NVIDIA y la mantiene despierta
> mientras el monitor externo esté conectado (§6).

### Qué no se versiona

Todo `~/.local/share/multimc`, por tres razones distintas: `accounts.json` son
tokens MSA (artefacto de autenticación, fuera por `CLAUDE.md`, igual que los ID
de AnyDesk y TeamViewer); `instances/`, `libraries/`, `assets/`, `meta/` y
`cache/` son datos y descargas que pesan y se regeneran; y `multimc.cfg`, aun
siendo configuración, se descarta porque la aplicación la reescribe entera al
salir —geometrías de ventana en base64 incluidas— y con Stow daría un archivo
que cambia solo en cada sesión.

**MultiMC no tiene paquete Stow.** Al repositorio solo entra su nombre en
`packages/aur.txt`. Es el caso contrario al de §13, donde lo versionado no es la
configuración del launcher sino una entrada de escritorio escrita a mano.

Historia y detalle completo: `history/2026-09-14-multimc.md`.

## 30. StreamDeck DIY: 12 teclas y 5 sliders  **[OK]**

Hardware propio, construido por el usuario y traído del PC de sobremesa
(Windows) el 2026-09-14: un **SparkFun Pro Micro 5V** (ATmega32U4) con una
matriz de 12 switches y 5 potenciómetros deslizantes, en carcasa impresa en 3D.
Funciona por **dos vías independientes**, y esa separación es la clave de todo
lo demás:

| Vía | Qué manda | Qué hace falta en el PC |
|---|---|---|
| **USB HID** (teclas) | F13–F21 y teclas multimedia estándar | **nada**: el kernel lo ve como `Arduino LLC Arduino Leonardo Keyboard` |
| **Puerto serie** (sliders) | `v0\|v1\|v2\|v3\|v4\n`, valores 0–1023 | el script propio `streamdeck_mixer.py` |

### El primer componente del repositorio que es código propio, no configuración

Todo lo demás en `dotfiles/` es configuración de programas ajenos. `streamdeck/`
es **un proyecto entero**: firmware Arduino (`firmware/`), el mezclador en
Python (`host/`) y su documentación de 35 KB, que se escribió en el sobremesa y
ya traía el proceso completo con sus trampas de soldadura, pinout y firmware.
**No es un paquete Stow** y no se enlaza nada bajo `~/.config`.

⚠️ **Pero sí depende de un enlace hecho a mano, y no lo crea Stow.**

```
~/StreamDeckDIY -> Projects/arch-msi/streamdeck
```

El servicio de usuario apunta a `%h/StreamDeckDIY/host/streamdeck_mixer.py`, así
que **sin ese symlink el mezclador no arranca**. Al restaurar en un equipo
limpio hay que crearlo —o cambiar el `ExecStart`—. Es el mismo tipo de requisito
manual que el directorio que hay que crear antes de invocar a Stow en §13, y por
la misma razón: algo fuera del repositorio tiene que existir primero.

### Lo que hace falta en el sistema

- **`python-pyserial`** (en `pacman-explicit.txt` desde el 2026-09-14). Ojo:
  `pip install` falla en Arch con *externally-managed-environment*, y **no se
  fuerza con `--break-system-packages`**: la dependencia está empaquetada.
- **`libpulse`**, que es quien trae `pactl`. Ya estaba.
- **`playerctl`** (ya estaba, explícito), para el volumen de Spotify por MPRIS.
  Ver el apartado de abajo.
- **El usuario en el grupo `uucp`**, para abrir `/dev/ttyACM0` (`crw-rw---- root
  uucp`). Verificado: `id` da `984(uucp)`. ⚠️ Tras el `usermod` **no basta con
  abrir otra terminal**: hay que cerrar la sesión de Hyprland y volver a entrar,
  porque el grupo se hereda del proceso de login.

### El servicio de usuario está COPIADO, no enlazado

`~/.config/systemd/user/streamdeck-mixer.service`, `enabled` y `active`
(comprobado: arrancado a las 22:00, conectado a `/dev/ttyACM0` a 115200 baudios,
con los cinco sliders mapeados en el log). El original vive en
`streamdeck/host/streamdeck-mixer.service` y hoy **son idénticos byte a byte**,
pero al ser una copia pueden desincronizarse: si se edita el del repositorio hay
que volver a copiarlo y hacer `systemctl --user daemon-reload`.

`Restart=always` con `RestartSec=5`: si el script muere, systemd lo relevanta.
El script además reintenta solo cuando el StreamDeck no está enchufado.

⚠️ **Sí añade requisitos a `install/services.sh`** (ver 6.1 del roadmap), al
contrario que rofi, yazi, minecraft o dunst. Son **dos, y de tipos distintos**:

1. **El `enable` de `streamdeck-mixer.service`**, que vive en
   `~/.config/systemd/user/graphical-session.target.wants/` y no se versiona —el
   cuarto hueco de 6.1—. Sin él los sliders no mueven nada, aunque **las teclas
   sí sigan funcionando**, porque son USB HID puro: el aparato parece medio roto
   en vez de apagado.
2. **El symlink `~/StreamDeckDIY`**, que no es un `enable` ni un archivo de
   configuración. Es el único requisito de su clase en el proyecto, y sin él el
   servicio arranca y muere sin encontrar el script.

### Identificar aplicaciones en PipeWire: tres propiedades, no una

El mezclador busca cada app por `application.process.binary`,
`application.name` y `node.name`, en ese orden, porque **cada programa publica
lo que le da la gana**:

| App | `application.name` | `…process.binary` | `node.name` |
|---|---|---|---|
| Firefox | `Firefox` | `firefox` | `Firefox` |
| Spotify | `Spotify` | *(no publica)* | `spotify` |
| AnyDesk | `AnyDesk` | `anydesk` | `AnyDesk` |

Spotify es el caso que obliga a mirar más de una: **no publica el binario**.
`media.name` queda deliberadamente fuera de la identificación —es el título de
la canción o de la pestaña y cambia constantemente—, y solo se usa como último
recurso si un flujo no publica ninguna de las otras tres.

Reparto actual: **0** maestro (`@DEFAULT_SINK@`), **1** navegador, **2** Spotify,
**3** «resto» (juegos: cada uno tiene un nombre distinto, así no hay que tocar
nada), **4** Discord.

### La curva de volumen se midió, no se supuso

PipeWire/PulseAudio aplican una escala **cúbica** al volumen software, así que
mandar la posición del fader tal cual concentra casi todo el cambio audible en
el tercio de abajo. La corrección no es un exponente a ojo: el fader se hace
**lineal en dB**, que es como se comporta una mesa de mezclas.

```
dB       = (posicion - 1) * RANGO_DB_LINUX     # 50 dB de recorrido
amplitud = 10 ** (dB / 20)
pactl    = amplitud ** (1/3)                   # deshace la cúbica de PipeWire
```

Medido sobre el hardware: **−5,00 dB por cada 10 % de recorrido**. `RANGO_DB_LINUX`
es el único número que hay que tocar para cambiar el tacto (40 corto, 50
equilibrado —lo puesto—, 60 como mesa de mezclas); a 0 se desactiva la
corrección. La constante de Windows (`CURVA_SESIONES_WINDOWS = 1.75`, otra
medida, contra `GetMasterVolumeLevel()`) **se conserva**: el mismo script corre
en los dos equipos.

### ⚠️ Spotify va por MPRIS, no por `pactl`, y el motivo es que se pisaba solo

Síntoma: al cambiar de canción, el volumen de Spotify volvía al 100 %. **No era
cosa del mezclador**: medido cada 120 ms, el `sink-input` salta a 65536 unos
150 ms después del cambio, y **pasa igual con el servicio parado**.

La reaplicación de `REAPLICAR_AL_CAMBIAR_APPS` no lo cogía porque compara la
**lista de apps sonando**, y ahí no cambia nada: el flujo conserva su índice
(`pactl subscribe` da 27 eventos `change` y **ningún** `new` ni `remove`) y
Spotify sigue en la lista. Lo que lo corregía a veces era el **ruido del
potenciómetro**: al temblar ≥ `UMBRAL_CRUDO`, el script reescribía por
casualidad. Con el slider quieto se quedaba al 100 %.

Causa de fondo: **el mezclador es de lazo abierto**. Solo escribe —no hay una
sola llamada a `get-sink-input-volume` en el código— así que cualquier programa
que toque el volumen gana por incomparecencia.

Arreglo (2026-09-14): `OBJETIVOS_MPRIS = {"spotify": "spotify"}`. Para esas
aplicaciones el volumen se le pide a la **propia app** con `playerctl`, y es
ella quien lo aplica a su flujo; si el que manda es el dueño del flujo, no hay
pelea. **La escala no cambia**, y eso está medido con tres puntos exactos
(MPRIS 0,50 → 32768; 0,25 → 16384; 0,75 → 49152, sobre 65536): MPRIS usa la
misma escala cruda de PulseAudio, así que `RANGO_DB_LINUX` y su raíz cúbica
siguen valiendo y solo hay que dividir entre `VOLUMEN_NORMAL`.

> **Intento descartado, y merece quedar escrito**: primero se midió la curva
> grabando el monitor del sink con `pw-record` y comparando RMS. Salieron
> exponentes de 1,51 a 2,94 sobre las mismas cuatro medidas —el RMS depende de
> qué suene en esos 1,5 s—, o sea **nada concluyente**. El número exacto estaba
> en lo que ya publicaba el sistema. (Aparte: `parec` devuelve 0 bytes en este
> equipo; `pw-record` sí graba.)

`playerctl` (2.4.1-5) pasa a ser **requisito** del mezclador. Si falta, el
script avisa al arrancar y sigue por `pactl`: se pierde el arreglo, no el
volumen. Los demás sliders **siguen por `pactl`**; `OBJETIVOS_MPRIS` es una
lista corta a propósito, solo para apps que gestionan su volumen por su cuenta.

**Comprobado con el hardware el 2026-09-15**: el slider 2 mueve el volumen de
Spotify y **se mantiene al cambiar de canción**. Antes de eso la validación era
solo de software —llamando al backend del script: 40 % → `stream=20722`, 70 % →
`stream=36851`, intacto tras dos cambios de canción—, y quedaba pendiente
justamente la parte que no se puede probar sin tocar el aparato.

### Pendientes

- ~~**Discord**: el nombre que publica no está confirmado en Arch.~~
  **Confirmado el 2026-09-15** con Discord 1.0.157 sonando: el flujo publica
  `application.process.binary = "Discord"`, que casa con el `discord` del
  `SLIDER_MAP`, así que el slider 4 lo coge.
  > ⚠️ **Y destapó un fallo en «resto», ya corregido.** Ese mismo flujo publica
  > ADEMÁS `application.name = node.name = "WEBRTC VoiceEngine"`, un alias que
  > no está asignado a ningún slider. Como «resto» se calculaba **nombre a
  > nombre**, ese alias suelto colaba el flujo de Discord en el grupo de los no
  > asignados: Discord acababa movido por DOS sliders a la vez, el suyo y el de
  > los juegos. Medido con Discord y Minecraft sonando, «resto» alcanzaba los
  > sink-input 13303 (Discord) y 13712 (java).
  >
  > El arreglo cambia el criterio: **«resto» se decide por FLUJO, no por
  > nombre**. Un flujo es del resto solo si NINGUNO de sus nombres está
  > asignado, lo que de paso protege igual a `EXCLUIDOS_DE_RESTO` —un intocable
  > con un alias suelto ya no se cuela—. El backend guarda ahora el mapa
  > `índice -> nombres` para poder preguntárselo.
- **OBS**: no está instalado en el portátil, así que sus hotkeys no se han
  probado aquí. Aviso heredado: bajo Wayland los atajos globales solo llegan si
  OBS corre en XWayland (`env -u WAYLAND_DISPLAY obs`).
- **F17–F21**: las cinco teclas custom siguen **sin asignar**. En Hyprland con
  configuración Lua no valen los `bind = , F17, exec, …` del README (§9): hay que
  escribirlas como `hl.bind(...)` en `hyprland.lua`.

Documentación completa del proyecto —cableado, pinout, firmware, montaje y
solución de problemas— en `streamdeck/README.md`; el encargo del traspaso, en
`streamdeck/TRASPASO-ARCH.md`. Historia de la incorporación al repositorio:
`history/2026-09-14-streamdeck.md`.

---

## 31. Símbolos que no están en el teclado (`Super + G`)  **[OK]**

Selector de símbolos —griegas, operadores matemáticos, conjuntos, flechas y
sub/superíndices— buscable **por nombre en castellano**. Nació de una pregunta
sobre Obsidian (§26), pero es del escritorio entero: sirve en kitty, en Dolphin
y en el navegador igual que en los apuntes.

| Pieza | Dónde |
|---|---|
| Script | `scripts/simbolos.sh` |
| En el `PATH` | `dotfiles/bin/.local/bin/simbolos` (symlink, paquete Stow `bin`) |
| Atajo | `Super + G` en `hyprland.lua` — G de «griego» |
| Depende de | `rofi` (ya estaba, §13) y `wl-clipboard`; `wtype` opcional, instalado el 2026-09-15 |

96 entradas. Los sub/superíndices son **Unicode reales** (`₀₁₂₃ₙ`, `⁰¹²³ⁿ⁻`), no
`<sub>`: la misma preferencia que ya se razonó en §26, porque se copian y pegan
a cualquier sitio.

### Por qué un menú y no una tecla Compose ni una distribución griega

Las tres vías se evaluaron con el sistema delante, y las otras dos perdieron por
motivos distintos:

- **Tecla Compose.** El archivo `Compose` del sistema **ya trae 67
  combinaciones griegas**, pero todas cuelgan de `<dead_greek>`, y `dead_greek`
  solo existe en la variante `us(altgr-weur)` — ni en `es` ni en `us(intl)`, que
  son las dos de este equipo (§20). Están en el disco y **son inalcanzables**.
  Se podrían recuperar con un `~/.XCompose` de prefijo `<Multi_key>`, pero sigue
  exigiendo **recordar una pulsación por símbolo**.
- **Tercera distribución `gr`.** `Super+Espacio` **rota** entre las cargadas
  (§20), así que pasaría de dos paradas a tres y se acabaría escribiendo en
  griego sin querer.

El menú gana porque **se busca por nombre**, que es lo que uno tiene en la
cabeza al escribir apuntes, y es lo único que escala a 96 símbolos sin
memorizar nada.

⚠️ **`Ctrl+Shift+U` no funciona en este equipo** y conviene tenerlo anotado: esa
entrada Unicode la aporta ibus, y aquí no hay ningún método de entrada
(`XMODIFIERS` vacío, ni ibus ni fcitx).

### Los alias sin tildes son deliberados

Cada entrada del catálogo lleva el nombre acentuado **y** su forma pelada:

```
Δ  Delta mayúscula · variación · variacion · incremento · \Delta
```

**rofi filtra por subcadena y no normaliza acentos.** Sin el alias, escribir
`variacion` con prisa no encontraría nada. Va también el nombre LaTeX, que es
como se llama al símbolo cuando se viene de escribir fórmulas.

### Se copia siempre; teclear es lo opcional

El símbolo elegido va **siempre** al portapapeles con `wl-copy -n` (la `-n` es
necesaria: sin ella se pegaría el símbolo *y* un salto de línea). Además, **si
`wtype` está instalado**, se teclea en la ventana enfocada; si no, un aviso de
dunst recuerda que se pega con `Ctrl+V`.

La detección es `command -v wtype`, así que el script funcionó desde el primer
momento sin instalar nada y cambia de modo solo cuando el paquete aparece. Se
copia aunque `wtype` funcione: cuesta nada y sirve de red si la aplicación
ignora el teclado virtual.

⚠️ **El `sleep 0.15` antes de teclear no es decorativo.** rofi es una capa de
Wayland que toma el foco del teclado; al cerrarse, Hyprland lo devuelve a la
ventana anterior de forma **asíncrona**. Sin la pausa, el carácter puede caer en
el limbo entre las dos ventanas.

### Estado de validación

Comprobado el 2026-09-15: `bash -n` y `luac -p` correctos; `stow -n` da **un
solo `LINK` y cero conflictos**; `hyprctl reload` → `ok` y `Super+G` sale
registrado en `hyprctl binds` (modmask 64, key G), con lo que el recuento pasa
de 57 a **58 binds**; y la ruta del portapapeles da `Δ` en **2 bytes sin salto
de línea**.

**Cerrado el mismo día, ya con `wtype 0.4-2` instalado.** El menú abre bien y el
símbolo llega a Obsidian. Comprobado además que `wtype ""` sale con código 0, o
sea que **Hyprland expone el protocolo de teclado virtual** y `wtype` habla con
él.

Y la parte que costaba separar también queda resuelta: **el carácter lo teclea
`wtype`, no se pega**. Como el script llena los dos caminos a la vez —se copia
siempre, aunque `wtype` funcione—, ambos dan el mismo resultado visible, así que
se hizo la prueba que los distingue: pulsar `Super + G`, elegir un símbolo y ver
si aparece **sin tocar `Ctrl+V`**. Aparece. El usuario lo confirma el 2026-09-15
escribiendo `βΓ` por esa vía.

Eso responde de paso la duda de fondo que arrastraba también la vía de Compose:
**Electron en Wayland nativo sí atiende el teclado virtual**.

Diagnóstico completo, con las cuatro vías y por qué se descartaron tres:
`history/2026-09-15-simbolos-griegos.md`.


## 32. Frecuencia del panel según la corriente  **[OK]**

El panel interno (AU Optronics 0xD298) es de **165 Hz** y `hyprland.lua` lo fija
así en la regla de `eDP-1`. Con batería eso se paga en autonomía, y hasta el
2026-09-16 **no había nada que lo bajara**: el equipo podía estar en
`power-saver` y desenchufado, y seguía a 165 Hz.

La regla, entera:

| Situación | Frecuencia |
|---|---|
| AC enchufado, cualquier perfil | **165 Hz** |
| Batería + `power-saver` | **60 Hz** |
| Batería + `balanced` o `performance` | **165 Hz** |

El perfil es el interruptor deliberado: en clase se pone `power-saver` y la
pantalla acompaña; si hace falta fluidez, se cambia de perfil y vuelve a 165 sin
enchufar nada.

| Pieza | Dónde |
|---|---|
| Script | `scripts/panel-hz.sh` |
| En el `PATH` | `dotfiles/bin/.local/bin/panel-hz` (symlink, paquete Stow `bin`) |
| Autoarranque | `hl.exec_cmd("panel-hz")` en `hyprland.start` (`hyprland.lua`) |
| Depende de | `udevadm`, `dbus-monitor`, `socat`, `jq`, `powerprofilesctl` — todo ya instalado |

El panel **solo ofrece dos modos** (`hyprctl monitors` → `availableModes`):
`165.04Hz` y `60.04Hz`. No hay nada intermedio que elegir, y `vrr` está en
`false`, así que tampoco hay refresco adaptativo de por medio.

### Se cambia con `eval`, no con `keyword`

Con configuración Lua, `hyprctl keyword` responde «keyword can't work with
non-legacy parsers» (§7). Se evalúa la misma llamada que usa el archivo:

```
hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2560x1600@60.04", position = "0x0", scale = 1.6 })'
```

⚠️ La resolución, la posición y la escala se repiten en esa llamada porque
`hl.monitor()` describe el monitor **entero**, no un delta. Si cambian en la
regla de `hyprland.lua`, hay que cambiarlas también en el script.

### ⚠️ `theme-apply` deshacía el ahorro en silencio

`scripts/theme-apply.sh` termina con un `hyprctl reload`, y un reload re-aplica
`hyprland.lua` de arriba abajo: la regla de `eDP-1` vuelve a poner 165 Hz.
Cambiar el fondo o el tema en mitad de una clase bastaba para perder el ahorro
**sin que saltara ningún aviso**.

Por eso el demonio escucha tres cosas y no solo el enchufe:

| Fuente | Qué detecta |
|---|---|
| `udevadm monitor --udev --subsystem-match=power_supply` | enchufar / desenchufar |
| `dbus-monitor --system`, `/net/hadess/PowerProfiles` | `ActiveProfile` (cambio de perfil) |
| socket2 de Hyprland, filtrando `configreloaded` | los `hyprctl reload` |

El enchufe se lee **al kernel y no a UPower**: es la fuente de verdad y no
depende de que ese demonio esté vivo. Y los eventos del socket2 se filtran en la
fuente, no en el bucle: si no, cada cambio de ventana despertaría al demonio y
se gastaría batería vigilando la batería.

Por encima hay un **sondeo de respaldo cada 60 s**, pensado para el caso en que
una señal se pierda al volver de suspensión: el peor caso deja de ser «se queda
mal» y pasa a ser «se corrige solo en menos de un minuto».

### Por qué no es una regla de udev

Es la respuesta obvia y aquí es la mala: correría **como root y fuera de la
sesión gráfica**, y para hablar con Hyprland hacen falta su socket y el entorno
del usuario; pide tocar `/etc` para algo que no lo necesita; y no cubriría ni el
cambio de perfil ni el `hyprctl reload`. Tampoco se abre una unidad de systemd,
por la convención que ya razona `vpn-autoconnect.sh` (§7): el autoarranque de la
sesión vive en `hyprland.lua`.

### Detalles del script

- **`flock`** en `$XDG_RUNTIME_DIR/panel-hz.lock`: reiniciar solo la sesión
  gráfica no debe dejar dos demonios peleándose por el modo.
- **`LC_NUMERIC=C`**, y no por capricho: el locale es `es_ES`, con coma decimal,
  y `printf '%.0f' 165.04` falla con «número inválido». Los números vienen de
  `hyprctl` en formato C. Se fija solo esa categoría para que las
  notificaciones sigan saliendo con acentos.
- **`PANEL_HZ_SIMULA_BATERIA=1`** finge que no hay corriente. Existe porque
  desde una terminal no se puede desenchufar el portátil, y sin ese gancho la
  lógica quedaría sin probar hasta la primera clase.
- `panel-hz --status` dice qué ve y qué haría; `--once` aplica y sale.

### Estado de validación

Comprobado el 2026-09-16 con el gancho de batería simulada, leyendo
`refreshRate` en cada paso: arranque en batería + `power-saver` → **60.04300**;
`balanced` → **165.03999**; vuelta a `power-saver` → **60.04300**; y tras un
`hyprctl reload` → **60.04300**, que es el caso de `theme-apply`. Además,
`stow -n` da **un solo `LINK` y cero conflictos**, la segunda instancia sale por
el cerrojo y al matar el demonio no quedan procesos huérfanos.

**Comprobado con el cable fuera el mismo día**: al desenchufar, el panel pasó a
60 Hz solo. No se pudo distinguir si lo disparó el uevent o el sondeo de
respaldo; ver §15.

**Sin comprobar** sigue **cuánto ahorra**. Y ojo con cómo se mide: esta batería
**no expone `power_now`**, solo `current_now` (µA) y `voltage_now` (µV), así que
la potencia se calcula multiplicándolos. Ver §15.

Una medición suelta del 2026-09-16, que no responde a la pregunta pero sitúa el
orden de magnitud: en batería, a 60 Hz, con el **monitor externo HDMI
conectado** y la dGPU en `active` —el HDMI cuelga de ella (§6)—, el equipo tiraba
**23,74 W**. Con ~36 Wh de carga restante eso es hora y media larga. El panel es
un sospechoso de la autonomía corta, pero con el externo enchufado no es el
principal: ahí quien manda es la NVIDIA despierta.

Diagnóstico completo: `history/2026-09-16-panel-60hz-bateria.md`.


## 33. Aplicaciones GTK y Qt: el tema más allá del escritorio  **[EN CURSO]**

Tarea 3.5. El escritorio entero sale de `tokens.toml` y matugen desde la 3.0
(§18), pero las **aplicaciones** iban por su cuenta: desde el 2026-09-13 eran
oscuras, y nada más. Esta tarea las mete en el tema.

Va por pasos. **Pasos A, B y C completados el 2026-09-16**; el D se descartó
con el sistema delante.

| Paso | Qué | Estado |
|---|---|---|
| A | Tema GTK3 real, iconos, cursor y fuente | **[OK]** 2026-09-16 |
| B | Colores de matugen en GTK3/GTK4 (`gtk.css`) | **[OK]** 2026-09-16 |
| C | Colores del tema en Dolphin (esquema KDE) | **[OK]** 2026-09-16 |
| D | ~~Qt6: Kvantum como estilo de widgets~~ | **descartado**, ver abajo |

### Paso A: lo que ve una aplicación GTK

| Ajuste | Antes | Ahora | De dónde sale |
|---|---|---|---|
| Tema | `Adwaita-dark` (inexistente) | `adw-gtk3-dark` | `matugen.mode` |
| Iconos | `Adwaita` | `Papirus-Dark` | `[apps].icon_theme` |
| Cursor | `default` | `Adwaita`, 24 px | `[apps].cursor_theme` |
| Fuente | `Adwaita Sans 11` | `JetBrainsMono Nerd Font 10` | `[font]` |

**Una sola familia en todo, decisión del 2026-09-16.** Los menús de las
aplicaciones usan la misma fuente monoespaciada que el escritorio y el terminal,
que es lo que ya declaraba la cabecera de `[font]` en `tokens.toml`. Se descartó
añadir una familia de interfaz aparte.

### ⚠️ `Adwaita-dark` no existía, y llevaba tiempo escrito en dos sitios

El paquete Stow `gtk` y `theme-apply` fijaban `gtk-theme-name=Adwaita-dark`.
**Ese tema no está instalado**: `/usr/share/themes` solo tenía `Default` y
`Emacs`. No estaba roto —GTK cae a su Adwaita interno y quien oscurecía era
`gtk-application-prefer-dark-theme`—, pero el nombre mentía, y el propio aviso
de §18 sobre `QT_QPA_PLATFORMTHEME=gtk3` ya lo decía mientras el archivo de al
lado lo seguía escribiendo.

Ahora hay un tema de verdad: **`adw-gtk-theme` 6.5-1**, del repositorio `extra`.

> ⚠️ **No se llama `adw-gtk3` en los repos.** `pacman -S adw-gtk3` no encuentra
> nada y parece cosa del AUR; el paquete está en `extra` con el nombre
> **`adw-gtk-theme`**, e instala dos temas, `adw-gtk3` y `adw-gtk3-dark`. La
> variante oscura es un tema propio, no un modificador del claro.

### El paquete Stow `gtk` se retiró: ahora es plantilla

Los dos `settings.ini` los genera matugen desde `tokens.toml`, igual que
`style.css` de Waybar desde la 3.0. El motivo es la regla que el propio
`tokens.toml` declara: el tema, los iconos y la fuente estaban a punto de quedar
escritos en dos sitios —el archivo estático y el `gsettings` de `theme-apply`—,
que es precisamente lo que esa regla llama error.

| Pieza | Dónde |
|---|---|
| Plantilla | `dotfiles/matugen/.config/matugen/templates/gtk-settings.ini` |
| Declarada en | `[templates.gtk3]` y `[templates.gtk4]` de `config.toml` |
| Salidas | `~/.config/gtk-3.0/settings.ini` y `~/.config/gtk-4.0/settings.ini` |
| Valores | `[apps]` y `[font]` de `theme/tokens.toml` |

**Una plantilla, dos salidas**: GTK3 y GTK4 leen el mismo formato y todas las
claves valen para las dos. Lo que cambia es qué hace cada una con
`gtk-theme-name`: GTK3 la obedece; en GTK4 las apps de libadwaita la ignoran y
siguen el `color-scheme` del portal.

Con el paquete fuera, los paquetes Stow pasan de 18 a **17**.

> ⚠️ El `stow -D` hay que hacerlo **antes** de declarar las plantillas. Si no,
> `theme-apply` aborta con «es un ENLACE de Stow», que es justo la protección
> que impone la regla de oro de §18.

### ⚠️ GSettings gana a `settings.ini`, y por eso la fuente no se aplicaba

Escribir la fuente solo en la plantilla **no funciona**. Con el archivo ya
generado y diciendo `JetBrainsMono Nerd Font 10`, `gtk-query-settings` —que
muestra los valores EFECTIVOS, no el contenido del archivo— seguía devolviendo
`Adwaita Sans 11`.

El motivo: en esta sesión GTK3 toma esas claves de GSettings, y `font-name` **ni
siquiera estaba en dconf**. O sea que `settings.ini` perdía contra el *default
del esquema* de GNOME, un valor que nadie había elegido.

Por eso `theme-apply` fija también `font-name` por `gsettings`. Y se lee aparte,
no con el `read -r` posicional del resto de tokens: «JetBrainsMono Nerd Font»
lleva espacios y aquel `read` la partiría en trozos.

El `settings.ini` se sigue generando igualmente: es lo único que hay en una
sesión sin dconf.

### Estado de validación

Comprobado el 2026-09-16 con `gtk-query-settings`, que devuelve lo efectivo y no
lo escrito: `adw-gtk3-dark`, `Papirus-Dark`, `JetBrainsMono Nerd Font 10` y
cursor `Adwaita`. Los cuatro coinciden con `tokens.toml`.

Además: `stow -n -D` limpio antes de desenlazar, `theme-apply` escribe los 15
artefactos sin abortar, y **`git status` queda limpio de generados**, que es la
prueba de la regla de oro.

**Sin confirmar visualmente**: que una ventana GTK recién abierta se vea como
debe. Las aplicaciones ya lanzadas (`nm-applet`, `blueman`) leen esto al
arrancar y no se enteran hasta reiniciarlas.

### Paso B: los colores del fondo llegan a las aplicaciones

Con el paso A las apps eran oscuras y coherentes en tema, iconos y fuente, pero
sus colores seguían siendo los de un Adwaita genérico. Ahora salen del **mismo
fondo de pantalla** que el resto del escritorio.

| Pieza | Dónde |
|---|---|
| Plantilla | `dotfiles/matugen/.config/matugen/templates/gtk-colors.css` |
| Declarada en | `[templates.gtk3-colors]` y `[templates.gtk4-colors]` |
| Salidas | `~/.config/gtk-3.0/gtk.css` y `~/.config/gtk-4.0/gtk.css` |

**No se reescribe el tema: se le cambian las constantes.** libadwaita (GTK4) y
adw-gtk3 (GTK3) construyen todo su aspecto sobre un puñado de colores con
nombre; redefinirlos con `@define-color` en el `gtk.css` del usuario los
sustituye en el tema entero sin tocar un solo widget.

El mapeo aprovecha que la escala de contenedores de Material You encaja casi uno
a uno con la jerarquía de superficies de libadwaita:

| libadwaita | Rol de matugen |
|---|---|
| `window_bg_color` | `surface` |
| `view_bg_color` | `surface_container_lowest` |
| `headerbar_bg_color` / `popover_bg_color` | `surface_container` |
| `sidebar_bg_color` / `card_bg_color` | `surface_container_low` |
| `dialog_bg_color` | `surface_container_high` |
| `accent_bg_color` / `accent_color` | el `accent` del escritorio |

⚠️ **El acento NO es `colors.primary`.** Es el mismo `accent` que pinta la barra,
rofi y el borde de la ventana activa, que sale de un TONO de la paleta primaria
elegido en `tokens.toml` y lo resuelve `theme-apply` porque las plantillas no
ven `palettes.*`.

⚠️ **Los estados no se derivan del fondo, a propósito.** `success`, `warning` y
`error` salen de `[colors.state]`: un aviso amarillo tiene que ser el mismo
amarillo en la barra, en una notificación y en un diálogo.

También se definen los nombres clásicos de GTK3 (`theme_bg_color`,
`theme_selected_bg_color`, `borders`…), que usaría un tema GTK3 que no fuera
adw-gtk3 o una aplicación vieja que los consulte directamente. En GTK4 se
ignoran sin más.

> **Lo que esto no alcanza:** las apps con CSS propio y colores cableados, y las
> que se pintan solas (Electron, Firefox con su tema), que van por
> `color-scheme` del portal (§18).

**Validación del paso B (2026-09-16).** No se miró el archivo generado, sino lo
que GTK resuelve de verdad: una ventana de prueba de GTK3 y otra de GTK4,
preguntando por `lookup_color()`. Los seis colores comprobados coinciden con la
plantilla, **en las dos versiones**:

```
window_bg_color   #0c141b      headerbar_bg_color   #1d252c
view_bg_color     #040b11      accent_bg_color      #58b4ef
theme_bg_color    #0c141b      theme_selected_bg…   #58b4ef
```

Y el CSS se carga **sin un solo aviso de parseo** en ninguna de las dos.

### Paso C: Dolphin con los colores del tema, y por qué no fue por donde parecía

El primer intento fue `QT_QPA_PLATFORMTHEME=qt6ct`, que lee una **paleta
completa** donde el portal solo sabe decir «oscuro o claro». La paleta se
aplicó perfecta —`Window #0c141b`, `Highlight` con el acento del escritorio— y
aun así **rompió las dos aplicaciones Qt del equipo**:

- **ZapZap se puso en claro** y se llevó por delante el tema de WhatsApp Web
  (§27). Su ajuste es `theme=auto`, y su código hace literalmente
  `if color_scheme == Dark: return Dark` y si no, `return Light`
  (`zapzap/core/theme/theme_manager.py`).
- **Dolphin salió claro con trozos oscuros**: los widgets tomaban la paleta de
  qt6ct, pero todo lo que pinta `KColorScheme` caía a Breeze **claro**.

La causa, medida con `QStyleHints` en vez de deducida:

```
PLATFORMTHEME=xdgdesktopportal -> colorScheme=Dark     Window=#323232
PLATFORMTHEME=qt6ct            -> colorScheme=Unknown  Window=#0c141b
```

> ⚠️ **`qt6ct` 0.11 no implementa `colorScheme()`.** Una paleta bonita no
> sustituye a esa señal: quien pregunta se queda sin respuesta y **asume claro**.
> Es el mismo tipo de trampa que ya documentaba §18 con `gtk3` —parece funcionar
> y no funciona—, pero al revés: allí el nombre del esquema era correcto y la
> paleta falsa; aquí la paleta es correcta y falta el nombre.

**La vía buena no pasa por el platformtheme.** Dolphin es KF6 y sus colores los
pone `KColorScheme`, que lee `~/.config/kdeglobals` y no la paleta de Qt. Así
que la variable **vuelve a `xdgdesktopportal`** —que sí da la señal— y los
colores entran por un esquema KDE:

| Pieza | Dónde |
|---|---|
| Plantilla | `templates/kde-colors.conf` |
| Declarada en | `[templates.kde-colors]` |
| Artefacto intermedio | `~/.config/kdeglobals-arch-msi.conf` |
| Destino final | secciones de color de `~/.config/kdeglobals` |

**Siete conjuntos de color** (`Window`, `View`, `Button`, `Selection`,
`Tooltip`, `Header`, `Complementary`) con el mismo mapeo que GTK y Qt: `View` ←
`surface_container_lowest` (la lista de archivos), `Selection` ← el acento del
escritorio. Las doce claves de cada conjunto salen del propio binario
(`strings /usr/lib/libKF6ColorScheme.so`), no de una lista de internet.

> ⚠️ **`kdeglobals` NO se puede generar entero, y por eso hay fusión.** Ahí
> escribe también Dolphin: `[KFileDialog Settings]` guarda el ancho de la barra
> lateral y el orden de las columnas. Generar el archivo los borraría en cada
> arranque. `theme-apply` funde solo las secciones de color y deja el resto
> intacto — comprobado: las 15 claves de Dolphin siguen idénticas tras la
> fusión.

> ⚠️ **En `kdeglobals` los colores van en `R,G,B` decimal.** La plantilla los
> escribe en hex porque se revisa mejor, y la fusión los convierte. `#58b4ef`
> acaba como `88,180,239`.

### Dolphin translúcido

La transparencia no la pone el tema Qt, sino Hyprland, con la **misma opacidad
que la barra y las notificaciones** (`[opacity].surface`). El token viaja por
`theme.lua`, que es el único camino que tiene `hyprland.lua` para leer
`tokens.toml` sin repetir el número.

> ⚠️ **Hyprland aplica la opacidad a la VENTANA ENTERA**, con su texto y sus
> iconos dentro, no solo al fondo como haría un tema Qt. Si el texto se lee mal,
> se sube `[opacity].surface` —lo comparte con la barra— o se le da a la regla un
> valor propio.

> ⚠️ **`opacity` es una CADENA** en `hl.window_rule`, con los dos valores
> separados por espacio. Con tabla o número, el parser responde «field
> 'opacity': string type requires a string» y **la regla entera se cae**; lo
> delató `hyprctl configerrors`, no un aviso al recargar.

La clase es `org.kde.dolphin`, leída de `hyprctl clients` con la ventana abierta:
en Wayland nativo las apps de KDE usan el ID de aplicación con dominio invertido.

### Paso D (Kvantum): descartado antes de empezar

Medido el 2026-09-16: **Kvantum no es un platformtheme, es un `QStyle`**
(`/usr/lib/qt6/plugins/styles/libkvantum.so`), así que se activaría con
`QT_STYLE_OVERRIDE` o desde qt6ct. Y ahí está el problema: sus temas traen sus
propios colores en SVG, que pisarían el esquema KDE que acaba de resolver
Dolphin. Aportaría forma de widgets a cambio de romper el color, para las dos
únicas aplicaciones Qt del equipo —una de las cuales es una ventana web—.

`qt6ct` y `kvantum` quedan instalados y **sin usar**. Se pueden quitar con
`sudo pacman -Rns qt6ct kvantum`.

Diagnóstico completo: `history/2026-09-16-theming-gtk-qt.md`.

---

## 34. La estética de HyDE, con nuestros colores  **[OK]**

Ampliación pedida el 2026-09-16, ya cerrada la 3.5: adoptar el aspecto de
**HyDE** (github.com/Hyde-project/hyde) —iconos, redondeos, tamaños,
distribución— **manteniendo el esquema de colores y las transparencias de este
repositorio**. Se clonó su repositorio (163 MB) y se leyó el original en vez de
ir de memoria.

### Qué se trajo y qué ya coincidía

| Aspecto | HyDE | Aquí |
|---|---|---|
| Config de Hyprland | Lua | Lua — **ya coincidía** |
| Radio de esquinas | 10pt | `metrics_radius = 10` — **ya coincidía** |
| Iconos | Tela-circle | adoptado, **recoloreado** (ver abajo) |
| Cursor | Bibata-Modern-Ice | adoptado tal cual |
| Opacidad de ventanas | 0.90 / 0.75 | adoptado y ajustado a **0.92 / 0.75** |
| Widgets Qt | Kvantum | adoptado, con su SVG |
| Dolphin | toolbar 16 px, sin barra de estado… | adoptado, con matices |
| Colores | wallbash (su motor) | **los nuestros**, matugen |

### Los iconos se generan, no se eligen

Tela-circle viene en dieciséis colores fijos y **ninguno es el acento**: el más
azul, `blue`, es un índigo `#5677fc`. Como el acento sale del fondo de pantalla,
ninguna variante fija iba a casar nunca.

Así que `theme-apply` genera la suya: copia la variante azul a
`~/.local/share/icons/Tela-circle-arch-msi` y sustituye ese índigo por el acento.

> **Se midió antes de escribirlo**: el tema son 110 MB aparentes pero **44 MB
> reales** —16 752 de sus 27 000 entradas son symlinks— y el azul aparece en
> solo **177 SVG**. Copia y reemplazo: **0,55 s**. Aun así no se rehace en cada
> arranque: guarda el acento usado en `.acento` y solo regenera si cambia.

### Transparencia y desenfoque

| Token | Valor | Qué es |
|---|---|---|
| `[opacity].window_active` | **1** | ventana enfocada: opaca |
| `[opacity].window_inactive` | 0.80 | las de detrás |
| `[blur].size` | 3 | radio del desenfoque |
| `[blur].passes` | 3 | pasadas |
| `[blur].brightness` | 0.80 | **lo que más ayuda a leer** |

⚠️ `brightness` por debajo de 1 hace más por la legibilidad que subir el
desenfoque: oscurece lo que queda detrás, así que el texto claro gana contraste.

⚠️ **Con la activa en 1, el blur no se ve en ella**: no hay nada translúcido que
desenfocar. Sigue actuando donde queda transparencia —ventanas inactivas, barra y
notificaciones—, así que `[blur]` no es código muerto, pero deja de notarse en la
ventana que uno mira. Los valores de HyDE eran 0.90/0.75; se ajustaron con el
escritorio en uso (2026-09-17).

⚠️ `[opacity].surface` (0.80) y estas dos NO son lo mismo y por eso son tokens
distintos: aquella tiñe superficies que dibuja una aplicación metiendo alfa en
el color; estas las aplica Hyprland a la ventana entera, contenido incluido.

### Kvantum: el estilo que sí pinta los widgets

La paleta de una app Qt la pone el `platformtheme`, y el del portal —el único
que da la señal de modo oscuro (§33)— no lee `kdeglobals`. Kvantum es un
**QStyle**: pinta los widgets él mismo.

> ⚠️ **HyDE lo activa con `QT_QPA_PLATFORMTHEME=qt6ct`, que aquí NO se puede
> usar**: ese plugin no implementa `colorScheme()` y deja a ZapZap en claro
> (§33). Se activa con **`QT_STYLE_OVERRIDE=kvantum`**, que carga el estilo sin
> tocar el platformtheme. El portal sigue dando la señal Y los widgets los pinta
> Kvantum. Es la mitad buena de lo que hace HyDE, sin la que rompía cosas.

| Pieza | Dónde |
|---|---|
| Plantilla del tema | `templates/kvantum-theme.kvconfig` |
| Plantilla de las formas | `templates/kvantum-theme.svg` |
| Selector | `templates/kvantum-select.kvconfig` |
| Salidas | `~/.config/Kvantum/arch-msi/` y `~/.config/Kvantum/kvantum.kvconfig` |

### ⚠️ El SVG viene de HyDE y es GPL-3.0

Un tema de Kvantum son dos archivos: el INI con los colores y **un SVG con las
formas de cada widget**. Los 37 temas que trae el sistema llevan su arte con
**colores cableados**, y por eso resistían: la cabecera de columnas salía gris y
la barra de herramientas con un degradado que no venía de ningún token.

El SVG de HyDE está hecho justo para lo contrario: todo su color entra desde
fuera, por diez marcadores. Se trajo y se convirtió en plantilla de matugen.

> **El mapeo de marcadores se dedujo, no se adivinó**: comparando su plantilla
> `.dcol` con el SVG ya generado, posición a posición. Cada marcador resultó
> tener un único color, así que la correspondencia es exacta:
> `pry1`→`surface`, `1xa1`→`surface_container_lowest`,
> `1xa2`→`surface_container`, `1xa3`→`surface_container_high`,
> `1xa4`→`outline`, `1xa9`→`on_surface`, `4xa6`/`4xa9`→`accent`,
> `4xa7`→`state_crit`, `4xa8`→`tertiary`.

> ⚠️ **LICENCIA.** `kvantum-theme.svg` y `kvantum-theme.kvconfig` son obra de
> HyDE bajo **GPL-3.0**, con la atribución en su cabecera. Este repositorio no
> tiene archivo de licencia propio; si algún día se le pone uno, tiene que ser
> compatible.

### ⚠️ Tres trampas del SVG, las tres silenciosas

1. **`##RRGGBB`.** Los marcadores del original venían precedidos de `#`, así que
   la sustitución generaba colores con doble almohadilla: **597 en el SVG y 52
   en el INI**. Qt no los parsea y no protesta — la ventana se veía casi
   transparente, y parecía que el tema era translúcido cuando en realidad no se
   pintaba nada.
2. **`reduce_window_opacity=10`.** Kvantum resta ese porcentaje por su cuenta y
   se sumaba al 0.92 de Hyprland. Puesto a 0: la transparencia se decide en un
   solo sitio, `tokens.toml`.
3. **`itemview-toggled` sin opacidad.** Ver abajo.

### La selección la pintan tres sitios, y solo manda uno

Costó tres intentos porque el color de la fila seleccionada **no sale de donde
parece**:

| Candidato | Resultado |
|---|---|
| `highlight.color` de Kvantum | ignorado |
| `[Colors:Selection]` de `kdeglobals` | no es quien pinta (pero se le añadió soporte de alfa igualmente) |
| **`itemview-toggled` del SVG** | **es este** |

El SVG traía `itemview-toggled` con `fill:{{accent}}` **a pelo**, mientras
`itemview-focused` —el resalte del ratón— sí llevaba `opacity:0.2`. De ahí que
el hover se viera bien y la selección fuera un bloque macizo.

Ahora la selección usa un tono **más saturado** de la misma paleta primaria y
con alfa. Los dos valores se declaran una vez, en `[apps]`:

```toml
selection_tone  = 50     # rampa: 40 #006492 · 50 #007eb6 · 70 #58b4ef (acento)
selection_alpha = "D9"   # 85 %
```

⚠️ El alfa se declara **una sola vez y en hexadecimal**; `theme-apply` lo
convierte a `0-1` para el SVG y a `R,G,B,A` para KDE, que son las dos unidades
que hacían falta. Y el color sale de `palettes.primary`, que las plantillas no
ven: lo resuelve el script, como ya hacía con el acento.

### Dolphin

Distribución de HyDE: barra de herramientas de 16 px solo iconos y no movible,
sin barra de selección, iconos de Places a 16, vista de iconos con preview 112 y
una línea de texto, y sus quince miniaturizadores —**verificados uno a uno**
contra `/usr/lib/qt6/plugins/kf6/thumbcreator/`, no copiados a ciegas—.

**No se copió su `dolphinui.rc`**: es XML de kxmlgui atado a una versión concreta
(el suyo declara `version="40"`) y Dolphin lo reescribe solo.

> **Regalo de su `kdeglobals`: `TerminalApplication=kitty`.** Cierra el pendiente
> que la 3.4 dejó abierto —«el "Abrir terminal aquí" no aparece en ningún `.kcfg`
> de Dolphin y no se localizó dónde se configura»—. No es de Dolphin, es de KDE
> entero.

> ⚠️ **`ShowStatusBar=true` a propósito, al revés que HyDE.** Con la barra
> oculta, Dolphin dibuja el recuento como un recuadro **flotante encima de la
> lista**. Dándole sitio fijo abajo, desaparece de en medio.

### Estado de validación

Todo lo de esta sección se comprobó **midiendo píxeles de capturas reales**
(`grim` + ImageMagick), no a ojo:

- Barra de herramientas: de un degradado `(67,71,76)`→`(3,12,22)` a un plano
  `(9,18,30)`.
- Cabecera de columnas: de `(59,64,78)` gris a `(4,11,19)`.
- Opacidades y blur: leídos con `hyprctl getoption`.
- Iconos: 177 SVG con el acento, 0 con el azul original.
- Selección: `itemview-toggled` con `opacity:0.85` y `fill:#007eb6` en el
  artefacto generado.

Diagnóstico completo, con los callejones sin salida: `history/2026-09-16-estetica-hyde.md`.



## 35. Suite ofimática y visor de PDF  **[OK]**

Instalado el 2026-09-17. Hasta entonces el equipo **no tenía ninguna suite
ofimática**, y el visor de PDF era Xournal++ sin que nadie lo hubiera elegido.

### El PDF lo abre Firefox, y antes no lo decidía nadie

`~/.config/mimeapps.list` **no tenía línea para `application/pdf`**. Sin
preferencia explícita manda `/usr/share/applications/mimeinfo.cache`, y ahí
Xournal++ figuraba el primero de la lista: se instaló para anotar con el lápiz
(§26) y de paso se quedó con la lectura. Corregido con

```
xdg-mime default firefox.desktop application/pdf
```

Xournal++ sigue registrado y disponible en «Abrir con».

> ⚠️ Al instalar LibreOffice, `libreoffice-draw.desktop` **también** se registró
> para `application/pdf`. Mientras la preferencia explícita esté puesta no
> importa; si se pierde `mimeapps.list`, el visor vuelve a elegirse solo entre
> tres candidatos.

### LibreOffice, y por qué no ONLYOFFICE

`libreoffice-fresh` 26.8.0-2 (423 MiB en disco). La elección se decidió al
concretarse el formato: **`.xls`**, el binario antiguo de Excel (97-2003,
BIFF8). LibreOffice Calc lo lee **y lo guarda**; ONLYOFFICE lo abre convirtiendo
pero **no escribe en ese formato** —devuelve `.xlsx` u `.ods`—, así que no sirve
para devolver un archivo en el formato en que llegó. Se descartaron también WPS
(propietario) y Calligra (poco mantenido).

Las asociaciones las registran los `.desktop` del paquete, no hubo que tocarlas:

| Tipo | Aplicación |
|---|---|
| `.xls`, `.xlsx`, `.ods` | `libreoffice-calc.desktop` |
| `.doc`, `.docx`, `.odt` | `libreoffice-writer.desktop` |
| `.pdf` | `firefox.desktop` (explícito, ver arriba) |

### Diccionarios: inglés, castellano y catalán

| | Castellano | Catalán | Inglés |
|---|---|---|---|
| Interfaz | `libreoffice-fresh-es` | `libreoffice-fresh-ca` | de serie |
| Ortografía | `hunspell-es_es` | `hunspell-ca` **(AUR)** | `hunspell-en_us`, `hunspell-en_gb` |
| Sinónimos | `mythes-es` | extensión `.oxt` (abajo) | `mythes-en` |
| Guionado | `hyphen-es` | **no existe** | `hyphen-en` |

> ⚠️ **`hunspell-ca` no está en los repos oficiales.** Solo hay `aspell-ca`, y
> LibreOffice corrige con hunspell, no con aspell. Viene del AUR (3.0.9-1, 27
> votos) y trae `ca_ES`, `ca_ES-valencia`, `ca_AD`, `ca_FR` y `ca_IT`.

No existe paquete de guionado catalán en ningún sitio. Es una carencia asumida.

### ⚠️ El tesauro catalán es una extensión, no un paquete

`mythes-ca` del AUR **está roto**: su PKGBUILD descarga de una ruta de
`softcatala.org` que hoy da **404**, porque el proyecto se mudó a GitHub. El
paquete no se toca desde **junio de 2015** (versión 1.5.0); está abandonado.

> ⚠️ El langpack `libreoffice-fresh-ca` **no** trae los sinónimos, aunque la web
> de Softcatalà diga que vienen con «el LibreOffice en català»: eso vale para la
> compilación de Softcatalà, no para la de Arch. Comprobado con `pacman -Ql` y
> buscando `th_ca*` en todo el sistema.

Se instaló en su lugar el `.oxt` oficial vigente, **como usuario y sin AUR**:

| | |
|---|---|
| Origen | `github.com/Softcatala/sinonims-cat/releases/download/2.3.1/thesaurus-ca.oxt` |
| Versión | **2.3.1** (frente a la 1.5.0 del AUR) |
| Licencia | CC-BY 4.0 — Jaume Ortolà / Softcatalà |
| Instalación | `unopkg add thesaurus-ca.oxt` |
| Identificador | `catalan.thesaurus.dictionary.from.Softcatalà.by.Joan.Montané` |
| Datos | `~/.config/libreoffice/4/user/` |
| Desinstalar | `unopkg remove <identificador>` |

> ⚠️ **`unopkg add` exige un stdin interactivo.** Pide aceptar la licencia
> escribiendo «sí» y, sin terminal, muere con `reading from stdin failed`. En
> esta versión **no existe** ningún `--suppress-license`: hay que darle la
> respuesta por tubería.

**Esta extensión no la controla pacman y no sale en `packages/`.** Es el quinto
agujero de reproducibilidad de §14.

### Estado de validación

- `pacman -Q` confirma los once paquetes instalados.
- `xdg-mime query default` y `gio mime`, de acuerdo: PDF → `firefox.desktop`.
- Las seis asociaciones ofimáticas, consultadas una a una (tabla de arriba).
- `unopkg list` devuelve la extensión 2.3.1; los `.dat`/`.idx` están en disco.

**Sin comprobar**: que los tres idiomas aparezcan en *Herramientas → Idioma* de
Writer y que `Ctrl+F7` dé sinónimos sobre una palabra catalana. Exige abrir la
interfaz gráfica. Ver §15.
