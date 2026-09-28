-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", ";;", "<Esc>", { noremap = true, silent = true })

-- Définir la largeur de texte à 80 caractères
vim.opt.textwidth = 80

-- Sauvegarde automatique des fichiers
vim.opt.autowriteall = true

-- Navigation entre les buffers
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-t>", ":enew<CR>", { noremap = true, silent = true })

-- Rechargement automatique des fichiers modifiés en externe
vim.opt.autoread = true

-- Navigation dans la command line vim Alt+j / Alt+k
vim.cmd([[
  cnoremap <M-j> <Down>
  cnoremap <M-k> <Up>
  cnoremap <Esc>j <Down>
  cnoremap <Esc>k <Up>
]])

-- Remap Ctrl+Tab pour alterner avec le dernier buffer
vim.keymap.set("n", "<C-Tab>", ":e#<CR>")
