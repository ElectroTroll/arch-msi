# 2026-09-14 · Spotify se subía el volumen solo, y el mezclador no tenía la culpa

Petición de partida: *cada vez que cambia la canción de Spotify se pone el
volumen al 100 %*. El StreamDeck se había versionado media hora antes (§30), así
que el sospechoso obvio era el mezclador recién documentado. **No era él.**

---

## 1. La primera hipótesis, y por qué era falsa

El razonamiento parecía sólido: si Spotify destruye su flujo de audio al cambiar
de canción y crea otro, el nuevo nace con el volumen por defecto y el script no
se entera, porque su reaplicación (`REAPLICAR_AL_CAMBIAR_APPS`) compara
**conjuntos de nombres** —`{spotify}` antes y `{spotify}` después—, no índices.

`pactl subscribe` durante dos cambios de canción lo desmintió en diez segundos:

```
27 eventos 'change' sobre sink-input #1650
 0 eventos 'new'
 0 eventos 'remove'
```

**El flujo no se recrea**: `#1650` antes, durante y después. La hipótesis se
cayó entera, aunque la conclusión sobre la reaplicación resultó ser cierta por
otro motivo: no se dispara porque efectivamente no cambia nada de lo que mira.

## 2. Lo que sí pasa, medido cada 120 ms

```
 0.02s  sink-input=1650  crudo=16418   25%
 2.04s  >>> cambio de canción <<<
 2.19s  sink-input=1650  crudo=65536  100%   <- 150 ms después
 4.36s  sink-input=1650  crudo=16541   25%   <- alguien lo corrige 2,2 s más tarde
```

Dos preguntas, dos culpables distintos, y la segunda es la interesante.

### ¿Quién sube el volumen? Spotify

La prueba limpia es parar el mezclador y repetir:

```
CON EL SERVICIO PARADO
 0.02s  crudo=16000   24%
 2.05s  >>> cambio de canción <<<
 2.20s  crudo=65536  100%   <- sube igual
        ... y se queda al 100 % nueve segundos, hasta que el servicio vuelve
```

**Sin el mezclador delante, el salto ocurre exactamente igual.** El mezclador no
es el culpable: es la víctima.

### ¿Quién lo bajaba a los 2,2 s? El ruido del potenciómetro

Esto explica por qué el fallo parecía intermitente. El script solo escribe
cuando el slider se mueve más de `UMBRAL_CRUDO` (3 cuentas). El potenciómetro
tiembla, y cada temblor provocaba una reescritura que **por casualidad**
arreglaba el volumen. Con el slider quieto —que es cuando el usuario lo nota— se
queda al 100 % para siempre.

De ahí la oscilación 24 % → 27 % → 22 % que apareció en las primeras pruebas y
que al principio no encajaba: no era el cambio de canción, era el ruido.

## 3. La causa de fondo: el mezclador es de lazo abierto

El script **nunca lee** el volumen: solo escribe. `grep` sobre el código lo
confirma —no hay una sola llamada a `get-sink-input-volume`—. Escribe cuando se
mueve el slider y cuando cambia la lista de apps, y nada más. Cualquier otro
programa que toque el volumen gana por incomparecencia.

## 4. El arreglo: dejar de pelearse por el mismo sitio

Se plantearon tres vías (vigilar la deriva por eventos, vigilarla en el bucle, o
mandarle el volumen a la propia aplicación). **Se eligió la tercera**: para
Spotify, el slider escribe su volumen por **MPRIS** con `playerctl`, y es
Spotify quien lo aplica a su flujo. Si el que manda es el dueño del flujo, no
hay pelea posible.

El coste declarado de esa opción era «curva propia sin medir», y el proyecto
tiene una regla clara sobre eso. Se midió.

### Primero por audio, que fue el camino equivocado

La idea era grabar el monitor del sink con `pw-record` a distintos volúmenes
MPRIS, sobre la misma sección de la canción, y comparar RMS. Salió esto:

| MPRIS | dBFS | exponente implícito |
|---|---|---|
| 1,00 | −13,57 | — |
| 0,80 | −19,23 | 2,94 |
| 0,60 | −20,26 | **1,51** |
| 0,50 | −29,56 | 2,66 |

Dispersión enorme: el RMS depende de qué esté sonando en esos 1,5 segundos, y el
`seek` no cae siempre en el mismo punto. **Con esos números no se puede afirmar
nada.** (De paso: `parec` devolvía 0 bytes en este equipo; `pw-record` sí graba.)

### Y luego por el camino bueno, que daba números exactos

Un dato de una prueba anterior apuntaba a algo mejor: el mezclador había puesto
el 30 % y el volumen MPRIS marcaba **0,303**. Demasiada coincidencia. Escribir
MPRIS y leer el sink-input lo confirmó:

| MPRIS escrito | volumen del sink-input |
|---|---|
| 0,50 | 32768 = **50 %** |
| 0,25 | 16384 = **25 %** |
| 0,75 | 49152 = **75 %** |

**MPRIS usa la misma escala cruda de PulseAudio** (`crudo = mpris × 65536`). No
hay curva nueva: `RANGO_DB_LINUX` y su raíz cúbica siguen valiendo, y solo hay
que dividir entre `VOLUMEN_NORMAL`. La medición por audio no solo era ruidosa:
era innecesaria.

**Moraleja, que es la misma de otras veces**: antes de montar un experimento
complicado, mirar si el sistema ya publica el número que buscas.

## 5. Validación

Con el volumen puesto por MPRIS, **dos cambios de canción seguidos lo respetan**.
Y llamando al backend real del script ya modificado:

| Posición del slider | Crudo esperado | Resultado |
|---|---|---|
| 40 % | 20724 | `stream=20722 (32 %)`, `mpris=0.316197` |
| 70 % | 36854 | `stream=36851 (56 %)`, `mpris=0.562295` |
| — tras dos cambios de canción — | | `36851`, intacto |

Las 2-3 cuentas de diferencia eran el redondeo a 4 decimales del valor MPRIS
(−0,0005 dB, inaudible); se subió a 6 decimales porque no costaba nada.

La comprobación que faltaba —mover el slider 2 físicamente, que no se puede
hacer desde una sesión de terminal— **la confirmó el usuario el 2026-09-15**: el
slider controla el volumen de Spotify y **aguanta el cambio de canción**. Con
eso el arreglo queda validado de punta a punta, hardware incluido.

## 6. Qué NO se tocó

- **El resto de sliders siguen por `pactl`.** `OBJETIVOS_MPRIS` es una lista
  corta y deliberada: solo entran las aplicaciones que gestionan su volumen por
  su cuenta. Firefox no lo necesita.
- **La curva**, porque resultó ser la misma.
- **El ruido del potenciómetro**, que sigue ahí. Ya no hace falta que arregle
  nada por casualidad, pero si algún día molesta, `UMBRAL_CRUDO` es el número.
- **`UseNativeGLFW`, el firmware y `CURVA_SESIONES_WINDOWS`**: nada de esto
  entra en el problema.
