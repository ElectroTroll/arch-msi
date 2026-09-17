# 2026-09-17 · La flecha de vector en Obsidian, y el plugin que sí es LaTeX

Pregunta de partida: *¿cómo se pone una flecha de vector encima de una letra?*
Sale un cuarto plugin propio, `vector`, y con él el primer caso de la familia en
el que **la respuesta correcta es LaTeX y no HTML** — justo al revés que los
subíndices de hace tres días.

---

## 1. Tres vías, y por qué aquí gana la que perdió en los subíndices

| Vía | Ejemplo | Nota |
|---|---|---|
| LaTeX | `$\vec{v}$` | MathJax de serie en Obsidian, en Live Preview y en Lectura |
| Unicode | `v⃗` (U+20D7 combinante) | se copia y pega a cualquier sitio, pero **pocas fuentes lo alinean** sobre la letra |
| HTML | — | **no existe**: no hay etiqueta que ponga nada encima de un carácter |

El `2026-09-14` se eligió HTML para `<sub>` y `<sup>` con el argumento de que
los apuntes son texto y no fórmulas, y LaTeX metía cursiva matemática donde no
tocaba. Aquí ese argumento **no se sostiene**, por dos motivos:

- **HTML no compite**: `<sub>`/`<sup>` existían; un «encima de» no. Lo más
  parecido sería un `<span>` con `text-decoration: overline`, que dibuja una
  raya de lado a lado, no una flecha, y depende de CSS del tema.
- **Un vector sí es notación matemática.** La cursiva de MathJax, que en
  `1010₂` estorbaba, en `$\vec{v}$` es lo que se quiere.

Unicode se descartó por lo de la alineación: `v⃗` se ve movido o partido según la
fuente, y el tema del vault no da ninguna garantía sobre eso.

⚠️ Se asume la pega que §26 ya tenía escrita para las griegas: **lo que se
guarda en el `.md` es `\vec{v}`, no un carácter con flecha**. Buscar la letra
sigue funcionando; buscar «el vector v» dibujado, no.

## 2. Por qué un plugin y no `editor:toggle-inline-math`

El comando existe y Obsidian lo trae de fábrica, pero solo abre los `$…$`
vacíos: el `\vec{}` de dentro hay que teclearlo igual, seis caracteres con dos
llaves y una barra invertida. Lo que se pedía era exactamente lo contrario —
**la sintaxis puesta y la letra vacía**.

Así que se clona otra vez `subrayar`, como ya se hizo con los dos índices.
`Ctrl+Alt+V` deja `$\vec{‸}$` con el cursor entre las llaves. El gesto es
`Ctrl+Alt+V` → `v` → `End`.

Sin selección **no opera sobre la palabra bajo el cursor**, igual que
`subindice` y `superindice` y al revés que `subrayar`. Aquí la razón es aún más
clara que allí: el vector se escribe *antes* de la letra, no después.

### La única novedad de comportamiento: dos órdenes según el tamaño

| Selección | Sale |
|---|---|
| un carácter | `$\vec{v}$` |
| dos o más | `$\overrightarrow{AB}$` |

No es un capricho: `\vec` centra una flecha corta sobre **un** carácter, y con
dos se queda descolocada sobre el primero. La flecha larga de `\overrightarrow`
es además la notación del segmento orientado, que es el caso en el que aparecen
dos letras. El alternado reconoce las dos órdenes, así que deshacer funciona
igual con una que con otra.

## 3. El atajo, verificado en los dos lados antes de elegirlo

El `2026-09-14` se perdió tiempo con `Super+,`, que no respondía y cuya causa
**sigue sin verificarse**. Esta vez se comprobó antes:

- **Hyprland**: ni un solo bind con `Ctrl+Alt`. Todos los de `hyprland.lua` son
  `Super + …`, teclas `XF86*` o `Print`.
- **Obsidian 1.13.7**, leyendo las declaraciones `hotkeys:[…]` del
  `obsidian.asar`: los únicos `Mod+Alt` de fábrica son `←`, `→`, `Enter` y `F`.
  Y, de propina, **no hay ningún atajo por defecto con la tecla V** — ni
  `Ctrl+V`, que es pegado nativo del navegador, ni ninguna combinación.

`Ctrl+Alt+V` queda además en la familia de `Ctrl+Alt+,` y `Ctrl+Alt+.`.

## 4. Cómo se validó, y qué NO se ha observado

La lógica se probó **fuera de Obsidian**, con un editor simulado que implementa
las seis llamadas de la API que usa el plugin (`getCursor`, `somethingSelected`,
`getRange`, `replaceRange`, `setCursor`, `setSelection`). Ocho casos, todos
correctos (`‸` es el cursor):

```
nota vacía                 -> $\vec{‸}$
a media frase              -> La velocidad $\vec{‸}$ es constante
una letra seleccionada     -> La velocidad $\vec{|v|}$ es constante
dos letras seleccionadas   -> El segmento $\overrightarrow{|AB|}$ mide 3
quitar, las cuatro formas  -> vuelve al texto limpio
```

Dos fallos aparentes del primer intento **eran del banco de pruebas, no del
plugin**: los índices de la selección se calcularon a mano sobre un fuente donde
`\\` son dos caracteres y en la cadena es uno. Se rehízo marcando la selección
con `|…|` dentro de la propia frase, que no se puede descontar mal.

**Lo que sí está observado dentro de Obsidian**: la aplicación arrancó con el
plugin enlazado y **reescribió ella misma `community-plugins.json` conservando
el `id`** (lo escribió el asistente a las 11:34; la aplicación lo reescribió con
su propio formato a las 11:44). Es la comprobación que §26 ya daba por buena.

⚠️ **Lo que NO está observado**: la pulsación real de `Ctrl+Alt+V` dentro de una
nota. Que el plugin carga está comprobado; que la tecla inserta la fórmula, no
— eso solo lo puede ver el usuario delante del teclado.

## 5. Qué entra en el repositorio

`obsidian/plugins/vector/` con sus dos archivos, y el symlink al vault hecho a
mano como los otros tres. La familia pasa de tres a cuatro, y §26 corrige los
«tres plugins propios» en los tres sitios donde lo decía.

El vault sigue **sin versionarse**. Al restaurar el equipo hay que rehacer los
cuatro enlaces y añadir los cuatro `id` a `community-plugins.json`.
