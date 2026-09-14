/*
  ===========================================================================
  StreamDeck DIY - Firmware para SparkFun Pro Micro (ATmega32U4)
  ===========================================================================

  Hardware:
    - SparkFun Pro Micro 5V / 16 MHz (compatible Arduino Leonardo, USB HID nativo)
    - Matriz de 4 filas x 3 columnas = 12 switches mecanicos (Holy Panda)
    - Un diodo 1N4148 por switch (anti-ghosting), orientacion COLUMNA -> FILA
    - 5 potenciometros deslizantes (sliders) lineales de 10K

  Que hace:
    1) BOTONES -> teclado USB HID puro (teclas normales, combinaciones y
       teclas multimedia). No necesita ningun software en el PC.
    2) SLIDERS -> se envian por puerto serie (USB CDC) como texto plano:
                    "v0|v1|v2|v3|v4\n"   (valores 0..1023)
       El script de Python del PC (host/streamdeck_mixer.py) los lee y
       ajusta el volumen POR APLICACION via Core Audio (Windows) o
       PipeWire/PulseAudio (Arch Linux).

  Librerias necesarias (Gestor de librerias de Arduino IDE):
    - "HID-Project" de NicoHood  (proporciona Keyboard + Consumer multimedia)

  Placa a seleccionar en Arduino IDE:
    - "SparkFun Pro Micro" (paquete SparkFun AVR Boards), Processor = ATmega32U4 (5V, 16MHz)
    - Alternativa valida si no instalas el paquete SparkFun: "Arduino Leonardo"

  ---------------------------------------------------------------------------
  IMPORTANTE - Los pines de abajo son una propuesta. Ajustalos a tu cableado
  real: solo hay que tocar el bloque "CONFIGURACION DE PINES".
  ---------------------------------------------------------------------------
*/

#include <HID-Project.h>

// ===========================================================================
// CONFIGURACION DE PINES
// ===========================================================================
//
// Pines disponibles en el Pro Micro: 2 3 4 5 6 7 8 9 10 14 15 16 18 19 20 21
// Pines con entrada analogica: 18(A0) 19(A1) 20(A2) 21(A3) 4(A6) 6(A7) 8(A8) 9(A9) 10(A10)
//
// MATRIZ DE BOTONES (4 filas x 3 columnas)
// CONFIRMADO con el hardware real (2026-08-30).
//
//              COL0(4)   COL1(3)   COL2(2)
//   FILA0(8)    [ 0 ]     [ 1 ]     [ 2 ]     mute micro / mute altavoces / camara
//   FILA1(7)    [ 3 ]     [ 4 ]     [ 5 ]     Fn custom / grabar OBS / Fn custom
//   FILA2(6)    [ 6 ]     [ 7 ]     [ 8 ]     Fn custom x3
//   FILA3(5)    [ 9 ]     [10 ]     [11 ]     anterior / play-pausa / siguiente

const uint8_t PINES_FILA[]    = { 8, 7, 6, 5 };
const uint8_t PINES_COLUMNA[] = { 4, 3, 2 };

const uint8_t NUM_FILAS    = sizeof(PINES_FILA);
const uint8_t NUM_COLUMNAS = sizeof(PINES_COLUMNA);
const uint8_t NUM_TECLAS   = NUM_FILAS * NUM_COLUMNAS;

// ---------------------------------------------------------------------------
// SENTIDO DE LOS DIODOS
// ---------------------------------------------------------------------------
// Al escanear, una linea se pone a OUTPUT LOW y las otras se leen con pull-up.
// La corriente va SIEMPRE de la linea leida (arriba) hacia la linea puesta a
// LOW (abajo), asi que el diodo tiene que dejar pasar en ese sentido: anodo en
// la linea leida, catodo (la BANDA) en la linea que ponemos a LOW.
//
//   false -> banda hacia la FILA     (montaje habitual: columna --|>|-- fila)
//            Se ponen a LOW las FILAS y se leen las COLUMNAS.
//
//   true  -> banda hacia la COLUMNA  (ESTE StreamDeck: fila --|>|-- columna)
//            Se ponen a LOW las COLUMNAS y se leen las FILAS.
//
// Si te equivocas de sentido no se rompe nada: simplemente no responde
// ninguna tecla, porque los diodos bloquean.
const bool DIODOS_HACIA_LA_COLUMNA = true;

// Segun lo anterior, quien manda (se pone a LOW) y quien se lee.
const uint8_t* const PINES_ACTIVOS = DIODOS_HACIA_LA_COLUMNA ? PINES_COLUMNA : PINES_FILA;
const uint8_t        NUM_ACTIVOS   = DIODOS_HACIA_LA_COLUMNA ? NUM_COLUMNAS  : NUM_FILAS;
const uint8_t* const PINES_LEIDOS  = DIODOS_HACIA_LA_COLUMNA ? PINES_FILA    : PINES_COLUMNA;
const uint8_t        NUM_LEIDOS    = DIODOS_HACIA_LA_COLUMNA ? NUM_FILAS     : NUM_COLUMNAS;

// SLIDERS (5 potenciometros de 10K)
//   Extremo 1 del potenciometro -> GND
//   Extremo 2 del potenciometro -> VCC
//   Cursor (pin central)        -> pin analogico
//
//   slider 0 (A0) -> volumen MAESTRO
//   slider 1 (A1) -> volumen NAVEGADOR
//   slider 2 (A2) -> volumen SPOTIFY
//   slider 3 (A3) -> volumen JUEGOS
//   slider 4 (A6) -> volumen DISCORD
//
// (Quien controla cada uno se decide en el PC, en SLIDER_MAP de
//  host/streamdeck_mixer.py; el firmware solo manda los 5 numeros en orden.)
// CONFIRMADO con el hardware real (2026-08-30).
const uint8_t PINES_SLIDER[] = { A0, A1, A2, A3, A10 };
//                                18  19  20  21   10    <- pin fisico equivalente
const uint8_t NUM_SLIDERS = sizeof(PINES_SLIDER);

// OJO: el pin 10 es A10. No lo uses tambien para la matriz o el slider 4
// arrastrara esa linea y el escaneo creera que hay teclas pulsadas.

// Pon "true" si un slider va al reves (arriba = volumen bajo). Suele pasar
// cuando en ese potenciometro estan intercambiados GND y VCC.
const bool SLIDER_INVERTIDO[5] = { false, false, false, false, false };


// ===========================================================================
// PARAMETROS DE COMPORTAMIENTO
// ===========================================================================

const uint16_t DEBOUNCE_MS            = 8;    // antirrebote de los switches
const uint16_t REPETICION_ESPERA_MS   = 400;  // tiempo pulsado antes de repetir
const uint16_t REPETICION_CADENCIA_MS = 110;  // intervalo entre repeticiones

const uint16_t SUAVIZADO_SLIDER   = 8;     // media movil exponencial (mas alto = mas suave)
const uint8_t  UMBRAL_SLIDER      = 4;     // cambio minimo (0..1023) para enviar
const uint16_t INTERVALO_ENVIO_MS = 20;    // no enviar mas rapido que esto
const uint16_t LATIDO_MS          = 1000;  // reenviar todo cada X ms (resincroniza el PC)

const uint32_t BAUDIOS = 115200;


// ===========================================================================
// TABLA DE MAPEO DE TECLAS
// ===========================================================================
//
// Para cambiar que hace cada boton solo hay que editar el array MAPA.
// El indice va por filas: 0..2 = fila 0, 3..5 = fila 1,
//                         6..8 = fila 2, 9..11 = fila 3.

// Mascaras de modificadores (se combinan con |)
#define MOD_NINGUNO 0x00
#define MOD_CTRL    0x01
#define MOD_SHIFT   0x02
#define MOD_ALT     0x04
#define MOD_GUI     0x08   // tecla Windows / Super

enum TipoAccion : uint8_t {
  ACCION_NINGUNA,     // boton desactivado
  ACCION_TECLA,       // tecla de teclado normal (con modificadores opcionales)
  ACCION_MULTIMEDIA   // tecla de consumo: play/pausa, volumen, pista...
};

struct Accion {
  TipoAccion  tipo;
  uint8_t     modificadores;  // solo para ACCION_TECLA
  uint16_t    codigo;         // KeyboardKeycode (KEY_*) o ConsumerKeycode (MEDIA_*)
  bool        repite;         // true = mantener pulsado repite la tecla
  const char* descripcion;    // documentacion, no se usa en ejecucion
};

// ---------------------------------------------------------------------------
// Por que F13..F24 para OBS: son teclas que existen en el estandar HID pero
// que ningun teclado fisico normal tiene, asi que nunca chocan con atajos del
// sistema ni de otros programas. OBS las acepta en Windows y en Linux.
// ---------------------------------------------------------------------------

const Accion MAPA[NUM_TECLAS] = {
  // ---- FILA 0 : SILENCIOS Y CAMARA ---------------------------------------
  /* [0]  F0C0 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F13,           false, "Mute MICROFONO (hotkey de OBS)" },
  /* [1]  F0C1 */ { ACCION_MULTIMEDIA, MOD_NINGUNO, MEDIA_VOLUME_MUTE, false, "Mute ALTAVOCES (volumen del sistema)" },
  /* [2]  F0C2 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F14,           false, "Activar/Desactivar CAMARA (hotkey de OBS)" },

  // ---- FILA 1 : GRABACION + CUSTOM ---------------------------------------
  /* [3]  F1C0 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F17,           false, "Fn custom 1" },
  /* [4]  F1C1 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F15,           false, "OBS: Iniciar/Parar GRABACION" },
  /* [5]  F1C2 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F18,           false, "Fn custom 2" },

  // ---- FILA 2 : TODO CUSTOM ----------------------------------------------
  /* [6]  F2C0 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F19,           false, "Fn custom 3" },
  /* [7]  F2C1 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F20,           false, "Fn custom 4" },
  /* [8]  F2C2 */ { ACCION_TECLA,      MOD_NINGUNO, KEY_F21,           false, "Fn custom 5" },

  // ---- FILA 3 : MULTIMEDIA -----------------------------------------------
  /* [9]  F3C0 */ { ACCION_MULTIMEDIA, MOD_NINGUNO, MEDIA_PREVIOUS,    false, "Cancion anterior" },
  /* [10] F3C1 */ { ACCION_MULTIMEDIA, MOD_NINGUNO, MEDIA_PLAY_PAUSE,  false, "Pausa / Reanudar" },
  /* [11] F3C2 */ { ACCION_MULTIMEDIA, MOD_NINGUNO, MEDIA_NEXT,        false, "Cancion siguiente" },
};

/*
  LAS 5 TECLAS "Fn CUSTOM" mandan F17, F18, F19, F20 y F21.
  No hacen nada por si solas: son teclas libres que asignas donde quieras.
    - En OBS: Ajustes -> Atajos de teclado (escenas, transiciones, etc.)
    - En Windows: propiedades de un acceso directo -> "Tecla de método abreviado",
      o cualquier lanzador tipo AutoHotkey.
    - En Hyprland: bind = , F17, exec, <lo que sea>
  Si prefieres que una de ellas envie directamente una combinacion, cambia su
  linea por una ACCION_TECLA con modificadores (ver ejemplos de abajo).

  ---------------------------------------------------------------------------
  EJEMPLOS PARA REASIGNAR (copia la linea sobre la que quieras cambiar):

    Mute del microfono a nivel de SISTEMA en vez de solo en OBS:
      (no existe una tecla HID estandar para esto; lo mas fiable es dejar F13
       y asignarlo tambien en el SO: en Hyprland con `wpctl set-mute
       @DEFAULT_AUDIO_SOURCE@ toggle`, en Windows con AutoHotkey)
    OBS iniciar/parar directo:
      { ACCION_TECLA, MOD_NINGUNO, KEY_F16, false, "OBS: Iniciar/Parar STREAM" },
    OBS cambiar de escena:
      { ACCION_TECLA, MOD_NINGUNO, KEY_F22, false, "OBS: Escena 1" },
    Subir volumen manteniendo pulsado:
      { ACCION_MULTIMEDIA, MOD_NINGUNO, MEDIA_VOLUME_UP, true, "Volumen +" },
    Abrir explorador de archivos (Win+E):
      { ACCION_TECLA, MOD_GUI, KEY_E, false, "Abrir explorador" },
    Alt+Tab:
      { ACCION_TECLA, MOD_ALT, KEY_TAB, false, "Cambiar ventana" },
    Guardar (Ctrl+S):
      { ACCION_TECLA, MOD_CTRL, KEY_S, false, "Guardar" },
    Recorte de pantalla de Windows (Win+Shift+S):
      { ACCION_TECLA, MOD_GUI | MOD_SHIFT, KEY_S, false, "Recorte de pantalla" },
    Desactivar un boton:
      { ACCION_NINGUNA, MOD_NINGUNO, 0, false, "libre" },

  Teclas multimedia disponibles en HID-Project:
    MEDIA_PLAY_PAUSE, MEDIA_STOP, MEDIA_NEXT, MEDIA_PREVIOUS,
    MEDIA_VOLUME_UP, MEDIA_VOLUME_DOWN, MEDIA_VOLUME_MUTE
  (Si alguno no compila, abre Consumer.h de la libreria: existen alias tipo
   MEDIA_VOL_UP o HID_CONSUMER_VOLUME_INCREMENT.)
*/


// ===========================================================================
// ESTADO INTERNO
// ===========================================================================

struct EstadoTecla {
  bool     lecturaPrevia;      // ultima lectura cruda del pin
  bool     estable;            // estado ya filtrado por el antirrebote
  uint32_t tCambio;            // instante del ultimo cambio de lectura cruda
  uint32_t tPulsacion;         // instante en que paso a pulsada (para repeticion)
  uint32_t tUltimaRepeticion;
};

EstadoTecla teclas[NUM_TECLAS];

int32_t  sliderAcumulado[5];   // acumulador del filtro (valor x SUAVIZADO_SLIDER)
int32_t  sliderFiltrado[5];    // valor suavizado actual, ya en 0..1023
int32_t  sliderEnviado[5];     // ultimo valor mandado por serie
uint32_t tUltimoEnvio  = 0;
uint32_t tUltimoLatido = 0;


// Declaracion adelantada (setup la usa antes de definirla)
int32_t leerSliderCrudo(uint8_t s);


// ===========================================================================
// SETUP
// ===========================================================================

void setup() {
  // --- Matriz -------------------------------------------------------------
  // Las lineas activas quedan en alta impedancia (INPUT) en reposo y solo
  // pasan a OUTPUT LOW durante el instante en que se escanean. Asi, aunque
  // hubiera un fallo de cableado, nunca se cortocircuitan dos salidas.
  for (uint8_t a = 0; a < NUM_ACTIVOS; a++) {
    pinMode(PINES_ACTIVOS[a], INPUT);
  }
  for (uint8_t l = 0; l < NUM_LEIDOS; l++) {
    pinMode(PINES_LEIDOS[l], INPUT_PULLUP);
  }

  for (uint8_t i = 0; i < NUM_TECLAS; i++) {
    teclas[i].lecturaPrevia     = false;
    teclas[i].estable           = false;
    teclas[i].tCambio           = 0;
    teclas[i].tPulsacion        = 0;
    teclas[i].tUltimaRepeticion = 0;
  }

  // --- Sliders ------------------------------------------------------------
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    pinMode(PINES_SLIDER[s], INPUT);
    // Primera lectura para arrancar el filtro en el valor real y no en 0
    // (si no, al enchufar el USB todos los volumenes darian un salto).
    sliderFiltrado[s]  = leerSliderCrudo(s);
    sliderAcumulado[s] = sliderFiltrado[s] * (int32_t)SUAVIZADO_SLIDER;
    sliderEnviado[s]   = -1000;  // fuerza el primer envio
  }

  // --- USB ----------------------------------------------------------------
  Keyboard.begin();
  Consumer.begin();
  Serial.begin(BAUDIOS);
}


// ===========================================================================
// LOOP PRINCIPAL
// ===========================================================================

void loop() {
  const uint32_t ahora = millis();
  escanearMatriz(ahora);
  procesarSliders(ahora);
}


// ===========================================================================
// MATRIZ DE BOTONES
// ===========================================================================

void escanearMatriz(uint32_t ahora) {
  for (uint8_t a = 0; a < NUM_ACTIVOS; a++) {

    // Activamos una linea: OUTPUT en LOW.
    pinMode(PINES_ACTIVOS[a], OUTPUT);
    digitalWrite(PINES_ACTIVOS[a], LOW);
    delayMicroseconds(5);   // deja que se estabilicen las lineas

    for (uint8_t l = 0; l < NUM_LEIDOS; l++) {
      // Linea leida con pull-up: LOW = tecla pulsada.
      const bool lectura = (digitalRead(PINES_LEIDOS[l]) == LOW);

      // Traducimos (activa, leida) a (fila, columna) segun el sentido de los
      // diodos, para que el indice del MAPA sea siempre fila*columnas+columna
      // y la tabla de teclas no dependa del cableado.
      const uint8_t fila    = DIODOS_HACIA_LA_COLUMNA ? l : a;
      const uint8_t columna = DIODOS_HACIA_LA_COLUMNA ? a : l;
      actualizarTecla(fila * NUM_COLUMNAS + columna, lectura, ahora);
    }

    // Devolvemos la linea a alta impedancia.
    pinMode(PINES_ACTIVOS[a], INPUT);
  }
}

void actualizarTecla(uint8_t i, bool lectura, uint32_t ahora) {
  EstadoTecla& t = teclas[i];

  // --- Antirrebote --------------------------------------------------------
  // La lectura cruda debe mantenerse igual durante DEBOUNCE_MS para que el
  // estado "estable" cambie.
  if (lectura != t.lecturaPrevia) {
    t.lecturaPrevia = lectura;
    t.tCambio = ahora;
    return;
  }

  if ((ahora - t.tCambio) >= DEBOUNCE_MS && lectura != t.estable) {
    t.estable = lectura;
    if (t.estable) {
      pulsar(MAPA[i]);
      t.tPulsacion        = ahora;
      t.tUltimaRepeticion = ahora;
    } else {
      soltar(MAPA[i]);
    }
    return;
  }

  // --- Repeticion mientras se mantiene pulsada ----------------------------
  if (t.estable && MAPA[i].repite) {
    if ((ahora - t.tPulsacion) >= REPETICION_ESPERA_MS &&
        (ahora - t.tUltimaRepeticion) >= REPETICION_CADENCIA_MS) {
      repetir(MAPA[i]);
      t.tUltimaRepeticion = ahora;
    }
  }
}

void pulsar(const Accion& a) {
  if (a.tipo == ACCION_TECLA) {
    if (a.modificadores & MOD_CTRL)  Keyboard.press(KEY_LEFT_CTRL);
    if (a.modificadores & MOD_SHIFT) Keyboard.press(KEY_LEFT_SHIFT);
    if (a.modificadores & MOD_ALT)   Keyboard.press(KEY_LEFT_ALT);
    if (a.modificadores & MOD_GUI)   Keyboard.press(KEY_LEFT_GUI);
    Keyboard.press((KeyboardKeycode)a.codigo);
  }
  else if (a.tipo == ACCION_MULTIMEDIA) {
    // Consumer.write() = pulsar y soltar de golpe, que es lo correcto aqui.
    Consumer.write((ConsumerKeycode)a.codigo);
  }
}

void soltar(const Accion& a) {
  if (a.tipo == ACCION_TECLA) {
    Keyboard.release((KeyboardKeycode)a.codigo);
    if (a.modificadores & MOD_GUI)   Keyboard.release(KEY_LEFT_GUI);
    if (a.modificadores & MOD_ALT)   Keyboard.release(KEY_LEFT_ALT);
    if (a.modificadores & MOD_SHIFT) Keyboard.release(KEY_LEFT_SHIFT);
    if (a.modificadores & MOD_CTRL)  Keyboard.release(KEY_LEFT_CTRL);
  }
  // Las multimedia ya se soltaron solas dentro de pulsar().
}

void repetir(const Accion& a) {
  if (a.tipo == ACCION_TECLA) {
    // Soltamos y volvemos a pulsar solo la tecla; los modificadores siguen puestos.
    Keyboard.release((KeyboardKeycode)a.codigo);
    Keyboard.press((KeyboardKeycode)a.codigo);
  }
  else if (a.tipo == ACCION_MULTIMEDIA) {
    Consumer.write((ConsumerKeycode)a.codigo);
  }
}


// ===========================================================================
// SLIDERS
// ===========================================================================

int32_t leerSliderCrudo(uint8_t s) {
  int32_t v = analogRead(PINES_SLIDER[s]);
  if (SLIDER_INVERTIDO[s]) v = 1023 - v;
  return v;
}

void procesarSliders(uint32_t ahora) {
  // 1) Leer y suavizar SIEMPRE.
  //
  //    Media movil exponencial con ACUMULADOR. Es importante hacerlo asi y no
  //    con la formula ingenua "filtrado += (crudo - filtrado) / SUAVIZADO":
  //    con division entera, mientras la diferencia sea menor que SUAVIZADO el
  //    resultado de la division es 0 y el filtro SE QUEDA CONGELADO. Eso crea
  //    una zona muerta de +-SUAVIZADO cuentas (~0.8% del recorrido) en la que
  //    mover el slider despacio no hace absolutamente nada, y luego salta de
  //    golpe. Era justo lo que impedia ajustar con precision.
  //
  //    Guardando el acumulador (valor x SUAVIZADO) no se pierden los restos,
  //    y el filtro responde a cualquier movimiento por pequenio que sea.
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    const int32_t crudo = leerSliderCrudo(s);

    sliderAcumulado[s] += crudo - (sliderAcumulado[s] / (int32_t)SUAVIZADO_SLIDER);
    sliderFiltrado[s]   = sliderAcumulado[s] / (int32_t)SUAVIZADO_SLIDER;

    // Forzamos los topes para poder llegar a 0 y a 1023 limpios (silencio
    // total y volumen maximo) aunque el potenciometro no llegue del todo.
    if (crudo <= 2) {
      sliderFiltrado[s]  = 0;
      sliderAcumulado[s] = 0;
    }
    if (crudo >= 1021) {
      sliderFiltrado[s]  = 1023;
      sliderAcumulado[s] = 1023 * (int32_t)SUAVIZADO_SLIDER;
    }
  }

  // 2) Limitar la frecuencia de envio.
  if ((ahora - tUltimoEnvio) < INTERVALO_ENVIO_MS) return;

  // 3) Enviar solo si algo ha cambiado lo suficiente, o si toca el "latido"
  //    (reenvio periodico para que el PC se resincronice si acaba de arrancar
  //    el script o si una app de audio se ha abierto despues).
  bool hayCambio = false;
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    if (abs(sliderFiltrado[s] - sliderEnviado[s]) >= (int32_t)UMBRAL_SLIDER) {
      hayCambio = true;
      break;
    }
  }
  const bool tocaLatido = (ahora - tUltimoLatido) >= LATIDO_MS;
  if (!hayCambio && !tocaLatido) return;

  // 4) Formato de salida: "v0|v1|v2|v3|v4\n"
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    Serial.print(sliderFiltrado[s]);
    if (s < NUM_SLIDERS - 1) Serial.print('|');
    sliderEnviado[s] = sliderFiltrado[s];
  }
  Serial.print('\n');

  tUltimoEnvio = ahora;
  if (tocaLatido) tUltimoLatido = ahora;
}
