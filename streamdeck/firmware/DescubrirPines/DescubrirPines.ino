/*
  ===========================================================================
  StreamDeck DIY - DESCUBRIR PINES
  ===========================================================================

  Averigua a que pines del Pro Micro esta soldada TU matriz y TUS sliders,
  sin tener que mirar el cableado ni acordarte de nada.

  Al final te escribe, listas para copiar y pegar, las tres lineas de
  configuracion que van al principio de StreamDeckDIY.ino:

      const uint8_t PINES_FILA[]    = { ... };
      const uint8_t PINES_COLUMNA[] = { ... };
      const uint8_t PINES_SLIDER[]  = { ... };

  No se presenta como teclado: no manda ni una pulsacion al PC.

  ---------------------------------------------------------------------------
  COMO SE USA  (Monitor Serie a 115200 baudios)
  ---------------------------------------------------------------------------

  PASO 1 - SLIDERS
    Si ya sabes donde estan, ponlos en SLIDERS_CONOCIDOS (mas abajo) y este
    paso se salta solo.
    Si no: mueve los sliders UNO A UNO, de tope a tope, en el orden en que
    quieras numerarlos (normalmente de izquierda a derecha). Cada vez que
    detecte uno nuevo te lo dira. Cuando tengas los 5, pasa al paso 2.
    Los pines que estan al aire NO se confunden con sliders: se descartan
    por la prueba de firmeza que hay mas abajo.

  PASO 2 - MATRIZ
    Escribe  m  + Enter.
    Los pines de los sliders quedan excluidos automaticamente para que no
    estorben. Ahora pulsa las 12 teclas, UNA A UNA. Cada pulsacion te dira
    que par de pines conecta y cual es la fila y cual la columna.

  PASO 3 - RESUMEN
    Escribe  r  + Enter y copia el resultado.

  Otros comandos:  a = volver al modo sliders    z = borrar todo y empezar
  ===========================================================================
*/

// ---------------------------------------------------------------------------
// Todos los pines que el Pro Micro saca al exterior.
// ---------------------------------------------------------------------------
const uint8_t CANDIDATOS[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 15, 16, 18, 19, 20, 21 };
const uint8_t NUM_CANDIDATOS = sizeof(CANDIDATOS);

// De esos, los que pueden leer una tension analogica (donde puede haber un slider).
const uint8_t PINES_ANALOGICOS[] = { 4, 6, 8, 9, 10, 18, 19, 20, 21 };
const uint8_t NUM_ANALOGICOS = sizeof(PINES_ANALOGICOS);

// Nombre "Ax" de cada uno de esos pines, en el mismo orden.
const char* const NOMBRES_ANALOGICOS[NUM_ANALOGICOS] = {
  "A6", "A7", "A8", "A9", "A10", "A0", "A1", "A2", "A3"
};

// ---------------------------------------------------------------------------
// SI YA SABES DONDE ESTAN TUS SLIDERS, PONLOS AQUI
// ---------------------------------------------------------------------------
// Con USAR_SLIDERS_CONOCIDOS a true, el sketch se salta el paso 1 y va directo
// a buscar la matriz, excluyendo estos pines. El orden de la lista es el orden
// de los sliders (0..4).
// Ponlo a false si prefieres que los detecte el solo.
const bool    USAR_SLIDERS_CONOCIDOS = true;
const uint8_t SLIDERS_CONOCIDOS[] = { A0, A1, A2, A3, A10 };
const uint8_t NUM_CONOCIDOS = sizeof(SLIDERS_CONOCIDOS);

// Un slider se da por detectado cuando cumple LAS DOS cosas:
//   1) esta CONECTADO a algo  -> su lectura es firme (ver mas abajo)
//   2) lo has MOVIDO          -> su lectura ha recorrido al menos esto
const int16_t RECORRIDO_MINIMO = 400;   // de 0..1023

// Como se distingue un pin con potenciometro de un pin al aire:
// se toman 16 lecturas seguidas, en menos de 2 ms. Un potenciometro es una
// fuente de baja impedancia y da 16 lecturas casi identicas. Un pin flotante
// no esta sujeto por nada y sus 16 lecturas saltan por todo el rango.
// Moverlo con la mano no engania a esta prueba: en 2 ms no te da tiempo a
// mover el slider lo suficiente.
const int16_t UMBRAL_FIRMEZA   = 12;   // dispersion maxima de 16 lecturas
const uint8_t CICLOS_PARA_FIAR = 5;    // ciclos seguidos firme para creerselo

const uint32_t BAUDIOS = 115200;


// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------
enum Modo : uint8_t { MODO_SLIDERS, MODO_MATRIZ };
Modo modo = MODO_SLIDERS;

int16_t  minAnalog[NUM_ANALOGICOS];
int16_t  maxAnalog[NUM_ANALOGICOS];
bool     detectado[NUM_ANALOGICOS];
uint8_t  ciclosFirme[NUM_ANALOGICOS];    // ciclos seguidos con lectura firme
uint8_t  ordenSliders[NUM_ANALOGICOS];   // indices, en orden de deteccion
uint8_t  numSlidersDetectados = 0;

// Mascaras de bits: conexion[i] tiene el bit j puesto si, poniendo el
// candidato i a LOW, se lee el candidato j tambien a LOW.
uint32_t conexionActual[NUM_CANDIDATOS];
uint32_t conexionPrevia[NUM_CANDIDATOS];
uint32_t conexionVista[NUM_CANDIDATOS];   // historico acumulado
bool     excluido[NUM_CANDIDATOS];

uint32_t tUltimo = 0;


void setup() {
  Serial.begin(BAUDIOS);
  while (!Serial && millis() < 4000) { }
  reiniciar();
  ayuda();
  censoAnalogico();

  // Si le has dicho donde estan los sliders, no hay nada que detectar.
  if (USAR_SLIDERS_CONOCIDOS) {
    for (uint8_t n = 0; n < NUM_CONOCIDOS; n++) {
      for (uint8_t i = 0; i < NUM_ANALOGICOS; i++) {
        if (PINES_ANALOGICOS[i] == SLIDERS_CONOCIDOS[n]) {
          detectado[i] = true;
          ordenSliders[numSlidersDetectados++] = i;
        }
      }
    }
    Serial.println();
    Serial.print(F(">> Sliders ya declarados en SLIDERS_CONOCIDOS: "));
    Serial.println(numSlidersDetectados);
    Serial.println(F(">> Me salto el paso 1 y voy directo a la matriz."));
    pasarAMatriz();
  }
}

// Foto fija de los 9 pines analogicos: dice en cuales hay algo conectado.
// Util para detectar de un vistazo un slider mal soldado o un cable suelto.
void censoAnalogico() {
  Serial.println();
  Serial.println(F(" CENSO DE PINES ANALOGICOS"));
  Serial.println(F(" pin        lectura   dispersion   ¿hay algo conectado?"));
  for (uint8_t i = 0; i < NUM_ANALOGICOS; i++) {
    const uint8_t pin = PINES_ANALOGICOS[i];
    const int16_t d = firmeza(pin);
    const int16_t v = analogRead(pin);

    Serial.print(F("  "));
    Serial.print(NOMBRES_ANALOGICOS[i]);
    Serial.print(F(" (pin "));
    Serial.print(pin);
    Serial.print(pin < 10 ? F(")   ") : F(")  "));
    Serial.print(F("  "));
    if (v < 100) Serial.print(' ');
    if (v < 10)  Serial.print(' ');
    Serial.print(v);
    Serial.print(F("       "));
    if (d < 100) Serial.print(' ');
    if (d < 10)  Serial.print(' ');
    Serial.print(d);
    Serial.println(d <= UMBRAL_FIRMEZA ? F("        SI") : F("        no (al aire)"));
  }
  Serial.println(F("-----------------------------------------------------------"));
}


void loop() {
  atenderComandos();
  if (modo == MODO_SLIDERS) buscarSliders();
  else                      escanearPares();
}


// ===========================================================================
// COMANDOS
// ===========================================================================

void ayuda() {
  Serial.println();
  Serial.println(F("==========================================================="));
  Serial.println(F(" StreamDeck DIY - DESCUBRIR PINES"));
  Serial.println(F("==========================================================="));
  Serial.println(F(" PASO 1: mueve los sliders UNO A UNO, de tope a tope,"));
  Serial.println(F("         en el orden en que quieras numerarlos."));
  Serial.println(F(" PASO 2: escribe  m  y pulsa las 12 teclas, una a una."));
  Serial.println(F(" PASO 3: escribe  r  para el resumen."));
  Serial.println(F(" Otros:  a = volver a sliders   z = borrar todo   h = ayuda"));
  Serial.println(F("-----------------------------------------------------------"));
}

void atenderComandos() {
  while (Serial.available()) {
    const char c = Serial.read();
    if (c == 'm' || c == 'M') pasarAMatriz();
    else if (c == 'a' || c == 'A') { modo = MODO_SLIDERS; Serial.println(F("\n>> MODO SLIDERS. Mueve uno...")); }
    else if (c == 'r' || c == 'R') resumen();
    else if (c == 'z' || c == 'Z') { reiniciar(); Serial.println(F("\n>> Todo borrado.")); }
    else if (c == 'h' || c == 'H') ayuda();
  }
}

void reiniciar() {
  for (uint8_t i = 0; i < NUM_ANALOGICOS; i++) {
    minAnalog[i]   = 1023;
    maxAnalog[i]   = 0;
    detectado[i]   = false;
    ciclosFirme[i] = 0;
  }
  numSlidersDetectados = 0;

  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    conexionActual[i] = 0;
    conexionPrevia[i] = 0;
    conexionVista[i]  = 0;
    excluido[i]       = false;
    pinMode(CANDIDATOS[i], INPUT);
  }
  modo = MODO_SLIDERS;
}


// ===========================================================================
// PASO 1 - DETECTAR LOS SLIDERS
// ===========================================================================

// Dispersion de 16 lecturas seguidas del mismo pin (tarda ~2 ms).
// Pequenia = hay algo conectado.  Enorme = el pin esta al aire.
int16_t firmeza(uint8_t pin) {
  int16_t mn = 1023, mx = 0;
  analogRead(pin);                 // lectura de descarte: asienta el multiplexor
  for (uint8_t k = 0; k < 16; k++) {
    const int16_t v = analogRead(pin);
    if (v < mn) mn = v;
    if (v > mx) mx = v;
  }
  return mx - mn;
}

void buscarSliders() {
  if (millis() - tUltimo < 30) return;
  tUltimo = millis();

  for (uint8_t i = 0; i < NUM_ANALOGICOS; i++) {
    const uint8_t pin = PINES_ANALOGICOS[i];

    // 1) ¿Hay algo conectado a este pin?
    if (firmeza(pin) <= UMBRAL_FIRMEZA) {
      if (ciclosFirme[i] < 255) ciclosFirme[i]++;
    } else {
      // Pin al aire: ademas de no contar, se olvida el recorrido acumulado,
      // que solo era ruido.
      ciclosFirme[i] = 0;
      minAnalog[i] = 1023;
      maxAnalog[i] = 0;
      continue;
    }
    if (ciclosFirme[i] < CICLOS_PARA_FIAR) continue;

    // 2) ¿Lo has movido?
    const int16_t v = analogRead(pin);
    if (v < minAnalog[i]) minAnalog[i] = v;
    if (v > maxAnalog[i]) maxAnalog[i] = v;

    if (!detectado[i] && (maxAnalog[i] - minAnalog[i]) >= RECORRIDO_MINIMO) {
      detectado[i] = true;
      ordenSliders[numSlidersDetectados++] = i;

      Serial.print(F(">> SLIDER "));
      Serial.print(numSlidersDetectados - 1);
      Serial.print(F(" detectado en el pin "));
      Serial.print(PINES_ANALOGICOS[i]);
      Serial.print(F("  ("));
      Serial.print(NOMBRES_ANALOGICOS[i]);
      Serial.print(F(")   recorrido "));
      Serial.print(minAnalog[i]);
      Serial.print(F(".."));
      Serial.println(maxAnalog[i]);

      if (numSlidersDetectados >= 5) {
        Serial.println(F(">> Ya van 5. Si estan todos, escribe  m  para pasar a la matriz."));
      }
    }
  }
}


// ===========================================================================
// PASO 2 - DETECTAR LA MATRIZ
// ===========================================================================

void pasarAMatriz() {
  // Los pines donde hay un slider se excluyen: un potenciometro pone
  // tensiones intermedias y falsearia el escaneo de continuidad.
  Serial.println();
  Serial.print(F(">> MODO MATRIZ. Pines excluidos (sliders): "));
  for (uint8_t i = 0; i < NUM_ANALOGICOS; i++) {
    if (!detectado[i]) continue;
    for (uint8_t k = 0; k < NUM_CANDIDATOS; k++) {
      if (CANDIDATOS[k] == PINES_ANALOGICOS[i]) {
        excluido[k] = true;
        Serial.print(CANDIDATOS[k]);
        Serial.print(' ');
      }
    }
  }
  if (numSlidersDetectados == 0) Serial.print(F("ninguno (ojo: no has movido los sliders)"));
  Serial.println();
  Serial.println(F(">> Pulsa las teclas UNA A UNA."));
  Serial.println();

  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    conexionActual[i] = 0;
    conexionPrevia[i] = 0;
  }
  modo = MODO_MATRIZ;
}

void escanearPares() {
  // Todos los candidatos a INPUT_PULLUP; luego, uno a uno, se pone cada
  // candidato a OUTPUT LOW y se mira quien se va a LOW con el.
  for (uint8_t j = 0; j < NUM_CANDIDATOS; j++) {
    if (!excluido[j]) pinMode(CANDIDATOS[j], INPUT_PULLUP);
  }

  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    if (excluido[i]) { conexionActual[i] = 0; continue; }

    pinMode(CANDIDATOS[i], OUTPUT);
    digitalWrite(CANDIDATOS[i], LOW);
    delayMicroseconds(30);

    uint32_t mascara = 0;
    for (uint8_t j = 0; j < NUM_CANDIDATOS; j++) {
      if (i == j || excluido[j]) continue;
      if (digitalRead(CANDIDATOS[j]) == LOW) mascara |= (1UL << j);
    }
    conexionActual[i] = mascara;

    pinMode(CANDIDATOS[i], INPUT_PULLUP);
  }

  // Solo damos por buena una conexion cuando se repite en dos barridos
  // seguidos (antirrebote sencillo).
  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    if (conexionActual[i] != conexionPrevia[i]) {
      conexionPrevia[i] = conexionActual[i];
      continue;
    }
    const uint32_t nuevas = conexionActual[i] & ~conexionVista[i];
    if (!nuevas) continue;

    for (uint8_t j = 0; j < NUM_CANDIDATOS; j++) {
      if (!(nuevas & (1UL << j))) continue;
      conexionVista[i] |= (1UL << j);

      // Con los diodos puestos, la corriente solo pasa de la COLUMNA hacia la
      // FILA. Como aqui el pin i es el que esta a LOW (el que "tira"), i es la
      // FILA y j es la COLUMNA.
      Serial.print(F("TECLA -> pin "));
      Serial.print(CANDIDATOS[i]);
      Serial.print(F(" (FILA)   +   pin "));
      Serial.print(CANDIDATOS[j]);
      Serial.println(F(" (COLUMNA)"));
    }
  }
}


// ===========================================================================
// PASO 3 - RESUMEN
// ===========================================================================

void resumen() {
  bool esFila[NUM_CANDIDATOS];
  bool esColumna[NUM_CANDIDATOS];
  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) { esFila[i] = false; esColumna[i] = false; }

  uint8_t totalTeclas = 0;
  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    for (uint8_t j = 0; j < NUM_CANDIDATOS; j++) {
      if (conexionVista[i] & (1UL << j)) {
        esFila[i] = true;
        esColumna[j] = true;
        totalTeclas++;
      }
    }
  }

  Serial.println();
  Serial.println(F("==========================================================="));
  Serial.println(F(" RESUMEN - copia estas lineas a StreamDeckDIY.ino"));
  Serial.println(F("==========================================================="));
  Serial.print(F(" Teclas distintas detectadas: "));
  Serial.print(totalTeclas);
  Serial.println(F(" (deberian ser 12)"));
  Serial.println();

  Serial.print(F("const uint8_t PINES_FILA[]    = { "));
  imprimirLista(esFila);
  Serial.println(F(" };"));

  Serial.print(F("const uint8_t PINES_COLUMNA[] = { "));
  imprimirLista(esColumna);
  Serial.println(F(" };"));

  Serial.print(F("const uint8_t PINES_SLIDER[]  = { "));
  for (uint8_t n = 0; n < numSlidersDetectados; n++) {
    if (n) Serial.print(F(", "));
    Serial.print(NOMBRES_ANALOGICOS[ordenSliders[n]]);
  }
  Serial.println(F(" };"));
  Serial.println();

  // Aviso si el numero de filas/columnas no cuadra con 12 teclas.
  uint8_t nf = 0, nc = 0;
  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) { if (esFila[i]) nf++; if (esColumna[i]) nc++; }
  Serial.print(F(" Filas: "));   Serial.print(nf);
  Serial.print(F("   Columnas: ")); Serial.print(nc);
  Serial.print(F("   -> "));      Serial.print(nf * nc);
  Serial.println(F(" teclas posibles"));

  if (totalTeclas < 12) {
    Serial.println(F(" AVISO: faltan teclas por pulsar, o alguna no hace contacto."));
  }
  if (numSlidersDetectados < 5) {
    Serial.println(F(" AVISO: no se han detectado los 5 sliders. Escribe 'a' y muevelos."));
  }
  Serial.println(F("==========================================================="));
}

void imprimirLista(bool* marcados) {
  bool primero = true;
  for (uint8_t i = 0; i < NUM_CANDIDATOS; i++) {
    if (!marcados[i]) continue;
    if (!primero) Serial.print(F(", "));
    Serial.print(CANDIDATOS[i]);
    primero = false;
  }
}
