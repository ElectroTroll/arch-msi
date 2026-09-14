/*
  ===========================================================================
  StreamDeck DIY - SKETCH DE DIAGNOSTICO
  ===========================================================================

  Sirve para comprobar el cableado y el mapeo ANTES de usar el firmware real:

    - Dice que tecla se ha pulsado, con su indice, fila, columna y la funcion
      que tendra asignada en el firmware definitivo.
    - Muestra los 5 sliders en crudo (0..1023), con el minimo y el maximo que
      han alcanzado y el ruido que tienen.
    - Avisa si detecta un patron tipico de ghosting (diodo mal puesto).

  IMPORTANTE: este sketch NO se presenta como teclado. No manda ninguna tecla
  al PC. Asi, si hay un switch en corto o un diodo al reves, no se te llena la
  pantalla de pulsaciones ni se te disparan atajos.

  Como se usa:
    A) Facil: Arduino IDE -> Herramientas -> Monitor Serie, a 115200 baudios.
       Se lee perfectamente tal cual.
    B) Bonito: cierra el Monitor Serie y ejecuta
         python host/test_streamdeck.py
       Muestra la rejilla 4x3 y las barras de los sliders en vivo.

  Comandos que puedes escribir en el Monitor Serie (y pulsar Enter):
    h -> vuelve a imprimir el mapa de teclas
    r -> reinicia las estadisticas (min/max) de los sliders

  ---------------------------------------------------------------------------
  LOS PINES DE ABAJO DEBEN SER LOS MISMOS QUE EN StreamDeckDIY.ino.
  Si cambias unos, cambia los otros.
  ---------------------------------------------------------------------------
*/

// ===========================================================================
// CONFIGURACION DE PINES  (copia exacta del firmware real)
// ===========================================================================
//
//              COL0(4)   COL1(3)   COL2(2)
//   FILA0(8)    [ 0 ]     [ 1 ]     [ 2 ]
//   FILA1(7)    [ 3 ]     [ 4 ]     [ 5 ]
//   FILA2(6)    [ 6 ]     [ 7 ]     [ 8 ]
//   FILA3(5)    [ 9 ]     [10 ]     [11 ]

const uint8_t PINES_FILA[]    = { 8, 7, 6, 5 };
const uint8_t PINES_COLUMNA[] = { 4, 3, 2 };

const uint8_t NUM_FILAS    = sizeof(PINES_FILA);
const uint8_t NUM_COLUMNAS = sizeof(PINES_COLUMNA);
const uint8_t NUM_TECLAS   = NUM_FILAS * NUM_COLUMNAS;

// Sentido de los diodos: en este StreamDeck la corriente va de la FILA hacia
// la COLUMNA, asi que hay que poner a LOW las COLUMNAS y leer las FILAS.
// (Ver la explicacion larga en StreamDeckDIY.ino.)
const bool DIODOS_HACIA_LA_COLUMNA = true;

const uint8_t* const PINES_ACTIVOS = DIODOS_HACIA_LA_COLUMNA ? PINES_COLUMNA : PINES_FILA;
const uint8_t        NUM_ACTIVOS   = DIODOS_HACIA_LA_COLUMNA ? NUM_COLUMNAS  : NUM_FILAS;
const uint8_t* const PINES_LEIDOS  = DIODOS_HACIA_LA_COLUMNA ? PINES_FILA    : PINES_COLUMNA;
const uint8_t        NUM_LEIDOS    = DIODOS_HACIA_LA_COLUMNA ? NUM_FILAS     : NUM_COLUMNAS;

// CONFIRMADO con el hardware real (2026-08-30): 18, 19, 20, 21 y 10.
const uint8_t PINES_SLIDER[] = { A0, A1, A2, A3, A10 };
const uint8_t NUM_SLIDERS = sizeof(PINES_SLIDER);

const uint16_t DEBOUNCE_MS       = 8;
const uint16_t INTERVALO_ENVIO_MS = 100;   // refresco de los sliders
const uint32_t BAUDIOS           = 115200;


// ===========================================================================
// QUE FUNCION TENDRA CADA TECLA EN EL FIRMWARE REAL
// ===========================================================================
// Solo es texto informativo. Si cambias el MAPA del firmware real, cambia
// tambien estas descripciones para que el diagnostico no te enganie.

const char* const DESCRIPCIONES[NUM_TECLAS] = {
  "Mute MICROFONO (F13 -> OBS)",       // [0]  F0C0
  "Mute ALTAVOCES (multimedia)",       // [1]  F0C1
  "Camara ON/OFF (F14 -> OBS)",        // [2]  F0C2

  "Fn custom 1 (F17)",                 // [3]  F1C0
  "GRABAR OBS (F15)",                  // [4]  F1C1
  "Fn custom 2 (F18)",                 // [5]  F1C2

  "Fn custom 3 (F19)",                 // [6]  F2C0
  "Fn custom 4 (F20)",                 // [7]  F2C1
  "Fn custom 5 (F21)",                 // [8]  F2C2

  "Cancion ANTERIOR",                  // [9]  F3C0
  "PAUSA / Reanudar",                  // [10] F3C1
  "Cancion SIGUIENTE",                 // [11] F3C2
};

const char* const NOMBRES_SLIDER[NUM_SLIDERS] = {
  "Maestro", "Navegador", "Spotify", "Juegos", "Discord"
};


// ===========================================================================
// ESTADO
// ===========================================================================

struct EstadoTecla {
  bool     lecturaPrevia;
  bool     estable;
  uint32_t tCambio;
};

EstadoTecla teclas[NUM_TECLAS];

int32_t  sliderMin[8];
int32_t  sliderMax[8];
uint32_t tUltimoEnvio = 0;


void setup() {
  for (uint8_t a = 0; a < NUM_ACTIVOS; a++) pinMode(PINES_ACTIVOS[a], INPUT);
  for (uint8_t l = 0; l < NUM_LEIDOS; l++)  pinMode(PINES_LEIDOS[l], INPUT_PULLUP);
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) pinMode(PINES_SLIDER[s], INPUT);

  for (uint8_t i = 0; i < NUM_TECLAS; i++) {
    teclas[i].lecturaPrevia = false;
    teclas[i].estable       = false;
    teclas[i].tCambio       = 0;
  }
  reiniciarEstadisticas();

  Serial.begin(BAUDIOS);
  while (!Serial && millis() < 4000) { /* espera al PC, pero no eternamente */ }
  imprimirCabecera();
}


void loop() {
  const uint32_t ahora = millis();
  atenderComandos();
  escanearMatriz(ahora);
  informarSliders(ahora);
}


// ===========================================================================
// CABECERA / MAPA
// ===========================================================================

void imprimirCabecera() {
  Serial.println(F("INFO|==================================================="));
  Serial.println(F("INFO|StreamDeck DIY - MODO DIAGNOSTICO (no manda teclas)"));
  Serial.println(F("INFO|==================================================="));
  Serial.print(F("INFO|Matriz: "));
  Serial.print(NUM_FILAS);
  Serial.print(F(" filas x "));
  Serial.print(NUM_COLUMNAS);
  Serial.println(F(" columnas"));
  Serial.println(F("INFO|Pulsa una tecla o mueve un slider. Comandos: h = mapa, r = reiniciar min/max"));
  Serial.println(F("INFO|---------------------------------------------------"));

  for (uint8_t i = 0; i < NUM_TECLAS; i++) {
    Serial.print(F("MAPA|"));
    Serial.print(i);                          Serial.print('|');
    Serial.print(i / NUM_COLUMNAS);           Serial.print('|');
    Serial.print(i % NUM_COLUMNAS);           Serial.print('|');
    Serial.println(DESCRIPCIONES[i]);
  }
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    Serial.print(F("MAPASLIDER|"));
    Serial.print(s);                          Serial.print('|');
    Serial.println(NOMBRES_SLIDER[s]);
  }
  Serial.println(F("INFO|---------------------------------------------------"));
}

void atenderComandos() {
  while (Serial.available()) {
    const char c = Serial.read();
    if (c == 'h' || c == 'H') imprimirCabecera();
    if (c == 'r' || c == 'R') {
      reiniciarEstadisticas();
      Serial.println(F("INFO|Estadisticas de los sliders reiniciadas."));
    }
  }
}

void reiniciarEstadisticas() {
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    sliderMin[s] = 1023;
    sliderMax[s] = 0;
  }
}


// ===========================================================================
// MATRIZ
// ===========================================================================

void escanearMatriz(uint32_t ahora) {
  for (uint8_t a = 0; a < NUM_ACTIVOS; a++) {
    pinMode(PINES_ACTIVOS[a], OUTPUT);
    digitalWrite(PINES_ACTIVOS[a], LOW);
    delayMicroseconds(5);

    for (uint8_t l = 0; l < NUM_LEIDOS; l++) {
      const bool lectura = (digitalRead(PINES_LEIDOS[l]) == LOW);
      const uint8_t fila    = DIODOS_HACIA_LA_COLUMNA ? l : a;
      const uint8_t columna = DIODOS_HACIA_LA_COLUMNA ? a : l;
      actualizarTecla(fila * NUM_COLUMNAS + columna, fila, columna, lectura, ahora);
    }

    pinMode(PINES_ACTIVOS[a], INPUT);
  }
}

void actualizarTecla(uint8_t i, uint8_t fila, uint8_t col, bool lectura, uint32_t ahora) {
  EstadoTecla& t = teclas[i];

  if (lectura != t.lecturaPrevia) {
    t.lecturaPrevia = lectura;
    t.tCambio = ahora;
    return;
  }

  if ((ahora - t.tCambio) >= DEBOUNCE_MS && lectura != t.estable) {
    t.estable = lectura;

    // Formato:  TECLA|indice|fila|columna|1=pulsada 0=soltada|descripcion
    Serial.print(F("TECLA|"));
    Serial.print(i);                    Serial.print('|');
    Serial.print(fila);                 Serial.print('|');
    Serial.print(col);                  Serial.print('|');
    Serial.print(t.estable ? 1 : 0);    Serial.print('|');
    Serial.println(DESCRIPCIONES[i]);

    if (t.estable) comprobarGhosting();
  }
}

// Si hay cuatro teclas pulsadas que forman exactamente un rectangulo
// (dos filas x dos columnas), lo mas probable es que una sea fantasma:
// falta un diodo o esta al reves.
void comprobarGhosting() {
  for (uint8_t f1 = 0; f1 < NUM_FILAS; f1++) {
    for (uint8_t f2 = f1 + 1; f2 < NUM_FILAS; f2++) {
      for (uint8_t c1 = 0; c1 < NUM_COLUMNAS; c1++) {
        for (uint8_t c2 = c1 + 1; c2 < NUM_COLUMNAS; c2++) {
          if (teclas[f1 * NUM_COLUMNAS + c1].estable &&
              teclas[f1 * NUM_COLUMNAS + c2].estable &&
              teclas[f2 * NUM_COLUMNAS + c1].estable &&
              teclas[f2 * NUM_COLUMNAS + c2].estable) {
            Serial.println(F("AVISO|Posible GHOSTING: 4 teclas en rectangulo. "
                             "Si solo estas pulsando 3, hay un diodo mal puesto o ausente."));
            return;
          }
        }
      }
    }
  }
}


// ===========================================================================
// SLIDERS
// ===========================================================================

void informarSliders(uint32_t ahora) {
  if ((ahora - tUltimoEnvio) < INTERVALO_ENVIO_MS) return;
  tUltimoEnvio = ahora;

  // Formato:  SLIDERS|v0|min0|max0|v1|min1|max1|...
  Serial.print(F("SLIDERS"));
  for (uint8_t s = 0; s < NUM_SLIDERS; s++) {
    const int32_t v = analogRead(PINES_SLIDER[s]);
    if (v < sliderMin[s]) sliderMin[s] = v;
    if (v > sliderMax[s]) sliderMax[s] = v;

    Serial.print('|'); Serial.print(v);
    Serial.print('|'); Serial.print(sliderMin[s]);
    Serial.print('|'); Serial.print(sliderMax[s]);
  }
  Serial.println();
}
