# 2026-09-17 · Escribir fórmulas deprisa: entra Latex Suite

Segunda pregunta del día sobre Obsidian. La primera fue la flecha de vector y
salió un plugin propio; ésta empezó igual —*¿cómo se escribe una fracción?*—,
siguió con *¿cómo se escribe la definición de gradiente?* y acabó donde la
familia de plugins propios ya no llega: **una fórmula por atajo no escala**.

---

## 1. Dónde deja de servir el patrón de los plugins propios

`subrayar`, `subindice`, `superindice` y `vector` son cuatro plugins de dos
archivos, y cada uno resuelve **una** sintaxis con **una** tecla. Funciona
porque son sintaxis cortas, universales y contadas.

Una fracción ya estira el patrón: `Ctrl+Alt+F` dejaría `$\frac{‸}{}$` y poco
más. Un gradiente lo rompe del todo —`\nabla`, tres `\frac`, tres `\partial`,
`\left(`, `\right)`— y detrás vienen las integrales, los sumatorios, las
matrices. Un atajo por fórmula es memorizar un teclado entero.

Así que la pregunta correcta no era «qué tecla», sino **qué convierte texto
corto en LaTeX largo**. Y eso ya existe hecho.

## 2. El estado real, antes de instalar nada

| Comprobación | Resultado |
|---|---|
| Vault | `~/Documentos/Apuntes` |
| Complementos activos | `ink`, `excalidraw` y los cuatro propios |
| `hotkeys.json` | **no existe** — ningún atajo asignado desde la interfaz |
| Complemento básico «Plantillas» | **activado y sin configurar**: no hay `templates.json` ni carpeta |
| «Comandos con barra» (`slash-command`) | desactivado |
| Obsidian | 1.13.7-2, **abierto** durante todo el trabajo |

De ahí salió una alternativa barata que se llegó a proponer: Plantillas ya está
encendido, y una carpeta de plantillas más un atajo insertan el bloque entero
del gradiente sin instalar nada. Se descartó porque inserta **texto fijo**: vale
para la fórmula que ya tienes escrita, no para la siguiente.

## 3. Por qué Latex Suite y no otro

El registro oficial de la tienda (`obsidianmd/obsidian-releases`) tiene **41
plugins** con «latex» en el nombre o el id. Se consultó ahí y no de memoria,
que es como se confirmó el repo correcto: `artisticat1/obsidian-latex-suite`.

Los demás resuelven otra cosa —OCR de fórmulas, exportar a LaTeX, renderizar con
otro motor, pegar desde ChatGPT—. El único que ataca *escribir deprisa* es Latex
Suite, y hay uno más que ataca *escribir a golpe de ratón*, `latex-symbol-picker`,
que queda anotado por si el catálogo de abreviaturas resulta ser demasiado.

## 4. La instalación, a mano y sin tocar lo que no es mío

Release **1.13.1** (2026-09-09), los tres archivos sueltos —no el `.zip`— a
`.obsidian/plugins/obsidian-latex-suite/`. Los tamaños coinciden con los que
declara la release y el `minAppVersion` es 1.1.0, muy por debajo del 1.13.7
instalado.

**`community-plugins.json` no se tocó.** Es exactamente la trampa del
`2026-09-14`: ese archivo lo reescribe la aplicación, y con Obsidian abierto
cualquier cosa escrita ahí se pierde. Lo registra ella al activar el plugin
desde la interfaz.

Por lo mismo, quedaron dos pasos para el usuario y no para el asistente:
recargar Obsidian (escanea la carpeta **solo al arrancar**) y activar el
interruptor.

## 5. El catálogo se leyó del binario, no de la documentación

Las abreviaturas viven dentro de `main.js`, en una cadena que contiene el
archivo de snippets que el usuario ve en los ajustes. Se extrajo esa cadena, se
desescapó y se generó la tabla desde ahí: `docs/obsidian-latex-suite.md`, **165
abreviaturas literales** más las reglas con patrón.

No es celo: leer la documentación del proyecto en vez del binario instalado
habría metido **tres errores**, porque hay entradas que el catálogo trae
**comentadas** y no funcionan.

### ⚠️ Tres cosas que se dijeron mal al leer el bundle por encima

Una primera pasada buscó `trigger:` en el `main.js` sin filtrar comentarios, y
de ahí salieron tres afirmaciones falsas que la extracción correcta desmintió:

| Se dijo | La verdad |
|---|---|
| `del` → `\nabla` | **comentada**. La que funciona es `nabl` |
| `--` → `–` en texto normal | **comentada**. No pasa nada al escribir `--` |
| Escribir `gamma` en prosa lo convierte en `$\gamma$` | **comentada**. No hay tal conversión |

La tercera era la importante, porque se había presentado como un choque con la
decisión del `2026-09-15` —prosa con carácter Unicode vía `Super + G`, para que
siga siendo buscable—. **No hay choque**: las cuatro reglas que actuarían sobre
texto normal vienen apagadas de fábrica. Latex Suite solo opera dentro de `$…$`,
así que los dos sistemas se reparten el trabajo limpiamente: fórmulas dentro,
símbolos sueltos fuera.

## 6. Lo que sí toca decidir: Conceal

`concealEnabled` viene en **false**. Es la función que enseña `α` y las
fracciones montadas **mientras escribes**, en vez del código. Sin ella se
escribe rápido pero a ciegas, que era justo la mitad de lo que se pedía
—«rápida **y visual**»—.

Es un interruptor en los ajustes del plugin, no un archivo, así que lo enciende
el usuario.

## 7. Cero conflictos de atajos, comprobado

Latex Suite registra seis comandos (`Box current equation`, `Select current
equation`, los tres de habilitar/deshabilitar y `Toggle conceal`) y **ninguno
declara `hotkeys`**. `Ctrl+Alt+,`, `Ctrl+Alt+.` y `Ctrl+Alt+V` siguen siendo de
los plugins propios.

Sí hay **solape funcional**: `xvec` hace dentro de una fórmula lo mismo que el
plugin `vector` de esta mañana. El propio sigue valiendo porque abre él los
`$…$` desde texto normal, que es donde Latex Suite no llega con esa tecla.

## 8. Qué queda comprobado y qué no

Comprobado:

- Repo de origen contrastado contra el registro oficial de la tienda.
- Los tres archivos en disco, con los tamaños de la release 1.13.1.
- `id` del manifiesto = nombre de la carpeta (`obsidian-latex-suite`), que es la
  condición que §26 ya tenía anotada para que Obsidian cargue un plugin.
- El catálogo, extraído del binario instalado: 165 literales, 12 comentadas.
- Las opciones de modo (`m n M t T c C A r w v U`), leídas del código y no
  supuestas.
- Los seis comandos y la ausencia de atajos por defecto.

**Sin comprobar**:

- Que el plugin **cargue**. Obsidian estaba abierto desde antes de copiarlo, así
  que ni siquiera lo ha escaneado. La prueba será que su `id` aparezca en
  `community-plugins.json` tras activarlo, y que escriba su `data.json`.
- Que **una sola abreviatura dispare**. La secuencia del gradiente está
  derivada de la tabla, no vista en pantalla.

## 9. Qué entra en el repositorio

La documentación, no el plugin: `docs/obsidian-latex-suite.md` con el catálogo y
esta nota. **El plugin es código de terceros y vive solo en el vault**, que no
se versiona. Al restaurar el equipo hay que volver a bajarlo, además de rehacer
los cuatro enlaces de los plugins propios.
