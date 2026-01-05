-- tests/minimal_init.lua
-- plenary.nvim を使ったテスト実行用の最小設定

local M = {}

-- パス設定
local plugin_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"

-- plenary.nvim がなければクローン
if vim.fn.isdirectory(plenary_dir) == 0 then
  print("Cloning plenary.nvim...")
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_dir,
  })
end

-- runtimepath 設定
vim.opt.rtp:prepend(plugin_dir)
vim.opt.rtp:prepend(plenary_dir)

-- 基本設定
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- plenary を読み込み
vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

return M
