# StreamDeck DIY — Pro Micro + 12 teclas + 5 sliders

Firmware y software reescritos desde cero. Nada de MIDI, nada de Deej.

- **Botones (matriz 4×3)** → el Pro Micro se presenta como un **teclado USB HID**
  estándar. Funciona en Windows y en Arch/Hyprland sin instalar nada.
- **Sliders (5×)** → el Pro Micro los manda por **puerto serie**, y un script de
  Python propio ajusta el volumen **por aplicación** hablando directamente con
  Core Audio (Windows) o PipeWire/PulseAudio (Linux).

```
StreamDeckDIY/
├── firmware/
│   ├── StreamDeckDIY/StreamDeckDIY.ino     ← firmware real (HID + sliders)
│   └── TestStreamDeck/TestStreamDeck.ino   ← sketch de diagnostico (no manda teclas)
├── host/
│   ├── streamdeck_mixer.py                 ← mezclador por app (Win + Linux)
│   ├── test_streamdeck.py                  ← visor en vivo para el diagnostico
│   ├── requirements.txt
│   ├── iniciar_mixer_oculto.vbs            ← autoarranque Windows
│   └── streamdeck-mixer.service            ← autoarranque Arch (systemd user)
└── README.md
```

**Orden recomendado:** sección 2 (subir) → sección 3 (comprobar con el sketch de
diagnóstico) → subir el firmware real → sección 4 (mezclador) → sección 5 (OBS).

> **Dónde vive esto en Arch.** El proyecto está versionado dentro del repositorio
> `arch-msi`, en `streamdeck/`, y `~/StreamDeckDIY` es un **enlace simbólico** a
> esa carpeta. Así el repositorio es la fuente de verdad y, a la vez, todas las
> rutas documentadas (incluida la del servicio de systemd, que usa
> `%h/StreamDeckDIY/…`) siguen valiendo sin cambios. Si reinstalas, basta con
> rehacer el enlace:
>
> ```bash
> ln -s Projects/arch-msi/streamdeck ~/StreamDeckDIY
> ```

---

## Estado

**ElectroPC (Windows):** funcionando del todo — 12 teclas, 5 sliders, mezclador
por aplicación y arranque automático.

**Portátil MSI (Arch + Hyprland):** funcionando. Validado el 2026-09-14 sobre el
hardware real:

| Comprobación | Resultado |
|---|---|
| Teclas (HID) | La placa enumera como `Arduino LLC Arduino Leonardo Keyboard`. No hace falta instalar nada. |
| Puerto serie | `/dev/ttyACM0`, trama `1023\|1023\|1023\|1023\|1023` correcta |
| Recorrido de los 5 sliders | Los cinco llegan de **0,0 % a 100,0 %** |
| Slider 0 → maestro | ✅ aplicado sobre `@DEFAULT_SINK@` |
| Slider 1 → Firefox | ✅ detectado como `firefox` |
| Slider 2 → Spotify | ✅ detectado como `spotify` |
| Slider 3 → «resto» | ✅ correcto que no encuentre nada: Firefox y Spotify tienen slider propio |
| Curva de volumen | Fader **lineal en dB** (`RANGO_DB_LINUX`): −5,00 dB por cada 10 % de recorrido, medido |

**Pendiente en Arch:**

- **Discord**: no se ha podido confirmar el nombre que publica porque no estaba
  sonando durante las pruebas. Compruébalo con `--listar` la primera vez.
- **OBS**: no está instalado en el portátil, así que la sección 5 está sin
  probar aquí.
- **F17–F21**: las 5 teclas custom siguen sin asignar.

---

## 1. Cableado y pines

> Los pines del sketch son una **propuesta**. Si tu cableado real no coincide,
> cambia solo las dos líneas `PINES_FILA` / `PINES_COLUMNA` y `PINES_SLIDER` al
> principio del `.ino`. No hay que tocar nada más.

### Matriz de botones (4 filas × 3 columnas)

**Confirmado con el hardware real:**

| | COL0 → pin 4 | COL1 → pin 3 | COL2 → pin 2 |
|---|---|---|---|
| **FILA0 → pin 8** | `[0]` Mute micro *(F13, OBS)* | `[1]` Mute altavoces *(multimedia)* | `[2]` Cámara on/off *(F14, OBS)* |
| **FILA1 → pin 7** | `[3]` Fn custom 1 *(F17)* | `[4]` Grabar OBS *(F15)* | `[5]` Fn custom 2 *(F18)* |
| **FILA2 → pin 6** | `[6]` Fn custom 3 *(F19)* | `[7]` Fn custom 4 *(F20)* | `[8]` Fn custom 5 *(F21)* |
| **FILA3 → pin 5** | `[9]` Canción anterior | `[10]` Pausa / Reanudar | `[11]` Canción siguiente |

Fíjate en que la matriz ocupa los pines 2–8 y los sliders A0–A3 más A10 (pin 10):
no se solapan, que era justo el problema que había antes.

Las **5 teclas «Fn custom»** mandan F17–F21 y no hacen nada por sí solas: son
teclas libres para que les asignes lo que quieras en OBS, en Windows
(acceso directo / AutoHotkey) o en Hyprland (`bind = , F17, exec, …`).

**Mute altavoces** es el mute de volumen del sistema (tecla multimedia estándar,
funciona sin configurar nada). **Mute micro** y **cámara** son hotkeys de OBS,
porque «silenciar mi micro en el directo» y «apagar la webcam» son acciones de
OBS, no del sistema operativo.

### Sliders (5 potenciómetros de 10 K)

**Confirmado con el hardware real:**

| Slider | Pin analógico | Pin físico Pro Micro | Controla |
|---|---|---|---|
| 0 | `A0` | 18 | Volumen maestro |
| 1 | `A1` | 19 | Navegador |
| 2 | `A2` | 20 | Spotify |
| 3 | `A3` | 21 | Juegos |
| 4 | `A10` | **10** | Discord |

> El slider 4 está en el **pin 10, que es A10**. Ese pin **no puede usarse
> además para la matriz**: si se usa como columna, al bajar el slider arrastra
> la línea a nivel bajo y el escaneo cree que están pulsadas todas las teclas de
> esa columna.

Cada potenciómetro: **extremo 1 → GND**, **extremo 2 → VCC**, **cursor (centro) → pin analógico**.

### Sentido de los diodos (importante)

En este StreamDeck los diodos van **al revés del montaje más habitual**:

```
pin FILA ──── [switch] ────(ánodo)▶|(cátodo, banda)──── pin COLUMNA
```

La **banda del diodo mira hacia la columna**, así que la corriente circula de
fila → columna. Por eso el firmware pone a `LOW` **las columnas** y lee **las
filas** con pull-up interno. Al escanear, la corriente siempre va de la línea
leída hacia la línea puesta a `LOW`, y el diodo tiene que dejar pasar en ese
sentido.

Esto **no hay que resoldarlo**: se configura con una sola línea en el sketch.

```cpp
const bool DIODOS_HACIA_LA_COLUMNA = true;   // banda hacia la columna
                                             // false = montaje habitual
```

Si te equivocas de valor no se rompe nada: simplemente **no responde ninguna
tecla**, porque los diodos bloquean el sentido del escaneo. Es el primer sitio
donde mirar si de repente la matriz entera deja de funcionar.

**Cómo comprobarlo sin desoldar:**

1. Con el multímetro en modo diodo y la tecla pulsada: punta **roja en el pin de
   la fila** y **negra en el pin de la columna** debe marcar ~0,6 V. Al revés,
   circuito abierto. (Si te sale justo lo contrario, pon la constante a `false`.)
2. Prueba práctica: pulsa a la vez tres teclas que formen una «L» — `[0]`, `[1]`
   y `[3]` (las dos primeras de la fila 0 más la primera de la fila 1). Si se
   activa también una cuarta tecla fantasma (`[4]`, la de grabar OBS), falta
   algún diodo o hay uno puesto al revés **respecto a los demás**.
3. `DescubrirPines.ino` también te lo dice: llama «fila» al grupo de pines que
   él pone a nivel bajo. Si el grupo que llama «fila» tiene 3 pines en vez de 4,
   los diodos van hacia la columna.

---

## 2. Firmware (Arduino IDE)

### Librería a instalar
**Herramientas → Gestionar bibliotecas… → busca `HID-Project`** (de NicoHood) → Instalar.

Es la única. Aporta `Keyboard` (teclas normales y F13–F24) y `Consumer` (teclas
multimedia reales). No instales ni uses `MidiUSB`: ya no hace falta.

### Placa

**Usa `Herramientas → Placa → Arduino AVR Boards → Arduino Leonardo`.**

Es el mismo chip (ATmega32U4 a 16 MHz), no tiene submenú de *Processor* donde
equivocarse, y está **comprobado que funciona con esta placa** (verificado el
2026-08-30: el Pro Micro de este proyecto es de **16 MHz**).

> ### ⚠️ La trampa de los 8 MHz
>
> Si eliges *SparkFun Pro Micro* y en **Processor** dejas
> *ATmega32U4 (3.3V, 8 MHz)*, el sketch se compila con `F_CPU = 8000000` pero el
> cristal de la placa va a 16 MHz. El PLL del USB queda mal configurado y el
> chip **deja de enumerar**: Windows lo muestra como «Dispositivo USB
> desconocido» y desaparece el puerto COM.
>
> Lo traicionero es que **la subida sí funciona**, porque avrdude habla con el
> bootloader, que tiene su propia configuración de reloj correcta. Todo parece
> ir bien hasta que arranca tu sketch.
>
> Si te pasa: doble reset, y vuelve a subir con *Arduino Leonardo* seleccionado.
> La placa siempre se recupera, el bootloader es intocable.

Si prefieres usar el paquete de SparkFun, añade esta URL en
*Preferencias → Gestor de URLs adicionales* y elige **Processor →
ATmega32U4 (5V, 16 MHz)**, nunca el de 8 MHz:
```
https://raw.githubusercontent.com/sparkfun/Arduino_Boards/main/IDE_Board_Manager/package_sparkfun_index.json
```

Con *Leonardo*, la placa se identifica con el VID/PID de Arduino
(`2341:8036`) en vez del de SparkFun. Los scripts de Python ya reconocen los
dos, así que la autodetección del puerto funciona igual.

### Cómo ganar la ventana de 8 segundos

El bootloader del Pro Micro solo acepta programación durante ~8 s tras un reset,
y el IDE se los gasta compilando. El truco es **compilar primero**:

1. **Ctrl+R** (*Verificar*) y espera a que termine de compilar.
2. Ahora **Ctrl+U** (*Subir*): como ya está compilado, avrdude arranca casi al
   instante.
3. En cuanto la consola diga `Uploading…`, puentea **RST con GND dos veces
   seguidas y rápido**.

Si aun así no entra: el bootloader aparece como un **puerto COM distinto** al
del sketch. Haz el doble reset, mira en *Herramientas → Puerto* qué número nuevo
sale, selecciónalo, y repite. Una vez que la placa enumera bien con un sketch
sano, el IDE la resetea sola y ya no hace falta el puente.

### Subir el sketch, paso a paso

> **La primera vez, sube el sketch de diagnóstico, no el firmware real.** Ver la
> sección 3. Si hay un switch en corto o un diodo al revés, el firmware real
> empezaría a mandar teclas solo y te costaría hasta recuperar la placa.

1. Conecta el Pro Micro por USB. Ojo: **tiene que ser un cable de datos**, no
   uno de solo carga. Es la causa nº 1 de «no aparece el puerto».
2. **Herramientas → Placa** → *SparkFun Pro Micro* (o *Arduino Leonardo*).
3. **Herramientas → Processor** → *ATmega32U4 (5V, 16 MHz)*. Si eliges 8 MHz por
   error, la placa arranca pero el USB va mal.
4. **Herramientas → Puerto** → elige el que aparezca (`COM…` en Windows,
   `/dev/ttyACM0` en Arch).
5. Cierra el **Monitor Serie** y cualquier script Python que tenga el puerto
   abierto: si no, la subida falla.
6. Pulsa **Subir** (la flecha →). La primera vez tarda un poco más.
7. Al terminar debe poner `avrdude done. Thank you.` en la consola.

**Si falla la subida** (lo normal en un Pro Micro, no te asustes):

El Pro Micro solo acepta programación durante los **~8 segundos** posteriores a
un reset. El truco:

1. Dale a **Subir** en el IDE.
2. En cuanto veas en la consola que empieza a compilar y aparece
   `Uploading…`, **puentea RST con GND dos veces seguidas y rápido**
   (o pulsa el botón de reset dos veces, si le pusiste uno).
3. Suéltalo. El bootloader se queda 8 s esperando y la subida entra.

Detalles útiles:

- El Pro Micro tiene **dos puertos distintos**: uno cuando corre tu sketch y
  otro cuando está en el bootloader. Es normal que el puerto «cambie de
  número» al resetear; si el IDE se queja, vuelve a elegir el puerto.
- **Windows**: si el puerto no aparece nunca, instala el paquete *SparkFun AVR
  Boards*, que trae el `.inf` con el VID/PID correcto.
- **Arch**: el puerto es `/dev/ttyACM0` y tu usuario tiene que estar en el grupo
  `uucp` (`sudo usermod -aG uucp $USER` y volver a iniciar sesión). Si no, el
  IDE dirá «permission denied».
- **Recuperar una placa que se ha quedado tonta** (por ejemplo, si el firmware
  HID manda una tecla sin parar): haz el doble reset y sube el sketch de
  diagnóstico, que no manda nada. Siempre se puede recuperar así.

### Cambiar qué hace cada botón
Edita el array `MAPA` del sketch. Cada entrada es:

```cpp
{ TIPO, MODIFICADORES, CODIGO, REPITE, "descripcion" }
```

```cpp
{ ACCION_TECLA,      MOD_CTRL | MOD_SHIFT, KEY_S,           false, "Recorte" },
{ ACCION_MULTIMEDIA, MOD_NINGUNO,          MEDIA_PLAY_PAUSE, false, "Play" },
{ ACCION_NINGUNA,    MOD_NINGUNO,          0,               false, "libre" },
```

`REPITE = true` hace que mantener pulsado repita la tecla (400 ms de espera,
luego cada 110 ms). Ahora mismo no lo usa ninguna tecla; está disponible por si
asignas volumen +/− a alguna de las custom.

---

## 3. Comprobar que todo está bien mapeado

### Paso 0 — averiguar en qué pines está soldado tu cableado

**Los pines de la sección 1 son una propuesta, no tu cableado.** Si no responde
ninguna tecla, o si mover un slider «pulsa» teclas solo, es que no coinciden.

Sube **`firmware/DescubrirPines/DescubrirPines.ino`** y abre el Monitor Serie a
115200. Descubre el cableado real por continuidad y te escribe las tres líneas
de configuración listas para copiar:

1. **Sliders**: muévelos uno a uno, de tope a tope, en el orden en que quieras
   numerarlos. Te va diciendo en qué pin está cada uno.
2. Escribe **`m`** + Enter. Los pines de los sliders quedan excluidos solos.
3. **Teclas**: púlsalas una a una. Cada una te dice el par de pines que conecta.
   Como los diodos solo dejan pasar corriente de columna a fila, el sketch
   deduce además **cuál es la fila y cuál la columna**.
4. Escribe **`r`** + Enter y copia el resultado a `StreamDeckDIY.ino` y a
   `TestStreamDeck.ino`.

> **Evita meter la matriz en pines analógicos.** El Pro Micro tiene exactamente
> 7 pines sin capacidad analógica (2, 3, 5, 7, 14, 15, 16) y la matriz necesita
> justo 7 (4 filas + 3 columnas). Dejando ahí la matriz, los 9 pines analógicos
> quedan libres para los sliders y no hay forma de que se pisen. Si algún día
> rehaces el cableado, ése es el reparto bueno.

### Comprobación de teclas y sliders

Con los pines ya correctos, sube **`firmware/TestStreamDeck/TestStreamDeck.ino`**.

Ese sketch **no se presenta como teclado**: no manda ni una sola pulsación al
PC. Solo escribe por el puerto serie qué tecla has pulsado y cómo van los
sliders. Así puedes probarlo todo sin riesgo de que un fallo de soldadura te
llene la pantalla de teclas o te dispare atajos.

### Opción A — sin instalar nada

Sube el sketch y abre **Herramientas → Monitor Serie a 115200 baudios**. Al
pulsar una tecla verás:

```
TECLA|4|1|1|1|GRABAR OBS (F15)
       ^ ^ ^ ^
       | | | +-- 1 = pulsada, 0 = soltada
       | | +---- columna
       | +------ fila
       +-------- índice en el MAPA
```

Escribe `h` + Enter para reimprimir el mapa completo, o `r` + Enter para
reiniciar el mín/máx de los sliders.

### Opción B — visor en vivo (recomendado)

Cierra el Monitor Serie (solo un programa puede tener el puerto abierto) y:

```bash
python host/test_streamdeck.py
```

Verás la rejilla 4×3 en tiempo real: la tecla que estás pulsando se ilumina, las
que ya has probado quedan marcadas con `[OK]` y hay un contador
«probadas: 7/12» para que no te dejes ninguna. Debajo, los 5 sliders con barra,
valor crudo, recorrido alcanzado y nivel de ruido.

### Qué comprobar

| Comprobación | Qué debe pasar |
|---|---|
| Pulsar las 12 teclas, una a una | El contador llega a **12/12** y cada tecla enciende **la casilla que le toca**. Si al pulsar la de arriba a la izquierda se enciende otra, tienes filas/columnas cambiadas o cables cruzados. |
| Pulsar `[0]`, `[1]` y `[3]` a la vez | Solo esas tres. Si se enciende también `[4]`, sale el aviso de **GHOSTING**: falta un diodo o está al revés. |
| Mover cada slider de tope a tope | Debe poner **«recorrido completo»** (llega casi a 0 y casi a 1023). Si se queda corto, revisa que los extremos del potenciómetro estén a GND y VCC. |
| Dejar los sliders quietos | El **ruido** debe ser de pocas unidades. Si sale en rojo («ALTO»), mira el apartado de sliders ruidosos en Troubleshooting. |
| Ver si algún slider va al revés | La barra debe **crecer** al subirlo. Si baja, pon `true` en su posición de `SLIDER_INVERTIDO[]` en el firmware real. |

Cuando todo cuadre, sube ya `firmware/StreamDeckDIY/StreamDeckDIY.ino` y sigue
con el mezclador.

> Si tocas el array `MAPA` del firmware real, actualiza también el array
> `DESCRIPCIONES` del sketch de diagnóstico, o el comprobador te enseñará
> nombres que ya no corresponden.

---

## 4. Mezclador de volumen por aplicación

### Por qué hace falta un script
HID no tiene ningún estándar para «sube el volumen *de esta app*». Solo existe
el volumen global. Para tocar el volumen de una aplicación concreta hay que
hablar con la API de audio del sistema, y eso solo puede hacerlo un programa
que corra en el PC. Este script es esa pieza, escrita desde cero.

### Instalación

**Windows:**

```bash
pip install -r requirements.txt
```

**Arch Linux** — aquí **no** se usa `pip`. El Python del sistema está marcado
como *externally managed* (PEP 668) y pip se niega a instalar fuera de un
entorno virtual. Como la única dependencia es `pyserial` y está empaquetada,
sale más limpio por pacman: la actualiza el sistema y el servicio de systemd
puede llamar a `/usr/bin/python` sin más.

```bash
sudo pacman -S python-pyserial libpulse
sudo usermod -aG uucp $USER
```

`libpulse` aporta `pactl`, que es con lo que el script habla con PipeWire.
El grupo `uucp` es el dueño de `/dev/ttyACM*`: **cierra la sesión y vuelve a
entrar** para que tenga efecto (comprueba con `id` que aparece `uucp`).

### Configurar qué app controla cada slider

1. Abre las aplicaciones y **ponlas a sonar** (una app sin audio activo no
   aparece en la lista).
2. Ejecuta:

```bash
python streamdeck_mixer.py --listar
```

3. Copia los nombres que salgan al diccionario `SLIDER_MAP`, arriba del script:

Configuración actual, con los nombres ya confirmados en ElectroPC:

```python
SLIDER_MAP = {
    0: ["maestro"],
    1: ["chrome", "msedge", "brave", "firefox", "chromium"],
    2: ["spotify"],
    3: ["resto"],                       # juegos
    4: ["discord", "vesktop", "webcord"],
}

EXCLUIDOS_DE_RESTO = ["sistema", "wledsrserver"]
```

Nota sobre el **slider 3 (juegos)**: está puesto como `"resto"`, es decir, todo
lo que no controle otro slider. Es lo más práctico, porque cada juego tiene un
nombre de proceso distinto (Minecraft es `javaw`, pero el siguiente será otra
cosa) y así no hay que editar el script cada vez. Si prefieres fijarlos a mano,
sustitúyelo por sus nombres: `["javaw", "cs2", "valorant-win64-shipping"]`.

`EXCLUIDOS_DE_RESTO` protege a los programas que **usan** audio para trabajar en
vez de para que tú los escuches: bajarles el volumen les rompe la función. Ahí
está `wledsrserver` (el servidor de WLED reactivo al sonido) además de los
sonidos del sistema. Si algún día añades otro programa así, apúntalo en esa
lista.

Palabras clave especiales:

| Valor | Qué controla |
|---|---|
| `"maestro"` | volumen general de la salida por defecto |
| `"microfono"` | ganancia de la entrada por defecto (tu SSL 2+ en ElectroPC) |
| `"resto"` | todas las apps que **no** estén asignadas a otro slider |
| `"sistema"` | sonidos del sistema (solo Windows) |
| cualquier otro | nombre de proceso de la app |

Los nombres se comparan en minúsculas y sin `.exe`, así que `"discord"` vale en
los dos sistemas. Puedes poner varios nombres en una lista para cubrir Windows
y Linux a la vez.

### Ajustar el tacto de los sliders

Por defecto la respuesta es **lineal**: la posición del slider es el volumen.

```python
EXPONENTE_VOLUMEN = 1.0   # 1.0 = lineal
                          # 1.5–2.5 = más resolución abajo, sube tarde
                          # 0.7 = más resolución arriba, sube pronto
UMBRAL_CRUDO = 3          # zona muerta en cuentas de 0..1023 (~0.3% del recorrido)
```

Conviene dejarlo en `1.0`. Core Audio y PipeWire **ya aplican su propia curva
perceptual** por dentro: sus escalas son «posición de fader», no amplitud. Si
además le metes aquí otra curva, se aplica dos veces y el resultado es el
recorrido aplastado por abajo (milímetros para mover un 1 %) con todo el cambio
útil concentrado en un tramo corto.

#### La corrección del volumen por aplicación (Windows)

Windows **no trata igual** el volumen maestro y el de cada aplicación, y esa es
la causa de que los sliders se sintieran distintos entre sí.

Medido sobre este equipo (`SetMasterVolumeLevelScalar`, rango −96…0 dB):

| escalar | dB reales | amplitud |
|---|---|---|
| 0,10 | −34,75 | 1,8 % |
| 0,25 | −20,99 | 8,9 % |
| 0,50 | −10,51 | 29,8 % |
| 0,75 | −4,36 | 60,5 % |

Eso no es amplitud lineal (0,5 daría −6 dB). Ajustando los puntos sale
**amplitud = escalar<sup>1,75</sup>**, con el exponente clavado entre 1,73 y
1,75 en todo el recorrido. Ese 1,75 está elegido a propósito: como la sonoridad
percibida va aproximadamente con amplitud<sup>0,6</sup>, el resultado es que la
posición del fader coincide con lo que oyes.

Pero el volumen **por aplicación** (`ISimpleAudioVolume.SetMasterVolume`) es un
multiplicador de amplitud **crudo**, sin esa curva. Sin corregirlo, en las apps
casi todo el cambio audible ocurre en el tercio de abajo y la mitad de arriba
apenas hace nada.

```python
CURVA_SESIONES_WINDOWS = 1.75   # 1.0 = comportamiento crudo
```

Con esto los cinco sliders se comportan igual: la diferencia entre la curva del
maestro y la de las apps queda por debajo de **0,25 dB** en todo el recorrido.

#### La curva del fader (Arch / PipeWire)

**Medido en el portátil el 2026-09-14** (PipeWire 1.6.8, `pactl` 17.0), poniendo
valores conocidos y leyendo los dB que devuelve el propio `pactl`:

| `pactl …%` | dB reales | amplitud |
|---|---|---|
| 10 % | −60,00 | 0,1 % |
| 25 % | −36,12 | 1,6 % |
| 50 % | −18,06 | 12,5 % |
| 75 % | −7,50 | 42,2 % |

Es **exactamente cúbica**: amplitud = porcentaje³. Se comprobó además que **los
sinks y los sink-inputs dan los mismos dB** para el mismo valor, así que el
maestro y las aplicaciones ya son consistentes entre sí.

##### Por qué una curva de potencia NO sirve

El primer intento fue copiar la curva de Windows (amplitud = posición<sup>1,75</sup>).
Cuadraba con Windows a menos de 0,25 dB… y **se sentía mal al probarlo**:

```
de 0,50 a 1,00 (media carrera) →  solo 10,5 dB
de 0,10 a 0,50 (40 % de carrera) →      24,5 dB
```

El motivo es que **cualquier** curva de potencia es logarítmica en la posición:
da los mismos dB cada vez que *doblas* la posición, no cada milímetro. El
resultado es que casi todo el cambio audible se concentra en la mitad de abajo
y la parte de arriba apenas hace nada. Eso incluye la curva cruda de PipeWire
(que es aún peor, porque el exponente es 3).

##### Fader lineal en dB

Lo que de verdad se siente lineal —y es lo que hace una mesa de mezclas— es dar
**los mismos dB por cada milímetro de recorrido**:

```
dB       = (posición − 1) × RANGO_DB_LINUX
amplitud = 10 ^ (dB / 20)
valor    = amplitud ^ (1/3)      ← deshace la cúbica de PipeWire medida arriba
```

```python
RANGO_DB_LINUX = 50.0    # 40 = recorrido corto, 60 = como una mesa de mezclas
                         # 0  = desactivar (comportamiento crudo de PipeWire)
```

Comprobado sobre el stream real de Spotify, con `RANGO_DB_LINUX = 50`:

| posición | dB medidos | salto |
|---|---|---|
| 1,0 | 0,00 | |
| 0,9 | −5,00 | −5,0 dB |
| 0,7 | −15,00 | −5,0 dB |
| 0,5 | −25,00 | −5,0 dB |
| 0,3 | −35,00 | −5,0 dB |
| 0,1 | −45,00 | −5,0 dB |
| 0,0 | −inf | silencio |

**−5,00 dB clavados por cada 10 % de fader**, mires donde mires del recorrido.

> Detalle de implementación: en Linux el script **no le manda porcentajes a
> `pactl`, sino el valor crudo 0–65536** (`PA_VOLUME_NORM`). Así no se pierde
> resolución al redondear a porcentajes enteros, y no depende de si el sistema
> escribe los decimales con coma o con punto.

> En Windows esto **no** está aplicado: allí sigue `CURVA_SESIONES_WINDOWS`, que
> es lo que hay probado en ElectroPC. Si algún día quieres el mismo tacto en los
> dos, habría que llevar esta misma idea al `BackendWindows`.

#### Si un potenciómetro tiembla

Sube `UMBRAL_CRUDO` a 6–8 antes de tocar ninguna curva.

### Probar

```bash
python streamdeck_mixer.py --debug
```

Mueve los sliders: debe imprimir una línea por cambio. `--puertos` lista los
puertos serie si la autodetección falla; `--puerto COM5` fuerza uno.

### Arranque automático

**Windows** — ya está configurado. Hay un acceso directo llamado
**«StreamDeck Mixer»** en la carpeta de inicio:

```
C:\Users\adria\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
```

Apunta a `wscript.exe` con `host\iniciar_mixer_oculto.vbs` como argumento, que
a su vez lanza el script con `pythonw.exe` (Python sin ventana de consola). No
aparece nada en pantalla al iniciar sesión.

Cosas útiles de saber:

- **Para desactivarlo**: borra ese acceso directo (`Win+R` → `shell:startup`),
  o desactívalo en *Administrador de tareas → Inicio*.
- **Para comprobar que está vivo**: el proceso se llama **`pythonw3.12.exe`**,
  no `pythonw.exe` — es el nombre real del ejecutable del Python de la
  Microsoft Store. Buscar «pythonw» en el Administrador de tareas no lo
  encuentra.
- **Para cerrarlo**: `taskkill /IM pythonw3.12.exe /F`
- **Si reinstalas Python en otra ruta**, actualiza la línea `pythonw = "..."`
  del `.vbs`. Si esa ruta no existe, recurre al PATH.

**No puede haber dos copias a la vez.** El script ocupa el puerto local 47821
como cerrojo: si lo lanzas a mano mientras el del arranque está corriendo, la
segunda copia avisa y se cierra en vez de quedarse peleando por el puerto serie.
Se usa un puerto y no un archivo de bloqueo porque, si el proceso muere de malas
maneras, el sistema libera el puerto solo y no queda un cerrojo huérfano.

**Arch Linux (Hyprland)** — servicio de usuario de systemd, incluido:

```bash
mkdir -p ~/.config/systemd/user
cp host/streamdeck-mixer.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now streamdeck-mixer.service
```

Ajusta la ruta de `ExecStart` si el proyecto no está en `~/StreamDeckDIY`
(usa `%h`, que systemd sustituye por tu carpeta personal).
Ver el log: `journalctl --user -u streamdeck-mixer -f`.

Comprobaciones rápidas:

```bash
systemctl --user status streamdeck-mixer     # debe poner "active (running)"
systemctl --user restart streamdeck-mixer    # tras editar SLIDER_MAP
systemctl --user stop streamdeck-mixer       # antes de lanzarlo a mano con --debug
```

El `ExecStart` lleva `python -u` a propósito: sin esa opción Python guarda la
salida en un búfer y el `journal` no enseña nada hasta que se llena.

**Para probarlo a mano hay que parar antes el servicio.** El script solo deja
una instancia viva (ocupa el puerto local 47821 como cerrojo), así que la
segunda copia avisa y se cierra en vez de pelearse por el puerto serie.

Alternativa más simple, en `~/.config/hypr/hyprland.conf`:

```
exec-once = python ~/StreamDeckDIY/host/streamdeck_mixer.py
```

(El servicio de systemd es preferible: reinicia solo si el script se cae.)

---

## 5. Configurar los hotkeys en OBS

El StreamDeck manda **F13, F14 y F15** a OBS. Son teclas que ningún teclado
físico tiene, así que no chocan con nada.

En OBS: **Ajustes → Atajos de teclado**. Haz clic en el campo de cada acción y
**pulsa el botón físico del StreamDeck** (así te aseguras de que OBS registra
exactamente lo que manda la placa):

| Botón | Tecla | Acción a configurar en OBS |
|---|---|---|
| `[0]` fila 0, col 0 | F13 | **Cambiar silencio** de tu fuente de micrófono |
| `[2]` fila 0, col 2 | F14 | **Mostrar/Ocultar** tu fuente de cámara |
| `[4]` fila 1, col 1 | F15 | **Iniciar grabación** *y* **Detener grabación** (la misma tecla en los dos campos) |

Detalles que ahorran disgustos:

- Para grabar, pon **la misma tecla en el campo de iniciar y en el de detener**:
  OBS lo convierte en un toggle.
- El mute del micro y el toggle de la cámara están en la lista de atajos por
  **cada fuente**: busca en la lista el nombre de tu fuente de micro y el de tu
  cámara. En el micro la acción se llama «Cambiar silencio»; en la cámara,
  «Mostrar/Ocultar» (también accesible desde el engranaje de la fuente en el
  *Mezclador de audio* → *Propiedades de atajos*).
- Si tienes la cámara en varias escenas, el atajo «Mostrar/Ocultar» es **por
  escena**. Para apagarla en todas a la vez, mete la cámara en un **grupo** o
  en una **escena anidada** y asígnale el atajo a esa.
- Marca **Ajustes → General → «Atajos de teclado activos cuando OBS no tiene el
  foco»** para que funcionen mientras juegas.
- En Hyprland/Wayland, OBS solo recibe atajos globales si corre bajo XWayland.
  Si no te responden con OBS en segundo plano, arráncalo con
  `env -u WAYLAND_DISPLAY obs`.
- **Las teclas multimedia de la fila de abajo no las gestiona el StreamDeck**,
  sino Hyprland. Con varios reproductores abiertos hay una trampa: ver la
  sección 7.
- Las 5 teclas custom (**F17–F21**) puedes asignarlas aquí mismo para escenas,
  transiciones o «Iniciar/Parar transmisión».

---

## 6. Troubleshooting

### Un botón no responde
1. **¿Responden los demás de su fila o de su columna?** Si falla una fila
   entera → soldadura del pin de fila. Si falla una columna entera → pin de
   columna. Si falla solo uno → switch o su diodo.
2. Comprueba continuidad con el multímetro entre el pin de la columna y el pin
   de la fila con la tecla pulsada (~0,6 V en modo diodo).
3. Verifica que los pines del `.ino` coinciden con tu cableado real.
4. Cuidado con el pin 16: en el Pro Micro es MOSI. Funciona perfectamente como
   entrada digital (y aquí es la columna 2), pero si tienes algo más soldado
   ahí, cámbialo por el 14 o el 15.

### Teclas fantasma / se activan solas (ghosting)
- Falta algún diodo o está al revés. Repite la prueba de la «L» descrita arriba.
- Si un botón dispara dos veces por pulsación, es rebote: sube `DEBOUNCE_MS` de
  8 a 15 en el sketch.

### El PC no reconoce el teclado
- Comprueba que la placa seleccionada es **Pro Micro / Leonardo**. Con un
  Uno/Nano el HID no existe y no funcionaría nada.
- Si el sketch se ha subido pero el USB no enumera, el `loop()` puede estar
  bloqueado: no metas `delay()` largos en el firmware.

### Un slider da lecturas ruidosas o salta solo
1. Sube `SUAVIZADO_SLIDER` de 8 a 16 o 32 en el sketch (más suave, algo más lento).
2. Sube `UMBRAL_SLIDER` de 4 a 8.
3. Sube `UMBRAL_CAMBIO` en el script de Python (de `0.008` a `0.02`).
4. Comprueba masa: los 5 potenciómetros deben compartir **la misma GND** que el
   Pro Micro, con cable corto. La mayoría del ruido de los potenciómetros
   baratos es en realidad una masa mala o cables largos sin trenzar.
5. Un condensador de 100 nF entre el cursor y GND filtra muchísimo, si el ruido
   persiste.

### Un slider va al revés
Pon `true` en su posición dentro de `SLIDER_INVERTIDO[]` en el sketch.

### `AttributeError: 'AudioDevice' object has no attribute 'Activate'`

pycaw cambió su API. En las versiones nuevas (probado con **20251023**),
`GetSpeakers()` devuelve un envoltorio `AudioDevice` que ya trae la propiedad
`.EndpointVolume` resuelta, en vez del puntero `IMMDevice` crudo al que había
que pedirle la interfaz con `Activate()`.

Lo curioso es que **`GetMicrophone()` sí sigue devolviendo el `IMMDevice`
antiguo**, así que las dos formas conviven en la misma versión. El script ya
prueba primero `.EndpointVolume` y recurre a `Activate()` si no existe, con lo
que funciona con pycaw viejo y nuevo. Lo mismo con las sesiones:
`.SimpleAudioVolume` primero, `QueryInterface` como respaldo.

Si te sale este error, es que tienes una copia antigua del script.

### El número de puerto COM cambia solo

Es normal y no hay que hacer nada: al pasar del sketch de diagnóstico al
firmware real, el dispositivo deja de ser un CDC simple y pasa a ser un
compuesto HID + serie, y Windows le asigna otro número (aquí pasó de COM10 a
COM11). Por eso el script **autodetecta el puerto por VID/PID** en vez de
llevarlo fijo. Solo tendrías que tocar algo si usas `--puerto` a mano.

### El script no encuentra el StreamDeck
```bash
python streamdeck_mixer.py --puertos
```
Si el puerto aparece pero no se detecta solo, pásalo con `--puerto`. En Linux,
si el puerto existe pero da «permission denied», falta el grupo `uucp`.

### El slider mueve el volumen pero la app no baja
El nombre no coincide. Ejecuta `--listar` **con la app sonando** y usa el nombre
exacto que aparezca. Algunos programas (navegadores, Discord) crean sesiones con
nombres distintos según la versión; por eso `SLIDER_MAP` acepta varios nombres.

### En Arch: «permission denied» al abrir `/dev/ttyACM0`

Falta el grupo `uucp`. Comprueba con `id` que sale en la lista; si lo acabas de
añadir con `usermod`, **no vale con abrir otra terminal**: hay que cerrar la
sesión de Hyprland y volver a entrar, porque el grupo se hereda del proceso de
login.

```bash
ls -l /dev/ttyACM0     # tiene que ser  crw-rw---- root uucp
id                     # tiene que aparecer "uucp"
```

### En Arch: `pip install` falla con «externally-managed-environment»

Es lo normal en Arch: el Python del sistema no deja instalar con pip fuera de un
entorno virtual. No lo fuerces con `--break-system-packages`; instala la
dependencia con pacman, que es la misma:

```bash
sudo pacman -S python-pyserial
```

### En Arch: el slider mueve el volumen pero la app no baja

Los nombres que publica PipeWire **no son siempre el del ejecutable**. Cada
programa publica los que le da la gana, y el script mira tres propiedades por
este orden: `application.process.binary`, `application.name` y `node.name`.

Comprobado en este portátil:

| App | `application.name` | `…process.binary` | `node.name` |
|---|---|---|---|
| Firefox | `Firefox` | `firefox` | `Firefox` |
| Spotify | `Spotify` | *(no publica)* | `spotify` |
| AnyDesk | `AnyDesk` | `anydesk` | `AnyDesk` |

Por eso Spotify **no se puede buscar por el binario**: hay que mirar también
`application.name`. Con la app sonando, `--listar` enseña el nombre ya
normalizado, que es el que va en `SLIDER_MAP`.

`media.name` **no** se usa para identificar apps (solo como último recurso si un
flujo no publica ninguna de las otras tres): es el título de la canción o de la
pestaña del navegador, cambia constantemente, y si se usara, «resto» acabaría
intentando bajarle el volumen a nombres inventados.

### En Arch: al mirar el volumen a mano no aparece «front-left»

Detalle que despista si inspeccionas con `pactl list sink-inputs | grep
front-left`: **Spotify publica sus canales como `aux0` / `aux1`**, no como
`front-left` / `front-right`, así que ese grep se lo salta. No afecta al script
(él escribe el volumen, no lo lee). Para verlo todo:

```bash
pactl list sink-inputs | grep -E "^Sink Input|Volume:|application.name "
```

### En Linux el volumen «rebota» al mover el slider
Si tienes un applet de volumen que también escribe en el mismo sink, pueden
pelearse. Cierra el applet o quítale la sincronización.
