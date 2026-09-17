# 2026-09-17 · LibreOffice, y el PDF que se abría con Xournal++ sin que nadie lo hubiera elegido

Dos peticiones en el mismo rato: *los PDF se abren con xournal, quiero que se
abran con firefox* y *necesito una app de office*. Ninguna de las dos era
difícil, pero las dos tenían debajo algo que conviene tener escrito: la primera,
**un valor por defecto que nadie había decidido**; la segunda, **una URL muerta
desde hace once años en el AUR**.

---

## 1. El PDF: no había ninguna preferencia, y por eso ganaba Xournal++

`xdg-mime query default application/pdf` respondía
`com.github.xournalpp.xournalpp.desktop`. La tentación es leer eso como «alguien
puso Xournal++ de visor». No lo hizo nadie: `~/.config/mimeapps.list` **no tenía
una sola línea para `application/pdf`**. Solo tenía los dos esquemas de Claude.

Sin preferencia explícita, el escritorio cae a la caché del sistema, y ahí el
orden lo fija quién aparece primero:

```
$ grep "^application/pdf=" /usr/share/applications/mimeinfo.cache
application/pdf=com.github.xournalpp.xournalpp.desktop;firefox.desktop;libreoffice-draw.desktop;
```

Xournal++ estaba el primero de la lista. Eso es todo. **El visor de PDF del
sistema se decidía por orden alfabético de un archivo generado**, y como
Xournal++ se instaló para anotar con el lápiz (§26), heredó también la lectura.

La corrección es una línea, como usuario y sin sudo:

```
xdg-mime default firefox.desktop application/pdf
```

que escribe en `~/.config/mimeapps.list`:

```ini
[Default Applications]
application/pdf=firefox.desktop
```

Comprobado por dos vías, porque cada pila lee la suya: `xdg-mime query default`
→ `firefox.desktop`, y `gio mime application/pdf` → misma respuesta. Xournal++
sigue registrado, así que no se pierde: queda en «Abrir con».

> ⚠️ **Ese tercer nombre de la caché importa.** Al instalar LibreOffice,
> `libreoffice-draw.desktop` se metió también en la lista de `application/pdf`.
> Mientras la preferencia explícita esté puesta da igual, pero si algún día se
> borra `mimeapps.list`, el visor de PDF vuelve a decidirse solo — y ahora hay
> tres candidatos en vez de dos.

## 2. La suite: por qué LibreOffice y no ONLYOFFICE

No había **ninguna** suite instalada. La pregunta era cuál, y la respuesta
cambió al concretarse el formato: la petición pasó de «una app de office» a
*«¿para abrir un archivo .xls?»*.

`.xls` es el binario antiguo de Excel (97-2003, BIFF8), no `.xlsx`, y eso
reordena a los candidatos:

| | `.xls` | Dónde vive |
|---|---|---|
| **LibreOffice Calc** | lee **y guarda**, más macros VBA | `extra`, oficial |
| ONLYOFFICE | lo abre convirtiendo; **no guarda en `.xls`**, devuelve `.xlsx`/`.ods` | AUR |
| Gnumeric | muy preciso con `.xls` heredado, pero solo hojas de cálculo | `extra`, oficial |

ONLYOFFICE gana en fidelidad OOXML moderna, que es su argumento habitual, pero
**no sirve para devolver un `.xls` en su formato original**. Con ese dato la
elección deja de ser discutible. Se instaló `libreoffice-fresh` (26.8.0-2,
148 MiB de descarga, 423 MiB en disco).

Las asociaciones **no hubo que tocarlas**: los `.desktop` del paquete las
registran solos. Comprobado tras instalar:

| Tipo | Se abre con |
|---|---|
| `.xls`, `.xlsx`, `.ods` | `libreoffice-calc.desktop` |
| `.doc`, `.docx`, `.odt` | `libreoffice-writer.desktop` |

## 3. Los diccionarios: el catalán no está donde parece

Inglés y castellano salen enteros de los repos oficiales. El catalán **no**:

> ⚠️ **`hunspell-ca` no existe en los repos oficiales.** Solo está `aspell-ca`,
> y LibreOffice corrige con **hunspell**, no con aspell. El paquete hay que
> sacarlo del AUR.

El reparto final, verificado paquete a paquete:

| | Castellano | Catalán | Inglés |
|---|---|---|---|
| Interfaz | `libreoffice-fresh-es` | `libreoffice-fresh-ca` | incluida de serie |
| Ortografía | `hunspell-es_es` | `hunspell-ca` **(AUR)** | `hunspell-en_us`, `hunspell-en_gb` |
| Sinónimos | `mythes-es` | **extensión `.oxt`**, ver abajo | `mythes-en` |
| Guionado | `hyphen-es` | **no existe** | `hyphen-en` |

No hay paquete de guionado catalán, ni en los repos ni en el AUR. Se buscó.

> ⚠️ **El langpack `libreoffice-fresh-ca` NO trae el diccionario de sinónimos.**
> Es una confusión fácil, porque la web de Softcatalà dice que su diccionario
> «ya viene instalado con el LibreOffice en català» — pero eso vale para **la
> compilación que distribuye Softcatalà**, no para el paquete de Arch. Se
> comprobó en disco: `pacman -Ql libreoffice-fresh-ca` solo devuelve traducción
> de interfaz y ayuda, y no hay ningún `th_ca*` en todo el sistema.

## 4. `mythes-ca` del AUR está roto, y lleva años roto

La instalación del tesauro catalán falló:

```
curl: (22) The requested URL returned error: 404
==> ERROR: Hubo fallos durante la descarga de
    http://www.softcatala.org/diccionaris/actualitzacions/sinonims/thesaurus-ca.oxt
```

No es un fallo de red ni un espejo caído. El PKGBUILD apunta a una ruta que
Softcatalà **ya no sirve**: el proyecto se mudó a GitHub. Y el paquete no se ha
tocado desde entonces — la RPC del AUR da `LastModified: 1434396155`, es decir
**junio de 2015**, con la versión 1.5.0 y 4 votos. Está abandonado de hecho.

### La salida: la extensión oficial, a nivel de usuario

En vez de parchear un PKGBUILD huérfano, se instaló el `.oxt` que Softcatalà
publica hoy. La página oficial lleva a una release de GitHub:

```
https://github.com/Softcatala/sinonims-cat/releases/download/2.3.1/thesaurus-ca.oxt
```

3,7 MB, más de 36.000 entradas, licencia **CC-BY 4.0** (Jaume Ortolà /
Softcatalà). Se descargó, se inspeccionó el ZIP antes de instalar nada
—`dictionaries/th_ca_ES.dat` y `.idx`, más el `description.xml`, nada
ejecutable— y se añadió **como extensión de usuario, sin sudo y sin AUR**:

```
unopkg add thesaurus-ca.oxt
```

> ⚠️ **`unopkg add` se queda esperando en la consola.** Pide aceptar la licencia
> escribiendo «sí», y sin un stdin interactivo muere con
> `ERROR: Exception occurred: reading from stdin failed`. No existe ningún
> `--suppress-license` en esta versión: se comprueba en `unopkg add --help` y no
> aparece. Hay que alimentar la respuesta por tubería.

Resultado, y es mejor que el que habría dado el AUR: **2.3.1 en vez de 1.5.0**.

```
$ unopkg list
Identifier: catalan.thesaurus.dictionary.from.Softcatalà.by.Joan.Montané
  Version: 2.3.1
```

Los datos quedan bajo `~/.config/libreoffice/4/user/`. Se desinstala con
`unopkg remove <identifier>`.

### Lo que esto deja abierto

La extensión **no la controla pacman**, así que no aparece en ningún inventario
de `packages/`: es un agujero de reproducibilidad del mismo tipo que los cuatro
que ya lista §14, y con el mismo final silencioso. Tras una restauración, el
corrector catalán funcionaría —ese sí es un paquete— pero los sinónimos no
estarían, y nada lo avisaría. Anotado como quinto agujero.

## 5. Un apunte del inventario que no es de esta tarea

Al regenerar `packages/` con `scripts/update-inventories.sh`, el diff quitaba
`qt6ct` además de añadir lo nuevo. **No lo quitó esta tarea.** El log lo sitúa
antes:

```
[2026-09-17T00:16:36+0200] [PACMAN] Running 'pacman -Rns qt6ct'
```

Los inventarios se habían generado a las 00:00 del mismo día, dieciséis minutos
antes de esa eliminación, así que iban desfasados desde entonces. Es coherente
con §34, donde `qt6ct` se descarta a propósito. El inventario simplemente se ha
puesto al día.
