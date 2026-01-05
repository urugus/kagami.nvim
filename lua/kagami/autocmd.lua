local M = {}

---@param state table
---@param source_buf integer
---@param on_change fun()
---@param cleanup fun()
function M.attach(state, source_buf, on_change, cleanup)
  local augroup = vim.api.nvim_create_augroup("Kagami_" .. source_buf, { clear = true })
  state.augroup = augroup

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP", "CursorMoved", "CursorMovedI", "WinScrolled" }, {
    group = augroup,
    buffer = source_buf,
    callback = on_change,
  })

  vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup,
    callback = on_change,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufHidden" }, {
    group = augroup,
    buffer = source_buf,
    callback = cleanup,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function(args)
      if not state then
        return
      end
      local closed = tonumber(args.match)
      if closed == state.preview_win or closed == state.source_win then
        cleanup()
      end
    end,
  })
end

return M

