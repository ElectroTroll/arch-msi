# Incidente de arranque: Windows renumeró las particiones (2026-08-24)

El sistema dejó de arrancar y cayó a `grub rescue>` con `unknown filesystem`.
Ni el disco ni el sistema de archivos tenían nada roto: lo único inválido era
una referencia grabada dentro del núcleo de GRUB.

## Qué pasó

Una actualización de Windows renumeró las particiones del NVMe. Dos de ellas
intercambiaron su número:

| Antes | Después | Contenido |
|-------|---------|-----------|
| `nvme0n1p6` | **`nvme0n1p5`** | Btrfs de Linux (raíz + home) |
| `nvme0n1p5` | **`nvme0n1p6`** | NTFS de recovery de MSI (`BIOS_RVY`) |

`grub-install` graba en el núcleo de GRUB la ubicación de `/boot/grub` como
**`(hd0,gptN)`** — una referencia **posicional**, no un UUID. GRUB tenía
grabado `(hd0,gpt6)`. Tras la renumeración, ese `(hd0,gpt6)` ya no era la raíz
Btrfs sino la NTFS de recovery, un sistema de archivos que GRUB no sabe leer en
esa fase. De ahí el `unknown filesystem` y la caída a la consola de rescate.

**El sistema de archivos de Linux estaba intacto todo el tiempo.** El fallo era
exclusivamente del bootloader.

## Por qué el `fstab` no se enteró

Un detalle que conviene entender, porque es la razón de que la recuperación
fuera limpia: `/etc/fstab` monta por **UUID**, no por nombre de dispositivo.

```
UUID=27a7d1f2-e0a7-4444-aba7-95611f71b5aa  /      btrfs  …,subvol=/@
UUID=27a7d1f2-e0a7-4444-aba7-95611f71b5aa  /home  btrfs  …,subvol=/@home
```

El UUID del sistema de archivos **no cambia** cuando cambia el número de
partición. Así que el `fstab` seguía siendo correcto y no hubo que tocarlo: en
cuanto GRUB consiguió cargar el kernel, `/` y `/home` montaron sin problema.

La moraleja se sostiene sola: **lo que se identifica por UUID sobrevive a una
renumeración; lo que se identifica por posición, no.** El `fstab` estaba en el
primer grupo. El núcleo de GRUB, en el segundo.

(Los comentarios `# /dev/nvme0n1p6` que `genfstab` dejó en el `fstab` sí
quedaron obsoletos, pero son solo comentarios y no afectan al montaje.)

## La reparación

Desde un USB de Arch, con chroot sobre el sistema instalado:

```
grub-install …
grub-mkconfig -o /boot/grub/grub.cfg
```

`grub-install` vuelve a grabar el núcleo con la posición **actual**, y
`grub-mkconfig` reescribe el menú. Windows siguió apareciendo en el menú tras la
reparación.

Rastro que dejó, visible en las fechas de los archivos:

```
grubx64.efi     2026-08-24 19:15   ← grub-install
x86_64-efi/     2026-08-24 19:15   ← módulos recopiados
grub.cfg        2026-08-24 19:16   ← grub-mkconfig
grub-btrfs.cfg  2026-08-24 19:16   ← submenú de snapshots regenerado
```

## El efecto colateral del reloj

Esas marcas de tiempo (19:15, 19:16) parecen posteriores a la hora real, y
tienen explicación. El primer arranque tras la reparación empezó marcando
**19:21**, y `systemd-timesyncd` lo corrigió **dos horas hacia atrás**:

```
ago 24 19:21:22  systemd-timesyncd: Starting Network Time Synchronization...
ago 24 17:22:01  systemd-timesyncd: Initial clock synchronization to 17:22:01 CEST
```

Es el patrón clásico de dual boot: **Windows escribe el reloj de hardware en
hora local**, y Linux lo interpreta como UTC. Ya está resuelto —`timedatectl`
confirma `RTC in local TZ: no` y timesyncd reescribió el RTC en UTC—, pero
conviene saberlo porque hace que los timestamps del incidente parezcan del
futuro cuando se leen después.

## Verificación posterior

Tras la reparación se hizo una verificación completa de solo lectura
(particiones, montajes, `fstab`, subvolúmenes, entradas EFI, servicios, enlaces
de Stow, journal y RTD3 de la dGPU). Todo salió correcto:

- `/` y `/home` montando desde `p5`, subvolúmenes con los mismos IDs
  (`@` 256, `@home` 257, `.snapshots` 261 anidado).
- `btrfs device stats` con los cinco contadores de error a **0**.
- `BootOrder 0001,0000` — GRUB primero, Windows después.
- Cero unidades fallidas, cero divergencias de servicios, cero conflictos de
  Stow, RTD3 de la NVIDIA en `D3cold`.

Se aprovechó para aplicar la actualización pendiente (23 días sin actualizar):
**221 paquetes de repos oficiales + 3 de AUR**, incluidos `linux`, `linux-lts`,
`nvidia-open-dkms`, `dkms`, `mkinitcpio`, `glibc` y `gcc`. Ni `grub` ni
`systemd` estaban entre ellos, así que el bootloader recién reparado no se
reinstaló.

Tras actualizar y regenerar el menú, se comprobó que la reparación seguía en
pie:

- **0** referencias `(hd0,gptN)` en `grub.cfg`.
- **5** resoluciones `search --no-floppy --fs-uuid`.
- Entrada de Windows como `osprober-efi-DEFF-2D9C` — **por UUID de la ESP**.
- NVRAM EFI **byte a byte idéntica** a la de antes de actualizar.
- Submenú de snapshots con 50 entradas.

El reinicio de validación arrancó `linux-lts` 6.18.46 sin incidencias.

## Lección

El menú ya no depende de la numeración de particiones, ni para Linux ni para
Windows. Aun así, la comprobación barata que detecta el problema **antes** de
que impida arrancar es:

```
sudo grep -c "hd0,gpt" /boot/grub/grub.cfg    # debe devolver 0
```

Conviene lanzarla tras cualquier actualización grande de Windows. Si devuelve
algo distinto de 0, regenerar con `grub-mkconfig` **antes** de reiniciar.

Y el aprendizaje general, que va más allá de GRUB: **preferir siempre
identificadores estables (UUID, PARTUUID, etiquetas) frente a nombres
posicionales (`/dev/sdaN`, `(hd0,gptN)`)** en cualquier configuración que deba
sobrevivir a cambios de disco. El `fstab` ya lo hacía bien y por eso no se
enteró del incidente.
