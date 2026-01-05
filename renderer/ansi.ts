import sliceAnsi from "slice-ansi";
import stringWidth from "string-width";
import stripAnsi from "strip-ansi";

export const clampLine = (line: string, width: number) => {
  if (width <= 0) return "";
  if (stringWidth(line) <= width) return line;
  return sliceAnsi(line, 0, width);
};

export const toPlainText = (text: string) => stripAnsi(text);
