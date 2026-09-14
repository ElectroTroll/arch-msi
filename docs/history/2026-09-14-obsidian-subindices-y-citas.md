# 2026-09-14 · Subíndices en Obsidian, y el texto que se volvía naranja

Pregunta de partida: *¿cómo se pone un número pequeño abajo para representar la
base de un binario?* De ahí salieron dos plugins propios y, después, el
diagnóstico de un problema de formato que llevaba tiempo apareciendo a media
nota sin motivo aparente.

---

## 1. Tres formas de escribir un subíndice, y por qué HTML

| Vía | Ejemplo | Nota |
|---|---|---|
| LaTeX | `$1010_2$` | tipografía matemática; con más de un carácter, `_{16}` |
| HTML | `1010<sub>2</sub>` | mantiene la fuente del texto |
| Unicode | `1010₂` | se copia y pega a cualquier sitio, pero solo hay `₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎` |

Se eligió HTML: los apuntes son texto, no fórmulas, y LaTeX pone el número en
cursiva matemática aunque no se quiera.

## 2. Dos plugins clonados del de subrayar

Obsidian no trae comando para `<sub>` ni `<sup>` — el único que mueve un número
de línea es `editor:toggle-inline-math`, que es LaTeX. Así que se repitió lo de
`subrayar`: un plugin propio por etiqueta, con la misma función de alternado
(envuelve, y si ya está envuelto por dentro o por fuera de la selección,
desenvuelve).

| Plugin | Etiqueta | Atajo |
|---|---|---|
| `subindice` | `<sub></sub>` | `Ctrl+Alt+,` |
| `superindice` | `<sup></sup>` | `Ctrl+Alt+.` |

La única diferencia de comportamiento respecto a `subrayar` es deliberada: **sin
selección no operan sobre la palabra bajo el cursor**, dejan el par vacío con el
cursor en medio. Al acabar de teclear `1010` la palabra bajo el cursor es el
número, y envolverlo entero sería justo lo contrario de lo que se busca.

### `Super+,` no funcionó, y la causa no se ha verificado

Fue el primer atajo. No respondía. Se comprobó que Hyprland no tiene ningún bind
con coma —o sea, el compositor no lo estaba robando— y se cambió a `Ctrl+Alt+,`,
que sí responde.

Pero al ir a cambiarlo apareció el dato que probablemente lo explica todo: el
plugin **no estaba activado**. `community-plugins.json` seguía listando solo
`ink`, `obsidian-excalidraw-plugin` y `subrayar`. Con el plugin sin cargar, no
habría funcionado ninguna tecla. Queda como no verificado si `Super+,` sirve.

Y de ahí la comprobación que sí queda anotada: **Obsidian escanea la carpeta de
complementos al arrancar**, así que un symlink creado con la aplicación abierta
no aparece en la lista hasta recargar.

## 3. El texto naranja con caja negra

Mismo documento, otro problema: en una nota estructurada indentando con
tabuladores, al dejar una línea en blanco dentro de un grupo, **todo lo que
quedaba por debajo salía naranja y metido en una caja**.

El diagnóstico se hizo sobre la configuración real, no de memoria:

1. El tema es **Blue Topaz**, y en su `theme.css` el color del texto de código
   es `--text-color-code: #d58000`. Ese es exactamente el naranja.
2. Las guías de indentación del tema solo existen en líneas de lista
   (`.HyperMD-list-line-N .cm-hmd-list-indent > .cm-indent::before`).
3. Reproducido con `markdown_py`, que no es el parser de Obsidian pero da el
   mismo resultado:

```
Titulo          →   <p>Titulo
	linea a             linea a</p>
	                →
	011 101 101         <pre><code>011 101 101</code></pre>
```

La cadena causal es ésta: **una línea que solo tiene un tabulador es una línea
en blanco** para Markdown y cierra el párrafo; a partir de ahí, una línea que
empieza en la columna 4 —y un tabulador son cuatro— ya no es continuación de
nada, es un **bloque de código indentado**. Mientras no hay línea en blanco, las
líneas tabuladas son continuación perezosa del párrafo y se ven como texto
normal; por eso el defecto aparece a media nota y parece aleatorio.

### El primer arreglo fue un parche

Se sustituyó la línea en blanco por la misma indentación más `<br>`: el párrafo
no se cierra y no hay bloque de código. Funcionaba —4 bloques `<pre><code>`
antes, 0 después— pero dejaba dos pegas: hay que escribir `<br>` cada vez, y el
hueco resultante es más alto de lo que se quería.

### El arreglo bueno: citas en vez de indentación

Se descartó bajar la indentación a 2 espacios porque solo aguanta un nivel: al
anidar el segundo, 2+2 vuelven a ser 4 y regresa la caja. Comprobado con el
parser, y no era hipotético — la nota ya tenía 14 líneas con doble tabulador.

La estructura pasa a hacerse con **cita** (`>`), y el segundo nivel con `>>`:

- la barra vertical a la izquierda la pinta el tema, que era el efecto buscado;
- la línea de separación es un `>` suelto, y **Obsidian lo escribe solo** al
  pulsar Enter dentro de la cita;
- sin indentación, el bloque de código no puede volver por mucho que se anide.

Dos trampas al convertir, porque dentro de la cita el contenido vuelve a la
columna 0 y recupera su significado: una línea de `=` bajo un texto es un
**título setext** y lo convierte en `<h1>`; una línea que empieza por `#` es un
encabezado. Dentro del bloque de código eran texto literal, así que se escapan.

Y una pérdida asumida: **la alineación monoespaciada**. Las tablas de bits
cuadradas a base de espacios se veían alineadas porque la caja era
monoespaciada. Como texto normal, los espacios seguidos se colapsan. Para eso
el sitio correcto es un bloque de código explícito, con caja pero a propósito.

## 4. Qué queda en el repositorio y qué no

El repositorio se lleva los dos plugins nuevos. **La nota no**: el vault sigue
sin versionarse. La conversión de tabuladores a citas se hizo sobre el archivo
del vault, con copia de seguridad previa fuera del repositorio, y se verificó
línea a línea que solo cambiaba el prefijo de cita y ningún texto.

⚠️ Durante esa conversión el archivo creció de 66 a 91 líneas: **el usuario
estaba escribiendo en él al mismo tiempo**. No se perdió nada porque el script
leyó y escribió en la misma pasada, pero la lección queda: editar un archivo que
Obsidian tiene abierto es una carrera contra su búfer, y hay que comprobar
después que la aplicación ha recargado.
