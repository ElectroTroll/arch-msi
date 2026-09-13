# 2026-09-13 · El rótulo `[ALSA UCM error]` de la SSL 2+, y los canales que no faltaban

Pregunta de partida: *¿por qué cada vez que selecciono la interfaz como salida
de audio pone `[ALSA UCM error]`?* La sospecha documentada desde el 2026-09-08
(§15) era peor que el síntoma: que el perfil UCM dejara **canales físicos sin
exponer**. Resultó que no, y que el arreglo ya estaba escrito por otra persona.

---

## 1. El síntoma y su causa exacta

La tarjeta aparecía en pavucontrol, en Waybar y en el selector de salida como
`SSL 2+ Mk II [ALSA UCM error]`, y wireplumber lo registraba en cada arranque:

```
spa.alsa: Error in ALSA UCM profile for _ucm0004.hw:II,0 (HiFi: Line2: sink): PlaybackChannels=4 < avail 6
spa.alsa: Error in ALSA UCM profile for _ucm0004.hw:II,0 (HiFi: Mic2: source): CaptureChannels=4 < avail 8
```

El perfil de `alsa-ucm-conf` en `ucm2/USB-Audio/SolidStateLabs/SSL2.conf`
declara `DirectPlaybackChannels`: 2 por defecto, y **4** si el componente casa
`USB31e9:000[29]` —el nuestro es `0009`, la Mk II—. Para captura declara **4**;
bajaría a 2 solo si `bcdDevice` casara con el regex `00..`, y el nuestro es
`0116`, que no casa.

El hardware dice otra cosa. De `/proc/asound/cardN/stream0`:

| | UCM declaraba | Hardware expone |
|---|---|---|
| Playback | 4 | **6** (S32_LE, hasta 192 kHz) |
| Capture | 4 | **8** (S32_LE, hasta 192 kHz) |

PipeWire compara los dos recuentos en `libspa-alsa.so` (`Error in ALSA UCM
profile ... Channels=%d < avail %d`) y, si no cuadran, cuelga la cadena literal
`%s [ALSA UCM error]` de la descripción de la tarjeta. De ahí que salga en todas
partes: no es un mensaje de error de la app que lo muestra, es el nombre del
dispositivo.

## 2. La vía que no era: el perfil `pro-audio`

§15 proponía mirar si «Pro Audio» (que ignora UCM) sacaba más canales que
`HiFi`. Se probó, y devuelve dos respuestas, una útil y otra que cierra la vía:

- **Sí** saca los 6 y 8 canales en crudo, pero como `aux0…aux5` / `aux0…aux7`,
  sin nombres que digan qué es cada uno.
- **El rótulo sigue ahí**: la descripción pasa a `SSL 2+ Mk II [ALSA UCM error]
  Pro`. La cadena se fija al **sondear** la tarjeta, no depende del perfil
  activo. Cambiar de perfil no arregla nada.

Y habría roto algo: `audio-salida` identifica el sink por el nombre `Line1`
(`PREFERENCIA_USB='Line1'`), que en `pro-audio` no existe. Dejar la tarjeta en
ese perfil se lleva por delante `Super + Z`.

## 3. Los canales que no faltaban

Esto no hacía falta medirlo con tonos: está en la documentación de SSL.

| | Qué hay de verdad |
|---|---|
| Entradas físicas | **2** (Mic/Line/Inst 1 y 2). No hay más |
| Salidas físicas | **4** jacks balanceados atrás = salidas 1-4 (la MkII sustituyó los RCA de la MkI) |
| Auriculares A y B | Ambos toman los buses 1/2 y 3/4; el botón **3&4** conmuta B a 3-4 para una mezcla independiente |
| Loopback | Una actualización de firmware lo subió de **1 par estéreo a 3** |

Con eso cuadran los 8 de captura: **2 entradas físicas + 6 de loopback**. No son
entradas perdidas, son retornos virtuales para streaming y podcast.

De los 6 de reproducción, 4 son los jacks del panel trasero. Sobre el par 5/6,
el autor del parche de abajo lo dejó escrito tras probarlo:

> Los canales USB de reproducción 5/6 están presentes en los descriptores del
> dispositivo pero **no producen salida audible en ninguna de las dos salidas de
> auriculares**, que llevan los buses 1/2 y 3/4 (probado en SSL 2+ MK II,
> `bcdDevice 0116`).

`0116` es el firmware de esta interfaz, comprobado en
`/sys/bus/usb/devices/3-2.1/bcdDevice`. Mismo hardware y mismo firmware, así que
la prueba vale tal cual.

**Conclusión: `Line1`, `Line2`, `Mic1` y `Mic2` ya cubrían todo lo que tiene
conectores.** La sospecha de §15 era infundada; lo único roto era un número mal
declarado.

## 4. El arreglo ya estaba escrito, y lleva tres semanas parado

PR **#837** de `alsa-ucm-conf`, *«ucm2: USB-Audio: fix channel counts for SSL 2+
MK II»*, de Alan Tran-Kiem, 2026-08-24. Añade una condición para `USB31e9:0009`
con `DirectPlaybackChannels 6` / `DirectCaptureChannels 8`, y una rama `If.chn6`
en `SSL2-HiFi.conf` que sabe partir un split de 6 canales (antes solo manejaba
splits de 4, y por eso la MkII caía en el caso «Stereo Line» sin partir). El
propio PR explica que el soporte MkII se añadió en su día **sin verificarlo en
un aparato real**, y por eso heredó los 4/4 de la MkI.

Estado comprobado contra la API de GitHub el 2026-09-13: `state: open`,
`merged: false`, **0 comentarios** desde el 24 de agosto. La última etiqueta
upstream es `v1.2.16.1`, que es justo la instalada. No está en ninguna versión
publicada.

El parche aplica limpio sobre los archivos instalados (`patch --dry-run`), así
que se aplica en local.

## 5. Por qué pisa archivos de un paquete

Porque no hay alternativa. `alsa-lib` solo busca perfiles UCM en
`/usr/share/alsa/ucm2` —comprobado con `strings` sobre `libasound.so.2`: las
únicas rutas que conoce son esa y `%s/ucm2/conf.virt.d`—. **No existe ruta de
override en `/etc` ni en `$HOME`.**

Consecuencia asumida, escrita en la cabecera del script para que no se pierda:
**cada actualización de `alsa-ucm-conf` devuelve los originales en silencio y el
rótulo vuelve.** Hay que reejecutar `alsa-ucm-apply`.

El script sigue la convención de `system/` que ya usaba el greeter —se copia con
sudo, no se enlaza— y añade dos guardas:

- **Guardián por sumas MD5.** Si lo instalado no coincide ni con los archivos de
  fábrica ni con los parcheados, upstream cambió el perfil: el script **se niega
  a tocar nada** y avisa de que hay que mirar si el PR ya entró, en vez de pisar
  a ciegas.
- **El respaldo solo se escribe la primera vez.** Sobrescribirlo con algo ya
  parcheado destruiría la vuelta atrás.

## 6. Validación

Tras `sudo scripts/alsa-ucm-apply.sh` y `systemctl --user restart wireplumber`:

- `journalctl --user -u wireplumber | grep -i ucm` → **ninguna línea**.
- `device.description = "SSL 2+ Mk II"`, sin sufijo.
- Los sinks `HiFi__Line1__sink` y `HiFi__Line2__sink` y los sources `Mic1` /
  `Mic2` siguen ahí con los mismos nombres; `audio-salida --status` los lista
  limpios, así que `Super + Z` no se ha visto afectado.
- Perfil activo: sigue `HiFi`.

## 7. De paso: el número de tarjeta no es fijo

§22 decía «tarjeta ALSA `1 [II]`». Hoy la SSL es la **2** (`hw:2`); la 1 es
`sof-hda-dsp` y la 0 la NVIDIA. El número depende del orden de enumeración y
cambia entre arranques y reconexiones. Lo estable es el identificador `II` —de
ahí que `amixer -cII` funcione igual que `amixer -c 2`— y el nombre del sink,
que es exactamente el motivo por el que `audio-salida` busca por nombre y no por
ID. Corregido en §22.

## 8. Cuando el PR entre upstream

Esto sobra entero: `sudo scripts/alsa-ucm-apply.sh --revert`, borrar
`system/alsa/` y `scripts/alsa-ucm-apply.sh`, y quitar la nota de §22.

Seguimiento: https://github.com/alsa-project/alsa-ucm-conf/pull/837
