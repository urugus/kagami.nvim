# renderer

Neovim プラグイン `kagami.nvim` から起動される、Ink ベースのレンダラです。

## セットアップ

```sh
npm i
```

## 手動起動（デバッグ）

```sh
npx tsx kagami-render.ts
```

stdin に JSONL を流すと更新します。

## Mermaid（sixel）

sixel モード時は、プレビュー中の ```mermaid フェンスブロックを画像化して表示できます。

- 必要: `magick`（ImageMagick）と `mmdc`（Mermaid CLI）
- `mmdc` は `$PATH` か `renderer/node_modules/.bin/mmdc` を探します（`KAGAMI_MMDC` で上書き可）
- 無効化: `KAGAMI_MERMAID=0`
