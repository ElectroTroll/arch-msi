#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===============================================================================
StreamDeck DIY - Mezclador de volumen por aplicacion
===============================================================================

Lee los 5 sliders del Pro Micro por puerto serie y ajusta el volumen de cada
aplicacion directamente contra la API de audio del sistema operativo:

  - Windows  ->  Core Audio (WASAPI) mediante pycaw:
                   * volumen maestro / microfono -> IAudioEndpointVolume
                   * volumen de cada app         -> ISimpleAudioVolume
  - Linux    ->  PipeWire / PulseAudio mediante el comando `pactl`:
                   * maestro   -> pactl set-sink-volume   @DEFAULT_SINK@
                   * microfono -> pactl set-source-volume @DEFAULT_SOURCE@
                   * cada app  -> pactl set-sink-input-volume <indice>

No depende de Deej ni de ninguna otra aplicacion de terceros: esto habla
directamente con el sistema.

Uso:
    python streamdeck_mixer.py                # funcionamiento normal
    python streamdeck_mixer.py --listar       # ver que apps hay sonando ahora
    python streamdeck_mixer.py --puertos      # ver los puertos serie disponibles
    python streamdeck_mixer.py --puerto COM5  # forzar un puerto concreto
    python streamdeck_mixer.py --debug        # mostrar cada cambio aplicado

Instalacion de dependencias:
    pip install -r requirements.txt
===============================================================================
"""

import argparse
import platform
import re
import shutil
import subprocess
import sys
import time

try:
    import serial                      # pyserial
    import serial.tools.list_ports
except ImportError:
    sys.exit("Falta pyserial. Instala las dependencias con:  pip install -r requirements.txt")


# =============================================================================
# CONFIGURACION  (esto es lo unico que normalmente hay que tocar)
# =============================================================================

# Que controla cada slider. El indice 0 es el primer valor que manda el
# Arduino (el slider conectado a A0), el 4 es el ultimo (A6).
#
# Cada slider tiene una LISTA de objetivos. Sirven:
#
#   "maestro"    -> volumen general del sistema (altavoces por defecto)
#   "microfono"  -> ganancia del microfono / entrada por defecto (SSL 2+)
#   "resto"      -> todas las apps que NO esten asignadas a otro slider
#   "sistema"    -> sonidos del propio sistema operativo (solo Windows)
#   cualquier otra cosa -> nombre de proceso de la aplicacion
#
# Los nombres de proceso se comparan sin distinguir mayusculas y sin la
# extension .exe, asi que puedes poner el mismo nombre para Windows y Linux.
# Puedes poner varios en la misma lista: el slider controlara a todos a la vez
# (util porque un mismo programa se llama distinto en cada sistema).
#
# Para averiguar los nombres exactos, arranca la app que quieras controlar,
# ponla a sonar, y ejecuta:   python streamdeck_mixer.py --listar

SLIDER_MAP = {
    # slider 0 -> volumen maestro del sistema
    0: ["maestro"],

    # slider 1 -> navegador.
    #   "chrome"  confirmado en ElectroPC (Windows).
    #   "firefox" confirmado en el portatil (Arch): PipeWire publica
    #             application.name = "Firefox" y application.process.binary =
    #             "firefox". Los demas quedan por si algun dia cambias de
    #             navegador.
    1: ["chrome", "msedge", "brave", "firefox", "chromium", "zen", "librewolf"],

    # slider 2 -> Spotify.
    #   Confirmado en los dos equipos. Ojo: en Arch, Spotify NO publica
    #   application.process.binary; solo application.name = "Spotify" y
    #   node.name = "spotify". Por eso el backend mira varias propiedades.
    2: ["spotify"],

    # slider 3 -> juegos.
    #   "resto" = todo lo que no este asignado a otro slider ni excluido abajo.
    #   Es lo mas practico para juegos, porque cada uno tiene un nombre de
    #   proceso distinto: Minecraft es "javaw", pero el siguiente juego sera
    #   otra cosa y con "resto" no hay que tocar nada.
    #   Si prefieres fijarlos a mano:
    #       3: ["javaw", "cs2", "valorant-win64-shipping"],
    3: ["resto"],

    # slider 4 -> Discord (confirmado en Windows; abre 2 sesiones y se
    #             controlan las dos). En Arch esta instalado el Discord oficial,
    #             pero no se ha podido confirmar el nombre porque no estaba
    #             sonando: comprueba con --listar la primera vez que lo uses.
    4: ["discord", "vesktop", "webcord", "armcord"],
}

# Aplicaciones que NUNCA debe tocar el objetivo "resto".
# Son programas que usan audio para trabajar, no para que tu los escuches:
# bajarles el volumen les rompe la funcion.
#   sistema      -> sonidos del propio Windows
#   wledsrserver -> servidor de WLED reactivo al sonido (las luces LED)
EXCLUIDOS_DE_RESTO = ["sistema", "wledsrserver"]

# Curva de volumen: volumen = (posicion del slider) ** EXPONENTE_VOLUMEN
#
#   1.0  -> LINEAL. Recomendado, y lo que hay puesto.
#   1.5 a 2.5 -> mas resolucion abajo, el volumen sube tarde
#   0.7  -> mas resolucion arriba, el volumen sube pronto
#
# Por que lineal: esta curva es COMUN a los dos sistemas, y cada sistema tiene
# la suya propia por dentro (Core Audio y PipeWire no usan la misma escala).
# Meter aqui una curva generica la aplicaria dos veces en uno de los dos.
# La correccion especifica de cada sistema va mas abajo, en
# CURVA_SESIONES_WINDOWS y RANGO_DB_LINUX, medidas cada una en su equipo.
EXPONENTE_VOLUMEN = 1.0

# Correccion para el volumen POR APLICACION en Windows.
# ---------------------------------------------------------------------------
# Windows no trata igual el volumen maestro y el de cada aplicacion:
#
#   - Maestro (IAudioEndpointVolume.SetMasterVolumeLevelScalar): Windows aplica
#     por dentro su propia curva. Medido en este equipo (SSL 2+, rango -96..0 dB):
#
#         escalar 0.10 -> -34.75 dB     escalar 0.50 -> -10.51 dB
#         escalar 0.25 -> -20.99 dB     escalar 0.75 ->  -4.36 dB
#
#     Ajustando esos puntos sale amplitud = escalar ** 1.75, con un exponente
#     clavado entre 1.73 y 1.75 en todo el recorrido. Ese 1.75 esta elegido a
#     proposito: como la sonoridad percibida va aproximadamente con
#     amplitud^0.6, el resultado es que la POSICION del fader coincide con la
#     sonoridad que oyes. Por eso el slider maestro se siente lineal.
#
#   - Por aplicacion (ISimpleAudioVolume.SetMasterVolume): es un multiplicador
#     de amplitud CRUDO. Sin esa curva, casi todo el cambio audible se
#     concentra en el tercio de abajo y la mitad de arriba apenas hace nada.
#
# Aplicando aqui el mismo 1.75, los cinco sliders se comportan igual.
# Ponlo a 1.0 si prefieres el comportamiento crudo de antes.
CURVA_SESIONES_WINDOWS = 1.75

# Curva del fader en Linux (PipeWire / PulseAudio).
# ---------------------------------------------------------------------------
# PRIMERO, lo que hace PipeWire por dentro. MEDIDO en el portatil el 2026-09-14
# (PipeWire 1.6.8, pactl 17.0), poniendo valores conocidos y leyendo los dB que
# devuelve el propio pactl:
#
#       pactl 10%  -> -60,00 dB        pactl  50%  -> -18,06 dB
#       pactl 25%  -> -36,12 dB        pactl  75%  ->  -7,50 dB
#
# Es exactamente amplitud = porcentaje ** 3 (cubica). Se comprobo ademas que
# los SINKS y los SINK-INPUTS dan los mismos dB para el mismo valor, asi que
# maestro y aplicaciones ya son consistentes entre si.
#
# SEGUNDO, que queremos que se sienta. Cualquier curva de tipo potencia
# (amplitud = posicion ** k) es LOGARITMICA en la posicion: da los mismos dB
# por cada VEZ que doblas la posicion, no por cada milimetro. Con k = 1.75
# (que es lo que hace Windows) salia esto:
#
#       de 0.50 a 1.00 (media carrera) -> solo 10,5 dB
#       de 0.10 a 0.50 (40% de carrera) -> 24,5 dB
#
# O sea: casi todo el cambio audible se concentra abajo y la mitad de arriba
# apenas hace nada. Probado sobre el hardware, se nota y molesta.
#
# La solucion es hacer el fader LINEAL EN dB: los mismos dB por cada milimetro
# de recorrido, mires donde mires del fader. Es lo que hace una mesa de mezclas
# y es lo que de verdad se siente lineal.
#
#       dB = (posicion - 1) * RANGO_DB_LINUX          posicion 1.0 ->   0 dB
#       amplitud = 10 ** (dB / 20)                    posicion 0.5 -> -25 dB
#       valor de pactl = amplitud ** (1/3)            posicion 0.0 -> silencio
#
# Ese ** (1/3) final es lo que DESHACE la cubica de PipeWire medida arriba,
# para que los dB que pedimos sean los dB que salen.
#
# RANGO_DB_LINUX es el unico numero a tocar si quieres otro tacto:
#
#       40  -> recorrido corto: a media carrera estas a -20 dB (aun se oye
#              bien). Menos margen fino arriba.
#       50  -> equilibrado. Es lo que hay puesto.
#       60  -> recorrido largo, como una mesa de mezclas de verdad. A media
#              carrera estas a -30 dB y el cuarto de abajo es practicamente
#              silencio.
#
# Poniendolo a 0 se desactiva la correccion y se manda la posicion tal cual a
# pactl (el comportamiento crudo de PipeWire, el mismo que los controles de
# volumen del escritorio).
RANGO_DB_LINUX = 50.0

# Cambio minimo, EN CUENTAS DEL SLIDER (0..1023), para aplicar el volumen.
# Se compara sobre el valor crudo y no sobre el volumen ya curvado, para que
# la zona muerta sea siempre la misma en milimetros de recorrido, mires donde
# mires del slider. 3 cuentas son ~0.3% del recorrido.
# Subelo a 6-8 si algun potenciometro tiene ruido y "tiembla" solo.
UMBRAL_CRUDO = 3

# Cada cuantos segundos se vuelve a mirar que aplicaciones estan sonando.
# (Si abres Spotify a mitad de sesion, tarda como mucho esto en detectarlo.)
INTERVALO_REFRESCO_S = 2.0

# Al detectar que ha aparecido o desaparecido una aplicacion, volver a aplicar
# la posicion actual de los sliders.
# Sin esto, una app que empieza a sonar arranca con el volumen que tuviera
# guardado el sistema y se queda ahi hasta que mueves su slider, aunque el
# fader este abajo del todo. Con esto, el StreamDeck manda siempre.
# El firmware reenvia los cinco valores una vez por segundo, asi que la
# correccion entra sola en menos de un segundo sin tocar nada.
REAPLICAR_AL_CAMBIAR_APPS = True

# Puerto serie. None = autodeteccion por VID/PID del Pro Micro.
PUERTO_SERIE = None
BAUDIOS = 115200

# Cuantos sliders espera el script (debe coincidir con el firmware).
NUM_SLIDERS = 5

# Puerto local que se usa como cerrojo para que no haya dos instancias a la vez.
# No se comunica nada por el: solo se ocupa mientras el script vive.
PUERTO_CERROJO = 47821


# VID/PID conocidos de placas ATmega32U4, para la autodeteccion del puerto.
VID_PID_CONOCIDOS = [
    (0x1B4F, 0x9205),  # SparkFun Pro Micro 5V
    (0x1B4F, 0x9206),  # SparkFun Pro Micro 3.3V
    (0x1B4F, 0x9203),  # Pro Micro (bootloader)
    (0x1B4F, 0x9204),  # Pro Micro (bootloader)
    (0x2341, 0x8036),  # Arduino Leonardo
    (0x2341, 0x0036),  # Arduino Leonardo (bootloader)
    (0x2A03, 0x8036),  # Arduino.org Leonardo
]


# =============================================================================
# UTILIDADES COMUNES
# =============================================================================

def normalizar_nombre(nombre):
    """'Spotify.exe' -> 'spotify'. Deja los nombres comparables entre sistemas."""
    if not nombre:
        return ""
    nombre = nombre.strip().lower()
    if nombre.endswith(".exe"):
        nombre = nombre[:-4]
    return nombre


def aplicar_curva(v):
    """Convierte 0.0-1.0 crudo del slider en el volumen final 0.0-1.0."""
    if EXPONENTE_VOLUMEN == 1.0:
        return round(v, 4)
    return round(v ** EXPONENTE_VOLUMEN, 4)


_cerrojo = None      # se mantiene abierto mientras viva el proceso

def instancia_unica():
    """True si somos la unica instancia; False si ya hay otra corriendo.

    Se hace ocupando un puerto local en lugar de con un archivo de bloqueo:
    si el proceso muere de malas maneras, el sistema libera el puerto solo y
    no queda un cerrojo huerfano que haya que borrar a mano.

    Importante: NO poner SO_REUSEADDR. En Windows esa opcion permite que dos
    procesos se aten al mismo puerto, que es justo lo contrario de lo que
    queremos aqui.
    """
    global _cerrojo
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", PUERTO_CERROJO))
    except OSError:
        s.close()
        return False
    s.listen(1)
    _cerrojo = s
    return True


def objetivos_explicitos():
    """Todos los nombres de app asignados a algun slider (sin las palabras clave)."""
    reservadas = {"maestro", "microfono", "resto", "sistema"}
    nombres = set()
    for destinos in SLIDER_MAP.values():
        for d in destinos:
            n = normalizar_nombre(d)
            if n not in reservadas:
                nombres.add(n)
    return nombres


# =============================================================================
# BACKEND WINDOWS  (Core Audio / WASAPI via pycaw)
# =============================================================================

class BackendWindows:

    nombre = "Windows (Core Audio / pycaw)"

    def __init__(self):
        from ctypes import cast, POINTER
        from comtypes import CLSCTX_ALL
        import comtypes
        from pycaw.pycaw import AudioUtilities, ISimpleAudioVolume, IAudioEndpointVolume

        self._cast = cast
        self._POINTER = POINTER
        self._CLSCTX_ALL = CLSCTX_ALL
        self._AudioUtilities = AudioUtilities
        self._ISimpleAudioVolume = ISimpleAudioVolume
        self._IAudioEndpointVolume = IAudioEndpointVolume

        # COM hay que inicializarlo en el hilo que lo usa.
        comtypes.CoInitialize()

        self._maestro = self._endpoint(AudioUtilities.GetSpeakers())
        try:
            self._microfono = self._endpoint(AudioUtilities.GetMicrophone())
        except Exception as e:
            self._microfono = None
            print("[aviso] No se ha podido abrir el microfono por defecto: %s" % e)

        self._sesiones = {}   # nombre normalizado -> [ISimpleAudioVolume, ...]
        self.refrescar()

    def _endpoint(self, dispositivo):
        """Devuelve el IAudioEndpointVolume de un dispositivo de audio.

        pycaw cambio de API por el camino y ademas no es consistente consigo
        mismo, asi que aceptamos las dos formas:

          - pycaw moderno (>= 2025): GetSpeakers() devuelve un AudioDevice que
            ya trae la propiedad .EndpointVolume resuelta.
          - pycaw clasico, Y TAMBIEN GetMicrophone() en las versiones nuevas:
            devuelven el puntero IMMDevice crudo, al que hay que pedirle la
            interfaz con Activate().
        """
        endpoint = getattr(dispositivo, "EndpointVolume", None)
        if endpoint is not None:
            return endpoint

        interfaz = dispositivo.Activate(
            self._IAudioEndpointVolume._iid_, self._CLSCTX_ALL, None)
        return self._cast(interfaz, self._POINTER(self._IAudioEndpointVolume))

    def _volumen_de_sesion(self, sesion):
        """ISimpleAudioVolume de una sesion, con las dos APIs de pycaw."""
        volumen = getattr(sesion, "SimpleAudioVolume", None)
        if volumen is not None:
            return volumen
        return sesion._ctl.QueryInterface(self._ISimpleAudioVolume)

    # -- descubrimiento ------------------------------------------------------

    def refrescar(self):
        sesiones = {}
        for s in self._AudioUtilities.GetAllSessions():
            try:
                if s.Process:
                    nombre = normalizar_nombre(s.Process.name())
                else:
                    nombre = "sistema"          # "System Sounds"
                control = self._volumen_de_sesion(s)
            except Exception:
                continue                        # sesion que acaba de morir
            sesiones.setdefault(nombre, []).append(control)
        self._sesiones = sesiones

    def listar(self):
        filas = [("maestro", "volumen general del sistema"),
                 ("microfono", "entrada por defecto")]
        for nombre in sorted(self._sesiones):
            filas.append((nombre, "%d sesion(es) de audio" % len(self._sesiones[nombre])))
        return filas

    # -- aplicacion ----------------------------------------------------------

    def aplicar(self, objetivo, volumen, no_asignadas):
        obj = normalizar_nombre(objetivo)

        if obj == "maestro":
            self._maestro.SetMasterVolumeLevelScalar(volumen, None)
            return True

        if obj == "microfono":
            if self._microfono is None:
                return False
            self._microfono.SetMasterVolumeLevelScalar(volumen, None)
            return True

        if obj == "resto":
            hecho = False
            for nombre in no_asignadas:
                hecho = self._aplicar_sesiones(nombre, volumen) or hecho
            return hecho

        return self._aplicar_sesiones(obj, volumen)

    def _aplicar_sesiones(self, nombre, volumen):
        controles = self._sesiones.get(nombre)
        if not controles:
            return False

        # ISimpleAudioVolume es amplitud cruda: le aplicamos nosotros la misma
        # curva que Windows aplica por dentro al volumen maestro, para que los
        # cinco sliders se sientan igual. (Ver CURVA_SESIONES_WINDOWS arriba.)
        if CURVA_SESIONES_WINDOWS != 1.0:
            volumen = volumen ** CURVA_SESIONES_WINDOWS

        vivos = []
        for c in controles:
            try:
                c.SetMasterVolume(volumen, None)
                vivos.append(c)
            except Exception:
                pass          # la app se ha cerrado; se limpia de la lista
        self._sesiones[nombre] = vivos
        return bool(vivos)

    def apps_activas(self):
        return set(self._sesiones.keys())


# =============================================================================
# BACKEND LINUX  (PipeWire / PulseAudio via pactl)
# =============================================================================

class BackendLinux:

    nombre = "Linux (PipeWire/PulseAudio via pactl)"

    # "100%" de PulseAudio en unidades crudas (PA_VOLUME_NORM). Se le manda a
    # pactl el valor crudo y no un porcentaje por dos motivos: no perdemos
    # resolucion en la parte baja del recorrido al redondear a enteros, y no
    # dependemos de si el idioma del sistema escribe los decimales con coma.
    VOLUMEN_NORMAL = 65536

    # De donde sale el nombre de cada aplicacion, por orden de preferencia.
    # media.name se queda fuera a proposito: es el titulo de la cancion o de la
    # pestana del navegador, cambia constantemente y llenaria la lista de
    # nombres inventados que ademas "resto" intentaria bajar uno por uno.
    # Solo se usa si un flujo no publica ninguna de las otras tres.
    PROPIEDADES_NOMBRE = ("application.process.binary",
                          "application.name",
                          "node.name")
    PROPIEDAD_RESPALDO = "media.name"

    def __init__(self):
        if shutil.which("pactl") is None:
            sys.exit("No se encuentra 'pactl'. En Arch:  sudo pacman -S libpulse")
        self._entradas = {}   # nombre normalizado -> [indices de sink-input]
        self.refrescar()

    def _pactl(self, *args):
        return subprocess.run(["pactl", *args], capture_output=True, text=True, timeout=5)

    # -- descubrimiento ------------------------------------------------------

    def refrescar(self):
        entradas = {}
        for indice, nombres in self._leer_sink_inputs():
            for n in nombres:
                entradas.setdefault(n, [])
                if indice not in entradas[n]:
                    entradas[n].append(indice)
        self._entradas = entradas

    def _nombres_de(self, propiedades):
        """Nombres normalizados con los que se puede referir un flujo de audio.

        Un mismo programa no publica siempre las mismas propiedades: Firefox da
        application.name = "Firefox" y application.process.binary = "firefox",
        pero Spotify NO publica binary y hay que cogerlo de application.name o
        de node.name. Por eso se miran las tres y se guardan todas.
        """
        nombres = set()
        for clave in self.PROPIEDADES_NOMBRE:
            n = normalizar_nombre(propiedades.get(clave))
            if n:
                nombres.add(n)
        if not nombres:
            n = normalizar_nombre(propiedades.get(self.PROPIEDAD_RESPALDO))
            if n:
                nombres.add(n)
        return nombres

    def _leer_sink_inputs(self):
        """Devuelve [(indice, {nombres posibles}), ...] de cada flujo de audio."""
        res = self._pactl("list", "sink-inputs")
        if res.returncode != 0:
            return []

        interesantes = set(self.PROPIEDADES_NOMBRE) | {self.PROPIEDAD_RESPALDO}
        flujos = []
        indice = None
        propiedades = {}

        for linea in res.stdout.splitlines():
            cabecera = re.match(r"^Sink Input #(\d+)", linea.strip())
            if cabecera:
                if indice is not None:
                    flujos.append((indice, self._nombres_de(propiedades)))
                indice = int(cabecera.group(1))
                propiedades = {}
                continue

            # Las propiedades vienen indentadas como:   clave = "valor"
            prop = re.match(r'^\s+([a-z0-9_.-]+)\s*=\s*"(.*)"\s*$', linea)
            if prop and indice is not None and prop.group(1) in interesantes:
                propiedades[prop.group(1)] = prop.group(2)

        if indice is not None:
            flujos.append((indice, self._nombres_de(propiedades)))
        return [(i, n) for i, n in flujos if n]

    def listar(self):
        filas = [("maestro", "salida por defecto (@DEFAULT_SINK@)"),
                 ("microfono", "entrada por defecto (@DEFAULT_SOURCE@)")]
        for nombre in sorted(self._entradas):
            filas.append((nombre, "sink-input %s" %
                          ",".join(str(i) for i in self._entradas[nombre])))
        return filas

    # -- aplicacion ----------------------------------------------------------

    def _valor_crudo(self, volumen):
        """0.0-1.0 de posicion del slider -> el numero que entiende pactl.

        Fader lineal en dB: los mismos dB por milimetro en todo el recorrido.
        Ver el comentario de RANGO_DB_LINUX arriba, que explica de donde sale.
        """
        if volumen <= 0.0:
            return "0"                      # abajo del todo = silencio
        if RANGO_DB_LINUX <= 0.0:
            return str(int(round(volumen * self.VOLUMEN_NORMAL)))

        decibelios = (volumen - 1.0) * RANGO_DB_LINUX
        amplitud = 10.0 ** (decibelios / 20.0)
        # La raiz cubica deshace la curva cubica que PipeWire aplica por dentro.
        posicion = amplitud ** (1.0 / 3.0)
        return str(int(round(posicion * self.VOLUMEN_NORMAL)))

    def aplicar(self, objetivo, volumen, no_asignadas):
        obj = normalizar_nombre(objetivo)
        valor = self._valor_crudo(volumen)

        if obj == "maestro":
            return self._pactl("set-sink-volume", "@DEFAULT_SINK@", valor).returncode == 0

        if obj == "microfono":
            return self._pactl("set-source-volume", "@DEFAULT_SOURCE@", valor).returncode == 0

        if obj == "sistema":
            return False   # en PipeWire no existe una sesion "sonidos del sistema"

        if obj == "resto":
            return self._aplicar_indices(self._indices_de(no_asignadas), valor)

        return self._aplicar_indices(self._entradas.get(obj, []), valor)

    def _indices_de(self, nombres):
        """Indices de sink-input de varios nombres, SIN repetir.

        Hace falta deduplicar porque un mismo flujo aparece bajo varios nombres
        (Firefox esta como "firefox" y como "Firefox"). Sin esto, "resto" le
        mandaria a pactl el mismo sink-input tres veces por cada movimiento del
        slider.
        """
        indices = []
        for n in nombres:
            for i in self._entradas.get(n, []):
                if i not in indices:
                    indices.append(i)
        return indices

    def _aplicar_indices(self, indices, valor):
        hecho = False
        for i in indices:
            # Si el indice ya no existe (la app se acaba de cerrar), pactl
            # devuelve error y no pasa nada mas: el refresco periodico rehace
            # la lista entera cada pocos segundos.
            if self._pactl("set-sink-input-volume", str(i), valor).returncode == 0:
                hecho = True
        return hecho

    def apps_activas(self):
        return set(self._entradas.keys())


# =============================================================================
# PUERTO SERIE
# =============================================================================

def listar_puertos():
    return list(serial.tools.list_ports.comports())


def autodetectar_puerto():
    puertos = listar_puertos()
    for p in puertos:
        if (p.vid, p.pid) in VID_PID_CONOCIDOS:
            return p.device
    # Segundo intento: buscar por descripcion.
    for p in puertos:
        texto = "%s %s" % (p.description or "", p.manufacturer or "")
        if re.search(r"pro micro|leonardo|arduino|sparkfun", texto, re.I):
            return p.device
    return None


def abrir_serie(puerto):
    s = serial.Serial(puerto, BAUDIOS, timeout=1)
    time.sleep(0.3)          # el 32U4 reinicia al abrir el puerto
    s.reset_input_buffer()
    return s


# =============================================================================
# PROGRAMA PRINCIPAL
# =============================================================================

def crear_backend():
    sistema = platform.system()
    if sistema == "Windows":
        try:
            return BackendWindows()
        except ImportError:
            sys.exit("Faltan pycaw/comtypes/psutil. Ejecuta:  pip install -r requirements.txt")
    if sistema == "Linux":
        return BackendLinux()
    sys.exit("Sistema operativo no soportado: %s" % sistema)


def mostrar_listado(backend):
    print("Backend: %s\n" % backend.nombre)
    print("Objetivos disponibles ahora mismo:")
    print("-" * 60)
    for nombre, detalle in backend.listar():
        print("  %-28s %s" % (nombre, detalle))
    print("-" * 60)
    print("Copia el nombre que quieras dentro de SLIDER_MAP, arriba en este archivo.")
    print('Ademas siempre puedes usar: "maestro", "microfono", "resto".')


def bucle(backend, puerto, debug):
    ser = abrir_serie(puerto)
    print("Conectado a %s a %d baudios." % (puerto, BAUDIOS))
    print("Backend: %s" % backend.nombre)
    for i in sorted(SLIDER_MAP):
        print("  slider %d -> %s" % (i, ", ".join(SLIDER_MAP[i])))
    print("Ctrl+C para salir.\n")

    ultimos = [-9999] * NUM_SLIDERS      # ultimo valor CRUDO aplicado (0..1023)
    t_refresco = 0.0
    apps_previas = backend.apps_activas()
    explicitos = objetivos_explicitos()
    intocables = {normalizar_nombre(n) for n in EXCLUIDOS_DE_RESTO}

    while True:
        # Refresco periodico de la lista de aplicaciones sonando.
        ahora = time.time()
        if ahora - t_refresco >= INTERVALO_REFRESCO_S:
            try:
                backend.refrescar()
                apps = backend.apps_activas()
                if REAPLICAR_AL_CAMBIAR_APPS and apps != apps_previas:
                    # Olvidamos el ultimo valor aplicado para que el proximo
                    # envio del firmware (como mucho 1 s) vuelva a poner los
                    # cinco sliders, y la app recien aparecida coja su volumen.
                    ultimos = [-9999] * NUM_SLIDERS
                    if debug:
                        print("[info] cambio de apps sonando: %s"
                              % (", ".join(sorted(apps)) or "ninguna"))
                apps_previas = apps
            except Exception as e:
                print("[aviso] fallo al refrescar sesiones: %s" % e)
            t_refresco = ahora

        linea = ser.readline().decode("utf-8", errors="ignore").strip()
        if not linea:
            continue

        partes = linea.split("|")
        if len(partes) != NUM_SLIDERS:
            continue                      # linea partida o basura del arranque
        try:
            crudos = [int(p) for p in partes]
        except ValueError:
            continue
        if any(v < 0 or v > 1023 for v in crudos):
            continue

        # Las apps que no tiene asignadas ningun slider (para el objetivo
        # "resto"), quitando ademas las que no hay que tocar nunca.
        no_asignadas = backend.apps_activas() - explicitos - intocables

        for i, crudo in enumerate(crudos):
            destinos = SLIDER_MAP.get(i)
            if not destinos:
                continue

            # La zona muerta se mide sobre el recorrido del slider, no sobre el
            # volumen resultante: asi es uniforme a lo largo de todo el fader.
            if abs(crudo - ultimos[i]) < UMBRAL_CRUDO:
                continue
            ultimos[i] = crudo

            volumen = aplicar_curva(crudo / 1023.0)

            for destino in destinos:
                try:
                    ok = backend.aplicar(destino, volumen, no_asignadas)
                except Exception as e:
                    ok = False
                    if debug:
                        print("[error] slider %d -> %s: %s" % (i, destino, e))
                if debug:
                    print("slider %d -> %-12s %5.1f%%  %s"
                          % (i, destino, volumen * 100, "ok" if ok else "(no encontrado)"))


def main():
    ap = argparse.ArgumentParser(description="Mezclador de volumen por app para el StreamDeck DIY")
    ap.add_argument("--puerto", help="puerto serie (ej. COM5 o /dev/ttyACM0)")
    ap.add_argument("--puertos", action="store_true", help="listar puertos serie y salir")
    ap.add_argument("--listar", action="store_true", help="listar objetivos de audio y salir")
    ap.add_argument("--debug", action="store_true", help="mostrar cada cambio aplicado")
    args = ap.parse_args()

    if args.puertos:
        for p in listar_puertos():
            vid = "%04X" % p.vid if p.vid else "----"
            pid = "%04X" % p.pid if p.pid else "----"
            print("%-12s  VID:PID %s:%s  %s" % (p.device, vid, pid, p.description))
        return

    if args.listar:
        mostrar_listado(crear_backend())
        return

    # Una sola instancia: al arrancar solo con la sesion, es facil acabar con
    # dos copias (la del arranque automatico y una lanzada a mano). La segunda
    # no podria abrir el puerto serie y se quedaria reintentando de fondo.
    if not instancia_unica():
        print("Ya hay otro streamdeck_mixer en marcha. No arranco una segunda copia.")
        if platform.system() == "Windows":
            print("Para cerrarlo:  taskkill /IM pythonw3.12.exe /F")
            print("(el Python de la Microsoft Store se llama pythonw3.12.exe, no pythonw.exe)")
        else:
            print("Suele ser el servicio de systemd. Para pararlo:")
            print("  systemctl --user stop streamdeck-mixer.service")
        return

    backend = crear_backend()

    # Bucle de reconexion: si desenchufas el StreamDeck, el script espera y
    # vuelve a conectarse solo cuando lo enchufas otra vez.
    while True:
        puerto = args.puerto or PUERTO_SERIE or autodetectar_puerto()
        if not puerto:
            print("StreamDeck no encontrado. Reintentando en 3 s... "
                  "(usa --puertos para ver los puertos disponibles)")
            time.sleep(3)
            continue
        try:
            bucle(backend, puerto, args.debug)
        except KeyboardInterrupt:
            print("\nAdios.")
            return
        except serial.SerialException as e:
            print("Puerto perdido (%s). Reintentando en 3 s..." % e)
            time.sleep(3)


if __name__ == "__main__":
    main()
