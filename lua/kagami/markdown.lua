local M = {}

---@param bufnr integer
---@param filetypes string[]
function M.is_markdown_buf(bufnr, filetypes)
  local ft = vim.bo[bufnr].filetype
  for _, v in ipairs(filetypes or {}) do
    if v == ft then
      return true
    end
  end
  return false
end

return M

