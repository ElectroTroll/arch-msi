# Roadmap

Plan de trabajo del proyecto `arch-msi` tras completar la fase inicial
(auditoría, repositorio, documentación y primeras migraciones a Stow).

Cada tarea indica **esfuerzo** aproximado y **riesgo**. Se mantiene el método del
proyecto: inspeccionar → plan → cambio mínimo → diff → validar → commit.

> Estado de partida (2026-07-22): sistema auditado, repo público en GitHub,
> tres paquetes Stow (`hypr`, `shell`, `swappy`), snapshots con purga automática,
> capturas de pantalla funcionando.

---

## Fase 2 — Escritorio funcional

El objetivo es cerrar lo que falta para un uso diario cómodo. Es lo que más se
nota y lo más inmediato.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 2.1 | ~~**Waybar** — barra de estado~~ **[OK] Completada** | Medio | Bajo |
| 2.2 | ~~**Dunst** — notificaciones~~ **[OK] Completada** | Bajo | Bajo |
| 2.3 | ~~**hypridle + hyprlock** — bloqueo automático~~ **[OK] Completada** | Medio | **Medio** |
| 2.4 | ~~**hyprpaper** — fondo de pantalla~~ **[OK] Completada** | Bajo | Bajo |
| 2.5 | ~~Limpieza: variable `menu` sobrante en `hyprland.lua`~~ **[OK] Completada** | Trivial | Nulo |

**2.1 Waybar.** **[OK] Completada (2026-08-02).** Barra superior de 34 px con
nueve módulos: workspaces (los 10, distinguiendo activo / con ventanas /
vacío), reloj, uso de Claude, volumen, Bluetooth, red, batería, perfil de
energía y menú de apagado. Cuarto paquete Stow (`dotfiles/waybar/`), más un
quinto para wlogout y un sexto para el hook de Claude Code.
`waybar.service` habilitado. Ver detalle en `docs/PROJECT_CONTEXT.md` §13.

> **El módulo de uso de Claude no consulta nada, lee lo que le dejan.** Los
> porcentajes de las ventanas de 5 h y 7 días no son accesibles desde fuera:
> ni subcomando del CLI, ni archivo en `~/.claude`, ni endpoint local. Solo
> aparecen en el JSON que Claude Code entrega a su hook `statusLine`. Por eso
> el hook los vuelca a `$XDG_RUNTIME_DIR` y Waybar lee ese archivo.
> Consecuencia: **el dato solo se refresca con una sesión de Claude Code
> abierta**; sin ella envejece, y el módulo lo marca en ámbar en vez de
> mostrar una cifra caducada como si fuera actual.

**2.2 Dunst.** **[OK] Completada (2026-08-04).** `dunstrc` propio como
**séptimo** paquete Stow (`dotfiles/dunst/`), con la paleta de Waybar: fondo
`#16181d` siempre y la urgencia codificada en el **color del marco**. Arriba a
la derecha bajo la barra (420 px lógicos), 5 s / 10 s / crítica sin expirar,
historial de 20 con `Super + N` y `Super + Shift + N`, y pausa automática
mientras la sesión está bloqueada (`on_lock_cmd` en `hypridle.conf`).
Ver detalle en `docs/PROJECT_CONTEXT.md` §16 (Notificaciones).

> **Corrige el supuesto de partida: dunst SÍ estaba corriendo.** La tarea se
> planteó por si «puede que ni siquiera se lance», y la auditoría demostró lo
> contrario: llevaba desde el arranque atendiendo notificaciones reales de
> Firefox, con los valores por defecto. El problema no era la ausencia de
> notificaciones, sino su aspecto y dos defaults rotos en silencio (`dmenu`
> sin instalar e `icon_path` apuntando a un tema inexistente, con avisos ya
> presentes en el journal).
>
> **Y el autoarranque no era un hueco.** Al revés que en 2.1 y 2.3, dunst
> **no añade nada a `install/services.sh`** (ver 6.1): arranca por activación
> D-Bus mediante un archivo que instala el propio paquete, y su unidad es
> `static` — no admite `enable`. Es el primer componente cuyo autoarranque se
> restaura solo. Lo que sí conviene saber: arranca **bajo demanda**, con la
> primera notificación, así que un `pgrep dunst` vacío no significa que esté
> roto.

**2.3 hypridle + hyprlock.** **[OK] Completada (2026-07-27), ampliada
(2026-08-25).** hyprlock con desbloqueo por contraseña vía PAM e hypridle con
tres listeners (480 s atenuar el brillo, 600 s bloquear, 900 s **apagar la
pantalla** y suspender **solo con batería**), más `before_sleep_cmd`,
`after_sleep_cmd` e `inhibit_sleep = 2`; `hypridle.service` habilitado y
verificado tras reinicio, y atajo manual **`Super + L`**. Ver detalle en
`docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) → «Bloqueo de pantalla e
inactividad».

> **Ampliación del 2026-08-25 — la pantalla no se apagaba nunca.** Se detectó
> al preguntar por qué la pantalla nunca llegaba a negro, ni enchufado ni con
> batería. No era una avería: **no había ninguna regla que la apagase**. El
> apagado se había descartado en su día tras el incidente del DPMS y nunca se
> sustituyó, así que la secuencia terminaba en el bloqueo de los 600 s con la
> retroiluminación encendida. Lo cubre ahora **`wlopm`** (nuevo paquete, repo
> `extra`), cliente del protocolo `zwlr_output_power_manager_v1`, que **no**
> pasa por el dispatcher de Hyprland ni por el parser Lua que provocó aquel
> incidente. A los 900 s: pantalla apagada siempre, suspensión solo con
> batería y **después** del apagado. Detalle y trampas en §9.

> ⚠️ **Vía de rescate — CORREGIDO el 2026-08-25.** Lo que decía aquí antes era
> falso en sus tres puntos, y conviene saber por qué: se afirmaba que
> `Ctrl+Alt+F2` no funcionaba porque Hyprland capturaba la combinación, que
> `tty2` estaba ocupado por un Xorg huérfano y que la única vía era `sudo chvt 3`.
>
> La realidad: **`Ctrl+Alt+F1/F2/F3` sí funcionan**. El problema era el TECLADO
> del portátil, no el compositor — la fila superior lleva las multimedia como
> función primaria, así que `F1`–`F12` exigen `Fn` y la combinación de cuatro
> teclas no llegaba. **Con Fn Lock activado va**, y con un teclado externo
> siempre funcionó. Y `tty2` no es un huérfano: es **el greeter de SDDM**, desde
> el que se puede iniciar sesión nueva. `tty3` y `tty4` son consolas de texto.
>
> ⚠️ **Fn Lock es un requisito práctico** de esta vía desde el teclado
> integrado; el teclado externo es la alternativa fiable.
>
> Ojo con **faillock**, compartido entre hyprlock y el login por TTY (`deny = 3`,
> `unlock_time = 600`): **ha bloqueado el equipo dos veces** (2026-08-24 con
> `sudo`, 2026-08-25 con hyprlock). No hace falta esperar los 10 minutos:
> **root tiene contador propio**, así que se entra como root en una TTY y se
> ejecuta `faillock --user elok --reset`. Detalle en
> `docs/PROJECT_CONTEXT.md` §9.

**2.4 hyprpaper.** **[OK] Completada (2026-08-25).** Fondo de pantalla con
hyprpaper 0.8.4. Toca dos paquetes Stow: la config en `hypr/` (existente) y las
imágenes en **`wallpapers/`**, nuevo, que despliega `~/Wallpapers`.
Arranque desde `hyprland.lua`, no por servicio (cambiado el 2026-08-27, ver
6.1 y `docs/PROJECT_CONTEXT.md` §17). **Una imagen aleatoria de la carpeta en
cada arranque**, como los fondos por defecto de Hyprland, sin rotación en caliente
(`timeout = 0` + `order = random`). Config sin rutas frágiles: `monitor =`
vacío en vez de `eDP-1`, y `path = ~/Wallpapers` en vez de una ruta absoluta;
ambas formas verificadas, igual que el autoarranque **tras un reinicio real**
(arranque de las 19:19: `systemd Started ...`, PID dentro del cgroup del
servicio, sin errores). Detalle en `docs/PROJECT_CONTEXT.md` §17. **Con esto se
cierra el bloque de escritorio (fase 2)**, junto con la limpieza de la 2.5.

**2.5 Limpieza.** **[OK] Completada (2026-08-27).** Eliminada
`local menu = "hyprlauncher"` de `hyprland.lua`. Era un resto de la plantilla
original: `Super + R` se corrigió en su día para llamar directamente a
`rofi -show drun`, y la variable se quedó sin un solo uso. Comprobado antes de
borrarla que no se referenciaba en ninguna parte del repositorio, y que
`hyprlauncher` **ni siquiera está instalado** en el equipo. Con esto **se cierra
la fase 2**.

> ⚠️ **`~/Wallpapers` es UN enlace de directorio, no un directorio real.** Es
> lo que hace que una imagen dejada ahí aterrice en el repositorio sin copiar
> nada a mano. Si al restaurar se crea el directorio ANTES de invocar a Stow,
> Stow enlaza archivo por archivo y las imágenes nuevas dejan de versionarse —
> en silencio, con el fondo funcionando igual. Ver §17.

> ⚠️ **La sintaxis de la wiki no funciona y falla en silencio.** hyprpaper
> 0.8.x se reescribió sobre hyprtoolkit y cambió el esquema. Con el clásico
> `preload` / `wallpaper = eDP-1,...` el resultado es **idéntico al de una
> config vacía**: proceso vivo, servicio activo, cero errores y cero fondo. La
> causa, verificada: hyprlang avisa de una clave desconocida dentro de una
> categoría conocida, pero **acepta en silencio** una clave desconocida en el
> nivel superior. El esquema real es un bloque `wallpaper { ... }`. Ver §17.

> **La imagen se versiona en el repo** (533 KB, JPEG q92, 2560×1600). Es el
> primer binario del repositorio y la decisión fue deliberada: una imagen no se
> recupera con `pacman -S`, así que documentar cuál era falla justo en el
> escenario para el que existe este proyecto. Contrapartida asumida: git guarda
> cada versión entera y para siempre, así que **cambiar de fondo a menudo sale
> caro**. Razonamiento completo en §17.

---

## Fase 3 — Configuración de aplicaciones

Kitty, Rofi, yazi y Dolphin no tienen configuración propia todavía: usan los
valores por defecto. Cada una que se configure se migra a Stow con el patrón ya
validado.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 3.0 | ~~**Tema centralizado** con matugen~~ **[OK] Completada** | Alto | Medio |
| 3.1 | ~~**Kitty** — tema, fuente, opacidad~~ **[OK] Completada** | Bajo | Nulo |
| 3.2 | ~~**Rofi** — tema y comportamiento~~ **[OK] Completada** | Bajo | Nulo |
| 3.3 | ~~**yazi** — atajos, previsualizaciones~~ **[OK] Completada** | Bajo | Nulo |
| 3.4 | **Dolphin** — solo archivos versionables | Medio | Bajo |
| 3.5 | **Theming GTK/Qt coherente** con `nwg-look` | Medio | Bajo |
| 3.6 | **Spotify** — versionar `spotify-flags.conf` como paquete Stow | Trivial | Nulo |
| 3.7 | **npm** — versionar `~/.npmrc` como paquete Stow | Trivial | Nulo |
| 3.8 | ~~**fastfetch** — config propia dentro del tema~~ **[OK] Completada** | Bajo | Nulo |

**3.0 Tema centralizado.** **[OK] Completada (2026-08-27/28).** Es la tarea que
hizo falta ANTES que las demás de esta fase: cada componente definía sus colores
por su cuenta —cinco duplicados en unas 25 apariciones literales y en dos
notaciones— y de hecho convivían DOS temas, porque Hyprland y hyprlock seguían
con los cian/verde/naranja de fábrica. Configurar Kitty, Rofi y yazi encima
habría multiplicado el problema.

Ahora hay una sola fuente, `theme/tokens.toml` (más `theme/strings.toml` para los
textos), y los colores que siguen al fondo de pantalla los pone **matugen**.
Arquitectura completa, trampas incluidas, en `docs/PROJECT_CONTEXT.md` §18.

**Con esto, TODO el escritorio está dentro del tema**: Waybar, dunst, hyprlock,
Hyprland, Kitty, fastfetch y wlogout — y desde la 3.2, también Rofi.

**3.1 Kitty.** **[OK] Completada (2026-08-27).** Config propia como noveno
paquete Stow, y nace ya dentro del tema: nunca llega a tener colores cableados.
Los 16 colores ANSI sí son fijos, y por una medición: la paleta base16 de matugen
devuelve ocho azules casi negros indistinguibles entre sí, con lo que `ls` y
`git diff` serían ilegibles. Detalle en §18.

**3.2 Rofi.** **[OK] Completada (2026-08-28), ampliada el mismo día.** Décimo paquete Stow, y como
Kitty nace ya dentro del tema: nunca llega a tener colores cableados. Tres modos
en un solo bind —`drun`, `window` y `filebrowser`, ciclados con `Ctrl+Tab`—,
centrada, una columna, iconos de Papirus-Dark a 28 px. Detalle en
`docs/PROJECT_CONTEXT.md` §18.

> **Ampliación: barra de modos y el modo ventana.** Al usarlo se vio que con un
> solo bind no había NADA que anunciara los otros dos modos, así que se añadió
> una barra discreta abajo, con el activo resaltado y los botones clicables. Y
> el modo ventana tenía dos defectos, los dos de rofi y no de la config: Claude
> salía sin icono (rofi lo busca por `app_id` y la app lo instala con otro
> nombre) y como `com.anthropic.Claude` (el modo ventana no lee los `.desktop`,
> donde sí está `Name=Claude`). El icono se arregla en la raíz con un
> **undécimo paquete Stow, `icons`**, que da al tema el nombre que rofi busca;
> el nombre, retirando la clase de la vista — sin perder búsqueda, porque
> `window-match-fields` es independiente del formato. Detalle en §18.

> **No es la rofi 1.7 de los tutoriales, y eso ahorra trabajo.** La 2.0 fusionó
> río arriba el soporte Wayland del fork de lbonn, así que `rofi-wayland` ya no
> existe como paquete aparte: esto corre en layer-shell NATIVO, sin XWayland, y
> ninguno de los apaños que circulan para «rofi borroso en Hyprland» hace falta.
> Tampoco despierta la dGPU: no enlaza EGL/GL/gbm, dibuja por software sobre
> `wl_shm`.

> ⚠️ **El `-h` de rofi miente sobre el tamaño de la pantalla.** Anuncia
> `scale: 2 · size: 2560,1600 · dpi: 96,92`, y ninguno de esos números es la
> unidad del tema: rofi 2.0 solo enlaza `wl_output`, ni `xdg-output` ni escala
> fraccional, así que ve el modo físico y la escala ENTERA (Hyprland redondea
> 1.6 a 2). Lo real se midió con `hyprctl layers`: **1 px del `.rasi` = 1 px
> lógico**, y los porcentajes son sobre los 1600×1000 lógicos. Misma unidad que
> Waybar. De ahí que la fuente se declare en `px` y no en puntos — ver §18.

> **El modo `window` SÍ funciona en Wayland**, en contra de lo que sugiere su
> `window-command` por defecto (`wmctrl`, que es X11 y ni siquiera está
> instalado). rofi implementa `zwlr_foreign_toplevel_manager_v1` y Hyprland lo
> expone; ese default solo se usaría para ejecutar un comando SOBRE la ventana,
> no para saltar a ella.

**3.8 fastfetch.** **[OK] Completada (2026-08-27).** Config propia, dentro del
tema, y con el ASCII de Arch dejando de romperse al estrechar la terminal: la
causa no era el tamaño del logo sino la DISPOSICIÓN, porque a la izquierda el
ancho necesario es la suma de dibujo y texto, y arriba es el máximo de los dos.

Ya está instalada la fuente `ttf-jetbrains-mono-nerd` y el tema de iconos
`papirus-icon-theme`, así que hay base para una estética unificada.

En 3.4, cuidado: Dolphin genera muchos archivos de estado y cachés. Versionar
solo lo relevante (`dolphinrc`, atajos), nunca el directorio completo.

Rofi (3.2) y yazi (3.3) heredan la ventaja de la 3.0: se configuran con
plantilla y no llegan a tener colores propios. Rofi admite `@import` y yazi no,
así que el primero conserva su config enlazada por Stow y el segundo se generará
entero — el mismo reparto que explica §18. **Confirmado al hacer la 3.2**: rofi
usa además la variante OPCIONAL, `?import`, que si el artefacto falta le deja
arrancar con el tema de fábrica en vez de abortar.

**3.3 yazi.** **[OK] Completada (2026-08-28).** Duodécimo paquete Stow, y como
Kitty y Rofi nace ya dentro del tema. `yazi.toml` y `keymap.toml` en Stow; el
tema, generado. Detalle en `docs/PROJECT_CONTEXT.md` §19.

> **La pregunta de la tarea era «qué manda desde dónde», y la respuesta cambió
> el trabajo.** El preset de tema de yazi está escrito casi entero con NOMBRES
> ANSI (`fg = "cyan"`, `"yellow"`, `"gray"`), no con hexadecimales — y los ANSI
> de esta sesión los pone kitty desde `tokens.toml`. O sea que **yazi ya estaba
> medio dentro del tema sin configurar nada**: no estaba «sin tema», estaba
> temado por HERENCIA. Lo que no hacía era seguir al fondo de pantalla. Así que
> la plantilla declara solo el CROMO —`cwd`, bordes, pestañas, indicador de modo,
> marcos de las cajas— y **no vuelve a declarar** los colores por tipo de
> archivo, los de permisos ni los marcadores: esos ya salen bien, y
> redeclararlos habría sido el mismo color en dos sitios, justo lo que resolvió
> la 3.0. Y **el fondo no se declara en absoluto**, porque yazi no pinta
> superficie propia: dibuja sobre la de kitty, así que la opacidad le llega sola.

> **Corrige un supuesto de la 3.0: yazi SÍ tiene vía de importación.** Se anotó
> en su día que «rofi admite `@import` y yazi no». Es falso — yazi tiene
> `[flavor]`, que carga `flavors/<nombre>.yazi/flavor.toml`. Se descartó
> igualmente, pero por otro motivo: su `theme.toml` no contiene NADA de
> comportamiento (eso vive en `yazi.toml`), así que no hay qué separar y un
> flavor solo añadiría un archivo puntero. Y su `theme.toml` es además una capa
> PARCIAL sobre el preset, así que el artefacto es corto.

> **No hubo previsualizaciones que habilitar, y ningún paquete que instalar.**
> Imagen, PDF, vídeo, comprimidos y código son plugins INTERNOS del binario, y
> las herramientas que invocan (`ffmpeg`, `pdftoppm`, `magick`, `7z`) ya estaban
> instaladas. Regenerados los inventarios: solo cambia la fecha de las
> cabeceras. El protocolo gráfico de kitty funciona de forma nativa —medido:
> 405 fragmentos APC `_G` para una foto, cero sixel—, así que tampoco hacen
> falta `chafa` ni `ueberzugpp`. Tres supuestos de partida corregidos:
> **`ffmpegthumbs` no lo usa yazi** (es de KDE, para Dolphin), `unarchiver`
> tampoco, y `mediainfo` sí pero como *opener*, no como previsualizador.

> **fzf y zoxide tampoco hubo que integrarlos**: son plugins internos y el
> preset ya los ata a `z` y `Z`, igual que `fd` y `ripgrep` a `s` y `S`. Los
> atajos de fábrica se conservan enteros; `keymap.toml` solo AÑADE cuatro con
> `prepend_keymap`, y existen para corregir uno roto: el preset trae
> `g d` → `~/Downloads` y en este equipo los directorios de `~` están en
> castellano.

> **Ampliación (2026-08-28/29): ver la imagen a pantalla completa (`M`).** Al
> usarlo se pidió ver las imágenes grandes en vez de en el panel lateral. Lo
> hace `shell --block -- kitten icat --hold --clear -- %s`, o sea el visor
> propio de kitty. `M` está libre en el preset: **no se pisa ningún atajo de
> fábrica**.
>
> ⚠️ **Antes hubo un plugin que maximizaba el PANEL, y se retiró tras dos
> fallos que solo apareció usándolo.** Movía `rt.mgr.ratio` en caliente, que es
> lo que hace el propio yazi al arrastrar el separador con el ratón — pero eso
> obliga a pelearse con el repintado DIFERENCIAL de ratatui mientras el
> protocolo gráfico de kitty escribe celdas fuera de su búfer. Primero dejaba
> los paneles en blanco al volver; arreglado eso, borraba los separadores de
> columna. `shell --block` no tiene esa clase de fallo porque es la misma vía
> por la que yazi abre `$EDITOR`: suelta el terminal y se redibuja entero al
> volver (verificado, 3 de 3). Contrapartida asumida: es un visor, no un panel,
> así que no se navega con j/k mientras está abierto.
>
> ⚠️ **Y el archivo se pasa con `%s`, no con `$0`.** El `shell` de yazi no pasa
> parámetros posicionales —`$#` vale 0 y `$0` es `sh`—: sustituye `%s` dentro
> del texto del comando, ya entrecomillado. Con `$0`, icat recibía literalmente
> `sh` y respondía «Stat sh: no such file or directory».
>
> Detalle, tabla de medidas y la trampa de medición que lo provocó, en §19.
>
> ⚠️ **Y obligó a subir la cota de la caché de imágenes, que hasta entonces era
> cosmética.** Maximizada, la previsualización pide el ancho entero y la cota
> RECORTA sin avisar: medido con la caché limpia, cota 1200 → maximizado 1200,
> cota 2000 → 1200 (la demanda real). Pasa a **2560x1600**, el tamaño del panel,
> que por definición no recorta.

> ⚠️ **La tarea toca un segundo paquete Stow, `shell`, y arregla un fallo que
> nadie había visto.** El opener de texto de yazi es `${EDITOR:-vi}`, `EDITOR`
> estaba sin definir y **`/usr/bin/vi` no existe en este equipo** (solo `vim`),
> así que abrir un archivo de texto desde yazi fallaba. Se arregla con
> `export EDITOR=vim` en `.bashrc`, que de paso sirve a git y a `systemctl edit`.
> Ahí va también la función `y`, que deja la shell en el directorio donde
> estabas: tiene que vivir en el shell porque un proceso hijo no puede cambiar
> el directorio de su padre.

> ⚠️ **Dos trampas silenciosas, las dos verificadas.** `stow yazi` a secas
> enlaza el DIRECTORIO entero y el `theme.toml` de matugen habría acabado dentro
> del repositorio: hay que usar `--no-folding`, como ya hubo que hacer con
> wlogout y fastfetch. Y **yazi no aplica el tema de usuario hasta terminar el
> handshake con el terminal** (`CSI ?996n`, `OSC 11`, `XTVERSION`, `DA1`…), de
> modo que bajo `script` el `theme.toml` no se lee en absoluto — se puede dejar
> con TOML roto y no protesta ni con `YAZI_LOG=debug`. La verificación buena es
> abrirlo en kitty y mirarlo. Detalle en §19.

**3.6 Spotify.** Instalado desde AUR (`paru -S spotify`) el 2026-08-02. El
2026-08-03 se creó a mano `~/.config/spotify-flags.conf` para forzar Wayland
nativo: en XWayland la app se veía borrosa por la escala 1.60 del panel (detalle
en `docs/PROJECT_CONTEXT.md` §7). Ese archivo **no está versionado**, así que
una restauración deja el problema otra vez sin avisar. Es el mismo tipo de
agujero silencioso que la 6.1, pero aquí basta con un **octavo** paquete Stow
(`dotfiles/spotify/`), no con `install/services.sh`. Corregir el síntoma ya está
hecho; falta solo meterlo en el repo.
(Era el «séptimo» hasta que la tarea 2.2 ocupó ese número con `dotfiles/dunst/`.)

**3.7 npm.** Detectada el 2026-08-27 auditando la 2.5. `~/.npmrc` contiene
`prefix=/home/elok/.local`, que es lo que permite `npm -g` **sin sudo** y lo que
sitúa a Codex CLI en `~/.local/lib/node_modules` (`PROJECT_CONTEXT.md` §10). No
está versionado: es el mismo agujero silencioso que la 3.6 —el archivo no vuelve
tras una restauración y nada lo avisa— y se cierra igual, con un paquete Stow
(`dotfiles/npm/`). Añadida a la lista de §14.

---

## Fase 4 — Hardware específico del convertible

Es lo más distintivo de este equipo y lo que ningún dotfiles genérico cubre.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 4.1 | **Pantalla táctil** en Hyprland | Medio | Bajo |
| 4.2 | **Rotación automática** en modo tableta | Alto | Medio |
| 4.3 | **Stylus** — presión, botones, mapeo | Medio | Bajo |
| 4.4 | **Gestos del touchpad** (3–4 dedos) | Bajo | Bajo |
| 4.5 | Revisar **S0ix** (aparecía `Disabled`) | Medio | Bajo |
| 4.6 | **Dynamic Boost** / `nvidia-powerd` | Bajo | Bajo |

**4.2** requiere leer el acelerómetro (`iio-sensor-proxy`) y rotar pantalla y
entrada táctil de forma coordinada. Es la tarea más compleja de esta fase.

**4.5** conviene mirarlo junto con el comportamiento de suspensión general:
verificar que suspender/reanudar funciona bien con la dGPU y RTD3.

---

## Fase 5 — Seguridad y resiliencia

Huecos reales detectados durante la auditoría. **Prioridad alta pese a no ser
vistosos.**

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 5.1 | ~~**Cortafuegos** — no hay ninguno instalado~~ **[OK] Completada** | Bajo | Bajo |
| 5.2 | **Copias de seguridad reales** fuera del disco | Alto | Bajo |
| 5.3 | **Probar arranque desde snapshot** en GRUB | Bajo | **Medio** |
| 5.4 | ~~Bloqueo de sesión (ver 2.3)~~ **[OK] Completada** | — | — |

**5.1** **[OK] Completada (2026-07-23).** Instalado y habilitado `firewalld`,
zona `public` con denegación entrante por defecto, servicio `ssh` retirado.
Ver detalle en `docs/PROJECT_CONTEXT.md` §9 (Red y seguridad).

**5.2** ⚠️ **Importante**: los snapshots de Btrfs **no son copias de
seguridad**. Viven en el mismo disco: si falla el NVMe o se corrompe el sistema
de archivos, se pierden con todo lo demás. Falta una estrategia real
(`borg`, `restic`, `btrfs send/receive` a disco externo) al menos para `@home`.

**5.3** Nunca se ha probado arrancar desde un snapshot en el menú de GRUB.
Descubrir que no funciona el día que haga falta sería el peor momento. Probarlo
en frío, con el snapshot #2 protegido como red.

**5.4** **[OK] Completada (2026-07-27)** junto con **2.3**: la sesión se bloquea
sola por inactividad, antes de suspender y a demanda con `Super + L`. Ver 2.3 y
`docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) → «Bloqueo de pantalla e
inactividad».

---

## Fase 6 — Reproducibilidad completa

Cerrar el objetivo original: poder reinstalar y recuperar el sistema.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 6.1 | `install/packages.sh`, `aur.sh`, `services.sh` — **incluye `services.sh` como requisito bloqueante** | Medio | Bajo |
| 6.2 | `install/ai-tools.sh` (Codex, Claude Code) | Bajo | Bajo |
| 6.3 | `docs/installation.md` — procedimiento completo | Medio | Nulo |
| 6.4 | `scripts/update.sh`, `backup.sh` | Medio | Bajo |
| 6.5 | **Prueba real de restauración en una VM** | Alto | Nulo |

**6.1** ⚠️ **Requisito bloqueante, no una nota menor: `install/services.sh`
tiene que reactivar TRES cosas que no viven en los dotfiles.** El `enable` de un
servicio de usuario crea un enlace en
`~/.config/systemd/user/graphical-session.target.wants/`, que **no** está
versionado; de él solo queda rastro en `packages/services-enabled.txt`. Los
tres huecos son del mismo tipo y fallan **en silencio**: los archivos vuelven
a su sitio, pero nada los activa y nada avisa de que falta el paso.

- **`hypridle.service`** — sin rehabilitarlo, la sesión no se bloquea sola
  nunca. Los archivos estarían todos en su sitio, `hyprlock` y `Super + L`
  seguirían funcionando a mano, y el equipo simplemente no se bloquearía solo
  — el mismo hueco de seguridad que cerró la tarea 2.3, reabierto en silencio.
  **Desde la tarea 2.2 este servicio gobierna también la PRIVACIDAD de las
  notificaciones**: su `on_lock_cmd` es quien pausa dunst al bloquear. Sin el
  servicio no hay pausa, y las notificaciones podrían mostrarse sobre
  hyprlock — con remitente y asunto legibles. Un mismo `enable` olvidado
  reabre ahora **dos** agujeros, no uno.
  > **Dunst NO añade un requisito propio a esta lista.** Su
  > autoarranque no depende de nada fuera de los dotfiles: lo activa D-Bus
  > mediante `/usr/share/dbus-1/services/org.knopwob.dunst.service`, que
  > instala el propio paquete, y `dunst.service` es `static` (no admite
  > `enable`). Es el único componente del proyecto que se restaura solo. Ver
  > `docs/PROJECT_CONTEXT.md` §16 (Notificaciones).
- **`waybar.service`** — sin rehabilitarlo no hay barra: `config.jsonc`,
  `style.css` y `claude-usage.sh` quedan enlazados por Stow, pero nadie lanza
  Waybar (tarea 2.1). No hay `exec-once` en `hyprland.lua` que sirva de
  respaldo: el servicio es la única vía de arranque.
  > **hyprpaper YA NO añade un requisito a esta lista** (cambio del
  > 2026-08-27; hasta esa fecha era el cuarto). `hyprpaper.service` está
  > **deshabilitado**: lo lanza `hyprland.lua` con
  > `hl.on("hyprland.start", ...)`, y ese archivo **sí** se versiona y viaja
  > con los dotfiles, así que el fondo se restaura solo. El cambio no se hizo
  > por la restauración —eso fue un efecto colateral bienvenido— sino por
  > latencia de arranque: pasando por systemd, el fondo tardaba medio segundo
  > de más en aparecer. Ver `docs/PROJECT_CONTEXT.md` §17.
- **`~/.claude/settings.json` → `statusLine.command`** — el script está
  versionado en `dotfiles/claude/` y se enlaza con Stow, pero quien lo invoca
  es este archivo, que **no** se versiona porque contiene credenciales y estado
  de sesión. Sin él, el módulo de uso de Claude se queda en `—` para siempre.

La fase 6 **no puede darse por completada** sin los tres, y la prueba de
restauración en VM (6.5) debe verificarlos explícitamente.
Ver `docs/PROJECT_CONTEXT.md` §9 (Red y seguridad), §13 (Dotfiles y estado del
repositorio) y §14 (Tareas pendientes).

**6.3** debe recoger los detalles no obvios: VMD activo en BIOS, ESP compartida
con Windows, layout de subvolúmenes, orden de instalación.

**6.5** es la única forma de saber si el proyecto cumple su propósito. Ya están
instalados `edk2-ovmf` y `virtiofsd`, así que hay base para virtualizar. Sin
esta prueba, la reproducibilidad es una hipótesis.

---

## Fase 7 — Objetivos originales pendientes

Del README inicial del repositorio, aún sin abordar.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 7.1 | **Entorno de desarrollo** | Alto | Bajo |
| 7.2 | **Automatización con IA** | Alto | Bajo |

Ambos requieren definir primero qué significan en concreto: lenguajes y
herramientas para 7.1; qué se quiere automatizar y con qué límites para 7.2.

---

## Orden recomendado

(Ya completadas: **5.1** cortafuegos, **2.3 / 5.4** bloqueo de sesión,
**2.1** Waybar y **2.2** Dunst.)

1. ~~**2.4** — fondo de pantalla~~ **[OK] hecha el 2026-08-25**; el escritorio
   queda completo, y la **2.5** cierra la fase (2026-08-27).
2. **5.3 (probar snapshots)** — validar la red de seguridad antes de seguir
   cambiando cosas.
3. **Fase 3** — pulido estético, sin riesgo, buen trabajo de relleno.
4. **5.2 (backups)** — antes de acumular datos importantes.
5. **Fase 4** — cuando apetezca algo técnico y específico.
6. **Fase 6** — cuando el sistema esté estable y merezca congelarse.

## Mantenimiento continuo

- Actualizar `packages/*.txt` periódicamente (`pacman -Qqe`, `pacman -Qqm`).
- Actualizar `docs/keybindings.md` al tocar binds.
- Revisar que la documentación siga coincidiendo con el sistema real.
- Registrar decisiones relevantes en `docs/history/`.
