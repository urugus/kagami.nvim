-- tests/kagami/config_spec.lua
local helpers = require("tests.helpers")

describe("kagami.config", function()
  local config
  local restore_notify, messages

  before_each(function()
    helpers.unload_kagami()
    config = require("kagami.config")
    restore_notify, messages = helpers.mock_notify()
  end)

  after_each(function()
    restore_notify()
  end)

  describe("defaults", function()
    it("should have expected default values", function()
      assert.equals(60, config.defaults.debounce_ms)
      assert.equals("ansi", config.defaults.mode)
      assert.is_true(config.defaults.follow_scroll)
      assert.is_true(config.defaults.follow_cursor)
    end)

    it("should have filetypes as table", function()
      assert.is_table(config.defaults.filetypes)
      assert.is_true(vim.tbl_contains(config.defaults.filetypes, "markdown"))
    end)

    it("should have mermaid config", function()
      assert.is_table(config.defaults.mermaid)
      assert.is_true(config.defaults.mermaid.enabled)
      assert.is_nil(config.defaults.mermaid.mmdc)
      assert.is_nil(config.defaults.mermaid.rows)
    end)
  end)

  describe("merge", function()
    it("should return defaults when opts is nil", function()
      local result = config.merge(nil)
      assert.equals(config.defaults.debounce_ms, result.debounce_ms)
      assert.equals(config.defaults.mode, result.mode)
      assert.is_true(result.follow_scroll)
      assert.is_true(result.follow_cursor)
    end)

    it("should return defaults when opts is empty", function()
      local result = config.merge({})
      assert.equals(config.defaults.debounce_ms, result.debounce_ms)
      assert.equals(config.defaults.mode, result.mode)
    end)

    it("should merge user options", function()
      local result = config.merge({ debounce_ms = 100 })
      assert.equals(100, result.debounce_ms)
      -- 他はデフォルトのまま
      assert.equals("ansi", result.mode)
    end)

    it("should merge multiple options", function()
      local result = config.merge({
        debounce_ms = 200,
        mode = "sixel",
        follow_scroll = false,
      })
      assert.equals(200, result.debounce_ms)
      assert.equals("sixel", result.mode)
      assert.is_false(result.follow_scroll)
      assert.is_true(result.follow_cursor) -- デフォルト
    end)

    it("should deep merge mermaid options", function()
      local result = config.merge({
        mermaid = { enabled = false },
      })
      assert.is_false(result.mermaid.enabled)
      -- 他のmermaidオプションはデフォルト
      assert.is_nil(result.mermaid.mmdc)
    end)
  end)

  describe("validation", function()
    describe("debounce_ms", function()
      it("should reset negative debounce_ms with warning", function()
        local result = config.merge({ debounce_ms = -1 })
        assert.equals(config.defaults.debounce_ms, result.debounce_ms)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("debounce_ms") ~= nil)
      end)

      it("should reset string debounce_ms with warning", function()
        local result = config.merge({ debounce_ms = "invalid" })
        assert.equals(config.defaults.debounce_ms, result.debounce_ms)
        assert.equals(1, #messages)
      end)

      it("should accept zero debounce_ms", function()
        local result = config.merge({ debounce_ms = 0 })
        assert.equals(0, result.debounce_ms)
        assert.equals(0, #messages)
      end)
    end)

    describe("mode", function()
      it("should reset invalid mode with warning", function()
        local result = config.merge({ mode = "invalid" })
        assert.equals("ansi", result.mode)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("mode") ~= nil)
      end)

      it("should accept sixel mode", function()
        local result = config.merge({ mode = "sixel" })
        assert.equals("sixel", result.mode)
        assert.equals(0, #messages)
      end)
    end)

    describe("filetypes", function()
      it("should reset non-table filetypes with warning", function()
        local result = config.merge({ filetypes = "markdown" })
        assert.same(config.defaults.filetypes, result.filetypes)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("filetypes") ~= nil)
      end)

      it("should accept custom filetypes", function()
        local result = config.merge({ filetypes = { "md", "mdx" } })
        assert.same({ "md", "mdx" }, result.filetypes)
        assert.equals(0, #messages)
      end)
    end)

    describe("mermaid", function()
      it("should reset non-table mermaid with warning", function()
        local result = config.merge({ mermaid = true })
        assert.is_table(result.mermaid)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("mermaid") ~= nil)
      end)

      it("should reset non-boolean mermaid.enabled with warning", function()
        local result = config.merge({ mermaid = { enabled = "yes" } })
        assert.is_true(result.mermaid.enabled)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("mermaid.enabled") ~= nil)
      end)

      it("should reset non-string mermaid.mmdc with warning", function()
        local result = config.merge({ mermaid = { mmdc = 123 } })
        assert.is_nil(result.mermaid.mmdc)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("mermaid.mmdc") ~= nil)
      end)

      it("should accept string mermaid.mmdc", function()
        local result = config.merge({ mermaid = { mmdc = "/usr/bin/mmdc" } })
        assert.equals("/usr/bin/mmdc", result.mermaid.mmdc)
        assert.equals(0, #messages)
      end)

      it("should reset invalid mermaid.rows with warning", function()
        local result = config.merge({ mermaid = { rows = 0 } })
        assert.is_nil(result.mermaid.rows)
        assert.equals(1, #messages)
        assert.is_true(messages[1].msg:match("mermaid.rows") ~= nil)
      end)

      it("should accept valid mermaid.rows", function()
        local result = config.merge({ mermaid = { rows = 10 } })
        assert.equals(10, result.mermaid.rows)
        assert.equals(0, #messages)
      end)
    end)
  end)
end)
