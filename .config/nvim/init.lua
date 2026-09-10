-- init.lua — config Neovim (>= 0.12) en un seul fichier.
--
-- Reprise de la vidéo « La config Neovim PARFAITE en partant de ZÉRO »
-- (Loïc Rust) : https://www.youtube.com/watch?v=-zSpBsiTy20
-- Config d'origine : https://github.com/darikoko/neovim-config
-- Ajouts : friendly-snippets, serveurs basedpyright (Python), jdtls (Java) et
-- bashls (bash), recherches ripgrep alignées sur l'alias rg du shell.
--
-- Plugins gérés par vim.pack, le gestionnaire intégré à Neovim 0.12 : clonés
-- au premier lancement dans ~/.local/share/nvim/site/pack/core/opt/, révisions
-- figées dans nvim-pack-lock.json (versionné à côté de ce fichier).
-- Mise à jour : :lua vim.pack.update()

-- ── Plugins ─────────────────────────────────────────────────────────────
vim.pack.add({
    { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
    'https://github.com/nvim-lualine/lualine.nvim',           -- barre d'état
    'https://github.com/folke/snacks.nvim',                   -- picker, explorer, lazygit
    'https://github.com/neovim/nvim-lspconfig',               -- configs LSP par défaut
    'https://github.com/nvim-treesitter/nvim-treesitter',     -- parsers (:TSInstall)
    'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
    'https://github.com/windwp/nvim-autopairs',
    'https://github.com/saghen/blink.lib',                    -- dépendance de blink.cmp
    'https://github.com/saghen/blink.cmp',                    -- autocomplétion
    'https://github.com/rafamadriz/friendly-snippets',        -- snippets, lus par blink.cmp
    'https://codeberg.org/andyg/leap.nvim',                   -- sauts à 2 caractères
})

-- ── Options de base ─────────────────────────────────────────────────────
vim.cmd.colorscheme('catppuccin-nvim')
vim.g.mapleader = ' '
vim.o.showmode = false -- le mode est affiché par lualine
vim.o.number = true
vim.o.shiftwidth = 4   -- espaces par niveau d'indentation
vim.o.tabstop = 4      -- largeur d'une tabulation, en caractères
vim.o.winborder = 'rounded'

-- :grep passe par ripgrep avec les options de l'alias rg et du :Rg de vim :
-- fichiers cachés inclus, .gitignore respecté, .git exclu. Le défaut de Neovim
-- quand rg est présent (`rg --vimgrep -uu`) fouille aussi node_modules, target…
vim.o.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git'"
vim.o.grepformat = '%f:%l:%c:%m'

-- Diagnostics : un rond dans la marge, le message est rendu par
-- tiny-inline-diagnostic (d'où virtual_text désactivé).
vim.diagnostic.config({
    virtual_text = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '●',
            [vim.diagnostic.severity.WARN] = '●',
            [vim.diagnostic.severity.INFO] = '●',
            [vim.diagnostic.severity.HINT] = '●',
        },
    },
})

-- ── Configuration des plugins ───────────────────────────────────────────
require('lualine').setup()
require('nvim-autopairs').setup({})

require('snacks').setup({
    picker = {
        enabled = true,
        -- Espace fg lance déjà ripgrep (.git exclu) : on y ajoute les fichiers
        -- cachés, comme :grep et le :Rg de vim.
        sources = { grep = { hidden = true } },
    },
    explorer = { enabled = true },
    lazygit = { enabled = true }, -- nécessite le binaire lazygit
})

require('tiny-inline-diagnostic').setup({
    options = {
        multilines = { enabled = true },
    },
    -- modern, classic, minimal, powerline, ghost, simple, nonerdfont, amongus
    preset = 'ghost',
})

-- blink.cmp compile sa lib Rust (cargo build --release) au premier lancement,
-- puis réutilise le binaire déjà construit.
local cmp = require('blink.cmp')
cmp.build():pwait()
cmp.setup({
    keymap = {
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Esc>'] = { 'cancel', 'fallback' },
    },
    completion = {
        accept = { auto_brackets = { enabled = true } },
    },
    sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
})

-- ── LSP ─────────────────────────────────────────────────────────────────
-- Les suggestions de blink.cmp viennent de ces serveurs. Noms tirés de la liste
-- nvim-lspconfig (rust_analyzer, pas rust-analyzer). Neovim n'installe aucun
-- serveur : install-dotfiles pose ceux de Rust, C/C++, Python, Java, Lua, bash
-- et JavaScript/TypeScript. Un serveur absent ne démarre pas : en silence pour
-- la plupart (ligne dans ~/.local/state/nvim/lsp.log), avec un message d'erreur
-- à l'ouverture d'un .html pour html.

-- basedpyright vérifie les types en mode « recommended » par défaut, très
-- bavard ; « standard » est le niveau de pyright.
vim.lsp.config('basedpyright', {
    settings = { basedpyright = { analysis = { typeCheckingMode = 'standard' } } },
})

vim.lsp.enable({
    'rust_analyzer', 'html', 'jinja_lsp', 'emmet_ls', 'ts_ls',
    'svelte', 'lua_ls', 'clangd', 'nushell',
    'basedpyright', 'jdtls', 'bashls', -- ajoutés à la config d'origine
})

-- ── Raccourcis ──────────────────────────────────────────────────────────
local map = vim.keymap.set

map('n', '<leader>ff', Snacks.picker.files, { desc = 'Fichiers' })
map('n', '<leader>fg', Snacks.picker.grep, { desc = 'Grep dans les fichiers' })
map('n', '<leader>fb', Snacks.picker.buffers, { desc = 'Buffers ouverts' })
map('n', '<leader>fe', function() Snacks.explorer() end, { desc = 'Explorateur' })
map('n', '<leader>fd', Snacks.picker.diagnostics, { desc = 'Diagnostics' })
map('n', '<leader>fs', Snacks.picker.lsp_symbols, { desc = 'Symboles du buffer' })
map('n', '<leader>fS', Snacks.picker.lsp_workspace_symbols, { desc = 'Symboles du projet' })
map('n', '<leader>fm', vim.lsp.buf.format, { desc = 'Formater' })
map('n', 'gd', Snacks.picker.lsp_definitions, { desc = 'Définition' })
map('n', 'gr', Snacks.picker.lsp_references, { desc = 'Références' })
map('n', '<leader>lg', function() Snacks.lazygit() end, { desc = 'LazyGit' })

map({ 'n', 'x', 'o' }, 's', '<Plug>(leap)', { desc = 'Leap : fenêtre courante' })
map('n', 'S', '<Plug>(leap-from-window)', { desc = 'Leap : autres fenêtres' })
