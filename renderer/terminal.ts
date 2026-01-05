export const clearScreen = () => {
  process.stdout.write("\x1b[2J\x1b[H");
};

export const printLines = (lines: string[]) => {
  process.stdout.write(lines.join("\n"));
  if (lines.length === 0 || lines[lines.length - 1] !== "") {
    process.stdout.write("\n");
  }
};
