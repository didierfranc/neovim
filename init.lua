-- ============================================================
-- My Neovim config
--   One Dark theme  ·  Tree-sitter  ·  rust-analyzer
--   gitsigns (git diff)  ·  blink.cmp  ·  telescope  ·  neo-tree
-- Single file: everything lives here.
-- ============================================================

vim.g.mapleader = " "

-- netrw off (we use neo-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ------------------------------------------------------------
-- OPTIONS
-- ------------------------------------------------------------

local opt = vim.opt

-- Interface
opt.number = true
opt.relativenumber = false    -- absolute line numbers
opt.cursorline = false        -- no current-line highlight
opt.signcolumn = "yes:1"
opt.numberwidth = 4           -- never go below this: the column would widen while scrolling (files > 999 lines)
opt.termguicolors = true
opt.background = "dark"
opt.laststatus = 3          -- a single statusline at the bottom
opt.showtabline = 0         -- no tabline row: the tabs live in the
                            -- header of the code window (see ui_winbar),
                            -- otherwise an empty band stays above the panel
opt.showmode = false        -- the mode is shown in the statusline
opt.mouse = "a"
opt.winborder = "rounded"   -- rounded floating windows (hover, completion…)
opt.pumheight = 12
opt.cmdheight = 0           -- no empty row at the bottom
opt.shortmess:append("c")   -- avoids spurious "Press ENTER" with cmdheight=0
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.updatetime = 200
opt.timeoutlen = 400
opt.confirm = true
opt.scrollback = 10000      -- built-in terminal buffer

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.autoindent = true
opt.smartindent = true
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false
opt.inccommand = "split"

-- Rendering: no "~" at end of buffer, invisible separators
opt.fillchars = {
    eob = " ",
    fold = " ",
    foldopen = " ",
    foldclose = " ",
    foldsep = " ",
    diff = "╱",
    vert = "│",     -- the thin vertical separator
    horiz = " ",
    horizup = " ",
    horizdown = " ",
    vertleft = " ",
    vertright = " ",
    verthoriz = " ",
}

-- Inactive splits keep the same background colour (flatter, prettier)
opt.winhighlight = "NormalNC:Normal,MsgSeparator:MsgSeparator"

-- Diff: line alignment + intra-line colouring
opt.diffopt:append({ "internal", "filler", "closeoff", "algorithm:histogram", "linematch:60" })

-- ------------------------------------------------------------
-- LAZY.NVIM
-- ------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    -- ========================================================
    -- THEME (One Dark)
    -- ========================================================
    {
        "olimorris/onedarkpro.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            options = {
                cursorline = true,
                transparency = true,   -- nvim no longer paints a background: no seam with the terminal margin
                terminal_colors = true,
                lualine_theme = "onedark",
                bold = true,
                italic = true,
            },
            styles = {
                comments = "italic",
                keywords = "italic",
                functions = "italic",   -- set it to "NONE" if you don't like it
                variables = "NONE",
                strings = "NONE",
                types = "NONE",
            },
        },
        config = function(_, opts)
            require("onedarkpro").setup(opts)
            vim.cmd.colorscheme("onedark")
        end,
    },

    -- ========================================================
    -- ICONS + STATUSLINE + TAB BAR
    -- ========================================================
    { "nvim-tree/nvim-web-devicons", lazy = true },

    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                -- Flat status bar with no coloured blocks,
                -- but on a slightly lighter background so it stands out.
                theme = {
                    normal = {
                        a = { fg = "#9aa3b2", bg = "#2f333d", gui = "bold" },
                        b = { fg = "#7f8797", bg = "#2f333d" },
                        c = { fg = "#5c6370", bg = "#2f333d" },
                    },
                    insert = { a = { fg = "#98c379", bg = "#2f333d", gui = "bold" }, b = { bg = "#2f333d" }, c = { bg = "#2f333d" } },
                    visual = { a = { fg = "#c678dd", bg = "#2f333d", gui = "bold" }, b = { bg = "#2f333d" }, c = { bg = "#2f333d" } },
                    replace = { a = { fg = "#e06c75", bg = "#2f333d", gui = "bold" }, b = { bg = "#2f333d" }, c = { bg = "#2f333d" } },
                    command = { a = { fg = "#e5c07b", bg = "#2f333d", gui = "bold" }, b = { bg = "#2f333d" }, c = { bg = "#2f333d" } },
                    inactive = {
                        a = { fg = "#4b5263", bg = "#272b34" },
                        b = { fg = "#4b5263", bg = "#272b34" },
                        c = { fg = "#4b5263", bg = "#272b34" },
                    },
                },
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                globalstatus = true,
                disabled_filetypes = { statusline = { "neo-tree", "lazy", "mason" } },
                refresh = { statusline = 500 },
            },
            sections = {
                lualine_a = {
                    { "mode", fmt = function(s) return s:sub(1, 1) end, padding = { left = 1, right = 1 } },
                },
                lualine_b = {
                    {
                        "diagnostics",
                        symbols = { error = " ", warn = " ", info = " ", hint = " " },
                        colored = true,
                    },
                    { "branch", icon = "", padding = { left = 2, right = 1 } },
                    { "diff", symbols = { added = " ", modified = " ", removed = " " }, colored = true },
                },
                lualine_c = {
                    {
                        function()
                            local names = {}
                            for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                                table.insert(names, c.name)
                            end
                            return #names > 0 and table.concat(names, ", ") or ""
                        end,
                        color = { fg = "#5c6370" },
                    },
                },
                lualine_x = {},
                lualine_y = { { "filetype", color = { fg = "#7f8797" } } },
                lualine_z = { { "location", padding = { left = 1, right = 1 } } },
            },
            extensions = { "neo-tree", "lazy", "quickfix" },
        },
    },

    -- (No more bufferline: the tabs are drawn in the code window's
    --  header by ui_winbar(), so nothing is left above the panel.
    --  The tabline row itself spans the whole width.)

    -- ========================================================
    -- TREE-SITTER (rich syntax highlighting)
    -- ========================================================
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        -- No `build = ":TSUpdate"`: that step re-runs a parser compilation
        -- through the tree-sitter CLI, which fails here ("Unable to handle
        -- compilation, expected exactly one compiler job") and shows a
        -- blocking error ("Press ENTER") at startup.
        config = function()
            local langs = {
                "rust", "lua", "vim", "vimdoc", "query", "comment",
                "toml", "json", "yaml", "markdown", "markdown_inline",
                "bash", "python", "javascript", "typescript", "tsx",
                "html", "css", "c", "cpp", "go", "diff", "gitcommit",
                "gitignore", "git_rebase", "regex", "dockerfile", "make",
            }

            require("nvim-treesitter").setup({})
            -- No install() here: every parser we use is already present,
            -- and the call re-runs a compilation through the tree-sitter CLI, which
            -- fails here ("Unable to handle compilation, expected exactly one
            -- compiler job") with a blocking "Press ENTER" error.
            -- To add a language: ":TSInstall <lang>" by hand.

            -- Turn on tree-sitter highlighting + tree-based indentation
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    if pcall(vim.treesitter.start, args.buf) then
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },

    -- ========================================================
    -- GIT: gutter diff + inline blame + hunks
    -- ========================================================
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            -- We compare against the last commit (so staged
            -- changes show up in the gutter too).
            base = "HEAD",
            signs = {
                add = { text = "┃", linehl = "GitSignsAddLine" },
                change = { text = "┃", linehl = "GitSignsChangeLine" },
                delete = { text = "┃", linehl = "GitSignsDeleteLine" },
                topdelete = { text = "┃", linehl = "GitSignsDeleteLine" },
                changedelete = { text = "┃", linehl = "GitSignsChangeLine" },
                untracked = { text = "┃" },
            },
            signs_staged = {
                add = { text = "┃", linehl = "GitSignsStagedAddLine" },
                change = { text = "┃", linehl = "GitSignsStagedChangeLine" },
                delete = { text = "┃", linehl = "GitSignsStagedDeleteLine" },
                topdelete = { text = "┃", linehl = "GitSignsStagedDeleteLine" },
                changedelete = { text = "┃", linehl = "GitSignsStagedChangeLine" },
            },
            -- Colour the changed word/line inside the line itself
            word_diff = false,   -- no word-by-word colour blocks
            -- Inline blame at end of line
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 400,
                ignore_whitespace = false,
            },
            current_line_blame_formatter = "  <author>, <author_time:%d/%m/%Y> · <summary>",
            preview_config = { border = "rounded", style = "minimal" },
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local function map(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc, silent = true })
                end

                map("n", "]c", function()
                    if vim.wo.diff then return "]c" end
                    vim.schedule(function() gs.nav_hunk("next") end)
                    return "<Ignore>"
                end, "Next hunk")
                map("n", "[c", function()
                    if vim.wo.diff then return "[c" end
                    vim.schedule(function() gs.nav_hunk("prev") end)
                    return "<Ignore>"
                end, "Previous hunk")

                map("n", "<leader>gs", gs.stage_hunk, "Git: stage hunk")
                map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Git: stage hunk")
                map("n", "<leader>gr", gs.reset_hunk, "Git: reset hunk")
                map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Git: reset hunk")
                map("n", "<leader>gu", gs.undo_stage_hunk, "Git: undo stage")
                map("n", "<leader>gp", gs.preview_hunk, "Git: preview hunk")
                map("n", "<leader>gd", gs.diffthis, "Git: open diff")
                map("n", "<leader>gD", function() gs.diffthis("~") end, "Git: diff vs last commit")
                map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Git: blame")
                map("n", "<leader>gB", gs.toggle_current_line_blame, "Git: blame inline on/off")
                map("n", "<leader>gS", gs.stage_buffer, "Git: stage file")
                map("n", "<leader>gR", gs.reset_buffer, "Git: reset file")
            end,
        },
        config = function(_, opts)
            require("gitsigns").setup(opts)
        end,
    },

    -- ========================================================
    -- LSP
    -- ========================================================
    { "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" } },

    {
        "mason-org/mason.nvim",
        cmd = "Mason",
        opts = { ui = { border = "rounded" } },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {},      -- nothing enforced: use :Mason to add more
            automatic_enable = true,
        },
    },

    -- ========================================================
    -- COMPLETION (popup menu + ghost text)
    -- ========================================================
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = { preset = "default" },
            appearance = { nerd_font_variant = "mono" },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
                ghost_text = { enabled = true },
                menu = { draw = { treesitter = { "lsp" } } },
            },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            signature = { enabled = true },
            fuzzy = { implementation = "lua" },
        },
    },

    -- ========================================================
    -- SEARCH (telescope)
    -- ========================================================
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find file" },
            { "<C-f>", "<cmd>Telescope live_grep<CR>", desc = "Search in project" },
        },
        opts = {
            defaults = {
                prompt_prefix = "  ",
                selection_caret = "  ",
                entry_prefix = "  ",
                sorting_strategy = "ascending",
                layout_strategy = "horizontal",
                path_display = { "smart" },
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                layout_config = {
                    horizontal = { preview_width = 0.55, prompt_position = "top" },
                    width = 0.9,
                    height = 0.85,
                },
                file_ignore_patterns = { "%.git/", "target/", "node_modules/", "%.lock" },
                vimgrep_arguments = {
                    "rg", "--color=never", "--no-heading", "--with-filename",
                    "--line-number", "--column", "--smart-case", "--hidden",
                    "--glob", "!.git/",
                },
            },
            pickers = { find_files = { hidden = true } },
        },
    },

    -- ========================================================
    -- EXPLORER (neo-tree)
    -- ========================================================
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        cmd = "Neotree",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = { { "<C-b>", "<cmd>Neotree toggle<CR>", desc = "Explorer" } },
        opts = {
            close_if_last_window = false,
            -- The project root is shown at the top of the panel: that is what
            -- you click to collapse/expand (the tab row header itself is
            -- not clickable).
            hide_root_node = false,
            -- Note: the tree's caret is painted by Terminal.app itself —
            -- verified: even with guicursor=a:NONE nvim cannot remove it.
            -- So we can only neutralise the cell on nvim's side
            -- (winhighlight, see below); its visible shape stays.

            enable_git_status = true,
            enable_diagnostics = true,
            filesystem = {
                -- disabled: incompatible with hide_root_node (infinite recursion in neo-tree).
                -- Use :Neotree reveal to realign on the current file.
                follow_current_file = { enabled = false },
                hijack_netrw_behavior = "disabled",
                use_libuv_file_watcher = true,
                filtered_items = {
                    visible = true,             -- show everything, git-ignored files included
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_by_name = {},
                },
            },
            default_component_configs = {
                indent = {
                    with_markers = true,
                    with_expanders = true,   -- ▸/▾ chevrons
                    indent_size = 2,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                -- This neo-tree version turns on size/type/date columns by
                -- default: we cut them, we only want names + icons + git.
                file_size = { enabled = false },
                type = { enabled = false },
                last_modified = { enabled = false },
                created = { enabled = false },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰉖",
                    folder_empty_open = "󰷏",
                    -- The glyphs above must be real Nerd Font codepoints:
                    -- so we provide them explicitly, and files go through devicons.
                    -- Muted colours in apply_theme_colors().
                    provider = function(icon, node)
                        if not node then
                            return icon
                        end
                        if node.type == "directory" then
                            local open = false
                            pcall(function()
                                open = node:is_expanded()
                            end)
                            icon.text = open and vim.fn.nr2char(0xf07c) or vim.fn.nr2char(0xf07b)
                            icon.highlight = "NeoTreeDirectoryIcon"
                        elseif node.type == "file" then
                            local name = node.name or ""
                            local ok, char = pcall(
                                require("nvim-web-devicons").get_icon,
                                name,
                                vim.fn.fnamemodify(name, ":e"),
                                { default = true }
                            )
                            if ok and char then
                                icon.text = char
                            end
                            icon.highlight = "NeoTreeFileName"
                        end
                        return icon
                    end,
                },
                git_status = {
                    symbols = {
                        added = "",
                        modified = "",
                        deleted = "✖",
                        renamed = "󰁕",
                        untracked = "",
                        ignored = "",
                        unstaged = "",
                        staged = "",
                        conflict = "",
                    },
                },
            },
            window = {
                position = "left",
                width = 32,
                mappings = {
                    -- Moving right opens the folder / the file,
                    -- moving left closes the folder.
                    -- By default neo-tree maps `l` to focus_preview.
                    ["l"] = "open",
                    ["<Right>"] = "open",
                    ["h"] = "close_node",
                    ["<Left>"] = "close_node",
                },
            },
        },
    },

    -- ========================================================
    -- SCROLLBAR with diff marks
    -- ========================================================
    {
        "lewis6991/satellite.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            winblend = 0,                    -- no "muddy" transparency
            excluded_filetypes = { "neo-tree", "pathbar", "lazy", "mason", "help" },
            handlers = {
                cursor = { enable = false },      -- no ⎺⎻⎼⎽ marker
                search = { enable = true },
                -- no diagnostic marks: they drew thin dashes
                -- everywhere, mixed in with the git diff segments
                diagnostic = { enable = false },
                gitsigns = {
                    enable = true,
                    -- half-block: about the same thickness as the bar's
                    -- cursor (the full block █ gave a mark that was too wide)
                    signs = { add = "▐", change = "▐", delete = "▐" },
                },
                marks = { enable = false },
            },
        },
    },

    -- ========================================================
    -- VISUAL INDENTATION guides + which-key
    -- ========================================================
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│", tab_char = "│" },
            scope = {
                enabled = true,
                show_start = false,
                show_end = false,
                highlight = { "Function", "Label" },
                priority = 200,
            },
            exclude = {
                filetypes = {
                    "help", "dashboard", "neo-tree", "lazy", "mason",
                    "notify", "toggleterm", "diff", "gitcommit",
                },
            },
        },
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
    },
}, {
    install = { colorscheme = { "onedark", "habamax" } },
    checker = { enabled = false },
    change_detection = { notify = false },
})

-- ------------------------------------------------------------
-- LSP: servers + settings + keymaps
-- ------------------------------------------------------------

vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = "●", source = "if_many" },
    signs = {
        text = { [vim.diagnostic.severity.ERROR] = " ", [vim.diagnostic.severity.WARN] = " ", [vim.diagnostic.severity.INFO] = " ", [vim.diagnostic.severity.HINT] = " " },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = true, header = "", prefix = "" },
})

-- Completion capabilities (blink.cmp)
pcall(function()
    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
end)

-- rust-analyzer
vim.lsp.config("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            check = { command = "clippy", extraArgs = { "--no-deps" } },
            checkOnSave = true,
            procMacro = { enable = true },
            imports = { granularity = { group = "module" }, prefix = "self" },
            files = { excludeDirs = { ".git", "target", "node_modules" } },
            inlayHints = {
                bindingModeHints = { enable = false },
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = { enable = "skip_trivial" },
                parameterHints = { enable = true },
                chainingHints = { enable = true },
                typeHints = { enable = true },
                maxLength = 25,
            },
            lens = { enable = true },
        },
    },
})

-- clangd (C/C++)
vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
    -- clangd must only activate where there is a real C/C++ project: otherwise,
    -- inside a Rust repo it attaches and emits "Unable to handle compilation,
    -- expected exactly one compiler job" — which, with cmdheight=0, becomes a
    -- blocking "Press ENTER" error (no more clicks and no navigation).
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd" },
})

vim.lsp.enable({ "rust_analyzer", "clangd" })

-- LSP keymaps + comforts, on server attach
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc, silent = true })
        end

        map("n", "gd", vim.lsp.buf.definition, "Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Declaration")
        map("n", "gr", vim.lsp.buf.references, "References")
        map("n", "gi", vim.lsp.buf.implementation, "Implementations")
        map("n", "gt", vim.lsp.buf.type_definition, "Type")
        map("n", "K", vim.lsp.buf.hover, "Documentation")
        map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, "Format")
        map("n", "<leader>e", vim.diagnostic.open_float, "Floating diagnostic")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostics to location list")

        -- Inlay hints (grey types)
        pcall(function()
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end)
    end,
})

-- ------------------------------------------------------------
-- GENERAL KEYMAPS
-- ------------------------------------------------------------

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search" })

-- Save / close
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save" })
map("n", "<C-q>", function() _G.ui_close_buffer(vim.api.nvim_get_current_buf()) end, { desc = "Close tab" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })

-- Move between tabs (like Ctrl+Tab / Ctrl+PgDn)
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next tab" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous tab" })
map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next tab" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous tab" })

-- Splits
map("n", "<leader>-", "<C-w>s", { desc = "Horizontal split" })
map("n", "<leader>|", "<C-w>v", { desc = "Vertical split" })

-- Windows: navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Telescope
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Open buffers" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>", { desc = "Diagnostics" })
map("n", "<leader>fc", "<cmd>Telescope commands<CR>", { desc = "Commands" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })

-- Quick test terminals (cargo)
map("n", "<leader>rr", "<cmd>terminal cargo run<CR>", { desc = "cargo run" })
map("n", "<leader>rt", "<cmd>terminal cargo test<CR>", { desc = "cargo test" })

-- ------------------------------------------------------------
-- MISC
-- ------------------------------------------------------------

-- Hides "service" buffers (the directory passed as an argument, the empty startup buffer)
local function hide_service_buffers()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" and not vim.bo[b].modified then
            local name = vim.api.nvim_buf_get_name(b)
            if name == "" or vim.fn.isdirectory(name) == 1 then
                vim.bo[b].buflisted = false
            end
        end
    end
end

-- Keep only the explorer: no "new file" panel on startup
local function keep_only_tree()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
        local b = vim.api.nvim_win_get_buf(w)
        if vim.bo[b].filetype ~= "neo-tree" and not vim.b[b].pathbar then
            pcall(vim.api.nvim_win_close, w, true)
        end
    end
    hide_service_buffers()

    -- No file open: hide the tab row, the tree moves to the very top
    local listed = 0
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].buflisted then
            listed = listed + 1
        end
    end
    if listed == 0 then
        vim.o.showtabline = 0
    end
end

-- Opens the current folder's README if there is one (otherwise nothing).
-- We open it in the code window, not in the explorer.
local function open_readme_if_any()
    for _, cand in ipairs({
        "README.md",
        "readme.md",
        "Readme.md",
        "README.markdown",
        "README.rst",
        "README.txt",
        "README",
    }) do
        if vim.fn.filereadable(cand) == 1 then
            local target
            for _, w in ipairs(vim.api.nvim_list_wins()) do
                if vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= "neo-tree" then
                    target = w
                end
            end
            if target then
                vim.api.nvim_win_call(target, function()
                    vim.cmd("edit " .. vim.fn.fnameescape(cand))
                    -- an edit during VimEnter does not trigger filetype
                    -- detection: force it, otherwise the README opens without colouring
                    vim.cmd("filetype detect")
                end)
            else
                vim.cmd("edit " .. vim.fn.fnameescape(cand))
                vim.cmd("filetype detect")
            end
            hide_service_buffers()
            return true
        end
    end
    return false
end

-- Open on a directory (nvim ~/dev/project): move into it and show the tree
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local args = vim.fn.argv()
        local dir
        for _, a in ipairs(args) do
            if vim.fn.isdirectory(a) == 1 then
                dir = a
            end
        end

        if dir then
            vim.cmd("cd " .. vim.fn.fnameescape(dir))
            vim.cmd("Neotree show")
            if not open_readme_if_any() then
                keep_only_tree()
            end
        elseif #args == 0 and vim.fn.line2byte("$") == -1 then
            vim.cmd("Neotree show")
            if not open_readme_if_any() then
                keep_only_tree()
            end
        end
    end,
})

-- Inside the explorer the cursor stays on the first column: vertical
-- movement only (and the line is highlighted).
vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "WinEnter" }, {
    callback = function(args)
        if vim.bo[args.buf].filetype ~= "neo-tree" then
            return
        end
        vim.wo.cursorline = true
        -- No caret in the tree: we paint the cursor's cell with the
        -- highlighted-line colour (the only way, Terminal.app has no
        -- cursor shape). We APPEND the mapping to neo-tree's list,
        -- otherwise we would overwrite its own.
        local want = "Cursor:NeoTreeCursorLine"
        local cur = vim.wo.winhighlight
        if not cur:find(want, 1, true) then
            vim.wo.winhighlight = want .. (cur ~= "" and ("," .. cur) or "")
        end
        if vim.fn.wincol() > 1 then
            vim.fn.cursor(vim.fn.line("."), 1)
        end
    end,
})

-- Yank highlight (visual feedback)
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

-- ------------------------------------------------------------
-- Theme palette: the One Dark colour set
-- (UI colours + syntax tokens, kept in one place)
-- Goal: the editor and the explorer share the same colours.
-- ------------------------------------------------------------
local theme = {
    -- UI
    bg            = "#282c33", -- editor.background
    fg            = "#acb2be", -- editor.foreground
    text          = "#dce0e5", -- text
    muted         = "#a9afbc", -- text.muted
    placeholder   = "#878a98", -- text.placeholder
    panel_bg      = "#2f343e", -- panel.background / tab_bar.background
    status_bg     = "#3b414d", -- status_bar.background
    border        = "#363c46", -- border.variant
    sel_bg        = "#454a56", -- element.selected
    lineno        = "#4e5a5f", -- editor.line_number
    lineno_active = "#d0d4da", -- editor.active_line_number
    -- syntax
    attribute   = "#74ade8",
    boolean     = "#bf956a",
    comment     = "#5d636f",
    comment_doc = "#878e98",
    constant    = "#dfc184",
    enum        = "#6eb4bf",
    function_   = "#73ade9",
    keyword     = "#b477cf",
    number      = "#bf956a",
    operator    = "#6eb4bf",
    property    = "#d07277",
    punct       = "#acb2be",
    punct_delim = "#b2b9c6",
    string      = "#a1c181",
    type_       = "#6eb4bf",
    variable    = "#acb2be",
    parameter   = "#d07277",
    variant     = "#73ade9",
    -- diagnostics / git
    error    = "#d07277",
    warning  = "#dec184",
    info     = "#74ade8",
    hint     = "#788ca6",
    added    = "#27a657",
    modified = "#d3b020",
    deleted  = "#e06c76",
}

local function zhi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

local function apply_theme_colors()
    -- Interface
    zhi("Normal", { fg = theme.fg })           -- no bg: we keep the transparency (zero band)
    zhi("NormalNC", { fg = theme.fg })
    zhi("LineNr", { fg = theme.lineno })
    zhi("CursorLineNr", { fg = theme.lineno_active })
    zhi("SignColumn", { fg = theme.lineno })
    zhi("WinSeparator", { fg = theme.border })
    -- Code window header: tab band (bar background) + breadcrumb
    zhi("WinBar", { fg = theme.text, bg = theme.panel_bg })
    zhi("WinBarNC", { fg = theme.muted, bg = theme.panel_bg })
    zhi("BreadcrumbDir", { fg = theme.placeholder })
    zhi("TabBar", { fg = theme.muted, bg = theme.panel_bg })
    zhi("TabBarActive", { fg = theme.text, bg = theme.bg, bold = true })
    -- Path bar (the second row above the code)
    zhi("PathBar", { fg = theme.muted, bg = theme.panel_bg })
    zhi("PathBarDir", { fg = theme.placeholder, bg = theme.panel_bg })
    zhi("PathBarFile", { fg = theme.text, bg = theme.panel_bg })
    zhi("Visual", { bg = "#3e4451" })
    zhi("Search", { fg = theme.bg, bg = "#74ade8" })
    zhi("IncSearch", { fg = theme.bg, bg = "#e8af74" })

    -- Diagnostics
    zhi("DiagnosticError", { fg = theme.error })
    zhi("DiagnosticWarn", { fg = theme.warning })
    zhi("DiagnosticInfo", { fg = theme.info })
    zhi("DiagnosticHint", { fg = theme.hint })
    zhi("DiagnosticVirtualTextError", { fg = theme.error })
    zhi("DiagnosticVirtualTextWarn", { fg = theme.warning })
    zhi("DiagnosticVirtualTextInfo", { fg = theme.info })
    zhi("DiagnosticVirtualTextHint", { fg = theme.hint })
    zhi("DiagnosticUnderlineError", { sp = theme.error, undercurl = true })
    zhi("DiagnosticUnderlineWarn", { sp = theme.warning, undercurl = true })
    zhi("DiagnosticUnderlineInfo", { sp = theme.info, undercurl = true })
    zhi("DiagnosticUnderlineHint", { sp = theme.hint, undercurl = true })

    -- Git (gutter + blame + line backgrounds)
    zhi("GitSignsAdd", { fg = theme.added })
    zhi("GitSignsChange", { fg = theme.modified })
    zhi("GitSignsDelete", { fg = theme.deleted })
    zhi("GitSignsTopdelete", { fg = theme.deleted })
    zhi("GitSignsChangedelete", { fg = theme.modified })
    zhi("GitSignsUntracked", { fg = theme.muted })
    zhi("GitSignsCurrentLineBlame", { fg = theme.placeholder })
    -- (no word-by-word highlight: on a fully added line
    --  it paints a big colour block — a bar + a tint is enough)
    -- Whole line: very light tint (10 %)
    zhi("GitSignsAddLine", { bg = "#283837" })
    zhi("GitSignsChangeLine", { bg = "#3b3931" })
    zhi("GitSignsDeleteLine", { bg = "#3c323a" })
    zhi("GitSignsStagedAddLine", { bg = "#283837" })
    zhi("GitSignsStagedChangeLine", { bg = "#3b3931" })
    zhi("GitSignsStagedDeleteLine", { bg = "#3c323a" })

    -- Syntax (tree-sitter)
    zhi("@comment", { fg = theme.comment })
    zhi("@comment.documentation", { fg = theme.comment_doc })
    zhi("@keyword", { fg = theme.keyword })
    zhi("@keyword.function", { fg = theme.keyword })
    zhi("@keyword.return", { fg = theme.keyword })
    zhi("@keyword.operator", { fg = theme.keyword })
    zhi("@keyword.import", { fg = theme.keyword })
    zhi("@function", { fg = theme.function_ })
    zhi("@function.call", { fg = theme.function_ })
    zhi("@function.method", { fg = theme.function_ })
    zhi("@function.method.call", { fg = theme.function_ })
    zhi("@function.macro", { fg = theme.function_ })
    zhi("@function.builtin", { fg = theme.function_ })
    zhi("@constructor", { fg = theme.function_ })
    zhi("@type", { fg = theme.type_ })
    zhi("@type.builtin", { fg = theme.type_ })
    zhi("@type.qualifier", { fg = theme.keyword })
    zhi("@string", { fg = theme.string })
    zhi("@string.escape", { fg = theme.comment_doc })
    zhi("@string.special", { fg = theme.number })
    zhi("@number", { fg = theme.number })
    zhi("@boolean", { fg = theme.boolean })
    zhi("@constant", { fg = theme.constant })
    zhi("@constant.builtin", { fg = theme.constant })
    zhi("@variable", { fg = theme.variable })
    zhi("@variable.parameter", { fg = theme.parameter })
    zhi("@variable.builtin", { fg = theme.parameter })
    zhi("@property", { fg = theme.property })
    zhi("@field", { fg = theme.property })
    zhi("@operator", { fg = theme.operator })
    zhi("@punctuation", { fg = theme.punct })
    zhi("@punctuation.delimiter", { fg = theme.punct_delim })
    zhi("@punctuation.bracket", { fg = theme.punct_delim })
    zhi("@punctuation.special", { fg = theme.attribute })
    zhi("@attribute", { fg = theme.attribute })
    zhi("@namespace", { fg = theme.text })
    zhi("@module", { fg = theme.text })
    zhi("@label", { fg = theme.attribute })
    zhi("@variant", { fg = theme.variant })
    zhi("@tag", { fg = theme.attribute })
    zhi("@tag.attribute", { fg = theme.property })
    zhi("@tag.delimiter", { fg = theme.punct_delim })

    -- Semantic LSP tokens (they win over tree-sitter)
    zhi("@lsp.type.namespace", { fg = theme.text })
    zhi("@lsp.type.type", { fg = theme.type_ })
    zhi("@lsp.type.class", { fg = theme.type_ })
    zhi("@lsp.type.enum", { fg = theme.type_ })
    zhi("@lsp.type.interface", { fg = theme.type_ })
    zhi("@lsp.type.struct", { fg = theme.type_ })
    zhi("@lsp.type.typeParameter", { fg = theme.type_ })
    zhi("@lsp.type.parameter", { fg = theme.parameter })
    zhi("@lsp.type.variable", { fg = theme.variable })
    zhi("@lsp.type.property", { fg = theme.property })
    zhi("@lsp.type.enumMember", { fg = theme.constant })
    zhi("@lsp.type.function", { fg = theme.function_ })
    zhi("@lsp.type.method", { fg = theme.function_ })
    zhi("@lsp.type.macro", { fg = theme.function_ })
    zhi("@lsp.type.keyword", { fg = theme.keyword })
    zhi("@lsp.type.modifier", { fg = theme.keyword })
    zhi("@lsp.type.comment", { fg = theme.comment })
    zhi("@lsp.type.string", { fg = theme.string })
    zhi("@lsp.type.number", { fg = theme.number })
    zhi("@lsp.type.operator", { fg = theme.operator })
    zhi("@lsp.type.decorator", { fg = theme.attribute })
    zhi("@lsp.type.lifetime", { fg = theme.constant })
    zhi("@lsp.type.label", { fg = theme.attribute })
    zhi("@lsp.typemod.variable.readonly", { fg = theme.variable })
    zhi("@lsp.mod.documentation", { fg = theme.comment_doc })
    zhi("@lsp.mod.deprecated", { strikethrough = true })

    -- Explorer: same background as the editor (transparent = the terminal's),
    -- only the selected line stands out.
    zhi("NeoTreeNormal", { fg = theme.muted })
    zhi("NeoTreeNormalNC", { fg = theme.muted })
    zhi("NeoTreeWinSeparator", { fg = theme.border })
    zhi("NeoTreeEndOfBuffer", { fg = theme.muted })
    zhi("NeoTreeDirectoryName", { fg = theme.muted })
    zhi("NeoTreeDirectoryIcon", { fg = theme.muted })
    zhi("NeoTreeFileName", { fg = theme.fg })
    zhi("NeoTreeFileNameOpened", { fg = theme.text })
    zhi("NeoTreeRootName", { fg = theme.text })
    zhi("NeoTreeIndentMarker", { fg = "#3b414d" })
    zhi("NeoTreeExpander", { fg = theme.placeholder })
    zhi("NeoTreeCursorLine", { bg = theme.sel_bg })
    zhi("NeoTreeMessage", { fg = theme.placeholder })
    zhi("NeoTreeDimText", { fg = theme.placeholder })
    zhi("NeoTreeSymbolicLinkTarget", { fg = theme.info })
    zhi("NeoTreeGitAdded", { fg = theme.added })
    zhi("NeoTreeGitModified", { fg = theme.modified })
    zhi("NeoTreeGitDeleted", { fg = theme.deleted })
    zhi("NeoTreeGitStaged", { fg = theme.added })
    zhi("NeoTreeGitRenamed", { fg = theme.modified })
    zhi("NeoTreeGitConflict", { fg = theme.error })
    zhi("NeoTreeGitUntracked", { fg = theme.placeholder })
    zhi("NeoTreeGitIgnored", { fg = theme.placeholder })

    -- Tab bar: it has its own background
    -- (tab_bar.background #2f343e) — without it, the band above the panel
    -- reads as an empty margin. The active tab is darker (#282c33).
    zhi("BufferLineFill", { bg = theme.panel_bg })
    zhi("BufferLineBackground", { fg = theme.muted, bg = theme.panel_bg })
    zhi("BufferLineBufferVisible", { fg = theme.muted, bg = theme.panel_bg })
    zhi("BufferLineBufferSelected", { fg = theme.text, bg = theme.bg, bold = true })
    zhi("BufferLineSeparator", { fg = theme.panel_bg, bg = theme.panel_bg })
    zhi("BufferLineSeparatorVisible", { fg = theme.panel_bg, bg = theme.panel_bg })
    zhi("BufferLineSeparatorSelected", { fg = theme.panel_bg, bg = theme.bg })
    zhi("BufferLineModified", { fg = theme.modified, bg = theme.panel_bg })
    zhi("BufferLineModifiedSelected", { fg = theme.modified, bg = theme.bg })
    zhi("BufferLineCloseButton", { fg = theme.panel_bg, bg = theme.panel_bg })
    zhi("BufferLineCloseButtonSelected", { fg = theme.panel_bg, bg = theme.bg })
    zhi("BufferLineOffsetSeparator", { fg = theme.border, bg = theme.panel_bg })
    zhi("BufferLineTruncMarker", { fg = theme.placeholder, bg = theme.panel_bg })
    zhi("BufferLineTab", { fg = theme.text, bg = theme.panel_bg })

    -- Indent guides
    zhi("IblIndent", { fg = "#363c46" })
    zhi("IblScope", { fg = "#4e5a5f" })

    -- Inlay hints (types/params shown grey by rust-analyzer)
    zhi("InlayHint", { fg = theme.placeholder })
    zhi("LspInlayHint", { fg = theme.placeholder })

    -- File icons: every devicons colour is muted down to a single
    -- discreet tone. Useful even when devicons loads late.
    for _, name in ipairs(vim.fn.getcompletion("DevIcon", "highlight")) do
        zhi(name, { fg = "#9aa3b2" })
    end
    zhi("NeoTreeDirectoryIcon", { fg = theme.muted })
    zhi("NeoTreeFileIcon", { fg = "#9aa3b2" })

    -- Scrollbar: git diff marks, diagnostics, search.
    -- Glyph only: painting the background too gave marks that were too wide.
    local function sat(name, color)
        zhi(name, { fg = color })
    end
    sat("SatelliteGitSignsAdd", theme.added)
    sat("SatelliteGitSignsChange", theme.modified)
    sat("SatelliteGitSignsDelete", theme.deleted)
    sat("SatelliteDiagnosticError", theme.deleted)
    sat("SatelliteDiagnosticWarn", theme.modified)
    sat("SatelliteDiagnosticInfo", theme.attribute)
    sat("SatelliteDiagnosticHint", theme.muted)
    sat("SatelliteSearch", theme.attribute)
    sat("SatelliteSearchCurrent", theme.text)
    sat("SatelliteCursor", theme.placeholder)
    sat("SatelliteMark", theme.placeholder)
    sat("SatelliteQuickfix", theme.modified)
end

apply_theme_colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_theme_colors })
-- devicons may load after startup: re-apply once everything is loaded
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", callback = apply_theme_colors })

-- The panel's root must show the folder name only ("lisa-qwen"),
-- not the shortened path ("~/dev/lisa-qwen"). neo-tree rewrites that
-- name in the source on every scan: so we wrap the "name" component of
-- the filesystem source, once, on the tree's first opening (by then the
-- dependencies, devicons included, are loaded).
local function shorten_root_name(tbl)
    if not tbl or type(tbl.name) ~= "function" or tbl._root_shortened then
        return
    end
    local orig = tbl.name
    tbl._root_shortened = true
    tbl.name = function(config, node, state)
        -- same test as neo-tree for the root: depth 1
        if node and node.type == "directory" and node:get_depth() == 1 then
            local saved = node.name
            node.name = vim.fn.fnamemodify(node.path or saved or "", ":t")
            local ok, res = pcall(orig, config, node, state)
            node.name = saved
            if ok then
                return res
            end
        end
        return orig(config, node, state)
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    callback = function()
        -- the module's component table AND the one held by the source's state
        local ok, comps = pcall(require, "neo-tree.sources.filesystem.components")
        if ok then
            shorten_root_name(comps)
        end
        local ok2, manager = pcall(require, "neo-tree.sources.manager")
        if ok2 then
            local state = manager.get_state("filesystem")
            shorten_root_name(state and state.components)
        end
    end,
})

-- Click AND drag in the scrollbar: navigate inside the file.
-- (satellite's own mouse mapping does not install here: the click fell back
--  to nvim's normal behaviour, which only placed the cursor.)
local ui_bar = { dragging = false }

-- Locates the bar's band under the mouse and returns its geometry.
local function ui_bar_geom()
    local m = vim.fn.getmousepos()
    -- Click in the tab bar / winbar (line 0): that is not the
    -- scrollbar — we let nvim handle the click on the tab itself.
    if (m.line or 1) <= 0 then
        return nil
    end
    local win = m.winid
    if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
        return nil
    end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
        -- satellite's bar is a floating window: we attach to the
        -- normal window sitting on the same band of rows
        local p = vim.api.nvim_win_get_position(win)
        local h = (type(cfg.height) == "number") and cfg.height or 1
        local code_win
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            local c2 = vim.api.nvim_win_get_config(w)
            if c2.relative == "" then
                local wp = vim.api.nvim_win_get_position(w)
                local wh = vim.api.nvim_win_get_height(w)
                if m.line >= wp[1] + 1 and m.line <= wp[1] + wh then
                    code_win = w
                    break
                end
            end
        end
        if not code_win then
            return nil
        end
        -- m.winrow is the row INSIDE the window under the mouse: for the bar,
        -- that is directly its row (no screen coordinates needed, and
        -- definitely not getmousepos().line, which is a buffer line).
        local h = vim.api.nvim_win_get_height(win)
        return { code_win = code_win, height = h, offset = 0 }
    end
    -- otherwise: last column of a code window
    if m.wincol >= vim.api.nvim_win_get_width(win) then
        local has_wb = vim.wo[win].winbar ~= "" and 1 or 0
        return { code_win = win, height = vim.api.nvim_win_get_height(win) - has_wb, offset = has_wb }
    end
    return nil
end

-- Moves to the line matching the mouse position in the bar.
-- While dragging we do not snap onto diffs: we scroll.
local function ui_bar_goto(geo)
    local m = vim.fn.getmousepos()
    local buf = vim.api.nvim_win_get_buf(geo.code_win)
    local ft = vim.bo[buf].filetype
    if ft == "" or ft == "neo-tree" then
        return
    end
    local total = vim.api.nvim_buf_line_count(buf)
    local row = math.max(1, math.min(geo.height, m.winrow - (geo.offset or 0)))
    local frac = (row - 1) / math.max(1, geo.height - 1)
    local target = math.floor(frac * (total - 1)) + 1

    if not ui_bar.dragging then
        -- simple click: if we touch a mark, we snap onto that change
        local ok, gs = pcall(require, "gitsigns")
        if ok then
            local ok2, hunks = pcall(gs.get_hunks, buf)
            if ok2 and hunks then
                for _, hk in ipairs(hunks) do
                    local added = hk.added
                    if added and added.start then
                        local first = added.start
                        local last = added.start + math.max(0, (added.count or 1) - 1)
                        local function r(l)
                            return math.floor(((l - 1) / math.max(1, total - 1)) * math.max(1, geo.height - 1)) + 1
                        end
                        if row >= r(first) - 2 and row <= r(last) + 2 then
                            target = first
                            break
                        end
                    end
                end
            end
        end
    end

    target = math.max(1, math.min(total, target))
    vim.api.nvim_win_set_cursor(geo.code_win, { target, 0 })
    vim.api.nvim_win_call(geo.code_win, function()
        vim.cmd("normal! zz")
    end)
end

-- These three mappings live at the FILE BUFFER level, never globally.
-- Globally, re-injecting the click short-circuited the panels' local
-- mappings: a double-click on a file in the tree (neo-tree maps
-- `<2-LeftMouse>` to `open`) missed and opened the help instead of the
-- file. The tree keeps its native behaviour, the editor keeps the click
-- on the scrollbar.
local function ui_mouse_maps(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    local ft = vim.bo[buf].filetype
    if ft == "neo-tree" or ft == "lazy" or ft == "mason" or ft == "help" then
        return
    end
    if vim.api.nvim_buf_get_name(buf) == "" then
        return
    end
    local o = { buffer = buf, noremap = true, silent = true }

    vim.keymap.set({ "n", "v", "o", "i" }, "<LeftMouse>", function()
        local geo = ui_bar_geom()
        if geo then
            ui_bar.dragging = true
            ui_bar_goto(geo)
            return
        end
        ui_bar.dragging = false
        local m = vim.fn.getmousepos()
        -- Clicking in ANOTHER window must leave insert mode, as nvim does
        -- natively: otherwise, editing a file and then clicking the tree leaves
        -- you in insert mode and its shortcuts (and j/k) stop responding
        -- — "I can no longer navigate the tree".
        if m.winid ~= vim.api.nvim_get_current_win() and vim.fn.mode():sub(1, 1) == "i" then
            vim.cmd("stopinsert")
        end
        vim.api.nvim_feedkeys(vim.keycode("<LeftMouse>"), "ni", false)
    end, o)

    vim.keymap.set({ "n", "v", "o", "i" }, "<LeftDrag>", function()
        if ui_bar.dragging then
            local geo = ui_bar_geom()
            if geo then
                ui_bar_goto(geo)
            end
            return
        end
        vim.api.nvim_feedkeys(vim.keycode("<LeftDrag>"), "ni", false)
    end, o)

    vim.keymap.set({ "n", "v", "o", "i" }, "<LeftRelease>", function()
        local was = ui_bar.dragging
        ui_bar.dragging = false
        if was then
            local geo = ui_bar_geom()
            if geo then
                ui_bar_goto(geo)
            end
            return
        end
        vim.api.nvim_feedkeys(vim.keycode("<LeftRelease>"), "ni", false)
    end, o)
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    callback = function(a)
        ui_mouse_maps(a.buf)
    end,
})

-- Breadcrumb above the editor
function _G.ui_breadcrumb()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" or vim.bo.filetype == "neo-tree" then
        return ""
    end
    local rel = vim.fn.fnamemodify(name, ":~:.")
    local dir = vim.fn.fnamemodify(rel, ":h")
    local file = vim.fn.fnamemodify(rel, ":t")
    if dir == "." then
        dir = ""
    elseif dir ~= "" then
        dir = dir .. "/"
    end
    return "  %#BreadcrumbDir#" .. dir .. "%#WinBar#" .. file .. " "
end

-- File tabs drawn in the code window's header, followed by the
-- breadcrumb. They are deliberately NOT in the `tabline` row: that one
-- spans the whole screen width, including above the explorer, which
-- left an empty band above the panel.
_G.__ui_tab_spans = {}

function _G.ui_winbar()
    local ok, res = pcall(function()
        local cur = vim.api.nvim_get_current_buf()
        local spans, parts, col = {}, {}, 0
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            -- Each buffer is tested individually: after a close,
            -- `nvim_list_bufs()` still holds invalid buffers and reading
            -- `vim.bo[b]` raised an error — the wrapping pcall then returned
            -- an empty winbar and ALL tabs vanished at once.
            -- We do NOT require the buffer to be loaded: when one file
            -- replaces another ('hidden' off), the abandoned buffer is unloaded
            -- but stays listed. Requiring it made its tab vanish from the bar —
            -- the README opened at startup "closed" as soon as a first file
            -- was opened.
            local ok2, listed = pcall(function()
                return vim.bo[b].buflisted
            end)
            if ok2 and listed then
                local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
                if name ~= "" then
                    local label = " " .. name .. " "
                    local width = vim.fn.strdisplaywidth(label)
                    local hl = (b == cur) and "TabBarActive" or "TabBar"
                    parts[#parts + 1] = "%#" .. hl .. "#"
                    parts[#parts + 1] = "%1@v:lua.ui_tab_click@"
                    parts[#parts + 1] = label
                    -- doc: %1@<fn>@<label>%X
                    parts[#parts + 1] = "%X"
                    spans[#spans + 1] = { from = col, to = col + width - 1, buf = b }
                    col = col + width
                end
            end
        end
        _G.__ui_tab_spans = spans
        parts[#parts + 1] = "%#WinBar#"
        parts[#parts + 1] = "%="
        parts[#parts + 1] = ui_breadcrumb()
        return table.concat(parts)
    end)
    return ok and res or ""
end

-- Click on a tab: each tab's column range is recorded while
-- rendering, then the clicked tab is found from the mouse position.
function _G.ui_tab_click()
    local m = vim.fn.getmousepos()
    local col = (m.wincol or 0) - 1
    for _, s in ipairs(_G.__ui_tab_spans or {}) do
        if col >= s.from and col <= s.to then
            if m.winid and m.winid ~= 0 then
                vim.api.nvim_win_set_buf(m.winid, s.buf)
            else
                vim.api.nvim_set_current_buf(s.buf)
            end
            return
        end
    end
end

-- (The breadcrumb is set window by window further down, never globally:
--  otherwise panels reserve an empty row.)

-- Closes a buffer WITHOUT collapsing the code window: otherwise nvim
-- keeps only the tree, the winbar disappears — and with it the whole tab
-- bar, which reads as "the README closed too".
_G.ui_close_buffer = function(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    if vim.bo[buf].modified then
        vim.notify("Tab modified — save or undo before closing", vim.log.levels.WARN)
        return
    end
    -- If the buffer is displayed somewhere, put another file there first.
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 and vim.api.nvim_win_is_valid(win) then
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            local ok, alt = pcall(function()
                return b ~= buf and vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= ""
                    and vim.api.nvim_buf_is_loaded(b)
            end)
            if ok and alt then
                pcall(vim.api.nvim_win_set_buf, win, b)
                break
            end
        end
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = false })
end

-- RIGHT click on a tab: closes the tab under the cursor.
-- The winbar's `%@` only handles the left button, hence this separate
-- mapping reusing the column ranges recorded at render time (__ui_tab_spans).
vim.keymap.set({ "n", "v", "o", "i" }, "<RightMouse>", function()
    local m = vim.fn.getmousepos()
    local spans = _G.__ui_tab_spans or {}
    -- Only inside the tab band: the code window's winbar first
    -- row (winid set) or the full-width tabline (winid = 0).
    local in_tab_band = (#spans > 0)
        and ((m.winid == 0 and (m.wincol or 0) == 0) or (m.winid ~= 0 and (m.line or 1) <= 0))
    if in_tab_band then
        local col = (m.winid == 0) and ((m.screencol or 1) - 1) or ((m.wincol or 1) - 1)
        -- Closes ONLY the tab under the mouse: if no range matches
        -- exactly, we touch nothing (never a cascade of closes —
        -- "it closes them all").
        for _, s in ipairs(spans) do
            if col >= s.from and col <= s.to then
                if vim.api.nvim_buf_is_valid(s.buf) then
                    ui_close_buffer(s.buf)
                end
                return
            end
        end
        return
    end
    vim.api.nvim_feedkeys(vim.keycode("<RightMouse>"), "ni", false)
end, { noremap = true, silent = true })

-- The breadcrumb is only set on file windows: panels (the
-- explorer) keep their first row for content and have no sign
-- column (it would shift the whole tree one cell to the right).
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "WinNew" }, {
    callback = function()
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            local b = vim.api.nvim_win_get_buf(w)
            local bft = vim.bo[b].filetype
            if bft == "neo-tree" or bft == "lazy" or bft == "mason" or bft == "help" then
                vim.wo[w].winbar = ""
                vim.wo[w].signcolumn = "no"
            elseif vim.api.nvim_buf_get_name(b) ~= "" then
                vim.wo[w].winbar = "%{%v:lua.ui_winbar()%}"
                vim.wo[w].signcolumn = "yes:1"
            end
        end
    end,
})
