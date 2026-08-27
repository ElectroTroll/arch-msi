-- theme.lua — PLANTILLA del tema de Hyprland (arch-msi)
--
-- Fuente:  dotfiles/matugen/.config/matugen/templates/hyprland-theme.lua (esto)
-- Salida:  ~/.config/hypr/theme.lua                                      (artefacto)
--
-- ⚠️ NO EDITAR la salida: la reescribe matugen en cada arranque.
--
-- Devuelve una TABLA que hyprland.lua carga con `dofile`. Se eligió `dofile` y
-- no `require` a propósito: `require` busca por `package.path`, que no incluye
-- ~/.config/hypr y además se resolvería de forma imprevisible al ser
-- hyprland.lua un enlace de Stow — el mismo problema que tuvo el `source` de
-- hyprlock. `dofile` con una ruta construida desde $HOME no depende de nada de
-- eso y tampoco cablea /home/elok.
--
-- Los colores van en el formato de Hyprland: "rgba(RRGGBBAA)", sin almohadilla.

return {
    -- Acento y superficies, del fondo de pantalla
    accent      = "rgba({{accent_stripped}}ff)",
    surface     = "rgba({{colors.surface.default.hex_stripped}}ff)",
    outline     = "rgba({{colors.outline_variant.default.hex_stripped}}aa)",

    -- Segundo color del degradado del borde activo. Sale TAMBIÉN de la paleta
    -- del fondo de pantalla (familia y tono en [matugen] de tokens.toml), no de
    -- los colores de identidad: el marco de la ventana enfocada viene entero
    -- del wallpaper.
    accent_alt  = "rgba({{accent_alt_stripped}}ff)",

    -- Sombra: negro del tema con alfa, no un gris arbitrario.
    shadow      = "rgba(000000ee)",

    -- Métricas, de theme/tokens.toml
    border_size = {{metrics_border}},
    rounding    = {{metrics_radius}},
    gaps_in     = {{metrics_gap}},
    gaps_out    = {{metrics_gaps_out}},
}
