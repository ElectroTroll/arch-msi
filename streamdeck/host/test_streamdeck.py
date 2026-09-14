#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===============================================================================
StreamDeck DIY - Comprobador de teclas y sliders
===============================================================================

Visor en vivo para el sketch de diagnostico
(firmware/TestStreamDeck/TestStreamDeck.ino).

Muestra:
  - La rejilla 4x3 con la funcion de cada tecla, cual esta pulsada ahora mismo
    y cuales ya has probado (para no dejarte ninguna).
  - Los 5 sliders con su barra, valor crudo, recorrido alcanzado y ruido.
  - Los avisos de posible ghosting que manda el firmware.

Uso:
    python test_streamdeck.py                # autodetecta el puerto
    python test_streamdeck.py --puerto COM5
    python test_streamdeck.py --crudo        # volcado de texto sin adornos

IMPORTANTE: cierra el Monitor Serie del Arduino IDE antes de ejecutarlo.
Solo un programa a la vez puede abrir el puerto.
===============================================================================
"""

import argparse
import os
import sys
import time

# Reutilizamos la deteccion de puerto del mezclador (misma carpeta).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import serial
    from streamdeck_mixer import autodetectar_puerto, listar_puertos, BAUDIOS
except ImportError:
    sys.exit("Falta pyserial. Instala las dependencias con:  pip install -r requirements.txt")


# --- Colores ANSI ------------------------------------------------------------
RESET   = "\033[0m"
NEGRITA = "\033[1m"
GRIS    = "\033[90m"
VERDE   = "\033[92m"
AMAR    = "\033[93m"
ROJO    = "\033[91m"
CIAN    = "\033[96m"
INVERSO = "\033[7m"

ANCHO_CELDA = 24          # ancho interior de cada casilla de la rejilla
ANCHO_BARRA = 28          # ancho de la barra de los sliders
MUESTRAS_RUIDO = 25       # cuantas lecturas se usan para estimar el ruido


def habilitar_ansi():
    """En Windows hace falta esto para que la consola entienda los colores."""
    if os.name == "nt":
        os.system("")


def limpiar():
    sys.stdout.write("\033[H\033[J")


def recortar(texto, ancho):
    return texto[:ancho] if len(texto) > ancho else texto.ljust(ancho)


class Estado:
    """Todo lo que sabemos del StreamDeck en este momento."""

    def __init__(self):
        self.filas = 4
        self.columnas = 3
        self.descripciones = {}       # indice -> texto
        self.nombres_slider = {}      # indice -> texto
        self.pulsada = {}             # indice -> bool
        self.veces = {}               # indice -> nº de pulsaciones
        self.sliders = {}             # indice -> (valor, min, max)
        self.historial = {}           # indice -> ultimas lecturas (para el ruido)
        self.avisos = []
        self.ultimo_evento = "-"

    # -- parseo de las lineas que manda el Arduino ---------------------------

    def procesar(self, linea):
        partes = linea.split("|")
        tipo = partes[0]

        if tipo == "MAPA" and len(partes) >= 5:
            i = int(partes[1])
            self.descripciones[i] = partes[4]
            self.pulsada.setdefault(i, False)
            self.veces.setdefault(i, 0)
            self.filas = max(self.filas, int(partes[2]) + 1)
            self.columnas = max(self.columnas, int(partes[3]) + 1)

        elif tipo == "MAPASLIDER" and len(partes) >= 3:
            self.nombres_slider[int(partes[1])] = partes[2]

        elif tipo == "TECLA" and len(partes) >= 6:
            i = int(partes[1])
            fila, col = int(partes[2]), int(partes[3])
            abajo = partes[4] == "1"
            self.descripciones.setdefault(i, partes[5])
            self.pulsada[i] = abajo
            if abajo:
                self.veces[i] = self.veces.get(i, 0) + 1
                self.ultimo_evento = ("tecla [%2d]  fila %d col %d  ->  %s"
                                      % (i, fila, col, partes[5]))

        elif tipo == "SLIDERS":
            valores = partes[1:]
            for s in range(len(valores) // 3):
                v, mn, mx = (int(valores[s * 3]), int(valores[s * 3 + 1]),
                             int(valores[s * 3 + 2]))
                self.sliders[s] = (v, mn, mx)
                h = self.historial.setdefault(s, [])
                h.append(v)
                if len(h) > MUESTRAS_RUIDO:
                    h.pop(0)

        elif tipo == "AVISO" and len(partes) >= 2:
            if not self.avisos or self.avisos[-1] != partes[1]:
                self.avisos.append(partes[1])
                self.avisos[:] = self.avisos[-3:]

    # -- dibujo --------------------------------------------------------------

    def dibujar(self, puerto):
        salida = []
        a = salida.append

        a("")
        a("  %sStreamDeck DIY - comprobacion de teclas y sliders%s   %s%s @ %d%s"
          % (NEGRITA, RESET, GRIS, puerto, BAUDIOS, RESET))
        a("")

        # ---- Rejilla de teclas --------------------------------------------
        probadas = sum(1 for v in self.veces.values() if v > 0)
        total = self.filas * self.columnas
        a("  %sTECLAS%s   %s(fondo claro = pulsada ahora,  [OK] = ya probada)%s   "
          "probadas: %s%d/%d%s"
          % (NEGRITA, RESET, GRIS, RESET,
             VERDE if probadas == total else AMAR, probadas, total, RESET))

        borde = "  +" + "+".join(["-" * ANCHO_CELDA] * self.columnas) + "+"
        a(borde)
        for f in range(self.filas):
            lineas = [[], [], []]
            for c in range(self.columnas):
                i = f * self.columnas + c
                desc = self.descripciones.get(i, "(sin descripcion)")
                n = self.veces.get(i, 0)
                marca = "[OK]" if n else "    "

                cab = recortar(" [%2d] F%dC%d" % (i, f, c), ANCHO_CELDA - 5) + marca + " "
                txt = recortar(" " + desc, ANCHO_CELDA)
                pie = recortar("  pulsaciones: %d" % n, ANCHO_CELDA)

                if self.pulsada.get(i):
                    color, fin = INVERSO + VERDE, RESET
                elif n:
                    color, fin = "", ""
                else:
                    color, fin = GRIS, RESET

                lineas[0].append(color + cab + fin)
                lineas[1].append(color + txt + fin)
                lineas[2].append(color + pie + fin)

            for l in lineas:
                a("  |" + "|".join(l) + "|")
            a(borde)

        # ---- Sliders -------------------------------------------------------
        a("")
        a("  %sSLIDERS%s   %s(mueve cada uno de tope a tope)%s"
          % (NEGRITA, RESET, GRIS, RESET))
        a("")
        for s in sorted(self.sliders):
            v, mn, mx = self.sliders[s]
            nombre = self.nombres_slider.get(s, "slider %d" % s)
            recorrido = mx - mn

            llenos = int(round(v / 1023.0 * ANCHO_BARRA))
            barra = "#" * llenos + "." * (ANCHO_BARRA - llenos)

            hist = self.historial.get(s, [])
            ruido = (max(hist) - min(hist)) if len(hist) >= 5 else 0

            # Un potenciometro sano llega casi a 0 y casi a 1023.
            if recorrido >= 1000:
                estado, color = "recorrido completo", VERDE
            elif recorrido >= 200:
                estado, color = "sigue moviendolo", AMAR
            else:
                estado, color = "sin mover / no llega", GRIS

            # Con el slider quieto, el ruido deberia ser de pocas unidades.
            if ruido > 12:
                nota_ruido = "%sruido %d (ALTO)%s" % (ROJO, ruido, RESET)
            else:
                nota_ruido = "%sruido %d%s" % (GRIS, ruido, RESET)

            a("   %d %-11s [%s] %4d  %3d%%   min %4d  max %4d   %s%-20s%s  %s"
              % (s, recortar(nombre, 11), barra, v, round(v / 1023.0 * 100),
                 mn, mx, color, estado, RESET, nota_ruido))

        # ---- Pie -----------------------------------------------------------
        a("")
        a("  %sUltimo evento:%s %s" % (CIAN, RESET, self.ultimo_evento))
        for av in self.avisos:
            a("  %s! %s%s" % (ROJO, av, RESET))
        a("")
        a("  %sCtrl+C para salir%s" % (GRIS, RESET))

        limpiar()
        sys.stdout.write("\n".join(salida) + "\n")
        sys.stdout.flush()


def modo_crudo(ser):
    print("Volcado en crudo. Ctrl+C para salir.\n")
    while True:
        linea = ser.readline().decode("utf-8", errors="ignore").rstrip()
        if linea:
            print(linea)


def main():
    ap = argparse.ArgumentParser(
        description="Comprobador de teclas y sliders del StreamDeck DIY")
    ap.add_argument("--puerto", help="puerto serie (ej. COM5 o /dev/ttyACM0)")
    ap.add_argument("--puertos", action="store_true", help="listar puertos y salir")
    ap.add_argument("--crudo", action="store_true",
                    help="mostrar las lineas tal cual, sin interfaz")
    args = ap.parse_args()

    if args.puertos:
        for p in listar_puertos():
            print("%-12s  %s" % (p.device, p.description))
        return

    puerto = args.puerto or autodetectar_puerto()
    if not puerto:
        sys.exit("No encuentro el StreamDeck. Usa --puertos para ver los "
                 "disponibles y --puerto para forzar uno.\n"
                 "Recuerda cerrar el Monitor Serie del Arduino IDE.")

    try:
        ser = serial.Serial(puerto, BAUDIOS, timeout=0.1)
    except serial.SerialException as e:
        sys.exit("No se puede abrir %s: %s\n"
                 "Lo mas probable: el Monitor Serie del Arduino IDE esta abierto."
                 % (puerto, e))

    time.sleep(0.4)          # el 32U4 se reinicia al abrir el puerto
    ser.reset_input_buffer()
    ser.write(b"h\n")        # pide el mapa de teclas

    habilitar_ansi()
    estado = Estado()
    ultimo_dibujo = 0.0

    try:
        if args.crudo:
            modo_crudo(ser)
            return

        while True:
            linea = ser.readline().decode("utf-8", errors="ignore").strip()
            if linea and not linea.startswith("INFO|"):
                try:
                    estado.procesar(linea)
                except (ValueError, IndexError):
                    pass          # linea partida durante el arranque

            ahora = time.time()
            if ahora - ultimo_dibujo >= 0.05:     # ~20 fps
                estado.dibujar(puerto)
                ultimo_dibujo = ahora

    except KeyboardInterrupt:
        print("\nAdios.")
    finally:
        ser.close()


if __name__ == "__main__":
    main()
