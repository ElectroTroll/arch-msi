# 2026-09-15 · Arch no arranca a la primera: GRUB se atasca cargando 221 MB de initramfs

Cada cierto tiempo, al elegir Arch en el menú de GRUB, el portátil se queda
congelado y no llega a iniciar el sistema. La única salida es mantener pulsado
el botón de encendido y reintentar varias veces hasta que arranca. **No está
corregido**: este documento deja escrito el diagnóstico, la medida y la
propuesta, para no rehacer la investigación la próxima vez.

## 1. El síntoma, medido

El episodio del 2026-09-15 quedó fechado en el journal:

| Evento | Hora |
|---|---|
| Apagado limpio del arranque anterior | **14:05:35** |
| Siguiente arranque correcto | **14:16:15** |
| **Hueco** | **10 min 40 s** |

La referencia que da sentido a ese número: los reinicios normales de este equipo
tardan **16–18 s** entre el último mensaje de apagado y el primero del arranque
siguiente (medido en los boots −24/−23, −20, −17, −16, −15 y −3 de
`journalctl --list-boots`). Los 10 min 40 s son los ciclos de botón de encendido.

**El arranque fallido no dejó ni una línea en el journal.** Eso acota el fallo a
la ventana anterior al primer volcado de `systemd-journald`: GRUB, kernel
temprano o initramfs.

## 2. Dónde se congela

Con `loglevel=3 quiet` en la línea de comandos no hay nada que leer, así que la
única prueba disponible es mirar la pantalla. El usuario confirma lo que ve:
**el texto de carga de GRUB congelado** (`Loading Linux …` / `Loading initial
ramdisk …`).

Eso sitúa el cuelgue en la **fase de carga del bootloader**, antes de que el
kernel tome el control. Descarta el initramfs y el kernel temprano como lugar
del fallo.

## 3. La anomalía: un initramfs de 221 MB

```
/boot/initramfs-linux-lts.img   221 MiB   (231 542 665 B)
/boot/initramfs-linux.img       223 MiB   (233 063 604 B)
/boot/vmlinuz-linux-lts          16 MiB
/boot/intel-ucode.img            15 MiB
```

Un initramfs normal en este equipo serían 40–60 MB. La causa está identificada y
es una sola línea de `/etc/mkinitcpio.conf`:

```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

`modinfo nvidia` declara cuatro blobs de firmware, y el hook `modconf` los mete
dentro del initramfs:

| Archivo | Tamaño |
|---|---|
| `nvidia/615.71.09/ucodes_ga10x.bin` | 56 MB |
| `nvidia/615.71.09/gsp_ga10x.bin` | 26 MB |
| `nvidia/615.71.09/gsp_tu10x.bin` | 22 MB |
| `nvidia/615.71.09/ucodes_tu10x.bin` | 8,5 MB |
| **Subtotal firmware** | **112 MB** |
| Los cinco `.ko` de `nvidia-open` (sin comprimir) | ~37 MB |

Todo eso ya viene comprimido, así que el zstd del initramfs apenas lo reduce.

## 4. Por qué encaja con el síntoma

Al elegir la entrada, GRUB tiene que leer **~252 MB** (221 de initramfs + 16 de
kernel + 15 de microcódigo) desde un subvolumen Btrfs montado con
`compress=zstd:3`, usando su propio driver de Btrfs, y cargarlos en memoria
antes de que el kernel imprima una sola letra. Es exactamente la fase donde se
ve el cuelgue.

Y se nota en la medida. Etapa `loader` de `systemd-analyze` en los 15 arranques
registrados: entre **3,9 s y 6,1 s**, un 55 % de variación. Ninguna otra etapa
se mueve así:

| Etapa | Rango observado |
|---|---|
| `firmware` | 5,3 – 6,3 s |
| **`loader` (GRUB)** | **3,9 – 6,1 s** |
| `kernel` | 0,74 – 0,93 s |
| `initrd` | 2,8 – 4,2 s |

La intermitencia encaja con que el mapa de memoria EFI que entrega el firmware
AMI no es idéntico en arranque en frío y en caliente.

> **Lo que está probado y lo que no.** Probado: el cuelgue existe y está fechado;
> ocurre en la fase de carga de GRUB; el initramfs pesa 221 MB y se sabe por qué.
> **No probado: que el tamaño sea la causa del cuelgue.** Es una inferencia, la
> más plausible y la única anomalía medible en esa fase, pero GRUB no deja log y
> el fallo es intermitente.

## 5. Lo que se descartó, con evidencia

- **No es un fallo de disco ni de sistema de archivos.** Cero errores de NVMe,
  ATA, checksum o corrupción de Btrfs en todo el journal.
- **No es el incidente del 2026-08-24** (`hd0,gptN` renumerado por Windows). Ese
  daba `grub rescue>` visible y era **permanente**, no intermitente.
- **No es un apagado sucio.** El apagado previo iba con la secuencia normal
  (última línea, `Starting Generate shutdown-ramfs...`).
- **No es hibernación.** No hay swap en disco ni hook `resume`.
- **No es falta de espacio.** ESP al 12 % (36 MB de 296 MB); raíz al 17 %.

## 6. Lo que queda sin comprobar

- **Desde cuándo pesa 221 MB.** Los initramfs actuales son del **2026-09-14
  22:10**, la misma hora en que se actualizaron `mkinitcpio` (41.1 → 42) y
  `linux-firmware-nvidia` (20260810-2 → 20260910-1). El historial está dentro de
  los snapshots de Snapper —`/boot` vive en el subvolumen `@`— pero `/.snapshots`
  no es legible sin root, así que no se pudo mirar.
- **La frecuencia real.** En el journal solo hay un episodio identificable con
  certeza: los reinicios rápidos que se ven son 6, y falló 1. Los demás huecos
  entre arranques son largos (noches, apagados) y no permiten distinguir un
  cuelgue de un apagado normal.
- **La BIOS.** `E1596IMS.10D`, de **10/2024**. No se ha mirado si MSI publicó
  algo posterior.

## 7. La corrección propuesta — **NO aplicada**

El KMS temprano de NVIDIA no aporta nada en este equipo: la pantalla interna
cuelga de la Intel (`i915` dibuja en `card1-eDP-1`) y la NVIDIA dice
`Cannot find any crtc or sizes`. Solo entra bajo demanda con `prime-run`.

```diff
 # /etc/mkinitcpio.conf
-MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
+MODULES=()
```

```
sudo mkinitcpio -P          # ← sudo
```

Sacar NVIDIA de `MODULES` **no desactiva PRIME offload ni Runtime D3**: solo
mueve la carga del módulo del initramfs a udev, ya sobre la raíz montada, donde
un fallo además quedaría registrado. `nouveau`, `nova_core` y `nova_drm` siguen
en la lista negra de `/usr/lib/modprobe.d/nvidia-utils.conf`, así que no hay
carrera de drivers.

> **Contradice lo que dice §4 de `PROJECT_CONTEXT.md`**, que presenta ese
> `MODULES` como necesario ("el orden inverso dejaría el arranque sin driver").
> Esa frase describe el orden de los hooks de pacman, y sigue siendo cierta
> *mientras* NVIDIA esté en `MODULES`; deja de aplicar si se saca. Queda
> señalado, no corregido.

Candidata secundaria, por si la primera no basta: `GRUB_GFXPAYLOAD_LINUX=keep`
en `/etc/default/grub`. Pasar el modo gráfico de GRUB al kernel se atasca de vez
en cuando en firmwares AMI; `text` es el valor de repliegue.

## 8. Si vuelve a pasar

**Primero, hacer visible el fallo** (reversible, no toca el arranque):

```diff
 # /etc/default/grub
-GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
+GRUB_CMDLINE_LINUX_DEFAULT=""
```

```
sudo grub-mkconfig -o /boot/grub/grub.cfg      # ← sudo
```

**Medir el initramfs** (solo lectura, confirma o tumba el punto 3):

```
sudo lsinitcpio -a /boot/initramfs-linux-lts.img                    # ← sudo
sudo lsinitcpio /boot/initramfs-linux-lts.img | grep firmware/nvidia # ← sudo
```

**Detectar el episodio en el journal** — un hueco de minutos donde deberían
haber 16–18 s:

```
journalctl --list-boots
```

**Validación tras aplicar la corrección**, si se llega a aplicar:

| Qué | Cómo | Esperado |
|---|---|---|
| Tamaño | `ls -la /boot/initramfs-linux-lts.img` | 221 MB → 40–60 MB |
| Carga de GRUB | `systemd-analyze` | etapa `loader` por debajo de 2 s |
| PRIME offload | `prime-run glxinfo \| grep "OpenGL renderer"` | la RTX 4060 |
| RTD3 | `cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` | `suspended` en reposo |
| El cuelgue | Varios reinicios seguidos | sin congelarse |

El último es el único que cuenta, y es el que tarda: con una tasa de fallo
cercana a 1 de cada 6 reinicios, una tanda corta que salga bien **no demuestra
nada**.

## 9. Estado

- **Confirmado:** el cuelgue, su fecha, que ocurre en la fase de carga de GRUB,
  y que el initramfs pesa 221 MB por el firmware de NVIDIA.
- **Propuesta pendiente:** §7, sin aplicar. Decisión del usuario.
- **Sin cambios en el sistema.** Nada de `/etc` ni de `/boot` se ha tocado.
