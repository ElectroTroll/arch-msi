# Hardware

Inventario verificado mediante auditoría no destructiva (2026-07-22) sobre el
equipo real. Salvo donde se indica, todos los datos provienen de `hostnamectl`,
`lscpu`, `lspci -nnk`, `lsblk -f`, `findmnt`, `dmidecode` y sysfs.

## Equipo

- **Modelo:** MSI Summit E16 AI Studio A1VFTG (serie A1V)
- **SKU:** 1596.1 · **Versión:** REV:1.0
- **Fabricante:** Micro-Star International Co., Ltd.
- **Firmware:** E1596IMS.10D (fecha 2024-10-01)
- **Hostname:** elok-archmsi
- **Chasis:** portátil convertible

## CPU

- **Intel Core Ultra 7 155H** (Meteor Lake-H, familia 6, modelo 170)
- 16 núcleos / 22 hilos · hasta 4,8 GHz · microcódigo `intel-ucode`
- Cachés: L2 18 MiB, L3 24 MiB
- Virtualización VT-x

## Memoria

- **16 GB LPDDR5-6400** · SK Hynix
- 8 × 2 GiB on-package (Controller0/1 × Channel A–D)
- **Soldada / on-package: no ampliable.**

## Gráficos (híbridos)

- **iGPU:** Intel Arc Graphics (Meteor Lake-P) `[8086:7d55]` · driver `i915`
  (módulo `xe` disponible)
- **dGPU:** NVIDIA GeForce RTX 4060 Mobile / Max-Q (AD107M) `[10de:28a0]`
  · driver `nvidia` (open) · 8 GB VRAM
- Audio HDMI/DP NVIDIA `[10de:22be]` (`snd_hda_intel`)

## Acelerador de IA

- **NPU Intel** (Meteor Lake) `[8086:7d1d]` · driver `intel_vpu`
- GNA (Gaussian & Neural-Network Accelerator) `[8086:7e4c]`

## Almacenamiento

- **NVMe Samsung PM9A1 1 TB** (`MZVL21T0HCLR-00B00`) — versión OEM,
  clase 980 PRO, PCIe 4.0. (Corrige la referencia previa a "990 Pro".)
- Gestionado a través de **Intel VMD / RST** (activo en BIOS).
- Lector de tarjetas Realtek RTS525A · Thunderbolt presente.

### Distribución del disco (dual boot)

| Partición    | FS      | Etiqueta | Uso                         |
|--------------|---------|----------|-----------------------------|
| nvme0n1p1    | vfat    | SYSTEM   | ESP (~300 MB) → `/boot/efi`, **compartida con Windows** |
| nvme0n1p2    | —       | —        | Microsoft Reserved (MSR)    |
| nvme0n1p3    | ntfs    | Windows  | Windows                     |
| nvme0n1p4    | ntfs    | —        | NTFS (datos/recovery)       |
| nvme0n1p5    | ntfs    | BIOS_RVY | Recovery MSI                |
| nvme0n1p6    | btrfs   | —        | Linux (raíz + home)         |

> ⚠️ Las particiones p1–p5 pertenecen a Windows / MSI. **No tocar.**

## Red

- **Wi-Fi 7** Intel `[8086:272b]` (clase BE200 / AX1790, subsistema
  Killer/Rivet Networks) · driver `iwlwifi`
- Gestión con NetworkManager

## Audio

- Intel SOF (`sof-audio-pci-intel-mtl` / `snd_hda_intel`)
- Servidor de sonido: PipeWire

## Pantalla

Verificado con `hyprctl monitors` y `hyprctl devices` (2026-07-22).

- **Salida:** `eDP-1` · panel **AU Optronics 0xD298** · 340×220 mm.
- **Resolución:** 2560×1600 (QHD+, 16:10) a **165.04 Hz**.
  Modos disponibles: `2560x1600@165.04Hz` y `2560x1600@60.04Hz`.
- **Escala:** 1.60 (HiDPI) · gestión de color: preset **sRGB** · **VRR
  desactivado**.
- **Táctil:** panel táctil `elan9024:00-04f3:4297` (Touch Device).
- **Lápiz activo:** soportado vía tablet `elan9024:00-04f3:4297-stylus`.
- **Touchpad:** `elan0305:00-04f3:31fd-touchpad` · **natural scrolling
  activado** (scroll factor `-1.00`).

## Firmware / BIOS

- E1596IMS.10D (2024-10-01). VMD (Intel RST) activo — condiciona cualquier
  reinstalación (la visibilidad del NVMe depende de este ajuste).
