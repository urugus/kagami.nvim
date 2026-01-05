local M = {}

M.defaults = {
  debounce_ms = 60,
  follow_scroll = true,
  follow_cursor = true,
  filetypes = { "markdown", "md", "pandoc" },
  renderer_cmd = nil, -- {"/abs/path/to/renderer/node_modules/.bin/tsx", "/abs/path/to/renderer/kagami-render.ts"}
  mode = "ansi", -- "ansi" | "sixel"
  mermaid = {
    enabled = true, -- sixel mode で ```mermaid を画像化（mmdc が必要）
    mmdc = nil, -- 例: "/opt/homebrew/bin/mmdc"（未指定なら PATH か renderer/node_modules/.bin を試す）
    rows = nil, -- 図の最大行数（未指定なら推定）
  },
}

---@param config table
---@return table
local function validate(config)
  if type(config.debounce_ms) ~= "number" or config.debounce_ms < 0 then
    vim.notify("Kagami: debounce_ms は 0 以上の数値である必要があります", vim.log.levels.WARN)
    config.debounce_ms = M.defaults.debounce_ms
  end
  if not vim.tbl_contains({ "ansi", "sixel" }, config.mode) then
    vim.notify("Kagami: mode は 'ansi' または 'sixel' である必要があります", vim.log.levels.WARN)
    config.mode = M.defaults.mode
  end
  if type(config.filetypes) ~= "table" then
    vim.notify("Kagami: filetypes はテーブルである必要があります", vim.log.levels.WARN)
    config.filetypes = M.defaults.filetypes
  end
  if type(config.mermaid) ~= "table" then
    vim.notify("Kagami: mermaid はテーブルである必要があります", vim.log.levels.WARN)
    config.mermaid = vim.deepcopy(M.defaults.mermaid)
  end
  if type(config.mermaid.enabled) ~= "boolean" then
    vim.notify("Kagami: mermaid.enabled は boolean である必要があります", vim.log.levels.WARN)
    config.mermaid.enabled = M.defaults.mermaid.enabled
  end
  if config.mermaid.mmdc ~= nil and type(config.mermaid.mmdc) ~= "string" then
    vim.notify("Kagami: mermaid.mmdc は string または nil である必要があります", vim.log.levels.WARN)
    config.mermaid.mmdc = M.defaults.mermaid.mmdc
  end
  if config.mermaid.rows ~= nil and (type(config.mermaid.rows) ~= "number" or config.mermaid.rows < 1) then
    vim.notify("Kagami: mermaid.rows は 1 以上の数値または nil である必要があります", vim.log.levels.WARN)
    config.mermaid.rows = M.defaults.mermaid.rows
  end
  return config
end

function M.merge(opts)
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return validate(merged)
end

return M
