-- tests/kagami/kagami_spec.lua
local helpers = require("tests.helpers")

describe("kagami", function()
  local kagami
  local cleanup, resources
  local restore_notify, messages

  before_each(function()
    helpers.unload_kagami()
    kagami = require("kagami")
    cleanup, resources = helpers.create_cleanup()
    restore_notify, messages = helpers.mock_notify()
  end)

  after_each(function()
    -- kagami の状態をクリーンアップ
    if kagami._state then
      kagami.close()
    end
    cleanup()
    restore_notify()
  end)

  describe("initial state", function()
    it("should have nil state", function()
      assert.is_nil(kagami._state)
    end)

    it("should have default config", function()
      assert.is_table(kagami._config)
      assert.equals(60, kagami._config.debounce_ms)
      assert.equals("ansi", kagami._config.mode)
    end)
  end)

  describe("setup", function()
    it("should apply custom config", function()
      kagami.setup({ debounce_ms = 200 })

      assert.equals(200, kagami._config.debounce_ms)
    end)

    it("should merge with defaults", function()
      kagami.setup({ mode = "sixel" })

      assert.equals("sixel", kagami._config.mode)
      assert.equals(60, kagami._config.debounce_ms) -- デフォルト維持
    end)

    it("should validate and reset invalid values", function()
      kagami.setup({ debounce_ms = -1 })

      assert.equals(60, kagami._config.debounce_ms) -- デフォルトにリセット
      assert.equals(1, #messages) -- 警告が出力された
    end)

    it("should accept empty opts", function()
      kagami.setup({})

      assert.equals(60, kagami._config.debounce_ms)
    end)

    it("should accept nil opts", function()
      kagami.setup(nil)

      assert.equals(60, kagami._config.debounce_ms)
    end)
  end)

  describe("open", function()
    it("should warn when not markdown buffer", function()
      local buf = helpers.create_temp_buf({ "# Hello" }, "lua")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      -- renderer が見つからない場合は open が失敗するが、警告は出る
      kagami.open()

      local found_warning = false
      for _, msg in ipairs(messages) do
        if msg.msg:match("markdown 以外") then
          found_warning = true
          break
        end
      end
      assert.is_true(found_warning)
    end)

    it("should error when renderer_cmd not resolved", function()
      -- renderer_cmd を無効な値に設定
      kagami.setup({ renderer_cmd = nil })

      -- runtimepath から renderer を見つけられない環境をシミュレート
      local original = vim.api.nvim_get_runtime_file
      vim.api.nvim_get_runtime_file = function()
        return {}
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.open()

      vim.api.nvim_get_runtime_file = original

      local found_error = false
      for _, msg in ipairs(messages) do
        if msg.msg:match("renderer_cmd") and msg.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      assert.is_true(found_error)
      assert.is_nil(kagami._state)
    end)

    it("should not open twice", function()
      -- termopen をモックして実際のプロセスを起動しない
      local original_termopen = vim.fn.termopen
      local termopen_count = 0
      vim.fn.termopen = function()
        termopen_count = termopen_count + 1
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })

      kagami.open()
      kagami.open() -- 2回目

      vim.fn.termopen = original_termopen

      -- 1回しか呼ばれていない
      assert.equals(1, termopen_count)
    end)

    it("should set state when opened successfully", function()
      local original_termopen = vim.fn.termopen
      vim.fn.termopen = function()
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })
      kagami.open()

      vim.fn.termopen = original_termopen

      assert.is_table(kagami._state)
      assert.equals(buf, kagami._state.source_buf)
      assert.is_number(kagami._state.preview_win)
      assert.is_number(kagami._state.chan)
    end)
  end)

  describe("close", function()
    it("should do nothing when not opened", function()
      assert.has_no.errors(function()
        kagami.close()
      end)
      assert.is_nil(kagami._state)
    end)

    it("should clear state when closed", function()
      local original_termopen = vim.fn.termopen
      vim.fn.termopen = function()
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })
      kagami.open()
      kagami.close()

      vim.fn.termopen = original_termopen

      assert.is_nil(kagami._state)
    end)

    it("should close preview window", function()
      local original_termopen = vim.fn.termopen
      vim.fn.termopen = function()
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })
      kagami.open()

      local preview_win = kagami._state.preview_win
      kagami.close()

      vim.fn.termopen = original_termopen

      assert.is_false(vim.api.nvim_win_is_valid(preview_win))
    end)
  end)

  describe("toggle", function()
    it("should open when closed", function()
      local original_termopen = vim.fn.termopen
      vim.fn.termopen = function()
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })
      kagami.toggle()

      vim.fn.termopen = original_termopen

      assert.is_table(kagami._state)
    end)

    it("should close when opened", function()
      local original_termopen = vim.fn.termopen
      vim.fn.termopen = function()
        return 1
      end

      local buf = helpers.create_temp_buf({ "# Hello" }, "markdown")
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      kagami.setup({ renderer_cmd = { "echo" } })
      kagami.toggle() -- open
      kagami.toggle() -- close

      vim.fn.termopen = original_termopen

      assert.is_nil(kagami._state)
    end)
  end)

  describe("refresh", function()
    it("should do nothing when not opened", function()
      assert.has_no.errors(function()
        kagami.refresh()
      end)
    end)

    -- refresh の詳細な動作は sync_spec.lua でテスト済み
  end)
end)
