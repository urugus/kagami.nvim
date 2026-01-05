# kagami.nvim

kagami.nvim is a Neovim plugin that previews Markdown in a right-hand split
using an external renderer.

The current MVP includes **ANSI text rendering via Ink** plus **live updates**
and **basic scroll/cursor following** driven from Neovim. A Sixel mode exists as
an extension point in the renderer, but Sixel support depends on your terminal
environment (Neovim `:terminal` may not render it).

## Requirements

- Neovim 0.9+ (0.10+ recommended)
- Node.js (npm included)
- A terminal that can display ANSI output (Sixel is optional / environment-dependent)

## Install

This repository includes a bundled renderer under `renderer/`. You must install
its dependencies for the preview to work.

### lazy.nvim

```lua
{
  "urugus/kagami.nvim",
  -- The renderer is started via Neovim `:terminal`, so install its deps at install time.
  build = "cd renderer && npm i",
  opts = {},
}
```

If you prefer to manage Node/npm yourself, omit `build` and run it manually once:
`cd renderer && npm i`

### Local development (dir)

1. Install renderer dependencies in `renderer/`:

   ```sh
   cd renderer
   npm i
   ```

2. Load the plugin in Neovim (lazy.nvim example):

   ```lua
   {
     dir = "/path/to/kagami.nvim",
     opts = {},
   }
   ```

3. In a Markdown buffer, run `:KagamiOpen`.

## Commands

- `:KagamiOpen` / `:KagamiClose` / `:KagamiToggle`
- `:KagamiRefresh`

## Configuration

```lua
require("kagami").setup({
  debounce_ms = 60,
  follow_scroll = true,
  follow_cursor = true,
  renderer_cmd = nil, -- when nil, runs the bundled renderer/kagami-render.ts via tsx
  mode = "ansi", -- "ansi" | "sixel"
  mermaid = {
    enabled = true, -- sixel mode で ```mermaid を画像化（mmdc が必要）
    mmdc = nil, -- "mmdc" を PATH から探す。必要ならフルパス指定
    rows = nil, -- 図の最大行数（未指定なら推定）
  },
  filetypes = { "markdown", "md", "pandoc" },
})
```

### renderer_cmd examples

By default, kagami.nvim resolves `renderer/kagami-render.ts` from your runtimepath
and runs it with `tsx` from `renderer/node_modules/`. If you want to use a custom renderer command:

```lua
require("kagami").setup({
  renderer_cmd = { "/abs/path/to/renderer/node_modules/.bin/tsx", "/abs/path/to/kagami-render.ts" },
})
```

## How it works (high level)

- `:KagamiOpen` opens a right-hand split and starts the renderer in `:terminal`.
- On edits / cursor move / scroll / resize, the plugin sends JSONL messages to the renderer.

## Help

After generating helptags (e.g. `:helptags ALL`), see `:help kagami`.

## Known limitations

- Neovim `:terminal` (libvterm) may not render Sixel depending on your environment.
- Scroll following approximates **source line -> preview line** at 1:1 (wrapping/lists/etc. can drift).
- Mermaid の画像化は sixel モードのみ。`magick`（ImageMagick）に加えて `mmdc` が必要です。

## Troubleshooting

- `Kagami: renderer_cmd could not be resolved`
  - Ensure you ran `cd renderer && npm i`.
  - If you set `renderer_cmd`, verify the command/path is correct.
  - If `renderer_cmd = nil`, the plugin must be installed as a full runtime directory
    so that `renderer/kagami-render.ts` exists on runtimepath.
- The preview opens but stays blank
  - Check `:messages` for errors from `tsx` or the renderer process.
  - Try `:KagamiRefresh`.
- Sixel does not render
  - Use `mode = "ansi"` unless you know your Neovim+terminal environment supports Sixel.

## Uninstall

Remove the plugin from your plugin manager. If you used the bundled renderer,
you can also delete `renderer/node_modules/` to reclaim disk space.
