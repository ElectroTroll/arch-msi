/*
 * Vector — plugin propio para Obsidian.
 *
 * La flecha de vector sobre una letra no es HTML, al revés que los otros tres
 * plugins de la familia: es LaTeX. Obsidian renderiza MathJax de serie, así que
 * `$\vec{v}$` sale bien tanto en Live Preview como en Lectura. El carácter
 * Unicode combinante (U+20D7, v⃗) se descarta: pocas fuentes lo alinean sobre
 * la letra y queda descolocado.
 *
 * Obsidian solo ofrece `editor:toggle-inline-math`, que abre los `$…$` vacíos;
 * el `\vec{}` de dentro hay que teclearlo igual. Este comando escribe la
 * fórmula entera y deja el cursor donde va la letra.
 *
 * Se asigna a Ctrl+Alt+V ("Mod" es Ctrl en Linux), en la misma familia de
 * Ctrl+Alt+, y Ctrl+Alt+. de los índices. Verificado libre en los dos lados:
 * Hyprland no tiene ningún bind con Ctrl+Alt, y en el bundle de Obsidian
 * 1.13.7 los únicos Mod+Alt de fábrica son las flechas, Enter y F — de hecho
 * no hay ningún atajo por defecto con la tecla V.
 *
 * Sin selección NO opera sobre la palabra bajo el cursor, igual que
 * `subindice` y `superindice`: deja la fórmula vacía con el cursor entre las
 * llaves. El gesto es atajo -> `v` -> `End`.
 *
 * Fuente versionada en el repo arch-msi (obsidian/plugins/vector/) y enlazada
 * al vault con un symlink. Ver docs/PROJECT_CONTEXT.md §26.
 */

const { Plugin } = require("obsidian");

const CIERRA = "}$";
const CORTA = "$\\vec{";            // flecha corta, para UNA letra
const LARGA = "$\\overrightarrow{"; // flecha larga, para dos o más
const ABRES = [CORTA, LARGA];

module.exports = class Vector extends Plugin {
	onload() {
		this.addCommand({
			id: "toggle-vector",
			name: "Vector / quitar vector",
			hotkeys: [{ modifiers: ["Mod", "Alt"], key: "v" }],
			editorCallback: (editor) => alternarVector(editor),
		});
	}
};

function alternarVector(editor) {
	const desde = editor.getCursor("from");
	const hasta = editor.getCursor("to");

	// Sin selección: fórmula vacía y cursor entre las llaves.
	if (!editor.somethingSelected()) {
		editor.replaceRange(CORTA + CIERRA, desde);
		editor.setCursor({ line: desde.line, ch: desde.ch + CORTA.length });
		return;
	}

	const texto = editor.getRange(desde, hasta);
	// El desplazamiento de la apertura solo afecta al final de la selección si
	// empieza y acaba en la MISMA línea.
	const unaLinea = desde.line === hasta.line;

	// Caso 1: la fórmula está dentro de lo seleccionado -> quitarla.
	for (const abre of ABRES) {
		if (
			texto.length >= abre.length + CIERRA.length &&
			texto.startsWith(abre) &&
			texto.endsWith(CIERRA)
		) {
			const limpio = texto.slice(abre.length, texto.length - CIERRA.length);
			editor.replaceRange(limpio, desde, hasta);
			editor.setSelection(desde, {
				line: hasta.line,
				ch: hasta.ch - CIERRA.length - (unaLinea ? abre.length : 0),
			});
			return;
		}
	}

	// Caso 2: la fórmula envuelve la selección por fuera -> quitarla.
	for (const abre of ABRES) {
		const antes = editor.getRange(
			{ line: desde.line, ch: Math.max(0, desde.ch - abre.length) },
			desde
		);
		const despues = editor.getRange(hasta, {
			line: hasta.line,
			ch: hasta.ch + CIERRA.length,
		});
		if (antes === abre && despues === CIERRA) {
			const ini = { line: desde.line, ch: desde.ch - abre.length };
			const fin = { line: hasta.line, ch: hasta.ch + CIERRA.length };
			editor.replaceRange(texto, ini, fin);
			editor.setSelection(ini, {
				line: hasta.line,
				ch: hasta.ch - (unaLinea ? abre.length : 0),
			});
			return;
		}
	}

	// Caso 3: no es un vector -> envolver. \vec centra la flecha sobre UN
	// carácter y se descoloca con dos; para varios la correcta es la flecha
	// larga de \overrightarrow, que es además la notación del segmento
	// orientado: $\overrightarrow{AB}$.
	const abre = texto.length === 1 ? CORTA : LARGA;
	editor.replaceRange(abre + texto + CIERRA, desde, hasta);
	editor.setSelection(
		{ line: desde.line, ch: desde.ch + abre.length },
		{ line: hasta.line, ch: hasta.ch + (unaLinea ? abre.length : 0) }
	);
}
