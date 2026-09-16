# 2026-09-16 · El panel a 165 Hz también con batería, y quién lo deshacía

Pregunta de partida: *en power-saver y con batería, ¿a qué frecuencia funciona
la pantalla?* La respuesta corta resultó ser **a 165 Hz, igual que enchufado**,
y de ahí salió el encargo: que en clase baje a 60 Hz.

---

## 1. El estado real, antes de proponer nada

| Comprobación | Resultado |
|---|---|
| `powerprofilesctl get` | `power-saver` |
| `/sys/class/power_supply/ADP1/online` | `1` — enchufado |
| `hyprctl monitors`, eDP-1 | `2560x1600@165.03999` |
| `vrr` | `false` |
| `availableModes` | **solo dos**: `165.04Hz` y `60.04Hz` |
| Reglas en `/etc/udev/rules.d/` | **ninguna** (directorio vacío) |
| Scripts que miren `power_supply` | ninguno que toque el modo de vídeo |

La primera conclusión ya estaba en esa tabla: **el equipo estaba en power-saver
y aun así a 165 Hz**. O sea que el perfil no toca la frecuencia, y no era
necesario desenchufar para saberlo.

Las razones, las cuatro:

1. `hyprland.lua` fija el modo a mano: `mode = "2560x1600@165.04"`. Hyprland no
   negocia otro por su cuenta.
2. `vrr: false` — no hay refresco adaptativo que baje los Hz solo.
3. No hay nada escuchando el enchufe. Lo único que distingue AC de batería en
   todo el escritorio es `hypridle.conf`, y solo para los **tiempos** de apagado
   y suspensión, no para el modo de vídeo.
4. `power-profiles-daemon` actúa sobre EPP, `platform_profile` y turbo de la
   CPU. El modo de vídeo no entra en su ámbito.

## 2. Cambiar el modo: `eval`, no `keyword`

Con configuración Lua, `hyprctl keyword` responde «keyword can't work with
non-legacy parsers» — ya estaba anotado en la sección MONITORS de
`hyprland.lua`, de cuando se calibró el monitor externo. La vía buena es evaluar
la misma llamada que usa el archivo:

```
hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2560x1600@60.04", position = "0x0", scale = 1.6 })'
```

Probado en vivo los dos sentidos, 165 → 60 → 165, `ok` en ambos. El cambio es
instantáneo y no arrastra nada más: la posición y la escala se repiten en la
llamada porque `hl.monitor()` describe el monitor entero, no un delta.

## 3. Quién deshacía el ahorro en silencio

Este es el hallazgo que cambió el diseño. `theme-apply` **termina con un
`hyprctl reload`** (`scripts/theme-apply.sh`, última línea), y un reload
re-aplica `hyprland.lua` de arriba abajo: la regla de eDP-1 vuelve a poner
165 Hz. Cambiar el fondo o el tema en mitad de una clase habría devuelto el
panel a la frecuencia alta **sin avisar de nada**.

Por eso el demonio no se limita a mirar la corriente: escucha también el evento
`configreloaded` del socket2 de Hyprland y vuelve a aplicar lo que toque.

Es el mismo tipo de trampa que ya apareció con el VPN (`hyprctl reload` y la
sesión gráfica reiniciada): lo que se aplica en caliente sobrevive solo hasta la
siguiente recarga.

## 4. Las tres fuentes de eventos, y por qué cada una

| Fuente | Qué detecta | Por qué esa y no otra |
|---|---|---|
| `udevadm monitor --udev --subsystem-match=power_supply` | enchufar / desenchufar | Es el **kernel**, no UPower: fuente de verdad y no depende de que ese demonio esté vivo. Funciona como usuario normal (comprobado). |
| `dbus-monitor --system` sobre `/net/hadess/PowerProfiles` | cambio de perfil | La señal es `PropertiesChanged` con `ActiveProfile`. Comprobado cambiando a `balanced` y volviendo: **2 señales capturadas**. |
| socket2 de Hyprland, filtrando `configreloaded` | `hyprctl reload` | Lo de §3. |

Y por encima, un **sondeo de respaldo cada 60 s**. No es desconfianza gratuita:
al volver de suspensión es fácil que una señal se pierda, y el coste de
comprobar es leer un archivo de sysfs y preguntar el modo actual. El peor caso
deja de ser «se queda mal hasta que pase algo» y pasa a ser «se corrige solo en
menos de un minuto».

El socket2 escupe **todos** los eventos de Hyprland —cada cambio de ventana, de
workspace—, así que se filtra **en la fuente** y no en el bucle: si no, el
demonio despertaría cientos de veces por sesión, y cada despertar es un
`hyprctl` y un `powerprofilesctl`. Sería absurdo gastar batería vigilando la
batería.

## 5. Por qué un demonio de sesión y no una regla de udev

Una regla de udev es la respuesta obvia a «haz algo al desenchufar», y aquí es
la mala:

- Corre **como root y fuera de la sesión gráfica**. Para hablar con Hyprland
  hace falta su socket y el entorno del usuario, que habría que reinyectar a
  mano.
- Pide tocar `/etc`, o sea `sudo`, para algo que no lo necesita.
- Y no cubre ni el cambio de perfil ni el `hyprctl reload`: haría falta el
  demonio igualmente.

Tampoco se abre una unidad de systemd: el repo no versiona ninguna (salvo la del
StreamDeck, §30, que es otro proyecto) y el autoarranque de la sesión vive en
`hyprland.lua`. Es la convención que ya razona la cabecera de
`vpn-autoconnect.sh`, y se sigue en vez de abrir una vía nueva.

## 6. Un cerrojo y un gancho de pruebas

**`flock`.** El demonio lo lanza `hyprland.start`; reiniciar solo la sesión
gráfica no debe dejar dos instancias peleándose por el modo. La segunda sale con
«ya hay un demonio en marcha».

**`PANEL_HZ_SIMULA_BATERIA=1`.** Finge que no hay corriente. Está ahí por un
motivo concreto: desde una terminal **no se puede desenchufar el portátil**, y
sin eso la lógica entera quedaría sin probar hasta la primera clase. Con el
gancho se validó la cadena completa —evento, decisión, cambio de modo— con el
cable puesto.

## 7. El tropiezo: la coma decimal

`printf '%.0f' 165.04` → **«número inválido»**. El locale del equipo es `es_ES`,
con coma decimal, y `printf` espera `165,04`. Los números vienen de `hyprctl` en
formato C, así que el arreglo es exportar **solo** `LC_NUMERIC=C`: se respeta el
resto del locale y las notificaciones siguen saliendo con acentos.

Pequeño, pero habría fallado justo en la comparación que decide si hay que
cambiar de modo o no.

## 8. Validación

Con `PANEL_HZ_SIMULA_BATERIA=1`, leyendo `refreshRate` de `hyprctl monitors -j`
en cada paso:

```
[1] arranque (batería + power-saver) -> 60.04300
[2] perfil balanced                  -> 165.03999
[3] vuelta a power-saver             -> 60.04300
[4] tras 'hyprctl reload'            -> 60.04300   <- el caso de §3
```

Y el resto de comprobaciones del día:

- `bash -n` correcto.
- `stow -n -v -d dotfiles -t ~ bin` → **un solo `LINK` y cero conflictos**.
- Segunda instancia → sale por el cerrojo.
- Al matar el demonio, **cero procesos huérfanos** (`udevadm`, `dbus-monitor`,
  `socat`).
- Panel devuelto a `165.03999` y perfil devuelto a `power-saver` al terminar.

## 9. Lo que queda sin comprobar

Dos cosas, y las dos exigen desenchufar de verdad:

- **Que el uevent de desconexión llegue.** Si no llegara, el sondeo de 60 s lo
  corrige igual: el peor caso es que tarde hasta un minuto. Al desenchufar debe
  saltar la notificación «Panel a 60 Hz».
- **Cuánto ahorra.** No se ha medido y no se pone una cifra inventada. Se mide
  desenchufado y con la pantalla quieta, comparando el consumo entre los dos
  modos —forzándolos con `hyprctl eval` y con el demonio parado, para que el
  perfil no contamine la medida—.

## 10. Epílogo del mismo día: el cable, y un archivo que no existe

Minutos después de dar la tarea por cerrada, el usuario desenchufó el portátil.
`panel-hz --status`: `AC enchufado: no`, perfil `power-saver`, panel **a 60 Hz**.
El primer punto de §9 queda observado en condiciones reales y sin montar ninguna
prueba. Lo que **no** se puede afirmar es si lo disparó el uevent o el sondeo de
respaldo: el log no lleva marcas de tiempo y nadie cronometró el tirón del cable.

El segundo punto se llevó una corrección más fea, porque el error estaba escrito
en la documentación que se acababa de commitear: **esta batería no expone
`power_now`**. `/sys/class/power_supply/BAT1/` tiene `current_now` (µA) y
`voltage_now` (µV); la potencia hay que calcularla. Lo que se había dado por
supuesto —que el archivo estándar estaría ahí— se cayó al primer `cat`.

Y de esa lectura salió un dato que no se buscaba:

| Medida (2026-09-16, en batería) | Valor |
|---|---|
| Consumo | **23,74 W** (1,540 A × 14,913 V) |
| Carga restante | 2473 de 4410 mAh (56 %) |
| `runtime_status` de la dGPU | **`active`** |
| Salidas | `eDP-1` **y `HDMI-A-1`** |
| Brillo | 52 % |

O sea: el monitor externo seguía conectado, y el HDMI cuelga de la NVIDIA (§6),
que por eso estaba despierta **en batería**. 23,74 W dan hora y media larga con
la carga que quedaba. No invalida nada de lo anterior —en clase no habrá monitor
externo—, pero sí coloca el ahorro del panel en su sitio: con la dGPU despierta,
los Hz de la pantalla no son el principal culpable.

Queda también sin tocar la pregunta de fondo del encargo —*en clase dura
poco*—: el panel es un sospechoso, no el único. La dGPU con RTD3 (§6) es el
otro, y se puede mirar sin despertarla leyendo `runtime_status`, que es lo que
ya hace `waybar-monitor` (§23).
