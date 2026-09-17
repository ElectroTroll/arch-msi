# Abreviaturas de Latex Suite (Obsidian)

Catálogo de fábrica de **Latex Suite 1.13.1**, tal y como viene instalado el
2026-09-17. No está copiado de la documentación del proyecto: está **extraído
del `main.js` instalado** y filtrado para dejar fuera las entradas que el propio
archivo trae comentadas, que son 12 (ver §7).

Contexto y decisión: `history/2026-09-17-latex-suite.md`. Estado del plugin en
`PROJECT_CONTEXT.md` §26.

---

## 1. Cómo se leen estas tablas

Una abreviatura se **expande sola** al teclear el último carácter si su modo
lleva `A`. Las que no lo llevan esperan a que pulses **Tab**.

`$0`, `$1`, `$2` son **paradas del cursor**: te deja en `$0` y saltas a la
siguiente con **Tab**. `${0:y}` es una parada con texto por defecto, ya
seleccionado, que se sustituye escribiendo encima.

La columna **Modo** es la cadena de opciones del propio plugin, comprobada
contra su código:

| Letra | Significado |
|---|---|
| `m` | dentro de fórmula (en línea y en bloque) |
| `n` | solo en fórmula **en línea** (`$…$`) |
| `M` | solo en fórmula **en bloque** (`$$…$$`) |
| `t` | en texto normal |
| `T` | dentro de un `\text{}` |
| `c` / `C` | en bloque de código / en código en línea |
| `A` | automática: no hace falta Tab |
| `r` | el disparador es una expresión regular |
| `w` | solo al principio de palabra |
| `v` | opera sobre el **texto seleccionado** |
| `U` | desactiva el deshacer con Retroceso (ninguna de fábrica lo usa) |

⚠️ **Retroceso deshace la expansión.** Si una abreviatura salta cuando no
querías, `Backspace` inmediatamente después devuelve el texto que habías
tecleado. Es el comportamiento por defecto (`undoKey`), y es lo que hace
tolerable que casi todo sea automático.

## 2. El caso que motivó esto: el gradiente

`$$\nabla f = \left( \frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z} \right)$$`
se teclea así, sin escribir ni una barra invertida ni una llave:

```
dm   nabl  ␣f␣=␣  lr(   pafx⇥ ,␣ pafy⇥ ,␣ pafz⇥
```

- `dm` abre el bloque `$$ … $$` y deja el cursor dentro.
- `nabl` da `\nabla`. ⚠️ **`del` NO vale**: viene comentado en el catálogo.
- `lr(` da `\left( … \right)`, que es lo que hace que los paréntesis crezcan
  hasta el alto de las fracciones.
- `pa` + dos letras + **Tab** da `\frac{ \partial f }{ \partial x }`. Es la vía
  corta; `par` + Tab hace lo mismo pero con `y` y `x` de relleno y hay que
  sobrescribirlas.

## 3. Las cinco que más se usan

| Tecleas | Sale |
|---|---|
| `mk` | `$‸$` — fórmula en línea, desde texto normal |
| `dm` | `$$⏎‸⏎$$` — fórmula en bloque, desde texto normal |
| `//` | `\frac{‸}{}` |
| `sq` | `\sqrt{ ‸ }` |
| `@a` … `@O` | las griegas (`\alpha` … `\Omega`) |

---

## 4. Catálogo completo (165 abreviaturas literales)

### Abrir y cerrar fórmula

| Tecleas | Sale | Modo |
|---|---|---|
| `mk` | `${}$0{}$` | `tA` |
| `mk` | `\($0\)` | `TA` |
| `dm` | `$$⏎$0⏎$$` — Display math | `tAw` |

### Letras griegas

| Tecleas | Sale | Modo |
|---|---|---|
| `@a` | `\alpha` | `mA` |
| `@b` | `\beta` | `mA` |
| `@g` | `\gamma` | `mA` |
| `@G` | `\Gamma` | `mA` |
| `@d` | `\delta` | `mA` |
| `@D` | `\Delta` | `mA` |
| `@e` | `\epsilon` | `mA` |
| `:e` | `\varepsilon` | `mA` |
| `@z` | `\zeta` | `mA` |
| `@t` | `\theta` | `mA` |
| `@T` | `\Theta` | `mA` |
| `:t` | `\vartheta` | `mA` |
| `@i` | `\iota` | `mA` |
| `@k` | `\kappa` | `mA` |
| `@l` | `\lambda` | `mA` |
| `@L` | `\Lambda` | `mA` |
| `@s` | `\sigma` | `mA` |
| `@S` | `\Sigma` | `mA` |
| `@u` | `\upsilon` | `mA` |
| `@U` | `\Upsilon` | `mA` |
| `@o` | `\omega` | `mA` |
| `@O` | `\Omega` | `mA` |
| `ome` | `\omega` | `mA` |
| `Ome` | `\Omega` | `mA` |

### Texto dentro de la fórmula

| Tecleas | Sale | Modo |
|---|---|---|
| `text` | `\text{$0}$1` | `mA` |
| `"` | `\text{$0}$1` | `mA` |

### Operaciones básicas

| Tecleas | Sale | Modo |
|---|---|---|
| `sr` | `^{2}` | `mA` |
| `cb` | `^{3}` | `mA` |
| `rd` | `^{$0}$1` — Raise to (D)the power of | `mA` |
| `_` | `_{$0}$1` | `mA` |
| `sts` | `_\text{$0}` | `mA` |
| `sq` | `\sqrt{ $0 }$1` | `mA` |
| `//` | `\frac{$0}{$1}$2` | `mA` |
| `invs` | `^{-1}` | `mA` |
| `conj` | `^{*}` | `mA` |
| `Re` | `\mathrm{Re}` | `mA` |
| `Im` | `\mathrm{Im}` | `mA` |
| `bf` | `\mathbf{$0}` | `mA` |
| `rm` | `\mathrm{$0}$1` | `mA` |

### Álgebra lineal

| Tecleas | Sale | Modo |
|---|---|---|
| `trace` | `\mathrm{Tr}` | `mA` |

### Más operaciones

| Tecleas | Sale | Modo |
|---|---|---|
| `([a-zA-Z])hat` | `\hat{[[0]]}` | `rmA` |
| `([a-zA-Z])bar` | `\bar{[[0]]}` | `rmA` |
| `([a-zA-Z])dot` | `\dot{[[0]]}` | `rmA` |
| `([a-zA-Z])ddot` | `\ddot{[[0]]}` | `rmA` |
| `([a-zA-Z])tilde` | `\tilde{[[0]]}` | `rmA` |
| `([a-zA-Z])und` | `\underline{[[0]]}` | `rmA` |
| `([a-zA-Z])vec` | `\vec{[[0]]}` | `rmA` |
| `([a-zA-Z]),\.` | `\mathbf{[[0]]}` | `rmA` |
| `([a-zA-Z])\.,` | `\mathbf{[[0]]}` | `rmA` |
| `\\(${GREEK}),\.` | `\boldsymbol{\[[0]]}` | `rmA` |
| `\\(${GREEK})\.,` | `\boldsymbol{\[[0]]}` | `rmA` |
| `hat` | `\hat{$0}$1` | `mA` |
| `bar` | `\bar{$0}$1` | `mA` |
| `dot` | `\dot{$0}$1` | `mA` |
| `ddot` | `\ddot{$0}$1` | `mA` |
| `cdot` | `\cdot` | `mA` |
| `tilde` | `\tilde{$0}$1` | `mA` |
| `und` | `\underline{$0}$1` | `mA` |
| `vec` | `\vec{$0}$1` | `mA` |
| `xnn` | `x_{n}` | `mA` |
| `\xii` | `x_{i}` | `mA` |
| `xjj` | `x_{j}` | `mA` |
| `xp1` | `x_{n+1}` | `mA` |
| `ynn` | `y_{n}` | `mA` |
| `yii` | `y_{i}` | `mA` |
| `yjj` | `y_{j}` | `mA` |

### Símbolos

| Tecleas | Sale | Modo |
|---|---|---|
| `ooo` | `\infty` | `mA` |
| `sum` | `\sum` | `mA` |
| `prod` | `\prod` | `mA` |
| `\sum` | `\sum_{${0:i}=${1:1}}^{${2:N}} $3` | `m` |
| `\prod` | `\prod_{${0:i}=${1:1}}^{${2:N}} $3` | `m` |
| `lim` | `\lim_{ ${0:n} \to ${1:\infty} } $2` | `mA` |
| `+-` | `\pm` | `mA` |
| `-+` | `\mp` | `mA` |
| `...` | `\dots` | `mA` |
| `nabl` | `\nabla` | `mA` |
| `xx` | `\times` | `mA` |
| `**` | `\cdot` | `mA` |
| `para` | `\parallel` | `mA` |
| `deg` | `\degree` | `mA` |
| `===` | `\equiv` | `mA` |
| `!=` | `\neq` | `mA` |
| `>=` | `\geq` | `mA` |
| `<=` | `\leq` | `mA` |
| `>>` | `\gg` | `mA` |
| `<<` | `\ll` | `mA` |
| `simm` | `\sim` | `mA` |
| `sim=` | `\simeq` | `mA` |
| `prop` | `\propto` | `mA` |
| `<->` | `\leftrightarrow ` | `mA` |
| `->` | `\to` | `mA` |
| `!>` | `\mapsto` | `mA` |
| `=>` | `\implies` | `mA` |
| `=<` | `\impliedby` | `mA` |
| `and` | `\cap` | `wmA` |
| `orr` | `\cup` | `mA` |
| `inn` | `\in` | `mA` |
| `notin` | `\not\in` | `mA` |
| `\\\` | `\setminus` | `mA` |
| `sub=` | `\subseteq` | `mA` |
| `sup=` | `\supseteq` | `mA` |
| `eset` | `\emptyset` | `mA` |
| `set` | `\{ $0 \}$1` | `wmA` |
| `LL` | `\mathcal{L}` | `mA` |
| `HH` | `\mathcal{H}` | `mA` |
| `CC` | `\mathbb{C}` | `mA` |
| `RR` | `\mathbb{R}` | `mA` |
| `ZZ` | `\mathbb{Z}` | `mA` |
| `NN` | `\mathbb{N}` | `mA` |
| `QQ` | `\mathbb{Q}` | `mA` |
| `([^\\])(${GREEK})` | `[[0]]\[[1]]` — Add backslash before Greek letters | `rmA` |
| `([^\\])(${SYMBOL})` | `[[0]]\[[1]]` — Add backslash before symbols | `rmA` |
| `\\(${GREEK}\|${SYMBOL}) sr` | `\[[0]]^{2}` | `rmA` |
| `\\(${GREEK}\|${SYMBOL}) cb` | `\[[0]]^{3}` | `rmA` |
| `\\(${GREEK}\|${SYMBOL}) rd` | `\[[0]]^{$0}$1` | `rmA` |
| `\\(${GREEK}) hat` | `\hat{\[[0]]}` | `rmA` |
| `\\(${GREEK}) dot` | `\dot{\[[0]]}` | `rmA` |
| `\\(${GREEK}) bar` | `\bar{\[[0]]}` | `rmA` |
| `\\(${GREEK}) vec` | `\vec{\[[0]]}` | `rmA` |
| `\\(${GREEK}) tilde` | `\tilde{\[[0]]}` | `rmA` |
| `\\(${GREEK}) und` | `\underline{\[[0]]}` | `rmA` |

### Derivadas e integrales

| Tecleas | Sale | Modo |
|---|---|---|
| `par` | `\frac{ \partial ${0:y} }{ \partial ${1:x} } $2` | `m` |
| `ddt` | `\frac{d}{dt} ` | `mA` |
| `\int` | `\int $0 \, d${1:x} $2` | `m` |
| `dint` | `\int_{${0:0}}^{${1:1}} $2 \, d${3:x} $4` — Definite integral | `mA` |
| `oint` | `\oint` | `mA` |
| `iint` | `\iint` | `mA` |
| `iiint` | `\iiint` | `mA` |
| `oinf` | `\int_{0}^{\infty} $0 \, d${1:x} $2` | `mA` |
| `infi` | `\int_{-\infty}^{\infty} $0 \, d${1:x} $2` | `mA` |

### Física

| Tecleas | Sale | Modo |
|---|---|---|
| `kbt` | `k_{B}T` | `mA` |
| `msun` | `M_{\odot}` | `mA` |

### Mecánica cuántica

| Tecleas | Sale | Modo |
|---|---|---|
| `dag` | `^{\dagger}` | `mA` |
| `o+` | `\oplus ` | `mA` |
| `ox` | `\otimes ` | `wmA` |
| `bra` | `\bra{$0} $1` | `mA` |
| `ket` | `\ket{$0} $1` | `mA` |
| `brk` | `\braket{ $0 \| $1 } $2` | `mA` |
| `outer` | `\ket{${0:\psi}} \bra{${0:\psi}} $1` | `mA` |

### Química

| Tecleas | Sale | Modo |
|---|---|---|
| `pu` | `\pu{ $0 }` | `mA` |
| `cee` | `\ce{ $0 }` | `mA` |
| `he4` | `{}^{4}_{2}He ` | `mA` |
| `he3` | `{}^{3}_{2}He ` | `mA` |
| `iso` | `{}^{${0:4}}_{${1:2}}${2:He}` | `mA` |

### Paréntesis y delimitadores

| Tecleas | Sale | Modo |
|---|---|---|
| `avg` | `\langle $0 \rangle $1` | `mA` |
| `norm` | `\lvert $0 \rvert $1` | `mA` |
| `Norm` | `\lVert $0 \rVert $1` | `mA` |
| `ceil` | `\lceil $0 \rceil $1` | `mA` |
| `floor` | `\lfloor $0 \rfloor $1` | `mA` |
| `mod` | `\|$0\|$1` | `mA` |
| `(` | `(${VISUAL})` | `mv` |
| `[` | `[${VISUAL}]` | `mv` |
| `{` | `{${VISUAL}}` | `mv` |
| `(` | `($0)$1` | `mA` |
| `{` | `{$0}$1` | `mA` |
| `[` | `[$0]$1` | `mA` |
| `lr(` | `\left( $0 \right) $1` | `mA` |
| `lr{` | `\left\{ $0 \right\} $1` | `mA` |
| `lr[` | `\left[ $0 \right] $1` | `mA` |
| `lr\|` | `\left\| $0 \right\| $1` | `mA` |
| `lra` | `\left< $0 \right> $1` | `mA` |
| `tayl` | `${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \frac{${2:h}^{2}}{2!} + \dots$3` — Taylor expansion | `mA` |

---

## 5. Reglas con patrón

Estas no son abreviaturas fijas: son expresiones regulares, y por eso no caben
en las tablas de arriba. Son las que más cambian la sensación de escribir.

| Tecleas | Sale | Modo |
|---|---|---|
| `xvec` `xhat` `xbar` `xdot` `xddot` `xtilde` `xund` | `\vec{x}`, `\hat{x}`, `\bar{x}`, `\dot{x}`, `\ddot{x}`, `\tilde{x}`, `\underline{x}` | `rmA` |
| `x3`, `\alpha3` | `x_{3}`, `\alpha_{3}` — subíndice automático tras letra o macro | `rmA` |
| `pa` + dos letras | `\frac{ \partial a }{ \partial b }` | `rm` (Tab) |
| `par2` … `par9` | derivada parcial de orden *n* | `mA` |
| `parn` | derivada parcial de orden `n`, con la `n` como parada | `mA` |
| `3rt` | `\sqrt[3]{ ‸ }` | `mA` |
| `ee` | `e^{ ‸ }` | `mA` |
| `sin` `cos` `tan` `sec` `csc` `cot` y sus `arc…` | les pone la barra sola: `\sin`… | `rmA` |
| `arccsc` `arcsec` `arccot` | `\operatorname{…}` — MathJax no las trae | `mA` |
| `exp` `log` `ln` `det` | les pone la barra sola | `rmA` |
| `beg` | `\begin{‸} … \end{‸}`, los dos nombres a la vez | `MA` / `nA` |
| `pmat` `bmat` `Bmat` `vmat` `Vmat` | `\begin{pmatrix} … \end{pmatrix}`, etc. | `rMA` |
| `matrix` `cases` `align` `array` | su entorno `\begin…\end` | `rMA` |
| `dm` tras texto o dentro de una lista | abre el bloque respetando la indentación | `rtA` |

⚠️ Las griegas y los símbolos llevan **una regla que les añade la barra
invertida sola**: dentro de una fórmula, escribir `alpha` o `to` se convierte en
`\alpha` y `\to` sin teclear la barra. Es cómodo y a la vez es la razón de que
palabras normales cambien solas dentro de `$…$`.

## 6. Sobre una selección

Se selecciona parte de la fórmula y se pulsa **una sola tecla**:

| Tecla | Sale |
|---|---|
| `U` | `\underbrace{ … }_{ }` |
| `O` | `\overbrace{ … }^{ }` |
| `B` | `\underset{ }{ … }` |
| `C` | `\cancel{ … }` |
| `K` | `\cancelto{ }{ … }` |
| `S` | `\sqrt{ … }` |
| `(` `[` `{` | lo encierra en ese paréntesis |

## 7. Las 12 que vienen desactivadas

El catálogo las trae **comentadas**. No funcionan salvo que se descomenten en
*Ajustes → Latex Suite → Snippets*.

| Desactivada | Qué haría |
|---|---|
| `--`, `–-`, `—-` | guion corto → guion largo, **en texto normal** |
| `del` | `\nabla` (por eso se usa `nabl`) |
| `vec` y `Xvec` (segunda forma) | `\overrightarrow{}` en vez de `\vec{}` |
| `\griega vec` (segunda forma) | `\overrightarrow{\alpha}` |
| `griega` + espacio, **en texto normal** | la envolvería en `$\alpha$` sola |
| letra suelta + espacio, en texto normal | la envolvería en `$x$` |
| `x=3` + espacio, en texto normal | lo envolvería en `$x=3$` |
| `\macro` | desactiva las abreviaturas mientras escribes una macro |

⚠️ Las cuatro que operan **en texto normal** son las importantes, y vienen
apagadas a propósito: encendidas, escribir «la gamma de la curva» en prosa
convertiría la palabra en `$\gamma$`. Eso **chocaría de frente con la decisión
de §31**, donde la prosa usa el carácter Unicode real vía `Super + G`
precisamente para que siga siendo buscable. Dejarlas apagadas es lo coherente
con el repositorio.

## 8. Los ajustes que importan

| Ajuste | De fábrica | Nota |
|---|---|---|
| Snippets | activado | el catálogo de este documento |
| Auto-fraction | activado | `/` monta la fracción sobre lo anterior; corta en `+ - =` y tabulador |
| Tabout | activado | Tab salta fuera del paréntesis o de la fórmula |
| Auto-enlarge brackets | activado | ensancha los paréntesis al meter una fracción |
| Color paired brackets | activado | |
| **Conceal** | **desactivado** | el que enseña `α` y las fracciones montadas **mientras escribes**, en vez del código |

**Conceal es el ajuste visual.** Sin él se escribe rápido pero viendo `\alpha`;
con él, el editor muestra el símbolo y solo destapa el código cuando pones el
cursor encima (*Reveal delay*, 0 ms de fábrica).

## 9. Los seis comandos que añade

`Box current equation`, `Select current equation`, `Enable all features`,
`Disable all features`, `Toggle all features` y `Toggle conceal`.

**Ninguno declara atajo por defecto** —comprobado en el bundle—, así que no
pisan los `Ctrl+Alt+,`, `Ctrl+Alt+.` ni `Ctrl+Alt+V` de los plugins propios
(§26). Viven en la paleta de comandos mientras no se les asigne uno.
