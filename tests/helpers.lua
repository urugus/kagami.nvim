-- tests/helpers.lua
-- テスト用共通ユーティリティ

local M = {}

---一時バッファを作成
---@param content? string[] バッファに設定する行
---@param filetype? string ファイルタイプ
---@return number bufnr
function M.create_temp_buf(content, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  if content then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  end
  if filetype then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

---バッファを安全に削除
---@param bufnr number
function M.delete_buf(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

---ウィンドウを安全に閉じる
---@param winid number
function M.close_win(winid)
  if winid and vim.api.nvim_win_is_valid(winid) then
    pcall(vim.api.nvim_win_close, winid, true)
  end
end

---augroup を安全に削除
---@param augroup number|string
function M.delete_augroup(augroup)
  if augroup then
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
  end
end

---タイマーを安全に停止・クローズ
---@param timer userdata
function M.close_timer(timer)
  if timer then
    pcall(function()
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end)
  end
end

---ジョブ/チャネルを安全に停止
---@param chan number
function M.stop_job(chan)
  if chan then
    pcall(vim.fn.jobstop, chan)
  end
end

---条件が真になるまで待機
---@param condition function 条件関数
---@param timeout_ms? number タイムアウト（デフォルト: 1000ms）
---@param interval_ms? number チェック間隔（デフォルト: 10ms）
---@return boolean 条件が満たされたか
function M.wait_until(condition, timeout_ms, interval_ms)
  timeout_ms = timeout_ms or 1000
  interval_ms = interval_ms or 10
  return vim.wait(timeout_ms, condition, interval_ms)
end

---指定時間待機（イベントループを回す）
---@param ms number
function M.wait(ms)
  vim.wait(ms, function()
    return false
  end, 10)
end

---モジュールをアンロード（再読み込み用）
---@param module_name string
function M.unload_module(module_name)
  package.loaded[module_name] = nil
  -- サブモジュールもアンロード
  for name, _ in pairs(package.loaded) do
    if name:match("^" .. module_name:gsub("%.", "%%.") .. "%.") then
      package.loaded[name] = nil
    end
  end
end

---kagami 関連モジュールを全てアンロード
function M.unload_kagami()
  M.unload_module("kagami")
end

---テスト用のクリーンアップ関数を生成
---@return function cleanup, table resources
function M.create_cleanup()
  local resources = {
    bufs = {},
    wins = {},
    augroups = {},
    timers = {},
    jobs = {},
  }

  local function cleanup()
    for _, buf in ipairs(resources.bufs) do
      M.delete_buf(buf)
    end
    for _, win in ipairs(resources.wins) do
      M.close_win(win)
    end
    for _, augroup in ipairs(resources.augroups) do
      M.delete_augroup(augroup)
    end
    for _, timer in ipairs(resources.timers) do
      M.close_timer(timer)
    end
    for _, job in ipairs(resources.jobs) do
      M.stop_job(job)
    end
    -- リセット
    resources.bufs = {}
    resources.wins = {}
    resources.augroups = {}
    resources.timers = {}
    resources.jobs = {}
  end

  return cleanup, resources
end

---vim.notify をキャプチャするモック
---@return function restore, table messages
function M.mock_notify()
  local messages = {}
  local original_notify = vim.notify

  vim.notify = function(msg, level, opts)
    table.insert(messages, {
      msg = msg,
      level = level,
      opts = opts,
    })
  end

  local function restore()
    vim.notify = original_notify
  end

  return restore, messages
end

---vim.fn.jobstart をモックする
---@param mock_fn function モック関数
---@return function restore
function M.mock_jobstart(mock_fn)
  local original = vim.fn.jobstart
  vim.fn.jobstart = mock_fn

  return function()
    vim.fn.jobstart = original
  end
end

return M
