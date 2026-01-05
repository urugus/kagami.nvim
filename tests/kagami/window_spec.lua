-- tests/kagami/window_spec.lua
local helpers = require("tests.helpers")

describe("kagami.window", function()
  local window
  local cleanup, resources

  before_each(function()
    helpers.unload_kagami()
    window = require("kagami.window")
    cleanup, resources = helpers.create_cleanup()
  end)

  after_each(function()
    cleanup()
  end)

  describe("open_preview_split", function()
    it("should return table with win and buf", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.is_table(result)
      assert.is_number(result.win)
      assert.is_number(result.buf)
    end)

    it("should create valid window", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.is_true(vim.api.nvim_win_is_valid(result.win))
    end)

    it("should create valid buffer", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.is_true(vim.api.nvim_buf_is_valid(result.buf))
    end)

    it("should create new window (not reuse current)", function()
      local initial_win = vim.api.nvim_get_current_win()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.not_equals(initial_win, result.win)
    end)

    it("should set buffer options correctly", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.equals("wipe", vim.bo[result.buf].bufhidden)
      assert.is_false(vim.bo[result.buf].swapfile)
    end)

    it("should set window options correctly", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      assert.is_false(vim.wo[result.win].number)
      assert.is_false(vim.wo[result.win].relativenumber)
      assert.equals("no", vim.wo[result.win].signcolumn)
    end)

    it("should set window width to approximately half of columns", function()
      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      local expected_width = math.floor(vim.o.columns / 2)
      local actual_width = vim.api.nvim_win_get_width(result.win)

      -- 幅は厳密に半分でなくても良い（ボーダーなどの影響）
      -- おおよそ半分であることを確認
      assert.is_true(actual_width >= expected_width - 2)
      assert.is_true(actual_width <= expected_width + 2)
    end)

    it("should create window on the right side", function()
      local initial_win = vim.api.nvim_get_current_win()
      local initial_pos = vim.api.nvim_win_get_position(initial_win)

      local result = window.open_preview_split()
      table.insert(resources.wins, result.win)
      table.insert(resources.bufs, result.buf)

      local preview_pos = vim.api.nvim_win_get_position(result.win)

      -- プレビューウィンドウは元のウィンドウより右にある
      assert.is_true(preview_pos[2] >= initial_pos[2])
    end)
  end)
end)
