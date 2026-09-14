# 2026-09-14 · El Bluetooth entra en `Super + Z`, y una nota caducada que lo estorbaba

Petición de partida: *el atajo alterna entre los altavoces y la SSL; que el
JBL Charge 5 también esté disponible.* El cambio en sí es pequeño —pasar de un
interruptor de dos posiciones a una rotación—, pero obliga a decidir algo que
hasta hoy no hacía falta: **qué salidas merecen estar en el atajo y cuáles no**.
De paso apareció que la nota `[VER]` de Bluetooth de §15 llevaba semanas
diciendo algo que ya no era cierto.

---

## 1. Lo que había, y por qué no bastaba con añadir un `elif`

`audio-salida` resolvía el destino con dos ramas:

```bash
if [ -n "$usb" ] && [ "$actual" != "$usb" ]; then
    destino="$usb"
else
    destino="$interno"
fi
```

Es un interruptor: *si no estoy en la interfaz, voy a la interfaz; si estoy, me
salgo*. Funciona perfectamente para dos destinos y no escala a tres, porque con
un tercero deja de haber un «el otro». Encadenar condiciones habría fijado
además el número de salidas en el código, y el número de salidas Bluetooth
**cambia solo**: depende de qué haya conectado en ese momento.

Así que la lógica pasa a construir una lista en el momento de pulsar y avanzar
una posición:

```bash
anillo="$(printf '%s\n%s\n%s\n' "$interno" "$usb" "$bt" | grep -v '^$')"
destino="$(printf '%s\n' "$anillo" | awk -v a="$actual" '
    { parada[NR] = $0 }
    $0 == a { i = NR }
    END { print parada[(i % NR) + 1] }')"
```

El `(i % NR) + 1` hace dos cosas de una vez. Si el predeterminado está en la
lista, avanza uno y vuelve al principio al desbordar. Y si **no** está —`i`
nunca se asigna, awk lo trata como 0— el resultado es `parada[1]`, los altavoces
internos. Es justo el comportamiento que hace falta para el caso raro en que un
HDMI acaba siendo el predeterminado: el atajo te devuelve a terreno conocido en
vez de quedarse mudo.

## 2. Por qué el Bluetooth sí y el HDMI no

Parece incoherente meter unos dispositivos y dejar otros fuera, pero la
diferencia es observable y es lo que decide el criterio:

| | Sinks que expone | Cuándo existen |
|---|---|---|
| HDMI/DP | **4** (3 del iGPU Intel + 1 de la RTX 4060) | **Siempre**, haya o no algo enchufado |
| Bluetooth | 1 por aparato | **Solo** mientras está emparejado **y** conectado |

Los HDMI son ruido permanente: incluirlos dejaría un atajo de seis paradas, casi
todas mudas, y habría que cruzar cuatro silencios para volver a los altavoces.
Un `bluez_output.*`, en cambio, aparece y desaparece con el aparato, así que la
rotación se encoge sola: sin interfaz ni Bluetooth, `Super + Z` vuelve a ser
exactamente el ida y vuelta de siempre. **La lista no se declara, se observa.**

## 3. Dos detalles que solo se ven con varios aparatos

- **Orden estable.** `pactl` lista los sinks por ID, y los IDs se reasignan en
  cada reconexión. Con dos aparatos Bluetooth conectados, la secuencia del atajo
  cambiaría de un día para otro sin tocar nada. Van ordenados por nombre, y el
  nombre lleva la MAC, que es fija.
- **La MAC, no la descripción.** El sink es
  `bluez_output.F8_5C_7E_D3_B7_E3.1`; «JBL Charge 5» es solo la etiqueta que se
  enseña en la notificación. Misma razón por la que la interfaz USB se busca por
  nombre y no por ID (§22).

## 4. `--status` ya no puede limitarse a marcar la activa

Con dos posiciones fijas no hacía falta explicar cuáles eran; con una rotación
variable, sí. Ahora la salida distingue tres estados:

```
* alsa_output.pci-...HiFi__Speaker__sink   Meteor Lake-P HD Audio Controller Speaker
· alsa_output.usb-...HiFi__Line1__sink     SSL 2+ Mk II Line Outputs 1/L + 2/R
· bluez_output.F8_5C_7E_D3_B7_E3.1         JBL Charge 5
  alsa_output.pci-...HDMI1__sink           Meteor Lake-P HD Audio Controller HDMI 1 Output
```

`*` la activa, `·` las demás paradas del atajo, y sin marca lo que queda fuera.
Así el comando responde a la pregunta que uno se hace de verdad —*¿cuántas veces
tengo que pulsar?*— y no solo a dónde está sonando.

## 5. Validación

Con el JBL conectado, una vuelta completa comprobando `pactl get-default-sink`
después de cada pulsación:

| Pulsación | Destino |
|---|---|
| 1 | `SSL 2+ Mk II Line Outputs 1/L + 2/R` |
| 2 | `JBL Charge 5` |
| 3 | `Meteor Lake-P HD Audio Controller Speaker` (vuelta al principio) |

Y el caso de la rama rara: forzando `pactl set-default-sink` al HDMI de la
NVIDIA, el atajo devolvió el audio a los altavoces internos. El sistema quedó al
terminar donde estaba al empezar.

**Lo que no está comprobado:** que suene de verdad por el altavoz. Lo verificado
es el enrutado —el predeterminado cambia y los flujos vivos se arrastran—, no el
sonido audible.

## 6. De paso: una nota `[VER]` que ya no describía la realidad

§15 decía desde el 2026-08-24 que en **cada arranque** el kernel fallaba al
cargar el firmware Bluetooth (`FW download error recovery failed (-19)`, más
`sending frame failed` y `Failed to read MSFT supported features`) y que quedaba
pendiente *emparejar un dispositivo real para saber si el Bluetooth funciona de
verdad o solo lo parece*.

Las dos mitades han caducado. Hay tres aparatos emparejados —JBL Charge 5,
OnePlus Buds Pro 3 y Pro 2—, uno conectado y dando sink. Y en el arranque de hoy
`journalctl -kb` no tiene **ninguna** de esas tres líneas: el firmware
`intel/ibt-0291-0291.sfi` carga entero, con `Firmware timestamp 2026.26 build
117936` y `Fseq status: Success (0x00)`.

> **La parte que NO se ha resuelto, anotada tal cual en §15:**
> `linux-firmware` sigue siendo **20260810-2**, exactamente la versión con la
> que el 2026-08-24 el error persistía. Lo que ha cambiado desde entonces es el
> kernel (`linux-lts` 6.18.51-1), pero **no se ha verificado** que sea esa la
> causa. Lo único que consta es que hoy el error no está. Convertir eso en «lo
> arregló el kernel» sería inventarse la mitad.

## 7. Archivos

| Archivo | Qué cambia |
|---|---|
| `scripts/audio-salida.sh` | interruptor → rotación; patrón `^bluez_output\.`; `--status` con tres marcas |
| `docs/PROJECT_CONTEXT.md` | §22 reescrita; §15 con la nota de Bluetooth cerrada y la discrepancia anotada |
| `docs/keybindings.md` | la fila de `Super + Z` |
| `README.md` | la línea de `audio-salida.sh` en el árbol de `scripts/` |

No hizo falta tocar `hyprland.lua` ni volver a pasar Stow: el atajo llama a
`audio-salida`, que ya es un symlink al script del repo, así que el cambio entró
en vigor al guardar.
