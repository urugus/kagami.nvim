import { spawn } from "node:child_process";

const cache = new Map<string, string>();

export const renderSixelFromText = async (text: string, cols: number, rows: number) => {
  const mode = (process.env.KAGAMI_MODE || "ansi").toLowerCase();
  if (mode !== "sixel") return null;

  const cacheKey = `${cols}x${rows}:${text}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const font = process.env.KAGAMI_FONT || "Menlo";
  const pointsize = Number(process.env.KAGAMI_POINTSIZE || 14);
  const cellW = Number(process.env.KAGAMI_CELL_W || 8);
  const cellH = Number(process.env.KAGAMI_CELL_H || 16);
  const pxW = Math.max(1, cols * cellW);
  const pxH = Math.max(1, rows * cellH);

  const rendered = await new Promise<string>((resolve) => {
    const child = spawn("magick", [
      "-background",
      "#0b0f14",
      "-fill",
      "#e6edf3",
      "-font",
      font,
      "-pointsize",
      String(pointsize),
      "-gravity",
      "northwest",
      "-size",
      `${pxW}x${pxH}`,
      "caption:@-",
      "sixel:-",
    ]);

    let out = "";
    let err = "";

    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (d) => {
      out += d;
    });
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (d) => {
      err += d;
    });

    child.on("close", (code) => {
      if (code === 0) resolve(out);
      else resolve(`(sixel error) ${err || "magick failed"}\n`);
    });

    child.stdin.end(text);
  });

  cache.set(cacheKey, rendered);
  if (cache.size > 120) cache.clear();
  return rendered;
};
