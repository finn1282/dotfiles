-- ~/.config/nvim/init.lua

-- Leader (space) — set before any keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ===== Your choices =====
local opt = vim.opt

-- Line numbers: absolute only
opt.number = true
opt.relativenumber = false

-- Indentation: 4 spaces, no real tabs
opt.tabstop = 4        -- a tab renders as 4 columns
opt.shiftwidth = 4     -- >> / << and auto-indent use 4
opt.softtabstop = 4    -- Tab/Backspace feel like 4 spaces
opt.expandtab = true   -- insert spaces, never a tab character
opt.autoindent = true  -- keep indent on new lines

-- Search: case-insensitive, but case-sensitive if you type a capital
opt.ignorecase = true
opt.smartcase = true

-- Highlight the line the cursor is on
opt.cursorline = true

-- ===== Sensible assumed defaults =====
opt.mouse = "a"                 -- mouse enabled in all modes
opt.clipboard = "unnamedplus"   -- y/p use the system (Wayland) clipboard
opt.termguicolors = true        -- 24-bit color

-- ===== Highlight yanked text briefly =====
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Flash yanked text",
    callback = function()
        (vim.hl or vim.highlight).on_yank({ timeout = 150 })
    end,
})

-- ===== Colorscheme =====
-- Left unset for now (configure later).

-- ===== Optional: one tiny convenience (delete if unwanted) =====
-- Esc clears search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- ===== Python: language server (pyright) =====
-- Errors, completion, hover docs. Needs: sudo pacman -S pyright
vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "requirements.txt", ".git" },
    settings = {
        python = { analysis = { typeCheckingMode = "basic" } },
    },
})
vim.lsp.enable("pyright")

-- Show errors at the end of the line
vim.diagnostic.config({ virtual_text = true })

-- Completion pops up as you type; Ctrl+n/Ctrl+p to move, Ctrl+y to accept
vim.opt.completeopt = { "menuone", "noselect", "popup" }
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
    end,
})

-- ===== Python: run the current file =====
-- <leader>r  run it; type input in the window below (Ctrl+d ends input)
-- <leader>i  run it with input.txt (same folder) as the input
-- q          close the output window (after the program ends)
local run_buf

local function run_python(use_input_file)
    vim.cmd("write")
    local file = vim.fn.expand("%:p")
    local cmd = "python3 " .. vim.fn.shellescape(file)

    if use_input_file then
        local input = vim.fn.expand("%:p:h") .. "/input.txt"
        if vim.fn.filereadable(input) == 0 then
            vim.notify("No input.txt next to " .. vim.fn.expand("%:t"), vim.log.levels.WARN)
            return
        end
        cmd = cmd .. " < " .. vim.fn.shellescape(input)
    end

    -- replace the previous run's window instead of stacking new ones
    if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
        vim.api.nvim_buf_delete(run_buf, { force = true })
    end

    vim.cmd("botright 12split")
    vim.cmd("enew")
    run_buf = vim.api.nvim_get_current_buf()
    vim.fn.jobstart(cmd, { term = true })
    vim.keymap.set("n", "q", "<cmd>bdelete!<CR>", { buffer = run_buf, desc = "Close output" })
    vim.cmd("startinsert")
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function(args)
        vim.keymap.set("n", "<leader>r", function() run_python(false) end, { buffer = args.buf, desc = "Run file" })
        vim.keymap.set("n", "<leader>i", function() run_python(true) end, { buffer = args.buf, desc = "Run with input.txt" })
    end,
})
