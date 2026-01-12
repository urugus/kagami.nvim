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

This repository includes a pre-built renderer under `renderer/dist/`.

### lazy.nvim

```lua
{
  "urugus/kagami.nvim",
  opts = {},
}
```

### Local development (dir)

1. Load the plugin in Neovim (lazy.nvim example):

   ```lua
   {
     dir = "/path/to/kagami.nvim",
     opts = {},
   }
   ```

2. In a Markdown buffer, run `:KagamiOpen`.

For renderer development (TypeScript), run `cd renderer && npm i` first.

## Commands

- `:KagamiOpen` / `:KagamiClose` / `:KagamiToggle`
- `:KagamiRefresh`

## Configuration

```lua
require("kagami").setup({
  debounce_ms = 60,
  follow_scroll = true,
  follow_cursor = true,
  renderer_cmd = nil, -- when nil, runs the bundled renderer/dist/kagami-render.mjs via node
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

By default, kagami.nvim resolves `renderer/dist/kagami-render.mjs` from your runtimepath
and runs it with `node`. If you want to use a custom renderer command:

```lua
require("kagami").setup({
  renderer_cmd = { "node", "/abs/path/to/kagami-render.mjs" },
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
  - If you set `renderer_cmd`, verify the command/path is correct.
  - If `renderer_cmd = nil`, the plugin must be installed as a full runtime directory
    so that `renderer/dist/kagami-render.mjs` exists on runtimepath.
- The preview opens but stays blank
  - Check `:messages` for errors from the renderer process.
  - Try `:KagamiRefresh`.
- Sixel does not render
  - Use `mode = "ansi"` unless you know your Neovim+terminal environment supports Sixel.

## Uninstall

Remove the plugin from your plugin manager.
