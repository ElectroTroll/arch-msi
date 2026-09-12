/*
 * Subrayar — plugin propio para Obsidian.
 *
 * Markdown no tiene sintaxis de subrayado, y Obsidian no registra ningún
 * `editor:toggle-underline` (sí bold, italics, highlight, strikethrough...).
 * Así que el subrayado se hace con HTML inline, <u></u>, que Obsidian renderiza
 * tanto en Live Preview como en Lectura.
 *
 * Se asigna a Ctrl+U, que de fábrica lleva `undoSelection` del historyKeymap de
 * CodeMirror. Los atajos de Obsidian se resuelven antes que los de CodeMirror,
 * así que este gana; `Alt+U` (redoSelection) se queda como estaba.
 *
 * Fuente versionada en el repo arch-msi (obsidian/plugins/subrayar/) y enlazada
 * al vault con un symlink. Ver docs/PROJECT_CONTEXT.md §26.
 */

const { Plugin } = require("obsidian");

const ABRE = "<u>";
const CIERRA = "</u>";

module.exports = class Subrayar extends Plugin {
	onload() {
		this.addCommand({
			id: "toggle-underline",
			name: "Subrayar / quitar subrayado",
			hotkeys: [{ modifiers: ["Mod"], key: "u" }],
			editorCallback: (editor) => alternarSubrayado(editor),
		});
	}
};

function alternarSubrayado(editor) {
	let desde = editor.getCursor("from");
	let hasta = editor.getCursor("to");

	// Sin selección se opera sobre la palabra bajo el cursor, que es el caso
	// normal: subrayar UNA palabra sin tener que seleccionarla antes.
	if (!editor.somethingSelected()) {
		const palabra = editor.wordAt(desde);
		if (!palabra) return;
		desde = palabra.from;
		hasta = palabra.to;
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

	// Caso 3: no está subrayado -> envolver.
	editor.replaceRange(ABRE + texto + CIERRA, desde, hasta);
	editor.setSelection(
		{ line: desde.line, ch: desde.ch + ABRE.length },
		{ line: hasta.line, ch: hasta.ch + salto }
	);
}
