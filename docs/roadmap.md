# Roadmap

Plan de trabajo del proyecto `arch-msi` tras completar la fase inicial
(auditoría, repositorio, documentación y primeras migraciones a Stow).

Cada tarea indica **esfuerzo** aproximado y **riesgo**. Se mantiene el método del
proyecto: inspeccionar → plan → cambio mínimo → diff → validar → commit.

> Estado de partida (2026-07-22): sistema auditado, repo público en GitHub,
> tres paquetes Stow (`hypr`, `shell`, `swappy`), snapshots con purga automática,
> capturas de pantalla funcionando.

---

## Fase 2 — Escritorio funcional

El objetivo es cerrar lo que falta para un uso diario cómodo. Es lo que más se
nota y lo más inmediato.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 2.1 | ~~**Waybar** — barra de estado~~ **[OK] Completada** | Medio | Bajo |
| 2.2 | **Dunst** — notificaciones | Bajo | Bajo |
| 2.3 | ~~**hypridle + hyprlock** — bloqueo automático~~ **[OK] Completada** | Medio | **Medio** |
| 2.4 | **hyprpaper** — fondo de pantalla | Bajo | Bajo |
| 2.5 | Limpieza: variable `menu` sobrante en `hyprland.lua` | Trivial | Nulo |

**2.1 Waybar.** **[OK] Completada (2026-08-02).** Barra superior de 34 px con
ocho módulos: workspaces (los 10, distinguiendo activo / con ventanas /
vacío), reloj, uso de Claude, volumen, Bluetooth, red, batería, perfil de
energía y menú de apagado. Cuarto paquete Stow (`dotfiles/waybar/`), más un
quinto para wlogout y un sexto para el hook de Claude Code.
`waybar.service` habilitado. Ver detalle en `docs/PROJECT_CONTEXT.md` §13.

> **El módulo de uso de Claude no consulta nada, lee lo que le dejan.** Los
> porcentajes de las ventanas de 5 h y 7 días no son accesibles desde fuera:
> ni subcomando del CLI, ni archivo en `~/.claude`, ni endpoint local. Solo
> aparecen en el JSON que Claude Code entrega a su hook `statusLine`. Por eso
> el hook los vuelca a `$XDG_RUNTIME_DIR` y Waybar lee ese archivo.
> Consecuencia: **el dato solo se refresca con una sesión de Claude Code
> abierta**; sin ella envejece, y el módulo lo marca en ámbar en vez de
> mostrar una cifra caducada como si fuera actual.

**2.2 Dunst.** Instalado pero sin configurar. Sin él, las notificaciones de
aplicaciones no se muestran. Configuración corta; buen candidato para
homogeneizar colores con Waybar y Kitty.

**2.3 hypridle + hyprlock.** **[OK] Completada (2026-07-27).** hyprlock con
desbloqueo por contraseña vía PAM e hypridle con tres listeners (480 s atenuar
el brillo, 600 s bloquear, 900 s suspender **solo con batería**), más
`before_sleep_cmd` e `inhibit_sleep = 2`; `hypridle.service` habilitado y
verificado tras reinicio, y atajo manual **`Super + L`**. Ver detalle en
`docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) → «Bloqueo de pantalla e
inactividad».

> ⚠️ **Vía de rescate — corrección importante (verificado 2026-07-27).**
> `Ctrl+Alt+F2` **no funciona** en este equipo: Hyprland captura la combinación
> y no la traduce a un cambio de VT, así que no hace nada. Además **tty2 está
> ocupado** por un Xorg huérfano del greeter de SDDM (framebuffer muerto, no
> acepta entrada): no es un destino válido. La vía válida es **tty3**,
> alcanzable solo con `sudo chvt 3` desde una terminal, no por teclado. Antes de
> cualquier cambio que pueda dejar la sesión bloqueada sin poder entrar, tener
> esa terminal abierta y lista. Ojo también con **faillock**, compartido entre
> hyprlock y el login por TTY (por defecto `deny = 3`, `unlock_time = 600`):
> tres fallos cerrarían también la vía de rescate durante 10 minutos.

**2.4 hyprpaper.** Fondo de pantalla. Requiere decidir dónde se guardan las
imágenes (¿versionar en el repo o mantener fuera por tamaño?).

---

## Fase 3 — Configuración de aplicaciones

Ninguna tiene configuración propia todavía: usan los valores por defecto. Cada
una que se configure se migra a Stow con el patrón ya validado.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 3.1 | **Kitty** — tema, fuente, opacidad | Bajo | Nulo |
| 3.2 | **Rofi** — tema y comportamiento | Bajo | Nulo |
| 3.3 | **yazi** — atajos, previsualizaciones | Bajo | Nulo |
| 3.4 | **Dolphin** — solo archivos versionables | Medio | Bajo |
| 3.5 | **Theming GTK/Qt coherente** con `nwg-look` | Medio | Bajo |

Ya está instalada la fuente `ttf-jetbrains-mono-nerd` y el tema de iconos
`papirus-icon-theme`, así que hay base para una estética unificada.

En 3.4, cuidado: Dolphin genera muchos archivos de estado y cachés. Versionar
solo lo relevante (`dolphinrc`, atajos), nunca el directorio completo.

---

## Fase 4 — Hardware específico del convertible

Es lo más distintivo de este equipo y lo que ningún dotfiles genérico cubre.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 4.1 | **Pantalla táctil** en Hyprland | Medio | Bajo |
| 4.2 | **Rotación automática** en modo tableta | Alto | Medio |
| 4.3 | **Stylus** — presión, botones, mapeo | Medio | Bajo |
| 4.4 | **Gestos del touchpad** (3–4 dedos) | Bajo | Bajo |
| 4.5 | Revisar **S0ix** (aparecía `Disabled`) | Medio | Bajo |
| 4.6 | **Dynamic Boost** / `nvidia-powerd` | Bajo | Bajo |

**4.2** requiere leer el acelerómetro (`iio-sensor-proxy`) y rotar pantalla y
entrada táctil de forma coordinada. Es la tarea más compleja de esta fase.

**4.5** conviene mirarlo junto con el comportamiento de suspensión general:
verificar que suspender/reanudar funciona bien con la dGPU y RTD3.

---

## Fase 5 — Seguridad y resiliencia

Huecos reales detectados durante la auditoría. **Prioridad alta pese a no ser
vistosos.**

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 5.1 | ~~**Cortafuegos** — no hay ninguno instalado~~ **[OK] Completada** | Bajo | Bajo |
| 5.2 | **Copias de seguridad reales** fuera del disco | Alto | Bajo |
| 5.3 | **Probar arranque desde snapshot** en GRUB | Bajo | **Medio** |
| 5.4 | ~~Bloqueo de sesión (ver 2.3)~~ **[OK] Completada** | — | — |

**5.1** **[OK] Completada (2026-07-23).** Instalado y habilitado `firewalld`,
zona `public` con denegación entrante por defecto, servicio `ssh` retirado.
Ver detalle en `docs/PROJECT_CONTEXT.md` §9 (Red y seguridad).

**5.2** ⚠️ **Importante**: los snapshots de Btrfs **no son copias de
seguridad**. Viven en el mismo disco: si falla el NVMe o se corrompe el sistema
de archivos, se pierden con todo lo demás. Falta una estrategia real
(`borg`, `restic`, `btrfs send/receive` a disco externo) al menos para `@home`.

**5.3** Nunca se ha probado arrancar desde un snapshot en el menú de GRUB.
Descubrir que no funciona el día que haga falta sería el peor momento. Probarlo
en frío, con el snapshot #2 protegido como red.

**5.4** **[OK] Completada (2026-07-27)** junto con **2.3**: la sesión se bloquea
sola por inactividad, antes de suspender y a demanda con `Super + L`. Ver 2.3 y
`docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) → «Bloqueo de pantalla e
inactividad».

---

## Fase 6 — Reproducibilidad completa

Cerrar el objetivo original: poder reinstalar y recuperar el sistema.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 6.1 | `install/packages.sh`, `aur.sh`, `services.sh` — **incluye `services.sh` como requisito bloqueante** | Medio | Bajo |
| 6.2 | `install/ai-tools.sh` (Codex, Claude Code) | Bajo | Bajo |
| 6.3 | `docs/installation.md` — procedimiento completo | Medio | Nulo |
| 6.4 | `scripts/update.sh`, `backup.sh` | Medio | Bajo |
| 6.5 | **Prueba real de restauración en una VM** | Alto | Nulo |

**6.1** ⚠️ **Requisito bloqueante, no una nota menor: `install/services.sh`
tiene que rehabilitar `hypridle.service`.** El `enable` de un servicio de
usuario **no vive en los dotfiles**: crea
`~/.config/systemd/user/graphical-session.target.wants/hypridle.service`, que no
está versionado, y de él solo queda rastro en `packages/services-enabled.txt`.
Consecuencia: **una restauración desde el repositorio deja el bloqueo de sesión
sin funcionar y no avisa de nada.** Los archivos estarían todos en su sitio,
`hyprlock` y `Super + L` seguirían funcionando a mano, y el equipo simplemente
no se bloquearía solo nunca — el mismo hueco de seguridad que cerró la tarea
2.3, reabierto en silencio. La fase 6 **no puede darse por completada** sin
esto, y la prueba de restauración en VM (6.5) debe verificarlo explícitamente.
Ver `docs/PROJECT_CONTEXT.md` §9 (Red y seguridad) y §14.

**6.3** debe recoger los detalles no obvios: VMD activo en BIOS, ESP compartida
con Windows, layout de subvolúmenes, orden de instalación.

**6.5** es la única forma de saber si el proyecto cumple su propósito. Ya están
instalados `edk2-ovmf` y `virtiofsd`, así que hay base para virtualizar. Sin
esta prueba, la reproducibilidad es una hipótesis.

---

## Fase 7 — Objetivos originales pendientes

Del README inicial del repositorio, aún sin abordar.

| # | Tarea | Esfuerzo | Riesgo |
|---|-------|----------|--------|
| 7.1 | **Entorno de desarrollo** | Alto | Bajo |
| 7.2 | **Automatización con IA** | Alto | Bajo |

Ambos requieren definir primero qué significan en concreto: lenguajes y
herramientas para 7.1; qué se quiere automatizar y con qué límites para 7.2.

---

## Orden recomendado

(Ya completadas: **5.1** cortafuegos, **2.3 / 5.4** bloqueo de sesión y
**2.1** Waybar.)

1. **2.2 + 2.4** — Dunst y fondo de pantalla; con eso el escritorio queda
   completo.
2. **5.3 (probar snapshots)** — validar la red de seguridad antes de seguir
   cambiando cosas.
3. **Fase 3** — pulido estético, sin riesgo, buen trabajo de relleno.
4. **5.2 (backups)** — antes de acumular datos importantes.
5. **Fase 4** — cuando apetezca algo técnico y específico.
6. **Fase 6** — cuando el sistema esté estable y merezca congelarse.

## Mantenimiento continuo

- Actualizar `packages/*.txt` periódicamente (`pacman -Qqe`, `pacman -Qqm`).
- Actualizar `docs/keybindings.md` al tocar binds.
- Revisar que la documentación siga coincidiendo con el sistema real.
- Registrar decisiones relevantes en `docs/history/`.
