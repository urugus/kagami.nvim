-- tests/kagami/markdown_spec.lua
local helpers = require("tests.helpers")

describe("kagami.markdown", function()
  local markdown
  local cleanup, resources

  before_each(function()
    helpers.unload_kagami()
    markdown = require("kagami.markdown")
    cleanup, resources = helpers.create_cleanup()
  end)

  after_each(function()
    cleanup()
  end)

  describe("is_markdown_buf", function()
    it("should return true when filetype matches", function()
      local buf = helpers.create_temp_buf(nil, "markdown")
      table.insert(resources.bufs, buf)

      assert.is_true(markdown.is_markdown_buf(buf, { "markdown", "md" }))
    end)

    it("should return true for alternative filetype in list", function()
      local buf = helpers.create_temp_buf(nil, "pandoc")
      table.insert(resources.bufs, buf)

      assert.is_true(markdown.is_markdown_buf(buf, { "markdown", "md", "pandoc" }))
    end)

    it("should return false when filetype does not match", function()
      local buf = helpers.create_temp_buf(nil, "lua")
      table.insert(resources.bufs, buf)

      assert.is_false(markdown.is_markdown_buf(buf, { "markdown", "md" }))
    end)

    it("should return false for empty filetypes list", function()
      local buf = helpers.create_temp_buf(nil, "markdown")
      table.insert(resources.bufs, buf)

      assert.is_false(markdown.is_markdown_buf(buf, {}))
    end)

    it("should return false when filetypes is nil", function()
      local buf = helpers.create_temp_buf(nil, "markdown")
      table.insert(resources.bufs, buf)

      assert.is_false(markdown.is_markdown_buf(buf, nil))
    end)

    it("should return false for buffer with no filetype", function()
      local buf = helpers.create_temp_buf(nil, nil)
      table.insert(resources.bufs, buf)

      assert.is_false(markdown.is_markdown_buf(buf, { "markdown" }))
    end)

    it("should be case-sensitive", function()
      local buf = helpers.create_temp_buf(nil, "Markdown")
      table.insert(resources.bufs, buf)

      assert.is_false(markdown.is_markdown_buf(buf, { "markdown" }))
    end)
  end)
end)
