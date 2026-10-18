return {
    { "mason-org/mason.nvim", opts = {} },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "stylua", "gofumpt", "goimports", "clang-format", "prettier" },
            start_delay = 3000,
        },
    },
    { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "saghen/blink.cmp",
        version = "1.*",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            { "mikavilpas/blink-ripgrep.nvim", version = "*" },
        },
        opts = {
            keymap = {
                preset = "default",
                ["<C-Space>"] = { "show" },
                ["<Tab>"] = {
                    function(blink)
                        if vim.g.ai_neocursor then
                            local ok, neocursor = pcall(require, "neocursor")
                            if ok and neocursor.accept and neocursor.accept() then return true end
                        elseif vim.g.ai_copilot then
                            local ok, suggestion = pcall(require, "copilot.suggestion")
                            if ok and suggestion.is_visible() then
                                suggestion.accept()
                                return true
                            end
                        end
                        return blink.select_and_accept()
                    end,
                    "snippet_forward",
                    function() return vim.api.nvim_replace_termcodes("<Plug>(Tabout)", true, true, true) end,
                    "fallback",
                },
                ["<CR>"] = { "select_and_accept", "fallback" },
            },
            snippets = { preset = "luasnip" },
            sources = {
                default = { "lazydev", "lsp", "snippets", "buffer", "path", "ripgrep" },
                providers = {
                    ripgrep = {
                        module = "blink-ripgrep",
                        name = "Ripgrep",
                        opts = {},
                    },
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            completion = {
                menu = { auto_show = true },
                documentation = { auto_show = true, auto_show_delay_ms = 500 },
            },
            signature = { enabled = true },
            cmdline = {
                keymap = { preset = "cmdline" },
                completion = { menu = { auto_show = true } },
                sources = function()
                    local cmdtype = vim.fn.getcmdtype()
                    if cmdtype == "/" or cmdtype == "?" then return { "buffer" } end
                    if cmdtype == ":" then return { "path", "cmdline" } end
                    return {}
                end,
            },
        },
    },
    -- LSPCONFIG
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "saghen/blink.cmp",
            "b0o/schemastore.nvim",
        },
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            -- Neovim hardcodes didChangeWatchedFiles off on Linux (vim/lsp/protocol.lua),
            -- even though the inotify backend is available. Force it on so Pyrefly sees
            -- file changes made outside nvim (agents, git) without a server restart.
            if vim.fn.has("linux") == 1 and vim.fn.executable("inotifywait") == 1 then
                capabilities.workspace = capabilities.workspace or {}
                capabilities.workspace.didChangeWatchedFiles =
                    { dynamicRegistration = true, relativePatternSupport = true }
            end
            local servers = {
                "lua_ls",
                "ts_ls",
                "gopls",
                "clangd",
                "rust_analyzer",
                "pyrefly",
                "jsonls",
                "yamlls",
                "eslint",
                "tailwindcss",
                "sqls",
            }

            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_enable = false,
            })

            vim.lsp.config("*", {
                capabilities = capabilities,
            })
            vim.lsp.config("pyrefly", {
                settings = {
                    python = {
                        pyrefly = { typeCheckingMode = "default" },
                    },
                },
            })
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        completion = { callSnippet = "Replace" },
                    },
                },
            })
            vim.lsp.config("jsonls", {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = { enable = true },
                    },
                },
            })
            vim.lsp.config("yamlls", {
                settings = {
                    yaml = {
                        schemaStore = { enable = false, url = "" },
                        schemas = require("schemastore").yaml.schemas(),
                    },
                },
            })

            for _, server in ipairs(servers) do
                vim.lsp.enable(server)
            end

            -- Diagnostic appearance & behavior
            vim.diagnostic.config({
                virtual_text = false,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "✘",
                        [vim.diagnostic.severity.WARN] = "▲",
                        [vim.diagnostic.severity.HINT] = "⚑",
                        [vim.diagnostic.severity.INFO] = "»",
                    },
                },
                underline = true,
                update_in_insert = true,
                severity_sort = true,
                float = {
                    focused = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end
    },
    {
        "rachartier/tiny-code-action.nvim",
        event = "LspAttach",
        dependencies = { "nvim-telescope/telescope.nvim" },
        opts = { picker = "telescope" },
    },
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy",
        priority = 1000,
        opts = {
            options = {
                overflow = { mode = "wrap" },
                override_open_float = true,
            },
        },
    },
}
