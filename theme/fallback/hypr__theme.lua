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
    accent      = "rgba(58b4efff)",
    surface     = "rgba(0c141bff)",
    outline     = "rgba(6d757eaa)",

    -- Segundo color del degradado del borde activo. Sale TAMBIÉN de la paleta
    -- del fondo de pantalla (familia y tono en [matugen] de tokens.toml), no de
    -- los colores de identidad: el marco de la ventana enfocada viene entero
    -- del wallpaper.
    accent_alt  = "rgba(007eb6ff)",

    -- Sombra: negro del tema con alfa, no un gris arbitrario.
    shadow      = "rgba(000000ee)",

    -- Métricas, de theme/tokens.toml
    border_size = 2,
    rounding    = 10,
    gaps_in     = 6,
    gaps_out    = 20,
}
