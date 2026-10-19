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
