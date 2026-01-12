local M = {}

---@return {win: integer, buf: integer}
function M.open_preview_split()
  vim.cmd("botright vsplit")
  local preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(preview_win, math.floor(vim.o.columns / 2))

  vim.cmd("enew")
  local preview_buf = vim.api.nvim_get_current_buf()

  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].modifiable = true
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = "no"
  vim.wo[preview_win].wrap = false

  return { win = preview_win, buf = preview_buf }
end

return M

