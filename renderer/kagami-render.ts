import { clampLine, toPlainText } from "./ansi.ts";
import { createInk } from "./ink.tsx";
import { renderSixelFromMermaid } from "./mermaid.ts";
import { type State, coerceState, defaultState, isRenderMsg } from "./protocol.ts";
import { renderSixelFromText } from "./sixel.ts";
import { clearScreen, printLines } from "./terminal.ts";

let state: State = defaultState;

const stdin = process.stdin;
const { stdout, ink, rerender } = createInk();

const getScrollTop = (height: number) => {
  let scrollTop = Math.max(0, (state.scroll?.topline || 1) - 1);
  if (!state.options?.follow_scroll) scrollTop = 0;

  if (state.options?.follow_cursor) {
    const cursorLine = Math.max(1, state.cursor?.line || 1) - 1;
    if (cursorLine < scrollTop) {
      scrollTop = Math.max(0, cursorLine - Math.floor(height / 3));
    } else if (cursorLine >= scrollTop + height) {
      scrollTop = Math.max(0, cursorLine - Math.floor((height * 2) / 3));
    }
  }
  return scrollTop;
};

const draw = async () => {
  const { width, height } = state.viewport;
  stdout.columns = Math.max(10, width);
  stdout.rows = Math.max(10000, height + 100);

  rerender(state.markdown);

  // Ink が lastFrame を更新するのを待つ
  await Promise.resolve();
  await Promise.resolve();

  // @ts-expect-error lastFrame exists but is not in type definition
  const frame = (ink.lastFrame() as string) || "";
  const frameLines = frame.split("\n");
  const scrollTop = getScrollTop(height);

  const visible: string[] = [];
  for (let i = 0; i < height; i++) {
    const src = frameLines[scrollTop + i] ?? "";
    visible.push(clampLine(src, width));
  }

  const plainVisible = toPlainText(visible.join("\n"));
  const mode = (process.env.KAGAMI_MODE || "ansi").toLowerCase();
  if (mode === "sixel") {
    const mermaidEnabled = String(process.env.KAGAMI_MERMAID ?? "1").toLowerCase() !== "0";
    const blocksEnabled =
      String(process.env.KAGAMI_SIXEL_BLOCKS || "").toLowerCase() === "1" || mermaidEnabled;
    clearScreen();

    if (blocksEnabled) {
      const blocks = plainVisible.split(/\n{2,}/g);
      for (const block of blocks) {
        const trimmed = block.trim();
        if (!trimmed) continue;

        const blockLines = trimmed.split("\n");
        const first = (blockLines[0] || "").trim().toLowerCase();
        const last = (blockLines[blockLines.length - 1] || "").trim();
        const isMermaidFence =
          mermaidEnabled && first === "```mermaid" && last === "```" && blockLines.length >= 3;

        if (isMermaidFence) {
          const code = blockLines.slice(1, -1).join("\n").trim();
          const { sixel, error } = await renderSixelFromMermaid(code, width, height);
          if (sixel) {
            process.stdout.write(sixel);
          } else {
            const fallback = await renderSixelFromText(
              `(mermaid render failed)\n${error || "unknown error"}`,
              width,
              3
            );
            process.stdout.write(fallback || "");
          }
        } else {
          const sixel = await renderSixelFromText(trimmed, width, Math.max(1, blockLines.length));
          process.stdout.write(sixel || "");
        }
        process.stdout.write("\n");
      }
    } else {
      const sixel = await renderSixelFromText(plainVisible, width, height);
      process.stdout.write(sixel || "");
    }
    return;
  }

  clearScreen();
  printLines(visible);
};

let pending = "";

const scheduleDraw = async () => {
  try {
    await draw();
  } catch (e) {
    clearScreen();
    process.stdout.write(`${String(e instanceof Error ? e.stack || e.message : e)}\n`);
  }
};

stdin.setEncoding("utf8");
stdin.on("data", (chunk) => {
  pending += chunk;
  while (true) {
    const idx = pending.indexOf("\n");
    if (idx === -1) break;
    const line = pending.slice(0, idx);
    pending = pending.slice(idx + 1);

    if (!line.trim()) continue;
    let msg: unknown = null;
    try {
      msg = JSON.parse(line);
    } catch {
      msg = null;
    }
    if (isRenderMsg(msg)) {
      state = coerceState(msg);
      void scheduleDraw();
    }
  }
});

stdin.on("end", () => {
  ink.unmount();
});

void scheduleDraw();
