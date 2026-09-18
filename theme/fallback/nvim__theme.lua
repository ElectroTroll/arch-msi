-- nvim/theme.lua — PLANTILLA del tema de Neovim (arch-msi)
--
-- Fuente:  dotfiles/matugen/.config/matugen/templates/nvim-theme.lua (esto)
-- Salida:  ~/.config/nvim/theme.lua                                  (artefacto)
--
-- ⚠️ NO EDITAR la salida: la reescribe matugen en cada `theme-apply`.
--
-- ⚠️ EL NOMBRE `theme.lua` NO EXISTE en el repositorio —el paquete Stow `nvim`
-- solo trae `init.lua`—, que es lo que mantiene la REGLA DE ORO: ninguna salida
-- de matugen puede caer sobre un enlace de Stow. La segunda red es que
-- ~/.config/nvim se enlazó con `--no-folding`, así que es un directorio REAL y
-- no un enlace al repo.
--
-- Devuelve una TABLA que init.lua carga con `dofile`, igual que hyprland.lua
-- con su theme.lua y por las mismas razones: `require` busca por package.path,
-- que no incluye ~/.config/nvim y se resolvería de forma imprevisible siendo
-- init.lua un enlace de Stow.
--
-- AQUÍ SOLO VAN COLORES, no grupos de resaltado. Qué grupo usa cada color vive
-- en init.lua, que es lo versionado. Mismo reparto que en Hyprland: la
-- plantilla trae los valores, la config trae el uso.

return {
    -- --- Superficies ---------------------------------------------------------
    bg          = "#0c141b",
    bg_alt      = "#1d252c",
    bg_high     = "#283037",
    bg_sel      = "#333b42",

    -- --- Texto ---------------------------------------------------------------
    fg          = "#edf6ff",
    fg_dim      = "#bfc7d1",
    outline     = "#98a1a9",
    outline_var = "#6d757e",

    -- --- Acento, del fondo de pantalla ---------------------------------------
    accent      = "#58b4ef",
    accent_alt  = "#007eb6",
    accent_sel  = "#007eb6",

    -- --- Estados -------------------------------------------------------------
    -- Los mismos tres que ya usan Waybar, dunst y los ANSI 1/2/3 de kitty: un
    -- error en Neovim debe ser del MISMO rojo que un error en la barra.
    crit        = "#f7768e",
    warn        = "#e0af68",
    ok          = "#9ece6a",

    -- --- Sintaxis ------------------------------------------------------------
    -- Salen de los ANSI del proyecto, NO de colores nuevos. Es el mismo criterio
    -- que llevó el tema de yazi a no redeclarar los colores por tipo de archivo:
    -- si kitty ya define la paleta de 16, inventar aquí una segunda gama sería
    -- duplicar, y además haría que el código se viese distinto en nvim y en
    -- cualquier otra herramienta de terminal.
    syn_blue    = "#7aa2f7",
    syn_cyan    = "#7dcfff",
    syn_magenta = "#bb9af7",
    syn_white   = "#a9b1d6",
}
