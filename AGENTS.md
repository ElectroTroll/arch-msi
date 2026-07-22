# AGENTS.md

Reglas operativas para OpenAI Codex CLI en el repositorio `arch-msi`.

**Las reglas de operación son idénticas para todos los asistentes.** Para evitar
divergencias, la fuente canónica es [`CLAUDE.md`](CLAUDE.md). Léelo y síguelo
íntegramente. El contexto técnico está en
[`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).

## Recordatorio de lo esencial

- Inspecciona antes de modificar; no inventes el estado del sistema; distingue
  confirmado / pendiente / antiguo.
- Cambios pequeños, reversibles y con diff visible; para cambios amplios, plan
  aprobado primero. No toques archivos no relacionados.
- **Codex se ejecuta como usuario normal, nunca con sudo.** `sudo` solo puntual
  y explicado.
- Nada de commits ni push automáticos.
- No versionar secretos/tokens/caches (ver `.gitignore`).

## Coordinación entre asistentes

Codex y Claude Code trabajan sobre el mismo repositorio pero **no deben modificar
los mismos archivos a la vez**. Un solo asistente conduce cada tarea. Consulta el
estado y las tareas pendientes en `docs/PROJECT_CONTEXT.md` §13 antes de empezar.

## Nota específica de Codex

Codex está instalado como global de npm bajo `/usr` (`npm prefix -g = /usr`).
Cualquier operación sobre esa instalación toca territorio de pacman; trátalo con
cuidado y no lo modifiques sin plan aprobado.
