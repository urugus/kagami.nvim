# Repository Guidelines

## Project Structure & Module Organization

- `lua/`: Neovim plugin runtime code.
  - `lua/kagami.lua`: Public API (`setup/open/close/toggle/refresh`).
  - `lua/kagami/*.lua`: Internal modules (autocmd, renderer launch, sync, window, lifecycle).
- `plugin/`: User commands registered at startup (e.g. `:KagamiOpen`).
- `renderer/`: External renderer (TypeScript + Ink) that receives JSONL over stdin and draws to stdout.

## Build, Test, and Development Commands

Renderer setup and checks (requires Node.js):

- `cd renderer && npm i`: Install renderer dependencies (Ink, Biome, types).
- `cd renderer && npm run check`: Run Biome lint + format checks.
- `cd renderer && npm run format`: Auto-format TS sources with Biome.
- `node --experimental-strip-types renderer/kagami-render.ts`: Run the renderer directly (reads JSONL from stdin).

Manual Neovim smoke test (no user config):

- `nvim -u NONE -i NONE --cmd 'set rtp+=/path/to/kagami.nvim'`: Load plugin from a local path.

## Coding Style & Naming Conventions

- Lua: keep modules small and single-responsibility; prefer `snake_case` for locals and `M.method` for exports.
- TypeScript (`renderer/`): Biome is the source of truth; use 2-space indentation, double quotes, and semicolons.
- Renderer TS policy: do not use the `function` keyword; use arrow functions only.

## Testing Guidelines

There is no automated test suite yet. Keep changes verifiable with:

- Neovim: open a Markdown buffer and run `:KagamiOpen`, then edit and scroll to confirm live updates.
- Renderer: run it standalone and pipe a single JSON line to validate parsing and output.

## Commit & Pull Request Guidelines

This repo may not have Git history in some environments. If contributing via PR:

- Prefer Conventional Commits (e.g. `feat: add sixel block rendering`, `fix: handle resize event`).
- Include a short description, reproduction steps, and (if UI-related) a terminal recording/screenshot.

## Security & Configuration Tips

- Sixel mode depends on terminal support and `magick` (ImageMagick). Keep renderer failures non-fatal and surface clear errors.
- Avoid executing untrusted Markdown as code; renderer should treat input as text only.
