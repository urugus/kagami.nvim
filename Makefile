.PHONY: test test-file lint format

TESTS_INIT = tests/minimal_init.lua
TESTS_DIR = tests/kagami

# 全テスト実行
test:
	@NVIM_LISTEN_ADDRESS= nvim --headless --noplugin -u $(TESTS_INIT) \
		-c "PlenaryBustedDirectory $(TESTS_DIR) {minimal_init = '$(TESTS_INIT)', sequential = true}"

# 単一ファイルのテスト実行 (例: make test-file FILE=tests/kagami/config_spec.lua)
test-file:
	@nvim --headless --noplugin -u $(TESTS_INIT) \
		-c "PlenaryBustedFile $(FILE)"

# renderer の lint
lint:
	cd renderer && npm run check

# renderer の format
format:
	cd renderer && npm run format
