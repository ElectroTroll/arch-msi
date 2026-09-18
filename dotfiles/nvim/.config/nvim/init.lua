-- init.lua — configuración de Neovim · arch-msi
--
-- Fuente:  dotfiles/nvim/.config/nvim/init.lua (esto, versionado)
-- Enlace:  ~/.config/nvim/init.lua             (Stow, `stow --no-folding nvim`)
--
-- ⚠️ EL PAQUETE STOW VA SIEMPRE CON `--no-folding`. Si se deja plegar,
-- ~/.config/nvim pasa a ser UN ENLACE al directorio del repositorio, y entonces
-- el `theme.lua` que escribe matugen caería DENTRO del repo. Es exactamente el
-- fallo que tuvo wlogout el 2026-08-28. Con --no-folding, ~/.config/nvim es un
-- directorio real y solo este archivo es enlace.
--
-- SIN PLUGINS, y es una decisión, no una carencia: Neovim 0.12 trae cliente LSP
-- y completado automático nativos —comprobado en este equipo el 2026-09-18—, y
-- eso cubre C++ entero vía clangd. Un gestor de plugins se añadirá cuando haga
-- falta algo que el núcleo no dé (blink.cmp, Tree-sitter para C++), no antes.


-- --- Tecla líder -------------------------------------------------------------
-- Se declara ANTES que cualquier mapeo: los atajos guardan el valor que la
-- variable tenga en el momento de definirse, no el de después.
vim.g.mapleader = ' '

-- --- Interfaz ----------------------------------------------------------------
vim.o.number         = true
vim.o.relativenumber = true
vim.o.signcolumn     = 'yes'   -- FIJA la columna de signos. Sin esto el texto
                               -- da un salto lateral cada vez que clangd emite
                               -- o retira un diagnóstico mientras escribes.
vim.o.termguicolors  = true    -- 24 bits; lo necesita el tema de matugen.
vim.o.mouse          = 'a'
vim.o.clipboard      = 'unnamedplus'  -- yank → portapapeles de Wayland.

-- --- Edición -----------------------------------------------------------------
vim.o.expandtab   = true
vim.o.shiftwidth  = 4
vim.o.tabstop     = 4
vim.o.smartindent = true
vim.o.undofile    = true   -- deshacer persistente en ~/.local/state/nvim/undo
vim.o.ignorecase  = true
vim.o.smartcase   = true   -- ...salvo que la búsqueda lleve mayúsculas.


-- --- Completado --------------------------------------------------------------
-- `noselect` NO SOBRA: sin él, Neovim preselecciona el primer candidato y un
-- <CR> para hacer salto de línea INSERTA ese candidato en vez de bajar de
-- línea. Con noselect no hay nada elegido hasta que tú eliges.
vim.o.completeopt = 'menu,menuone,noselect,popup'


-- --- Diagnósticos ------------------------------------------------------------
-- El texto virtual va al final de la línea. Con clangd y plantillas de C++ los
-- mensajes son larguísimos, así que se trunca y el detalle se lee con
-- `vim.diagnostic.open_float` (atajo <leader>e, más abajo).
vim.diagnostic.config({
    virtual_text  = { spacing = 2, prefix = '●' },
    severity_sort = true,
    float         = { border = 'rounded', source = true },
})


-- --- LSP: clangd -------------------------------------------------------------
-- clangd YA ESTABA INSTALADO en este equipo: lo trae el paquete `clang`, no hay
-- que instalarlo aparte.
--
-- ⚠️ clangd NECESITA SABER CÓMO SE COMPILA EL PROYECTO. Sin un
-- `compile_commands.json` (lo genera CMake con -DCMAKE_EXPORT_COMPILE_COMMANDS=ON,
-- o `bear -- make`) o un `compile_flags.txt` en la raíz, adivina los flags y
-- marca errores falsos en cuanto uses cabeceras propias. No es opcional.
vim.lsp.config('clangd', {
    cmd = {
        'clangd',
        '--background-index',        -- indexa el proyecto en segundo plano
        '--clang-tidy',              -- avisos de clang-tidy junto a los errores
        '--completion-style=detailed',
        '--header-insertion=iwyu',   -- añade el #include que falte al completar
        '--offset-encoding=utf-16',
    },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = {
        'compile_commands.json',
        'compile_flags.txt',
        '.clangd',
        '.git',
    },
})

vim.lsp.enable('clangd')


-- --- Al engancharse un servidor ----------------------------------------------
-- Neovim 0.12 ya trae de serie grn (rename), gra (code action), grr
-- (references), gri (implementation), grt (type definition), gO (símbolos) y
-- <C-S> (firma). NO SE REDEFINEN. Aquí solo va lo que el núcleo no da.
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        -- EL MENÚ QUE SALE SOLO AL TECLEAR. Sin `autotrigger` el completado
        -- existe igual, pero hay que pedirlo a mano con <C-x><C-o>.
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end

        local function map(keys, fn, desc)
            vim.keymap.set('n', keys, fn, { buffer = ev.buf, desc = desc })
        end

        map('gd', vim.lsp.buf.definition, 'LSP: ir a la definición')
        map('gD', vim.lsp.buf.declaration, 'LSP: ir a la declaración')
        map('<leader>e', vim.diagnostic.open_float, 'LSP: diagnóstico completo')
        map('<leader>f', function() vim.lsp.buf.format({ async = true }) end,
            'LSP: formatear (clang-format)')
    end,
})


-- --- Tema --------------------------------------------------------------------
-- Los colores salen de theme/tokens.toml y del fondo de pantalla, vía matugen:
-- la plantilla es dotfiles/matugen/.config/matugen/templates/nvim-theme.lua y el
-- artefacto que escribe es ~/.config/nvim/theme.lua, un archivo REAL junto a
-- este enlace.
--
-- `pcall` NO SOBRA: en una restauración recién hecha —Stow puesto pero
-- theme-apply todavía sin ejecutar— el artefacto no existe. Sin el pcall,
-- Neovim arrancaría con un error en pantalla en cada `git commit`. Con él, cae
-- al colorscheme de serie y sigue.
--
-- `dofile` y no `require`, por lo mismo que en hyprland.lua: `require` busca por
-- package.path, que no incluye ~/.config/nvim, y siendo init.lua un enlace de
-- Stow se resolvería de forma imprevisible.
local ok, t = pcall(dofile, os.getenv('HOME') .. '/.config/nvim/theme.lua')

if not ok or type(t) ~= 'table' then
    vim.cmd.colorscheme('habamax')  -- respaldo del propio Neovim
    return
end

vim.cmd.colorscheme('default')  -- base limpia sobre la que pintar
vim.o.background = 'dark'

local function hl(group, spec) vim.api.nvim_set_hl(0, group, spec) end

-- ⚠️ EL FONDO VA EN `NONE`, no en t.bg, Y ES DELIBERADO. kitty corre con
-- `background_opacity 0.8` ([opacity].surface de theme/tokens.toml), y esa
-- transparencia solo la aplica a las celdas que llevan el fondo POR DEFECTO:
-- una celda con color de fondo explícito se dibuja opaca. Si aquí se pusiera
-- t.bg, Neovim quedaría como un rectángulo opaco dentro de una terminal
-- translúcida. Con NONE se ve el fondo de kitty, que ya es el color correcto y
-- además translúcido.
--
-- Por eso `t.bg` casi no se usa arriba: está para los primeros planos que van
-- SOBRE un acento (PmenuSel, Search), donde hace de color de texto.
hl('Normal',       { bg = 'NONE', fg = t.fg })
hl('NormalNC',     { bg = 'NONE', fg = t.fg })
hl('EndOfBuffer',  { bg = 'NONE', fg = t.outline_var })
hl('SignColumn',   { bg = 'NONE' })

-- Las flotantes y el menú de completado SÍ llevan fondo propio: se superponen
-- al texto y sin él serían ilegibles.
hl('NormalFloat',  { bg = t.bg_alt,  fg = t.fg })
hl('FloatBorder',  { bg = t.bg_alt,  fg = t.outline })
hl('Pmenu',        { bg = t.bg_alt,  fg = t.fg })
hl('PmenuSel',     { bg = t.accent_sel, fg = t.bg, bold = true })
hl('PmenuSbar',    { bg = t.bg_high })
hl('PmenuThumb',   { bg = t.outline })

hl('CursorLine',   { bg = t.bg_high })
hl('CursorLineNr', { fg = t.accent, bold = true })
hl('LineNr',       { fg = t.outline })
hl('Visual',       { bg = t.bg_sel })
hl('Search',       { bg = t.accent, fg = t.bg })
hl('IncSearch',    { bg = t.accent_alt, fg = t.bg })
hl('MatchParen',   { fg = t.accent, bold = true })
hl('WinSeparator', { fg = t.outline_var })
hl('StatusLine',   { bg = t.bg_alt, fg = t.fg })
hl('StatusLineNC', { bg = t.bg_alt, fg = t.fg_dim })

-- Sintaxis, con los ANSI del proyecto
-- ⚠️ EL COMENTARIO VA EN `outline_var`, NO en el ANSI bright black, aunque el
-- resto de la sintaxis sí salga de los ANSI. Medido el 2026-09-18 contra el
-- fondo real (#0c141b): bright black da 2.08:1, por debajo de legible, y
-- outline_variant da 3.97:1. Un comentario debe CEDER frente al código, no
-- desaparecer. Si algún día se cambia, medir antes.
hl('Comment',    { fg = t.outline_var, italic = true })
hl('String',     { fg = t.ok })
hl('Character',  { fg = t.ok })
hl('Number',     { fg = t.syn_magenta })
hl('Boolean',    { fg = t.syn_magenta })
hl('Constant',   { fg = t.syn_magenta })
hl('Identifier', { fg = t.fg })
hl('Function',   { fg = t.syn_blue })
hl('Statement',  { fg = t.accent })
hl('Keyword',    { fg = t.accent })
hl('Conditional',{ fg = t.accent })
hl('Repeat',     { fg = t.accent })
hl('Operator',   { fg = t.fg_dim })
hl('PreProc',    { fg = t.syn_cyan })   -- en C++, los #include y las macros
hl('Include',    { fg = t.syn_cyan })
hl('Type',       { fg = t.syn_cyan })
hl('Structure',  { fg = t.syn_cyan })
hl('Special',    { fg = t.accent_alt })
hl('Todo',       { fg = t.warn, bold = true })

-- Diagnósticos, con los tres estados del proyecto
hl('DiagnosticError', { fg = t.crit })
hl('DiagnosticWarn',  { fg = t.warn })
hl('DiagnosticInfo',  { fg = t.syn_blue })
hl('DiagnosticHint',  { fg = t.fg_dim })
hl('DiagnosticUnderlineError', { sp = t.crit, undercurl = true })
hl('DiagnosticUnderlineWarn',  { sp = t.warn, undercurl = true })
