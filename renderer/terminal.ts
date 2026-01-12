import stripAnsi from "strip-ansi";

const isPlain = process.env.KAGAMI_PLAIN === "1";
export const FRAME_END_MARKER = "\x00KAGAMI_FRAME_END\x00";

export const clearScreen = () => {
  if (isPlain) return;
  process.stdout.write("\x1b[2J\x1b[H");
};

export const printLines = (lines: string[]) => {
  const output = isPlain ? lines.map((l) => stripAnsi(l)) : lines;
  process.stdout.write(output.join("\n"));
  if (output.length === 0 || output[output.length - 1] !== "") {
    process.stdout.write("\n");
  }
};

export const printFrameEnd = () => {
  if (isPlain) {
    process.stdout.write(`${FRAME_END_MARKER}\n`);
  }
};
