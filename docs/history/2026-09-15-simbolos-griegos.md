# 2026-09-15 · Escribir Δ y γ: cuatro vías, y por qué ganó un menú

Pregunta de partida: *¿cómo escribo caracteres griegos —el signo de variación,
la gamma— en Obsidian?* La respuesta obligó a mirar primero qué había de verdad
en el sistema, porque tres de las cuatro vías posibles dependen de cosas que
este equipo **no tiene configuradas**.

---

## 1. El estado real, antes de proponer nada

| Comprobación | Resultado |
|---|---|
| `kb_options` en `hyprland.lua` | **vacío** — no hay tecla Compose |
| `~/.XCompose` | **no existe** |
| `XMODIFIERS`, ibus, fcitx | **nada** — no hay método de entrada |
| `rofi` | 2.0.0-1, Wayland nativo, ya en uso (`Super+R`) y con el tema del escritorio |
| `wl-copy` | instalado (wl-clipboard) |
| `wtype` | **no instalado**; está en `extra` |
| Obsidian | 1.13.7-2, Wayland nativo (lo dice `electron-flags.conf`) |

De ahí sale el primer descarte: **`Ctrl+Shift+U` no sirve en este equipo**. Esa
entrada Unicode la aporta ibus, y aquí no hay ningún método de entrada corriendo.

## 2. La trampa de la tecla Compose: los griegos están, pero no se alcanzan

`/usr/share/X11/locale/en_US.UTF-8/Compose` **ya trae 67 combinaciones griegas**
hechas, `Δ` y `γ` incluidas. Parecía cuestión de activar una tecla Compose y
listo. No lo era:

```
<dead_greek> <D>  : "Δ"  U0394
<dead_greek> <g>  : "γ"  U03B3
```

Todas cuelgan de **`<dead_greek>`**, no de `<Multi_key>`. Y `dead_greek` solo
aparece en una variante de teclado:

```
$ grep -rl dead_greek /usr/share/X11/xkb/symbols/   ->  eu fi de fr us
$ grep -B25 dead_greek /usr/share/X11/xkb/symbols/us
  xkb_symbols "altgr-weur"  ->  key <AE08> { [ 8, asterisk, ssharp, dead_greek ] }
```

`us(altgr-weur)`, que no es ninguna de las dos de este equipo (`es` y
`us(intl)`, ver §20). En `es` no hay `dead_greek` en absoluto. O sea: **las 67
combinaciones están en el disco y hoy son inalcanzables**.

Se podrían recuperar escribiendo un `~/.XCompose` con prefijo `<Multi_key>`
—comprobado que `*d`, `*D`, `*g`, `*p` y `*W` están libres; colisionan solo
`*a`/`*A` (`å`), `*u`/`*U` (`ů`) y `*0` (`°`)—, pero eso sigue sin resolver el
problema de fondo: **hay que acordarse de una pulsación distinta por símbolo**.
Y queda una incógnita sin despejar: si Electron en Wayland nativo, sin método de
entrada, aplica Compose. No se ha probado.

## 3. LaTeX sirve, pero no para lo que se preguntaba

Obsidian renderiza MathJax de serie: `$\Delta v$`, `$\gamma$`. Cero configuración.

Es la vía buena **para fórmulas**, y es exactamente el mismo razonamiento que ya
llevó a los plugins `subindice` y `superindice` (§26, nota del 2026-09-14): todo
lo que va entre `$` sale en tipografía matemática, y en el `.md` **se guarda
`\Delta`, no `Δ`**, así que buscar `Δ` en el vault no lo encuentra. Para un
carácter suelto en prosa —«la Δ de temperatura», «rayos γ»— desentona y no es
buscable.

Anotado de paso, contrastado contra el bundle de Obsidian: el comando
`editor:toggle-inline-math` **viene sin atajo asignado por defecto** —su
`addCommand` no declara `hotkeys`—, y el `hotkeys.json` del vault está vacío.
Vive solo en la paleta de comandos mientras no se le asigne uno.

## 4. La tercera distribución, descartada

`kb_layout = "es,us,gr"` es barato de escribir, pero `Super+Espacio` **rota**
entre las cargadas (ver `kb-layout.sh`): pasaría de dos paradas a tres, y se
acabaría escribiendo en griego sin querer. Descartada por ergonomía, no por
dificultad.

## 5. Lo que se hizo: un menú buscable por nombre

`scripts/simbolos.sh` + `Super+G` (G de «griego»). rofi ya estaba, ya tiene el
tema del escritorio aplicado y ya se usa para el lanzador, así que el coste era
el catálogo.

**El criterio: se busca por nombre, no por tecla.** Es lo que uno tiene en la
cabeza al escribir apuntes —«no sé qué tecla es la delta, pero sé que se llama
delta»—, y es lo único que escala a 96 símbolos sin memorizar nada.

96 entradas: griegas minúsculas y mayúsculas, operadores, conjuntos y lógica,
flechas, geometría y sub/superíndices Unicode reales (`₀₁₂₃ₙ`, `⁰¹²³ⁿ⁻`), que
son los que ya se preferían en §26 por copiarse y pegarse a cualquier sitio.

### Los alias sin tildes no son un descuido

Cada entrada lleva su nombre acentuado **y** la forma pelada:

```
Δ  Delta mayúscula · variación · variacion · incremento · \Delta
```

rofi filtra por subcadena y **no normaliza acentos**: quien escribe `variacion`
con prisa no encontraría una entrada que solo dijera «variación». Va también el
nombre LaTeX, que es como se llama al símbolo cuando se viene de escribir
fórmulas.

### Dos caminos hasta la ventana, y el `sleep` que no es decorativo

1. **`wtype`** teclea el carácter en la ventana enfocada. Es lo cómodo.
2. **`wl-copy`** lo deja en el portapapeles para `Ctrl+V`.

Se copia **siempre**, aunque `wtype` funcione: cuesta nada y sirve de red si la
aplicación ignora el teclado virtual. Y el script detecta `wtype` con
`command -v`, así que funcionó desde el primer día sin instalar nada y cambia de
modo solo cuando el paquete aparece.

El `sleep 0.15` antes de teclear tiene motivo: rofi es una capa de Wayland que
**toma el foco del teclado**. Al cerrarse, Hyprland lo devuelve a la ventana
anterior de forma **asíncrona**; si `wtype` dispara en ese mismo instante, el
carácter puede caer en el limbo entre las dos ventanas.

## 6. Qué quedó comprobado y qué no

Comprobado:

- `bash -n` y `luac -p`: sintaxis correcta en el script y en `hyprland.lua`.
- `stow -n -d dotfiles -t ~ bin`: **un solo `LINK`, cero conflictos**. Aplicado.
- `hyprctl reload` → `ok`, y `Super+G` **aparece registrado** (modmask 64,
  key G). El recuento pasa de 57 a **58 binds**. No pisa nada: las teclas
  ocupadas con SUPER eran `C E J L M N P Q R S V Z`, espacio, flechas, 1-0,
  `Print` y ratón.
- Ruta del portapapeles de punta a punta: `Δ` → **2 bytes, sin salto de línea**
  (de ahí el `wl-copy -n`). El portapapeles previo se restauró.
- Extracción del símbolo en las 96 líneas del catálogo: los 96 primeros campos
  salen limpios.

**Sin comprobar:**

- El menú en pantalla. rofi necesita la sesión del usuario, no se puede abrir
  desde una terminal de agente.
- Que `wtype` llegue a Obsidian. Usa el protocolo de **teclado virtual** de
  Wayland, y es la misma incógnita que dejó abierta el apartado 2 con Compose:
  Electron puede ignorarlo. El paquete se instala después de escribir esto.

## 7. Qué queda en el repositorio

| Archivo | Qué es |
|---|---|
| `scripts/simbolos.sh` | el selector |
| `dotfiles/bin/.local/bin/simbolos` | symlink relativo, paquete Stow `bin` |
| `dotfiles/hypr/.config/hypr/hyprland.lua` | +6 líneas: el bind `Super+G` |

Nada más. `wtype` es un paquete de `extra` y entra en `packages/` por la vía
normal, no por aquí.
