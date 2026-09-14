/*
  ===========================================================================
  StreamDeck DIY - TEST USB MINIMO
  ===========================================================================

  Sketch de descarte. Sirve para una sola pregunta:

      ¿el problema es el USB / la placa / Windows,
       o es el cableado de la matriz y los sliders?

  Este sketch NO toca ni un solo pin de la matriz ni de los sliders.
  No pone nada como OUTPUT. Solo abre el puerto serie y escribe.

    - Si con esto SI aparece un puerto COM  -> la placa y el USB estan bien,
      el problema esta en el cableado (algun pin en corto al poner una fila
      como OUTPUT LOW) o en las descripciones del otro sketch.

    - Si con esto TAMPOCO aparece  -> el problema es de la placa, del cable,
      de la seleccion de procesador (8 MHz en vez de 16 MHz) o del driver
      cacheado de Windows. No es cosa del cableado.

  Ademas parpadea el LED RX de la placa una vez por segundo, para que veas a
  simple vista si el sketch se esta ejecutando aunque el USB no enumere.

  Placa: SparkFun Pro Micro / Processor: ATmega32U4 (5V, 16 MHz)
  Monitor Serie a 115200 baudios.
  ===========================================================================
*/

const uint32_t BAUDIOS = 115200;

uint32_t contador = 0;
uint32_t tUltimo = 0;
bool     ledEncendido = false;

void setup() {
  // El LED RX del Pro Micro esta en el pin 17 y es de logica invertida
  // (LOW = encendido). Es el unico pin que tocamos, y no va a la matriz.
  pinMode(17, OUTPUT);
  digitalWrite(17, HIGH);   // apagado

  Serial.begin(BAUDIOS);
  // Sin espera bloqueante: si el PC no abre el puerto, seguimos igualmente.
}

void loop() {
  const uint32_t ahora = millis();
  if (ahora - tUltimo < 1000) return;
  tUltimo = ahora;

  ledEncendido = !ledEncendido;
  digitalWrite(17, ledEncendido ? LOW : HIGH);

  contador++;
  Serial.print(F("USB OK - segundos en marcha: "));
  Serial.println(contador);
}
