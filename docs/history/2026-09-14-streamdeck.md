# 2026-09-14 · StreamDeck DIY: el proyecto entra en el repositorio por un symlink

> **Alcance de esta nota.** El traspaso del StreamDeck de Windows a Arch lo hizo
> otra sesión, entre las 17:41 y las 18:39. Lo que se cuenta aquí de ese trabajo
> viene de `streamdeck/README.md` y `streamdeck/TRASPASO-ARCH.md`, que son su
> registro; **está marcado como tal**. Lo que se comprobó de primera mano al
> incorporarlo al repositorio, a las 22:5x, va en la sección 3.

---

## 1. Qué es, y por qué no se parece a nada de lo que había

Hardware propio: un **SparkFun Pro Micro 5V** (ATmega32U4) con 12 switches
mecánicos en matriz de 4×3, 5 potenciómetros deslizantes y carcasa impresa en
3D. Construido por el usuario, en marcha desde hace tiempo en el sobremesa con
Windows.

Todo lo que había en el repositorio hasta hoy era **configuración de programas
ajenos** —ficheros de Hyprland, de Waybar, de dunst—, con la única excepción de
los tres plugins propios de Obsidian (§26), que son cuatro archivos. `streamdeck/`
es otra cosa: **un proyecto entero y autónomo**, con firmware Arduino, un
mezclador de audio en Python de 786 líneas y 35 KB de documentación escrita
antes de que este repositorio existiera.

Por eso **no es un paquete Stow**: no hay nada que enlazar bajo `~/.config`.

Funciona por dos vías que no se tocan entre sí, y esa separación explica por qué
el traspaso a Linux fue tan asimétrico:

- **Las teclas van por USB HID puro.** El kernel ve un
  `Arduino LLC Arduino Leonardo Keyboard` y manda F13–F21. **No hay nada que
  instalar**: esa mitad funcionó en Arch sin tocar una línea.
- **Los sliders van por puerto serie.** La placa escribe
  `v0|v1|v2|v3|v4\n` y un script propio traduce eso a volumen por aplicación.
  Toda la dificultad estaba aquí, porque el backend de Linux del script **nunca
  se había ejecutado**: estaba escrito a ciegas desde Windows.

## 2. Lo que resolvió la sesión del traspaso *(fuente: README del proyecto)*

Tres cosas, y las tres están documentadas allí con sus comprobaciones:

**Los nombres de PipeWire no son el ejecutable.** El script busca cada
aplicación por `application.process.binary`, `application.name` y `node.name`,
en ese orden, porque cada programa publica lo que quiere. Spotify es el caso que
obliga a mirar más de uno: **no publica el binario**, solo `application.name` y
`node.name`. `media.name` se dejó fuera a propósito —es el título de la canción
o de la pestaña, cambia cada minuto— y si se usara, el slider de «resto»
acabaría persiguiendo nombres inventados.

**La curva de volumen se midió.** El encargo de traspaso ya avisaba de no
suponerla, y traía una hipótesis: que PipeWire usa escala cúbica y que haría
falta un exponente de ~0,58. La solución que se implementó es mejor que la
hipótesis: en vez de un exponente a ojo, el fader se hace **lineal en dB**, que
es como se comporta una mesa de mezclas de verdad.

```
dB       = (posicion - 1) * RANGO_DB_LINUX     # 50 dB de recorrido
amplitud = 10 ** (dB / 20)
pactl    = amplitud ** (1/3)                   # deshace la cúbica de PipeWire
```

Medido sobre el hardware: **−5,00 dB por cada 10 % de recorrido**, igual en todo
el fader. La constante de Windows (`CURVA_SESIONES_WINDOWS = 1.75`, medida en su
día contra `GetMasterVolumeLevel()`) se conserva intacta: el mismo archivo corre
en los dos equipos.

**El arranque automático es un servicio de usuario**, no un `exec-once` de
Hyprland, para que systemd lo relevante si se cae (`Restart=always`,
`RestartSec=5`).

## 3. Lo que se comprobó hoy al meterlo en el repositorio

Nada de lo de arriba se dio por bueno sin mirar el estado real:

| Comprobación | Resultado |
|---|---|
| `python-pyserial` | instalado, 3.5-8, a las **17:59** según `pacman.log` |
| `libpulse` (trae `pactl`) | instalado, 17.0 |
| Grupo `uucp` | `id` devuelve `984(uucp)`; `/dev/ttyACM0` es `crw-rw---- root uucp` |
| Servicio | `enabled` + `active`, arrancado a las 22:00 |
| Log del servicio | `Conectado a /dev/ttyACM0 a 115200 baudios`, backend Linux, los 5 sliders mapeados |
| `.service` del repo vs. el instalado | **idénticos byte a byte** (`diff` limpio) |
| Secretos | ninguno: `grep` de password/token/api_key/secret sobre `.py`, `.md`, `.ino` y `.service` no devuelve nada |
| `__pycache__` | ya cubierto por `.gitignore` (línea 54); los tres `.pyc` se quedan fuera |

### La trampa que quedaba: el servicio no apunta al repositorio

El `ExecStart` es `%h/StreamDeckDIY/host/streamdeck_mixer.py`, y el proceso vivo
(PID 2994) corre desde `/home/elok/StreamDeckDIY/...`. Parecía que el código
estaba fuera del repositorio y que la carpeta versionada era una copia. No lo
es:

```
~/StreamDeckDIY -> Projects/arch-msi/streamdeck
```

Es un **symlink al propio repositorio**, creado a las 18:39. O sea que el
servicio ya está ejecutando el código versionado, y no hay dos copias que
mantener.

**Pero ese enlace no lo crea nada.** No es Stow, no es el instalador de
`system/`, no está en ningún script. Al restaurar en un equipo limpio hay que
crearlo a mano o el mezclador no arranca. Queda escrito en §30 junto al resto de
requisitos manuales, que es donde alguien lo va a buscar el día que haga falta.

## 4. Qué queda pendiente

- **Discord**: el nombre que publica en Arch sigue **sin confirmar**, porque no
  estaba sonando durante las pruebas. El `SLIDER_MAP` lleva de momento cuatro
  candidatos (`discord`, `vesktop`, `webcord`, `armcord`); `--listar` con la app
  sonando dirá cuál es.
- **OBS**: no está instalado en el portátil, así que las teclas F13–F16 no se
  han probado aquí. Aviso heredado del README: bajo Wayland los atajos globales
  solo llegan a OBS si corre en XWayland (`env -u WAYLAND_DISPLAY obs`).
- **F17–F21 siguen sin asignar.** Y aquí hay un detalle que el README no puede
  saber: propone `bind = , F17, exec, …`, que es la sintaxis clásica de
  Hyprland. En este equipo **no vale**, porque la configuración es Lua (§9): hay
  que escribirlas como `hl.bind(...)` en `hyprland.lua`.
