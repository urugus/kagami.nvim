import { describe, expect, it } from "vitest";
import { clampLine, toPlainText } from "./ansi.ts";

describe("clampLine", () => {
  it("returns empty string for width <= 0", () => {
    expect(clampLine("hello", 0)).toBe("");
    expect(clampLine("hello", -1)).toBe("");
  });

  it("returns original string if within width", () => {
    expect(clampLine("hello", 10)).toBe("hello");
    expect(clampLine("hello", 5)).toBe("hello");
  });

  it("truncates string exceeding width", () => {
    expect(clampLine("hello world", 5)).toBe("hello");
  });

  it("handles ANSI escape sequences", () => {
    const red = "\x1b[31mhello\x1b[0m";
    const result = clampLine(red, 3);
    expect(toPlainText(result)).toBe("hel");
  });

  it("handles wide characters (CJK)", () => {
    // Each CJK character has width 2
    // slice-ansi includes partial characters rather than truncating
    const cjk = "日本語";
    expect(clampLine(cjk, 4)).toBe("日本");
    expect(clampLine(cjk, 6)).toBe("日本語");
  });
});

describe("toPlainText", () => {
  it("strips ANSI escape sequences", () => {
    expect(toPlainText("\x1b[31mred\x1b[0m")).toBe("red");
    expect(toPlainText("\x1b[1m\x1b[32mbold green\x1b[0m")).toBe("bold green");
  });

  it("returns plain text unchanged", () => {
    expect(toPlainText("hello")).toBe("hello");
  });

  it("handles empty string", () => {
    expect(toPlainText("")).toBe("");
  });
});
