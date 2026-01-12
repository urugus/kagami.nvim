local M = {}

local function default_renderer_cmd()
  -- ビルド済みの dist/kagami-render.mjs を探す
  local files = vim.api.nvim_get_runtime_file("renderer/dist/kagami-render.mjs", false)
  if not files or #files == 0 then
    return nil
  end

  return { "node", files[1] }
end

function M.resolve_cmd(config)
  return config.renderer_cmd or default_renderer_cmd()
end

function M.termopen(cmd, env, on_exit)
  return vim.fn.termopen(cmd, {
    env = env,
    on_exit = on_exit,
  })
end

return M
