/*
 * Subíndice — plugin propio para Obsidian.
 *
 * Markdown no tiene sintaxis de subíndice, y el único comando de Obsidian que
 * baja un número es `editor:toggle-inline-math`, que mete una fórmula LaTeX
 * ($1010_2$) con su tipografía matemática. Cuando se quiere texto normal la vía
 * es HTML inline, <sub></sub>, que Obsidian renderiza tanto en Live Preview
 * como en Lectura. Caso de uso: la base de un número, 1010<sub>2</sub>.
 *
 * Se asigna a Ctrl+Alt+, ("Mod" es Ctrl en Linux). Ctrl+, a secas ya lo ocupan
 * los ajustes de Obsidian, y Super+, no llegaba a la aplicación. Hyprland no
 * tiene ningún bind con coma ni con Ctrl+Alt.
 *
 * Sin selección NO opera sobre la palabra bajo el cursor, al revés que el
 * plugin `subrayar`: al acabar de teclear "1010" la palabra bajo el cursor es
 * el propio número, y envolverlo entero sería justo lo contrario de lo que se
 * busca. Deja el par vacío con el cursor en medio, listo para teclear la base.
 *
 * Fuente versionada en el repo arch-msi (obsidian/plugins/subindice/) y
 * enlazada al vault con un symlink. Ver docs/PROJECT_CONTEXT.md §26.
 */

const { Plugin } = require("obsidian");

const ABRE = "<sub>";
const CIERRA = "</sub>";

module.exports = class Subindice extends Plugin {
	onload() {
		this.addCommand({
			id: "toggle-subscript",
			name: "Subíndice / quitar subíndice",
			hotkeys: [{ modifiers: ["Mod", "Alt"], key: "," }],
			editorCallback: (editor) => alternarSubindice(editor),
		});
	}
};

function alternarSubindice(editor) {
	const desde = editor.getCursor("from");
	const hasta = editor.getCursor("to");

	// Sin selección: par vacío y cursor entre las etiquetas.
	if (!editor.somethingSelected()) {
		editor.replaceRange(ABRE + CIERRA, desde);
		editor.setCursor({ line: desde.line, ch: desde.ch + ABRE.length });
		return;
	}

	const texto = editor.getRange(desde, hasta);
	// El desplazamiento de la etiqueta de apertura solo afecta al final de la
	// selección si empieza y acaba en la MISMA línea.
	const unaLinea = desde.line === hasta.line;
	const salto = unaLinea ? ABRE.length : 0;

	// Caso 1: las etiquetas están dentro de lo seleccionado -> quitarlas.
	if (
		texto.length >= ABRE.length + CIERRA.length &&
		texto.startsWith(ABRE) &&
		texto.endsWith(CIERRA)
	) {
		const limpio = texto.slice(ABRE.length, texto.length - CIERRA.length);
		editor.replaceRange(limpio, desde, hasta);
		editor.setSelection(desde, {
			line: hasta.line,
			ch: hasta.ch - CIERRA.length - salto,
		});
		return;
	}

	// Caso 2: las etiquetas envuelven la selección por fuera -> quitarlas.
	const antes = editor.getRange(
		{ line: desde.line, ch: Math.max(0, desde.ch - ABRE.length) },
		desde
	);
	const despues = editor.getRange(hasta, {
		line: hasta.line,
		ch: hasta.ch + CIERRA.length,
	});
	if (antes === ABRE && despues === CIERRA) {
		const ini = { line: desde.line, ch: desde.ch - ABRE.length };
		const fin = { line: hasta.line, ch: hasta.ch + CIERRA.length };
		editor.replaceRange(texto, ini, fin);
		editor.setSelection(ini, { line: hasta.line, ch: hasta.ch - salto });
		return;
	}

	// Caso 3: no está en subíndice -> envolver.
	editor.replaceRange(ABRE + texto + CIERRA, desde, hasta);
	editor.setSelection(
		{ line: desde.line, ch: desde.ch + ABRE.length },
		{ line: hasta.line, ch: hasta.ch + salto }
	);
}
