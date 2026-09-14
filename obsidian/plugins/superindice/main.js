/*
 * Superíndice — plugin propio para Obsidian.
 *
 * Gemelo de `subindice`, con <sup></sup> en vez de <sub></sub>. Markdown no
 * tiene sintaxis de superíndice, y el único comando de Obsidian que sube un
 * número es `editor:toggle-inline-math`, que mete una fórmula LaTeX ($2^{10}$)
 * con su tipografía matemática. Cuando se quiere texto normal la vía es HTML
 * inline, <sup></sup>, que Obsidian renderiza tanto en Live Preview como en
 * Lectura. Caso de uso: exponentes, 2<sup>10</sup>, y ordinales, 1<sup>o</sup>.
 *
 * Se asigna a Ctrl+Alt+. ("Mod" es Ctrl en Linux), al lado del Ctrl+Alt+, del
 * subíndice: la coma baja, el punto sube. Hyprland no tiene ningún bind con
 * punto ni con Ctrl+Alt.
 *
 * Sin selección NO opera sobre la palabra bajo el cursor, al revés que el
 * plugin `subrayar`: al acabar de teclear "2" la palabra bajo el cursor es la
 * base, y envolverla entera sería justo lo contrario de lo que se busca. Deja
 * el par vacío con el cursor en medio, listo para teclear el exponente.
 *
 * Fuente versionada en el repo arch-msi (obsidian/plugins/superindice/) y
 * enlazada al vault con un symlink. Ver docs/PROJECT_CONTEXT.md §26.
 */

const { Plugin } = require("obsidian");

const ABRE = "<sup>";
const CIERRA = "</sup>";

module.exports = class Superindice extends Plugin {
	onload() {
		this.addCommand({
			id: "toggle-superscript",
			name: "Superíndice / quitar superíndice",
			hotkeys: [{ modifiers: ["Mod", "Alt"], key: "." }],
			editorCallback: (editor) => alternarSuperindice(editor),
		});
	}
};

function alternarSuperindice(editor) {
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

	// Caso 3: no está en superíndice -> envolver.
	editor.replaceRange(ABRE + texto + CIERRA, desde, hasta);
	editor.setSelection(
		{ line: desde.line, ch: desde.ch + ABRE.length },
		{ line: hasta.line, ch: hasta.ch + salto }
	);
}
