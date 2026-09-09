# 2026-09-09 · Ver el iPad desde el portátil: TeamViewer y una dependencia que el AUR no declara

Pregunta de partida: *¿se puede acceder en remoto a un iPad desde Linux, con
algo tipo AnyDesk?* La respuesta corta es **no como AnyDesk**, y el motivo no
está en Linux sino en iPadOS. De ahí salió la instalación de TeamViewer, que
falló al primer arranque por una dependencia ausente en el empaquetado.

---

## 1. Por qué no existe el «AnyDesk para iPad»

Apple no expone ninguna API que permita a una app de terceros controlar el
dispositivo. Las apps de AnyDesk, RustDesk y compañía para iPadOS son **solo
clientes**: desde el iPad controlas otros equipos, nunca al revés.

Lo máximo que permite el sistema es **compartir la pantalla** mediante
ReplayKit, y eso lo implementa `TeamViewer QuickSupport`. De ahí la elección:

| | Sirve para ver el iPad |
|---|---|
| **AnyDesk** (`aur/anydesk-bin 8.0.4-1`) | **No.** Su app de iOS es solo cliente |
| **TeamViewer** (`aur/teamviewer 15.79.4-1`) | Sí, vía QuickSupport, **solo visión** |

No se eligió TeamViewer por ser mejor programa: es que **AnyDesk no puede hacer
esto en absoluto**. Si el objetivo se reduce a ver la pantalla del iPad dentro
de la LAN, `aur/uxplay` (receptor AirPlay) hace lo mismo sin cuenta, sin
software propietario y sin límites de licencia; TeamViewer solo gana cuando hace
falta alcance por Internet.

## 2. El fallo: `status=127` por `libminizip.so.1`

Tras `paru -S teamviewer` y habilitar el servicio, el demonio no arrancó:

```
teamviewerd: error while loading shared libraries: libminizip.so.1:
cannot open shared object file: No such file or directory
teamviewerd.service: Control process exited, code=exited, status=127/n/a
```

⚠️ **No es un problema del sistema: es el paquete AUR, que no declara la
dependencia.** Comprobado en su propio `PKGBUILD`:

```
depends=(hicolor-icon-theme qt5-x11extras qt5-quickcontrols qt5-svg)
```

`minizip` no está ahí, y no venía arrastrado por nada más: no existía ningún
`/usr/lib/libminizip*` en el equipo. Encaja con que el paquete esté **marcado
como desactualizado en el AUR desde el 2026-07-23**.

`ldd` sobre los dos binarios (`teamviewerd` y `TeamViewer`) confirmó que era la
**única** biblioteca ausente, así que bastó con:

```
sudo pacman -S minizip     # core/minizip 1:1.3.2-3
```

que sí provee el soname exacto:

```
/usr/lib/libminizip.so.1 -> libminizip.so.1.0.0
```

**Cómo diagnosticarlo de nuevo en 30 segundos**, sin adivinar: `ldd
/opt/teamviewer/tv_bin/teamviewerd | grep "not found"` da el nombre de la
biblioteca, y `pacman -Fx 'libminizip\.so\.1$'` el paquete que la provee (hace
falta `pacman -Fy` una vez: la base de datos de ficheros no estaba descargada).

## 3. La trampa menor: el servicio no se reinicia solo

Con `minizip` ya instalado el servicio **seguía en `failed`**, y a primera vista
parecía que el arreglo no había funcionado. No era eso: la unidad conservaba el
error **de la ejecución anterior**, misma invocación (`cb5e1cb3…`) y misma marca
de tiempo. El demonio nunca llegó a probar la biblioteca nueva porque nadie lo
había vuelto a lanzar.

Lección aplicable a cualquier `status=127`: **comparar la marca de tiempo y el
`Invocation:` del fallo con la hora del arreglo** antes de concluir que el
arreglo no sirvió.

## 4. Estado final verificado

| Comprobación | Resultado |
|---|---|
| `systemctl is-active teamviewerd` | `active` desde las 17:17:06, invocación nueva |
| `ldd .../teamviewerd \| grep "not found"` | vacío |
| GUI | en marcha, y **bajo XWayland** (`hyprctl clients`: `"class": "TeamViewer"`, `"xwayland": true`) |

**Lo que esto da y lo que no:** la pantalla del iPad en el portátil, **solo
visión**. No hay control: es la limitación de iPadOS del §1, no un ajuste
pendiente. Cada sesión exige además pulsar *Iniciar transmisión* a mano en el
iPad (diálogo de ReplayKit); iPadOS no permite dejarlo autorizado.

⚠️ **Sin probar**: la dirección contraria, compartir la pantalla de Hyprland
hacia fuera. TeamViewer es un cliente de la era X11 y funciona aquí bajo
XWayland, que sirve para *ver*, pero la captura de la sesión Wayland es otro
asunto. No se ha intentado y no debe darse por buena.

⚠️ **Licencia**: gratuito solo para uso personal, con detección agresiva de
«uso comercial» que corta sesiones a los pocos minutos. Hay que declarar uso
personal en el primer arranque.

## 5. Qué toca en el repositorio

Inventarios regenerados con `scripts/update-inventories.sh`:

- `packages/aur.txt` → `teamviewer`
- `packages/pacman-explicit.txt` → `teamviewer`, `minizip`
- `packages/services-enabled.txt` → `teamviewerd.service`

**El ID de TeamViewer no se versiona**, ni el contenido de
`~/.config/teamviewer/client.conf`: es un identificador de acceso remoto y cae
de lleno en las reglas de `CLAUDE.md`.

⚠️ **Desfase ajeno a esta tarea**: la regeneración arrastró también `nano`
(instalado el 2026-09-09 a las 01:07, antes de esta sesión, por un camino que no
consta). Se deja en el inventario porque refleja el estado real del equipo, pero
**no lo instaló este trabajo**.
