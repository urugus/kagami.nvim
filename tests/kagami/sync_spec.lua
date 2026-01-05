-- tests/kagami/sync_spec.lua
local helpers = require("tests.helpers")

describe("kagami.sync", function()
  local sync
  local cleanup, resources
  local restore_notify, messages

  before_each(function()
    helpers.unload_kagami()
    sync = require("kagami.sync")
    cleanup, resources = helpers.create_cleanup()
    restore_notify, messages = helpers.mock_notify()
  end)

  after_each(function()
    cleanup()
    restore_notify()
  end)

  describe("send", function()
    it("should return false when chan is nil", function()
      assert.is_false(sync.send(nil, { type = "test" }))
    end)

    it("should return false when JSON encode fails", function()
      -- 循環参照を持つテーブルはエンコードできない
      local circular = {}
      circular.self = circular

      assert.is_false(sync.send(1, circular))
    end)

    it("should return false when channel is invalid", function()
      -- 無効なチャネルへの送信
      assert.is_false(sync.send(-999, { type = "test" }))
    end)
  end)

  describe("get_view", function()
    it("should return nil for nil window", function()
      assert.is_nil(sync.get_view(nil))
    end)

    it("should return nil for invalid window", function()
      assert.is_nil(sync.get_view(-1))
      assert.is_nil(sync.get_view(999999))
    end)

    it("should return view for current window", function()
      local win = vim.api.nvim_get_current_win()
      local view = sync.get_view(win)

      assert.is_table(view)
      assert.is_number(view.topline)
      assert.is_number(view.lnum)
      assert.is_number(view.col)
    end)

    it("should return correct topline value", function()
      local buf = helpers.create_temp_buf({ "line1", "line2", "line3", "line4", "line5" })
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)

      local win = vim.api.nvim_get_current_win()
      local view = sync.get_view(win)

      assert.equals(1, view.topline)
    end)

    it("should return correct cursor position", function()
      local buf = helpers.create_temp_buf({ "hello world" })
      table.insert(resources.bufs, buf)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_win_set_cursor(0, { 1, 5 })

      local win = vim.api.nvim_get_current_win()
      local view = sync.get_view(win)

      assert.equals(1, view.lnum)
      assert.equals(5, view.col)
    end)
  end)

  describe("render_now", function()
    local function create_mock_state()
      local buf = helpers.create_temp_buf({ "# Hello", "", "World" }, "markdown")
      table.insert(resources.bufs, buf)

      vim.cmd("vsplit")
      local source_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_buf(buf)

      vim.cmd("vsplit")
      local preview_win = vim.api.nvim_get_current_win()
      table.insert(resources.wins, preview_win)

      -- ソースウィンドウに戻る
      vim.api.nvim_set_current_win(source_win)

      return {
        source_buf = buf,
        source_win = source_win,
        preview_win = preview_win,
        chan = nil, -- 実際の送信はしない
      }
    end

    it("should do nothing when state is nil", function()
      local cleanup_called = false
      assert.has_no.errors(function()
        sync.render_now(nil, {}, function()
          cleanup_called = true
        end)
      end)
      assert.is_false(cleanup_called)
    end)

    it("should call cleanup when source_buf is invalid", function()
      local cleanup_called = false
      local state = { source_buf = -1 }

      sync.render_now(state, {}, function()
        cleanup_called = true
      end)

      assert.is_true(cleanup_called)
    end)

    it("should call cleanup when preview_win is invalid", function()
      local buf = helpers.create_temp_buf()
      table.insert(resources.bufs, buf)

      local cleanup_called = false
      local state = {
        source_buf = buf,
        preview_win = -1,
      }

      sync.render_now(state, {}, function()
        cleanup_called = true
      end)

      assert.is_true(cleanup_called)
    end)

    it("should cache markdown and skip if unchanged", function()
      local state = create_mock_state()
      local config = { follow_cursor = true, follow_scroll = true }

      -- 初回レンダリング
      sync.render_now(state, config, function() end)

      -- キャッシュが設定されている
      assert.is_not_nil(state.last_markdown)
      assert.is_not_nil(state.last_view)
      assert.is_not_nil(state.last_width)
      assert.is_not_nil(state.last_height)
    end)

    it("should update cache on markdown change", function()
      local state = create_mock_state()
      local config = { follow_cursor = true, follow_scroll = true }

      -- 初回レンダリング
      sync.render_now(state, config, function() end)
      local first_markdown = state.last_markdown

      -- バッファを変更
      vim.api.nvim_buf_set_lines(state.source_buf, 0, -1, false, { "# Changed" })

      -- 再レンダリング
      sync.render_now(state, config, function() end)

      assert.not_equals(first_markdown, state.last_markdown)
      assert.equals("# Changed", state.last_markdown)
    end)

    it("should update cache on cursor move", function()
      local state = create_mock_state()
      local config = { follow_cursor = true, follow_scroll = true }

      -- 初回レンダリング
      sync.render_now(state, config, function() end)
      local first_lnum = state.last_view.lnum

      -- カーソル移動
      vim.api.nvim_win_set_cursor(state.source_win, { 3, 0 })

      -- 再レンダリング
      sync.render_now(state, config, function() end)

      assert.not_equals(first_lnum, state.last_view.lnum)
    end)
  end)

  describe("schedule_render", function()
    it("should do nothing when state is nil", function()
      assert.has_no.errors(function()
        sync.schedule_render(nil, {}, vim.uv or vim.loop, function() end)
      end)
    end)

    it("should do nothing when timer is nil", function()
      assert.has_no.errors(function()
        sync.schedule_render({}, {}, vim.uv or vim.loop, function() end)
      end)
    end)

    it("should start timer with debounce_ms", function()
      local uv = vim.uv or vim.loop
      local timer = uv.new_timer()
      table.insert(resources.timers, timer)

      local render_called = false
      local state = { timer = timer }
      local config = { debounce_ms = 10 }

      sync.schedule_render(state, config, uv, function()
        render_called = true
      end)

      -- タイマーが起動するまで待機
      helpers.wait_until(function()
        return render_called
      end, 100)

      assert.is_true(render_called)
    end)

    it("should debounce multiple calls", function()
      local uv = vim.uv or vim.loop
      local timer = uv.new_timer()
      table.insert(resources.timers, timer)

      local render_count = 0
      local state = { timer = timer }
      local config = { debounce_ms = 50 }

      local render_fn = function()
        render_count = render_count + 1
      end

      -- 複数回連続で呼び出し
      sync.schedule_render(state, config, uv, render_fn)
      helpers.wait(10)
      sync.schedule_render(state, config, uv, render_fn)
      helpers.wait(10)
      sync.schedule_render(state, config, uv, render_fn)

      -- デバウンス待機
      helpers.wait_until(function()
        return render_count > 0
      end, 200)

      -- デバウンスにより1回のみ呼ばれる
      assert.equals(1, render_count)
    end)

    it("should call render after debounce delay", function()
      local uv = vim.uv or vim.loop
      local timer = uv.new_timer()
      table.insert(resources.timers, timer)

      local render_called = false
      local state = { timer = timer }
      local config = { debounce_ms = 30 }

      sync.schedule_render(state, config, uv, function()
        render_called = true
      end)

      -- まだ呼ばれていない
      helpers.wait(10)
      assert.is_false(render_called)

      -- デバウンス後に呼ばれる
      helpers.wait_until(function()
        return render_called
      end, 100)
      assert.is_true(render_called)
    end)
  end)
end)
