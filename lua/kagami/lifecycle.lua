local M = {}

local function safe_close_win(winid)
  if winid and vim.api.nvim_win_is_valid(winid) then
    pcall(vim.api.nvim_win_close, winid, true)
  end
end

function M.safe_close_win(winid)
  safe_close_win(winid)
end

---@param state table|nil
---@return nil
function M.cleanup(state)
  if not state then
    return
  end

  if state.timer then
    pcall(state.timer.stop, state.timer)
    pcall(state.timer.close, state.timer)
  end

  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
  end

  if state.chan then
    pcall(vim.fn.chanclose, state.chan)
  end

  safe_close_win(state.preview_win)
end

return M

