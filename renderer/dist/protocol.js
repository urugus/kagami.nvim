export const defaultState = {
    markdown: "",
    viewport: { width: 80, height: 24 },
    scroll: { topline: 1 },
    cursor: { line: 1, col: 0 },
    options: { follow_cursor: true, follow_scroll: true },
};
export const isRenderMsg = (msg) => typeof msg === "object" && msg !== null && msg.type === "render";
export const coerceState = (msg) => ({
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
