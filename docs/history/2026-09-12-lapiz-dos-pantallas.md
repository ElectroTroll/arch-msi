# El lápiz se descalibra con el monitor externo

**Fecha:** 2026-09-12
**Estado:** resuelto y **confirmado** por el usuario el 2026-09-12, con el
monitor externo conectado

## Síntoma

Con el LG UltraGear conectado por HDMI, el trazo del lápiz y el toque del dedo
caían **desplazados** respecto al punto que se estaba tocando. Desconectando el
monitor, perfectos. Apareció usando Obsidian, un día después de montarlo
(ver `2026-09-11-apuntes-lapiz-obsidian.md`).

## Causa

El digitalizador reporta coordenadas **absolutas** sobre su propia superficie:
"estoy al 30 % del ancho y al 60 % del alto". Alguien tiene que decidir el ancho
y el alto de qué. Sin `output` en la configuración del dispositivo, Hyprland usa
el **área combinada de todas las salidas**.

De `hyprctl monitors` en el momento del fallo:

| | Posición | Tamaño lógico |
|---|---|---|
| `eDP-1` | `0x0` | 1600×1000 (2560×1600 ÷ escala 1,6) |
| `HDMI-A-1` | `-2560x-220` | 2560×1440 |
| **Combinada** | | **~4160×1220** |

El lápiz estaba mapeado a una superficie **2,6 veces más ancha** que el panel.
Con una sola salida las dos áreas coinciden al píxel, y de ahí que el problema
no existiera hasta enchufar el monitor.

Esto ya se había anticipado el 2026-09-11, al documentar el hardware del lápiz,
pero se dejó como propuesta sin aplicar porque en ese momento no había monitor
externo conectado con el que comprobarlo.

## Arreglo

Un bloque en `hyprland.lua`, junto a los demás `hl.device`:

```lua
for _, puntero in ipairs({
    "elan9024:00-04f3:4297-stylus", -- lápiz (sección Tablets)
    "elan9024:00-04f3:4297",        -- táctil (sección Touch)
}) do
    hl.device({ name = puntero, output = "eDP-1" })
end
```

**Dos** entradas, no una: `hyprctl devices` lista el mismo digitalizador en
`Tablets` (con sufijo `-stylus`) y en `Touch` (sin él). Anclar solo el lápiz
habría dejado el dedo descalibrado, y el síntoma parecería "medio arreglado".

## ⚠️ Dos trampas del parser Lua

**1. `hyprctl keyword` ya no sirve.** Es lo primero que uno intenta para probar
en caliente, y responde:

```
keyword can't work with non-legacy parsers. Use eval.
```

**2. `eval` responde `ok` sin demostrar nada.** El equivalente sí se acepta:

```
$ hyprctl eval 'hl.device({ name = "elan9024:00-04f3:4297-stylus", output = "eDP-1" })'
ok
```

Pero ese `ok` solo dice que la llamada Lua se ejecutó sin error de sintaxis, no
que el dispositivo se haya remapeado. Y el camino de vuelta está cerrado:

```
$ hyprctl getoption 'device[elan9024:00-04f3:4297-stylus]:output'
no such option
```

O sea que **el mapeo de un device no se puede leer de vuelta por software**. No
hay forma de verificar este arreglo salvo tocando la pantalla.

Por eso se abandonó la vía del `eval` en caliente y se fue directo al archivo
más `hyprctl reload`, que re-aplica la configuración entera desde cero y además
es lo que hace falta para que el arreglo sea permanente.

## Validación

- `hyprctl reload` → `ok`
- `hyprctl configerrors` → **vacío**
- Los dos dispositivos siguen en `hyprctl devices` tras el reload, y las dos
  salidas activas

Lo que **no** se pudo verificar por software es que el trazo caiga ahora bajo la
punta, por el motivo de arriba. **Confirmado a mano por el usuario el mismo día**,
con el monitor externo conectado: el lápiz vuelve a calibrar.

## Si volviera a fallar

Distinguir el tipo de desfase, porque apuntan a causas distintas:

- **Proporcional** (crece según te alejas de una esquina) → sigue siendo un
  problema de área: el anclaje no se está aplicando, o la salida cambió de
  nombre.
- **Constante** (desplazamiento fijo en toda la pantalla) → no es el área;
  mirar `transform` y la escala de `eDP-1`.
