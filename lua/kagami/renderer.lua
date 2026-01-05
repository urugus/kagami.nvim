local M = {}

local function default_renderer_cmd()
  local files = vim.api.nvim_get_runtime_file("renderer/kagami-render.ts", false)
  if not files or #files == 0 then
    return nil
  end
  return { "node", "--experimental-strip-types", files[1] }
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

