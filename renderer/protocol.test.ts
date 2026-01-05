import { describe, expect, it } from "vitest";
import { coerceState, defaultState, isRenderMsg } from "./protocol.ts";

describe("isRenderMsg", () => {
  it("returns true for valid render message", () => {
    expect(isRenderMsg({ type: "render" })).toBe(true);
    expect(isRenderMsg({ type: "render", markdown: "# Hello" })).toBe(true);
  });

  it("returns false for invalid messages", () => {
    expect(isRenderMsg(null)).toBe(false);
    expect(isRenderMsg(undefined)).toBe(false);
    expect(isRenderMsg({})).toBe(false);
    expect(isRenderMsg({ type: "other" })).toBe(false);
    expect(isRenderMsg("render")).toBe(false);
    expect(isRenderMsg(123)).toBe(false);
  });
});

describe("coerceState", () => {
  it("returns default values for empty message", () => {
    const state = coerceState({ type: "render" });
    expect(state.markdown).toBe("");
    expect(state.viewport).toEqual({ width: 80, height: 24 });
    expect(state.scroll).toEqual({ topline: 1 });
    expect(state.cursor).toEqual({ line: 1, col: 0 });
    expect(state.options).toEqual({ follow_cursor: true, follow_scroll: true });
  });

  it("coerces provided values", () => {
    const state = coerceState({
      type: "render",
      markdown: "# Test",
      viewport: { width: 120, height: 40 },
      scroll: { topline: 10 },
      cursor: { line: 5, col: 3 },
      options: { follow_cursor: false, follow_scroll: false },
    });
    expect(state.markdown).toBe("# Test");
    expect(state.viewport).toEqual({ width: 120, height: 40 });
    expect(state.scroll).toEqual({ topline: 10 });
    expect(state.cursor).toEqual({ line: 5, col: 3 });
    expect(state.options).toEqual({ follow_cursor: false, follow_scroll: false });
  });

  it("handles partial viewport", () => {
    const state = coerceState({
      type: "render",
      viewport: { width: 100 },
    });
    expect(state.viewport).toEqual({ width: 100, height: 24 });
  });
});

describe("defaultState", () => {
  it("has expected default values", () => {
    expect(defaultState.markdown).toBe("");
    expect(defaultState.viewport.width).toBe(80);
    expect(defaultState.viewport.height).toBe(24);
  });
});
