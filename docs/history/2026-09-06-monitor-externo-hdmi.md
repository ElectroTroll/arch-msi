# 2026-09-06 · El HDMI cuelga de la NVIDIA: medidas y qué se puede hacer

Sesión de diagnóstico, **sin cambios en el sistema**. Punto de partida: un LG
UltraGear conectado por HDMI y una pregunta simple — ¿qué GPU lo está moviendo,
la Intel o la NVIDIA?

La respuesta corta es *las dos, con reparto*. La larga está en
`PROJECT_CONTEXT.md` §6; aquí queda el rastro de cómo se llegó y los dos
tropiezos del camino.

---

## 1. La respuesta: el puerto es de la NVIDIA, el render es de la Intel

Es la distinción que costó separar, y es la que importa:

- **El conector `HDMI-A-1` solo existe bajo `card2` (`nvidia`).** `card1`
  (`i915`) expone `eDP-1` y tres `DP-*`, ninguno HDMI. Eso no es una decisión de
  configuración: es cómo está cableada la placa.
- **Pero Hyprland compone en la Intel.** El log de aquamarine lo dice literal:
  `gpu /dev/dri/card1 becomes primary drm`, y arranca `card2` *con*
  `primary /dev/dri/card1`. La NVIDIA solo hace el *scanout* del panel externo.

O sea: la dGPU está despierta haciendo de puente, no renderizando. `glxinfo -B`
sigue devolviendo Mesa Intel Arc y no hay una sola variable de entorno NVIDIA/
GBM/WLR forzada. PRIME offload intacto.

La huella de la copia entre GPUs aparece sola en el log:

```
GBM: Buffer is marked as multigpu, forcing linear
```

## 2. La trampa de `nvidia-smi`, reproducida al pie de la letra

`PROJECT_CONTEXT.md` §6 ya avisaba desde el 2026-07-22: **no usar `nvidia-smi`,
porque despierta la GPU y falsea la lectura.** Se usó igualmente, y el aviso se
cumplió con precisión incómoda.

| Lectura | Resultado |
|---------|-----------|
| Primera consulta de `nvidia-smi` | **9,49 W · 24 % de uso · P3** |
| Muestreo sostenido (26 lecturas / 32 s) | **2,1–2,3 W · 0 % · P8 · 210 MHz** |

Ese 9,49 W se llegó a comunicar como dato bueno antes de comprobarlo. Era el
propio comando despertando la GPU y midiéndose a sí mismo. Un factor de 4,5×
sobre el valor real, y suficiente para haber justificado una «optimización»
contra un problema inexistente.

**Matiz que el aviso original no cubría:** con el HDMI conectado la GPU ya está
despierta, así que `nvidia-smi` no rompe nada — pero **la primera lectura sigue
sin servir**. Hay que muestrear varios segundos, o quedarse en sysfs.

## 3. Lo que sí zanjó la duda: los contadores del kernel

Ninguna medida de vatios fue tan concluyente como esto, y no despierta nada:

```
/sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time  → 27,0 min
/sys/bus/pci/devices/0000:01:00.0/power/runtime_active_time     → 15,8 min
uptime                                                          → 42 min
```

27 + 15,8 ≈ 42. La dGPU estuvo suspendida **todo** el tiempo hasta que se
enchufó el cable, y **activa sin interrupción** desde entonces. El mecanismo
queda demostrado sin depender de ninguna lectura instantánea.

Complementos del mismo bloque:

- `/proc/driver/nvidia/gpus/*/power`: `Video Memory` pasa de `Off` a `Active`.
  El RTD3 sigue `Enabled (fine-grained)` — no se ha roto, está inhibido.
- La función de audio `01:00.1` **sí** sigue suspendida (`D3hot`): el HDMI lleva
  vídeo, pero nadie usa su salida de sonido.

## 4. ¿Es mucho? No

~2,1–2,3 W sobre una batería de 71 Wh. dGPU a 45 °C, CPU package a 55 °C, NVMe a
43 °C: todo en reposo normal. Los 2774 RPM de los ventiladores son el perfil por
defecto de MSI, no una reacción al calor de la dGPU.

Perceptible en autonomía a lo largo de una jornada. Irrelevante enchufado.
**No justifica tocar nada.**

## 5. Lo que NO funciona como bypass

Se descartaron por escrito para no volver sobre ellas:

- **Blacklistear `nvidia`.** Deja el HDMI muerto y, sin driver gestionando el
  PM, la dGPU puede consumir *más*. Además rompe un invariante del proyecto.
- **Modo «Discrete Graphics» en la BIOS de MSI.** Hace lo contrario: fuerza
  *todo* por la NVIDIA. La opción inversa no existe, porque no puede existir.
- **`AQ_DRM_DEVICES` apuntando a la NVIDIA.** Quitaría la copia entre GPUs a
  cambio de renderizar el escritorio entero en la dGPU. Mucho peor.

## 6. La única vía real, y está sin probar

`card1` expone `DP-1`, `DP-2` y `DP-3` **desconectados**. Apuntan a las salidas
DisplayPort alt-mode de los Type-C (`port0`, `port1`, más un dominio
Thunderbolt). Si el monitor entra por ahí y aparece como `card1-DP-N`, la NVIDIA
vuelve a D3cold y desaparece también la copia entre GPUs.

**No se ha comprobado.** No se descarta que alguno de los Type-C esté también
cableado a la dGPU, que pasa en algunos MSI. Anotado en §15 con la prueba
concreta: conectar y mirar `/sys/class/drm/card*-*/status` junto a
`runtime_status`.

---

## Lecciones

1. **Un aviso en la documentación propia vale más que una herramienta cómoda.**
   El de `nvidia-smi` llevaba escrito desde julio y describía exactamente lo que
   pasó.
2. **Los contadores acumulados baten a las lecturas instantáneas.**
   `runtime_suspended_time` frente al reloj demostró el mecanismo entero sin
   perturbar el sistema.
3. **«Qué GPU se usa» son dos preguntas, no una:** quién *renderiza* y quién
   *saca la señal por el puerto*. Aquí la respuesta es distinta para cada una.
