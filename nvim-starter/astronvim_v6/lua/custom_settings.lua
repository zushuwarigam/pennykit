vim.opt.mouse = ''

vim.g.clipboard = 'osc52'

vim.g.editorconfig = true

vim.keymap.set("n", "<Tab>", ":bnext<CR>")
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>")

vim.keymap.set('n', '<M-Up>', ':resize +2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-Down>', ':resize -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-Left>', ':vertical resize -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-Right>', ':vertical resize +2<CR>', { noremap = true, silent = true })
