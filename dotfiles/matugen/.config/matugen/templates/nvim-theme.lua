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
    bg          = "{{colors.surface.default.hex}}",
    bg_alt      = "{{colors.surface_container.default.hex}}",
    bg_high     = "{{colors.surface_container_high.default.hex}}",
    bg_sel      = "{{colors.surface_container_highest.default.hex}}",

    -- --- Texto ---------------------------------------------------------------
    fg          = "{{colors.on_surface.default.hex}}",
    fg_dim      = "{{colors.on_surface_variant.default.hex}}",
    outline     = "{{colors.outline.default.hex}}",
    outline_var = "{{colors.outline_variant.default.hex}}",

    -- --- Acento, del fondo de pantalla ---------------------------------------
    accent      = "{{accent}}",
    accent_alt  = "{{accent_alt}}",
    accent_sel  = "{{accent_sel}}",

    -- --- Estados -------------------------------------------------------------
    -- Los mismos tres que ya usan Waybar, dunst y los ANSI 1/2/3 de kitty: un
    -- error en Neovim debe ser del MISMO rojo que un error en la barra.
    crit        = "{{state_crit}}",
    warn        = "{{state_warn}}",
    ok          = "{{state_ok}}",

    -- --- Sintaxis ------------------------------------------------------------
    -- Salen de los ANSI del proyecto, NO de colores nuevos. Es el mismo criterio
    -- que llevó el tema de yazi a no redeclarar los colores por tipo de archivo:
    -- si kitty ya define la paleta de 16, inventar aquí una segunda gama sería
    -- duplicar, y además haría que el código se viese distinto en nvim y en
    -- cualquier otra herramienta de terminal.
    syn_blue    = "{{term_blue}}",
    syn_cyan    = "{{term_cyan}}",
    syn_magenta = "{{term_magenta}}",
    syn_white   = "{{term_white}}",
}
