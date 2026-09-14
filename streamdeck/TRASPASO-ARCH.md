# Prompt de traspaso — StreamDeck DIY, de Windows a Arch Linux

> Pega todo lo que hay debajo de la línea como primer mensaje de la nueva sesión
> de Claude Code en el portátil, con la carpeta `StreamDeckDIY` ya copiada.

---

## Contexto

Tengo un **StreamDeck casero** construido por mí, que ya funciona **perfectamente
en mi PC de sobremesa con Windows**. Quiero ponerlo a funcionar en este portátil
(Arch Linux + Hyprland). El proyecto está en la carpeta `StreamDeckDIY` que te
adjunto; léela entera antes de hacer nada, sobre todo el `README.md`, que
documenta todo el proceso y las trampas que fueron apareciendo.

**Todo el código y los comentarios en español**, incluidos nombres de variables
y funciones. Y prioriza fiabilidad y facilidad de mantenimiento sobre funciones
avanzadas: prefiero algo sencillo y robusto a algo completo pero frágil.

## Hardware (confirmado, no lo cambies)

- **SparkFun Pro Micro 5V / 16 MHz** (ATmega32U4, USB HID nativo).
- Matriz de **4 filas × 3 columnas** = 12 switches mecánicos Holy Panda, con un
  diodo 1N4148 por switch.
- **5 potenciómetros deslizantes lineales de 10K.**
- Carcasa impresa en 3D (los STL están en `E:\archivos\Fusion 360\StreamDeck`
  del otro PC, no hacen falta aquí).

### Pinout real, ya verificado sobre el hardware

```cpp
const uint8_t PINES_FILA[]    = { 8, 7, 6, 5 };        // filas 0..3
const uint8_t PINES_COLUMNA[] = { 4, 3, 2 };           // columnas 0..2
const uint8_t PINES_SLIDER[]  = { A0, A1, A2, A3, A10 };
const bool DIODOS_HACIA_LA_COLUMNA = true;
```

Tres cosas importantes que costaron encontrar y que **no hay que volver a
descubrir**:

1. **Los diodos van al revés del montaje habitual**: la banda (cátodo) mira
   hacia la *columna*, así que el escaneo pone a LOW las **columnas** y lee las
   **filas**. Eso es lo que hace la constante `DIODOS_HACIA_LA_COLUMNA`. Si se
   pone a `false` no responde ninguna tecla.
2. **El slider 4 está en A10, que es el pin 10.** Ese pin no puede usarse
   también para la matriz.
3. **En el IDE hay que seleccionar `Arduino Leonardo`**, no *SparkFun Pro Micro*
   con procesador de 8 MHz. Si se compila para 8 MHz, el PLL del USB queda mal
   configurado y la placa **deja de enumerar por USB** (aparece como dispositivo
   desconocido). Lo traicionero es que la subida sí funciona, porque avrdude
   habla con el bootloader, que tiene su propio reloj correcto.

## Arquitectura

- **Botones → USB HID puro** (librería `HID-Project` de NicoHood). No necesita
  software en el PC, así que en Arch debería funcionar sin tocar nada. Manda
  F13–F21 para OBS y las teclas custom, más teclas multimedia estándar.
- **Sliders → puerto serie.** El Pro Micro manda `"v0|v1|v2|v3|v4\n"` (valores
  0..1023) y un script de Python propio ajusta el volumen **por aplicación**.
  Nada de Deej ni de ninguna app de terceros: está escrito desde cero.

El script `host/streamdeck_mixer.py` detecta el sistema operativo y tiene dos
backends. El de Windows (pycaw/Core Audio) está probado y funcionando. **El de
Linux usa `pactl` y NO se ha probado nunca**: ésa es la parte que hay que sacar
adelante.

Reparto de sliders: 0 maestro, 1 navegador, 2 Spotify, 3 juegos (`"resto"`),
4 Discord.

## Lo que quiero que hagas

1. **Poner en marcha el mezclador en Arch.** Instalar dependencias
   (`pyserial`; `pactl` viene en el paquete `libpulse`), añadir mi usuario al
   grupo `uucp` para poder abrir `/dev/ttyACM*`, y comprobar que el script lee
   el puerto y mueve el volumen.
2. **Arreglar el backend de Linux si hace falta.** Es el código menos probado
   del proyecto. Lo más frágil es `_leer_sink_inputs()`, que parsea la salida de
   texto de `pactl list sink-inputs` buscando `application.name`,
   `application.process.binary`, `media.name` y `node.name`. Con PipeWire los
   nombres de esas propiedades pueden no coincidir. Verifícalo de verdad, no lo
   supongas.
3. **Adaptar `SLIDER_MAP` a los nombres de proceso de Arch.** En Windows son
   `chrome`, `spotify`, `discord` y `javaw` (Minecraft). Aquí serán otros
   (probablemente `vesktop` en vez de `discord`, y otro navegador). Con las apps
   **sonando**, `python streamdeck_mixer.py --listar` los muestra.
4. **Dejarlo arrancando solo al iniciar sesión.** Hay un servicio de usuario de
   systemd preparado en `host/streamdeck-mixer.service`, que espera el proyecto
   en `~/StreamDeckDIY`. Ajusta la ruta si lo pongo en otro sitio. Alternativa
   más simple: `exec-once` en `~/.config/hypr/hyprland.conf`, pero el servicio
   de systemd es mejor porque reinicia solo si el script se cae.
5. **Revisar la curva de volumen, midiéndola.** Ver el apartado siguiente.

## La curva de volumen: mídela, no la supongas

Esto fue la lección más importante del proyecto, así que no la repitas por las
malas. En Windows resultó que:

- El **volumen maestro** (`SetMasterVolumeLevelScalar`) no es amplitud lineal:
  Windows aplica por dentro `amplitud = escalar ** 1.75`. Lo medí comparando
  contra `GetMasterVolumeLevel()`, que devuelve dB reales.
- El **volumen por aplicación** (`ISimpleAudioVolume`) es amplitud **cruda**,
  sin esa curva. Por eso el slider maestro se sentía lineal y los otros cuatro
  no: casi todo el cambio audible ocurría en el tercio de abajo.
- La solución fue aplicar ese mismo 1.75 a las sesiones, en la constante
  `CURVA_SESIONES_WINDOWS`. Quedó a menos de 0,25 dB del maestro en todo el
  recorrido.

**En Linux la situación es distinta y hay que medirla.** Mi hipótesis, sin
verificar: PulseAudio/PipeWire usan una escala **cúbica** para el volumen
software, o sea `pactl ... 50%` daría amplitud 0,125 (≈ −18 dB). Si eso es así,
para conseguir la misma sensación que en Windows habría que mandar
`pct = posicion ** 0.58` aproximadamente. Pero **compruébalo antes de aplicarlo**,
y comprueba también si los *sinks* (salida) y los *sink-inputs* (aplicaciones) se
comportan igual entre sí, porque en Windows no lo hacían.

Cómo medirlo: `pactl list sinks` y `pactl list sink-inputs` muestran el volumen
en dB además de en porcentaje. Pon varios porcentajes conocidos, lee los dB
resultantes, y ajusta el exponente sobre esos datos.

Si hace falta una corrección, añade una constante `CURVA_SESIONES_LINUX` en
paralelo a la de Windows, con el mismo estilo de comentario explicando de dónde
sale el número.

## Cosas que NO hay que tocar

- El firmware (`firmware/StreamDeckDIY/StreamDeckDIY.ino`) funciona y está
  verificado. Los pines, el sentido de los diodos y el filtro de los sliders son
  correctos. Solo tendría sentido volver a subirlo si lo reprogramo, y entonces
  hay que usar **Arduino Leonardo** en el IDE.
- `CURVA_SESIONES_WINDOWS` y todo el `BackendWindows`: no aplican aquí y el otro
  PC los sigue usando. El script tiene que seguir funcionando en los dos sitios.

## Estado y pendientes

- **Funciona del todo en el sobremesa** (Windows): 12 teclas, 5 sliders,
  mezclador por aplicación y arranque automático.
- **Pendiente aquí**: todo lo de Arch.
- **Pendiente en general**: las 5 teclas custom (F17–F21) siguen sin asignar.
  En Hyprland se asignan con `bind = , F17, exec, <lo que sea>`. Si se te
  ocurren usos razonables, propónmelos, pero no los des por buenos sin
  preguntarme.
- Aviso sobre OBS en Wayland: los atajos globales solo llegan si OBS corre bajo
  XWayland (`env -u WAYLAND_DISPLAY obs`). Está anotado en el README.

Empieza leyendo el `README.md` de la carpeta y dime qué plan propones antes de
cambiar nada.
