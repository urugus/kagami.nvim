export type RenderMsg = {
  type: "render";
  markdown?: string;
  cursor?: { line?: number; col?: number };
  scroll?: { topline?: number };
  viewport?: { width?: number; height?: number };
  options?: { follow_cursor?: boolean; follow_scroll?: boolean };
};

export type State = {
  markdown: string;
  viewport: { width: number; height: number };
  scroll: { topline: number };
  cursor: { line: number; col: number };
  options: { follow_cursor: boolean; follow_scroll: boolean };
};

export const defaultState: State = {
  markdown: "",
  viewport: { width: 80, height: 24 },
  scroll: { topline: 1 },
  cursor: { line: 1, col: 0 },
  options: { follow_cursor: true, follow_scroll: true },
};

export const isRenderMsg = (msg: unknown): msg is RenderMsg =>
  typeof msg === "object" && msg !== null && (msg as { type?: unknown }).type === "render";

export const coerceState = (msg: RenderMsg): State => ({
  markdown: String(msg.markdown ?? ""),
  viewport: {
    width: Number(msg.viewport?.width ?? 80),
    height: Number(msg.viewport?.height ?? 24),
  },
  scroll: { topline: Number(msg.scroll?.topline ?? 1) },
  cursor: { line: Number(msg.cursor?.line ?? 1), col: Number(msg.cursor?.col ?? 0) },
  options: {
    follow_cursor: Boolean(msg.options?.follow_cursor ?? true),
    follow_scroll: Boolean(msg.options?.follow_scroll ?? true),
  },
});
