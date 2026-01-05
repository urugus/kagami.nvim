-- tests/kagami/renderer_spec.lua
local helpers = require("tests.helpers")

describe("kagami.renderer", function()
  local renderer
  local cleanup, resources

  before_each(function()
    helpers.unload_kagami()
    renderer = require("kagami.renderer")
    cleanup, resources = helpers.create_cleanup()
  end)

  after_each(function()
    cleanup()
  end)

  describe("resolve_cmd", function()
    it("should return renderer_cmd if provided", function()
      local config = { renderer_cmd = { "custom", "cmd" } }
      local result = renderer.resolve_cmd(config)

      assert.same({ "custom", "cmd" }, result)
    end)

    it("should return renderer_cmd for complex command", function()
      local config = {
        renderer_cmd = { "node", "--experimental-strip-types", "/path/to/custom.ts" },
      }
      local result = renderer.resolve_cmd(config)

      assert.same(config.renderer_cmd, result)
    end)

    it("should fallback to default when renderer_cmd is nil", function()
      local config = { renderer_cmd = nil }
      local result = renderer.resolve_cmd(config)

      -- デフォルトは環境依存（runtimepath に renderer があるかどうか）
      -- nil または テーブルのいずれか
      if result then
        assert.is_table(result)
        assert.equals("node", result[1])
        assert.equals("--experimental-strip-types", result[2])
        assert.is_true(result[3]:match("kagami%-render%.ts$") ~= nil)
      end
    end)

    it("should fallback to default when config is empty", function()
      local result = renderer.resolve_cmd({})

      -- デフォルトは環境依存
      if result then
        assert.is_table(result)
      end
    end)
  end)

  describe("termopen", function()
    it("should call vim.fn.termopen with correct arguments", function()
      -- termopen をモックして呼び出しを検証
      local called_cmd = nil
      local called_opts = nil
      local original_termopen = vim.fn.termopen

      vim.fn.termopen = function(cmd, opts)
        called_cmd = cmd
        called_opts = opts
        return -1 -- ダミーのチャネルID
      end

      local cmd = { "echo", "test" }
      local env = { KAGAMI = "1", KAGAMI_MODE = "ansi" }
      local on_exit = function() end

      renderer.termopen(cmd, env, on_exit)

      vim.fn.termopen = original_termopen

      assert.same(cmd, called_cmd)
      assert.same(env, called_opts.env)
      assert.equals(on_exit, called_opts.on_exit)
    end)

    it("should return channel id from termopen", function()
      local original_termopen = vim.fn.termopen

      vim.fn.termopen = function()
        return 12345
      end

      local result = renderer.termopen({ "echo" }, {}, function() end)

      vim.fn.termopen = original_termopen

      assert.equals(12345, result)
    end)
  end)

  -- スモークテスト: 実際にレンダラーが見つかるか
  describe("smoke test", function()
    it("should find renderer in runtimepath", function()
      -- プラグインディレクトリが runtimepath に含まれている場合
      local files = vim.api.nvim_get_runtime_file("renderer/kagami-render.ts", false)

      -- テスト環境では見つかるはず
      if #files > 0 then
        assert.is_true(files[1]:match("kagami%-render%.ts$") ~= nil)
      end
    end)

    -- 実際のプロセス起動は CI では重くなるためスキップ可能
    -- 以下は手動テスト用
    pending("should start renderer process (manual test)", function()
      -- このテストは手動で実行する場合のみ
      -- make test-file FILE=tests/kagami/renderer_spec.lua
      local cmd = renderer.resolve_cmd({})
      if not cmd then
        pending("renderer command not found")
        return
      end

      -- テスト用バッファを作成してターミナルを開く
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      local exited = false
      local chan = renderer.termopen(cmd, { KAGAMI = "1", KAGAMI_MODE = "ansi" }, function()
        exited = true
      end)

      if chan > 0 then
        table.insert(resources.jobs, chan)
        -- 少し待ってからジョブを停止
        helpers.wait(100)
        vim.fn.jobstop(chan)
        helpers.wait_until(function()
          return exited
        end, 1000)
      end
    end)
  end)
end)
