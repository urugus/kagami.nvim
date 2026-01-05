-- tests/kagami/lifecycle_spec.lua
local helpers = require("tests.helpers")

describe("kagami.lifecycle", function()
  local lifecycle
  local cleanup, resources

  before_each(function()
    helpers.unload_kagami()
    lifecycle = require("kagami.lifecycle")
    cleanup, resources = helpers.create_cleanup()
  end)

  after_each(function()
    cleanup()
  end)

  describe("safe_close_win", function()
    it("should not error on nil window", function()
      assert.has_no.errors(function()
        lifecycle.safe_close_win(nil)
      end)
    end)

    it("should not error on invalid window id", function()
      assert.has_no.errors(function()
        lifecycle.safe_close_win(-1)
        lifecycle.safe_close_win(999999)
      end)
    end)

    it("should close valid window", function()
      -- 新しいウィンドウを作成
      vim.cmd("split")
      local win = vim.api.nvim_get_current_win()
      assert.is_true(vim.api.nvim_win_is_valid(win))

      lifecycle.safe_close_win(win)

      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)

    it("should not error when closing already closed window", function()
      vim.cmd("split")
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_close(win, true)

      assert.has_no.errors(function()
        lifecycle.safe_close_win(win)
      end)
    end)
  end)

  describe("cleanup", function()
    it("should not error on nil state", function()
      assert.has_no.errors(function()
        lifecycle.cleanup(nil)
      end)
    end)

    it("should not error on empty state", function()
      assert.has_no.errors(function()
        lifecycle.cleanup({})
      end)
    end)

    it("should stop and close timer if present", function()
      local uv = vim.uv or vim.loop
      local timer = uv.new_timer()
      timer:start(1000, 0, function() end)

      local state = { timer = timer }
      lifecycle.cleanup(state)

      -- timer should be stopped (no way to verify directly, but should not error)
      assert.has_no.errors(function()
        lifecycle.cleanup(state)
      end)
    end)

    it("should delete augroup if present", function()
      local augroup = vim.api.nvim_create_augroup("TestKagamiLifecycle", { clear = true })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        pattern = "*",
        callback = function() end,
      })

      local state = { augroup = augroup }
      lifecycle.cleanup(state)

      -- augroup should be deleted (trying to delete again should be safe)
      assert.has_no.errors(function()
        lifecycle.cleanup(state)
      end)
    end)

    it("should close channel if present", function()
      -- モックチャネル（実際のジョブは起動しない）
      local state = { chan = -1 } -- 無効なチャネル

      assert.has_no.errors(function()
        lifecycle.cleanup(state)
      end)
    end)

    it("should close preview window if present", function()
      vim.cmd("vsplit")
      local win = vim.api.nvim_get_current_win()

      local state = { preview_win = win }
      lifecycle.cleanup(state)

      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)

    it("should handle full state with all resources", function()
      local uv = vim.uv or vim.loop

      -- 全リソースを持つ state を作成
      local timer = uv.new_timer()
      local augroup = vim.api.nvim_create_augroup("TestKagamiFullCleanup", { clear = true })
      vim.cmd("vsplit")
      local win = vim.api.nvim_get_current_win()

      local state = {
        timer = timer,
        augroup = augroup,
        chan = -1,
        preview_win = win,
      }

      assert.has_no.errors(function()
        lifecycle.cleanup(state)
      end)

      -- window が閉じられていることを確認
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)

    it("should be idempotent (can be called multiple times)", function()
      local uv = vim.uv or vim.loop
      local timer = uv.new_timer()
      local augroup = vim.api.nvim_create_augroup("TestKagamiIdempotent", { clear = true })
      vim.cmd("vsplit")
      local win = vim.api.nvim_get_current_win()

      local state = {
        timer = timer,
        augroup = augroup,
        preview_win = win,
      }

      -- 2回呼んでもエラーにならない
      assert.has_no.errors(function()
        lifecycle.cleanup(state)
        lifecycle.cleanup(state)
      end)
    end)
  end)
end)
