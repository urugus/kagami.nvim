-- tests/kagami/autocmd_spec.lua
local helpers = require("tests.helpers")

describe("kagami.autocmd", function()
  local autocmd_mod
  local cleanup, resources

  before_each(function()
    helpers.unload_kagami()
    autocmd_mod = require("kagami.autocmd")
    cleanup, resources = helpers.create_cleanup()
  end)

  after_each(function()
    cleanup()
  end)

  describe("attach", function()
    it("should create augroup and attach to state", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function() end)
      table.insert(resources.augroups, state.augroup)

      assert.is_number(state.augroup)
      assert.is_true(state.augroup > 0)
    end)

    it("should create unique augroup per buffer", function()
      local buf1 = helpers.create_temp_buf()
      local buf2 = helpers.create_temp_buf()
      table.insert(resources.bufs, buf1)
      table.insert(resources.bufs, buf2)

      local state1 = {}
      local state2 = {}

      autocmd_mod.attach(state1, buf1, function() end, function() end)
      autocmd_mod.attach(state2, buf2, function() end, function() end)
      table.insert(resources.augroups, state1.augroup)
      table.insert(resources.augroups, state2.augroup)

      assert.not_equals(state1.augroup, state2.augroup)
    end)

    it("should register autocmds in the augroup", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function() end)
      table.insert(resources.augroups, state.augroup)

      -- augroup に autocmd が登録されていることを確認
      local autocmds = vim.api.nvim_get_autocmds({ group = state.augroup })
      assert.is_true(#autocmds > 0)
    end)

    it("should register TextChanged event", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function() end)
      table.insert(resources.augroups, state.augroup)

      local autocmds = vim.api.nvim_get_autocmds({
        group = state.augroup,
        event = "TextChanged",
      })
      assert.equals(1, #autocmds)
    end)

    it("should register VimResized event", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function() end)
      table.insert(resources.augroups, state.augroup)

      local autocmds = vim.api.nvim_get_autocmds({
        group = state.augroup,
        event = "VimResized",
      })
      assert.equals(1, #autocmds)
    end)

    it("should register WinClosed event", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function() end)
      table.insert(resources.augroups, state.augroup)

      local autocmds = vim.api.nvim_get_autocmds({
        group = state.augroup,
        event = "WinClosed",
      })
      assert.equals(1, #autocmds)
    end)

    it("should call on_change callback on TextChanged", function()
      local buf = helpers.create_temp_buf({ "initial" })
      table.insert(resources.bufs, buf)

      -- バッファをウィンドウに表示
      vim.api.nvim_set_current_buf(buf)

      local called = false
      local state = {}

      autocmd_mod.attach(state, buf, function()
        called = true
      end, function() end)
      table.insert(resources.augroups, state.augroup)

      -- TextChanged をトリガー（バッファを編集）
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "modified" })
      vim.cmd("doautocmd TextChanged")

      assert.is_true(called)
    end)

    it("should call cleanup callback on BufWipeout", function()
      local buf = helpers.create_temp_buf()
      -- resources に追加しない（テスト内で削除するため）

      vim.api.nvim_set_current_buf(buf)

      local cleanup_called = false
      local state = {}

      autocmd_mod.attach(state, buf, function() end, function()
        cleanup_called = true
      end)
      -- augroup は buf 削除時に不要になる

      -- BufWipeout をトリガー
      vim.api.nvim_buf_delete(buf, { force = true })

      assert.is_true(cleanup_called)
    end)

    it("should call cleanup callback on WinClosed for preview_win", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)

      -- プレビューウィンドウを作成
      vim.cmd("vsplit")
      local preview_win = vim.api.nvim_get_current_win()

      local cleanup_called = false
      local state = { preview_win = preview_win }

      autocmd_mod.attach(state, buf, function() end, function()
        cleanup_called = true
      end)
      table.insert(resources.augroups, state.augroup)

      -- WinClosed をトリガー
      vim.api.nvim_win_close(preview_win, true)

      assert.is_true(cleanup_called)
    end)

    it("should not call cleanup for unrelated window close", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)

      -- 別のウィンドウを作成
      vim.cmd("split")
      local unrelated_win = vim.api.nvim_get_current_win()

      -- プレビューウィンドウを作成
      vim.cmd("vsplit")
      local preview_win = vim.api.nvim_get_current_win()
      table.insert(resources.wins, preview_win)

      local cleanup_called = false
      local state = { preview_win = preview_win }

      autocmd_mod.attach(state, buf, function() end, function()
        cleanup_called = true
      end)
      table.insert(resources.augroups, state.augroup)

      -- 無関係なウィンドウを閉じる
      vim.api.nvim_win_close(unrelated_win, true)

      assert.is_false(cleanup_called)
    end)

    it("should clear previous autocmds when re-attaching to same buffer", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)

      local state1 = {}
      local state2 = {}

      autocmd_mod.attach(state1, buf, function() end, function() end)
      -- 同じバッファに再度アタッチ
      autocmd_mod.attach(state2, buf, function() end, function() end)

      table.insert(resources.augroups, state2.augroup)

      -- 最初の augroup は同じ名前で作成されるため、クリアされる
      -- 新しい state2.augroup のみが有効
      local autocmds = vim.api.nvim_get_autocmds({ group = state2.augroup })
      assert.is_true(#autocmds > 0)
    end)
  end)
end)
