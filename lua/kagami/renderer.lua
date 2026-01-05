local M = {}

local function default_renderer_cmd()
  local files = vim.api.nvim_get_runtime_file("renderer/kagami-render.ts", false)
  if not files or #files == 0 then
    return nil
  end

  local renderer_dir = vim.fn.fnamemodify(files[1], ":h")
  local tsx = renderer_dir .. "/node_modules/.bin/tsx"
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    tsx = tsx .. ".cmd"
  end

  if vim.fn.executable(tsx) == 1 then
    return { tsx, files[1] }
  end

  -- renderer/node_modules が未インストール等で tsx が見つからない場合は nil にして、
  -- プラグイン側で分かりやすくエラー表示させる。
  return nil
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
