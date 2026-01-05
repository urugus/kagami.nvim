local M = {}

---@param chan integer|nil
---@param msg table
---@return boolean success
function M.send(chan, msg)
  if not chan then
    return false
  end
  local ok, encoded = pcall(vim.json.encode, msg)
  if not ok then
    vim.notify("Kagami: JSON encode 失敗: " .. tostring(encoded), vim.log.levels.DEBUG)
    return false
  end
  local send_ok, err = pcall(vim.api.nvim_chan_send, chan, encoded .. "\n")
  if not send_ok then
    vim.notify("Kagami: 送信失敗: " .. tostring(err), vim.log.levels.DEBUG)
    return false
  end
  return true
end

---@param winid integer
---@return {topline: integer, lnum: integer, col: integer}|nil
function M.get_view(winid)
  if not (winid and vim.api.nvim_win_is_valid(winid)) then
    return nil
  end
  local view = nil
  vim.api.nvim_win_call(winid, function()
    view = vim.fn.winsaveview()
  end)
  return {
    topline = view.topline or 1,
    lnum = view.lnum or 1,
    col = view.col or 0,
  }
end

---@param state table
---@param config table
---@param cleanup fun()
function M.render_now(state, config, cleanup)
  if not state then
    return
  end

  local source_buf = state.source_buf
  local source_win = state.source_win
  local preview_win = state.preview_win

  if not (source_buf and vim.api.nvim_buf_is_valid(source_buf)) then
    cleanup()
    return
  end
  if not (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
    cleanup()
    return
  end

  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local markdown = table.concat(lines, "\n")

  local view = M.get_view(source_win) or { topline = 1, lnum = 1, col = 0 }
  local width = vim.api.nvim_win_get_width(preview_win)
  local height = vim.api.nvim_win_get_height(preview_win)

  -- 変更がない場合はスキップ（パフォーマンス改善）
  if
    state.last_markdown == markdown
    and state.last_view
    and state.last_view.topline == view.topline
    and state.last_view.lnum == view.lnum
    and state.last_width == width
    and state.last_height == height
  then
    return
  end

  state.last_markdown = markdown
  state.last_view = vim.deepcopy(view)
  state.last_width = width
  state.last_height = height

  M.send(state.chan, {
    type = "render",
    markdown = markdown,
    cursor = { line = view.lnum, col = view.col },
    scroll = { topline = view.topline },
    viewport = { width = width, height = height },
    options = { follow_cursor = config.follow_cursor, follow_scroll = config.follow_scroll },
  })
end

---@param state table
---@param config table
---@param uv any
---@param render_now fun()
function M.schedule_render(state, config, uv, render_now)
  if not state or not state.timer then
    return
  end
  state.timer:stop()
  state.timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    render_now()
  end))
end

return M
