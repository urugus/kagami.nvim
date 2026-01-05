local uv = vim.uv or vim.loop

local config_mod = require("kagami.config")
local autocmd = require("kagami.autocmd")
local lifecycle = require("kagami.lifecycle")
local markdown = require("kagami.markdown")
local renderer = require("kagami.renderer")
local sync = require("kagami.sync")
local window = require("kagami.window")

local M = {}

---@type table<string, any>
M._config = vim.deepcopy(config_mod.defaults)

---@type {source_buf?: integer, source_win?: integer, preview_buf?: integer, preview_win?: integer, chan?: integer, timer?: any, augroup?: integer}?
M._state = nil

local function cleanup()
  if not M._state then
    return
  end
  lifecycle.cleanup(M._state)
  M._state = nil
end

local function render_now()
  if not M._state then
    return
  end
  sync.render_now(M._state, M._config, cleanup)
end

local function schedule_render()
  if not M._state then
    return
  end
  sync.schedule_render(M._state, M._config, uv, render_now)
end

function M.setup(opts)
  M._config = config_mod.merge(opts)
end

function M.open()
  if M._state then
    return
  end

  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()

  if not markdown.is_markdown_buf(source_buf, M._config.filetypes) then
    vim.notify("Kagami: markdown 以外の filetype です", vim.log.levels.WARN)
  end

  local cmd = renderer.resolve_cmd(M._config)
  if not cmd then
    vim.notify("Kagami: renderer_cmd が解決できません", vim.log.levels.ERROR)
    return
  end

  local preview = window.open_preview_split()
  local preview_win = preview.win
  local preview_buf = preview.buf

  local env = {
    KAGAMI = "1",
    KAGAMI_MODE = tostring(M._config.mode or "ansi"),
  }

  local mermaid = M._config.mermaid or {}
  env.KAGAMI_MERMAID = mermaid.enabled == false and "0" or "1"
  if type(mermaid.mmdc) == "string" and mermaid.mmdc ~= "" then
    env.KAGAMI_MMDC = mermaid.mmdc
  end
  if type(mermaid.rows) == "number" and mermaid.rows >= 1 then
    env.KAGAMI_MERMAID_ROWS = tostring(mermaid.rows)
  end

  local chan = renderer.termopen(cmd, env, function()
    vim.schedule(cleanup)
  end)

  if chan <= 0 then
    vim.notify("Kagami: renderer の起動に失敗しました", vim.log.levels.ERROR)
    lifecycle.safe_close_win(preview_win)
    return
  end

  local timer = uv.new_timer()
  M._state = {
    source_buf = source_buf,
    source_win = source_win,
    preview_buf = preview_buf,
    preview_win = preview_win,
    chan = chan,
    timer = timer,
  }

  autocmd.attach(M._state, source_buf, schedule_render, cleanup)

  vim.api.nvim_set_current_win(source_win)
  render_now()
end

function M.close()
  cleanup()
end

function M.toggle()
  if M._state then
    M.close()
  else
    M.open()
  end
end

function M.refresh()
  render_now()
end

return M
