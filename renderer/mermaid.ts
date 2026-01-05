import { spawn } from "node:child_process";
import { access, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import crypto from "node:crypto";

type RunResult = { code: number | null; stdout: string; stderr: string };

const run = (cmd: string, args: string[], stdinText?: string) =>
  new Promise<RunResult>((resolve) => {
    const child = spawn(cmd, args);
    let stdout = "";
    let stderr = "";

    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (d) => {
      stdout += d;
    });
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (d) => {
      stderr += d;
    });

    child.on("close", (code) => {
      resolve({ code, stdout, stderr });
    });

    if (stdinText != null) child.stdin.end(stdinText);
    else child.stdin.end();
  });

const sha1 = (text: string) => crypto.createHash("sha1").update(text).digest("hex");

const mermaidCache = new Map<string, string>();

const resolveLocalMmdc = async () => {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const local = path.join(here, "node_modules", ".bin", "mmdc");
  try {
    await access(local);
    return local;
  } catch {
    return null;
  }
};

const coerceEnvNumber = (v: string | undefined, fallback: number) => {
  const n = Number(v);
  if (!Number.isFinite(n)) return fallback;
  return n;
};

const estimateRows = (code: string, maxRows: number) => {
  const lines = code.split("\n").length;
  return Math.max(8, Math.min(maxRows, Math.ceil(lines * 2)));
};

export const renderSixelFromMermaid = async (
  code: string,
  cols: number,
  maxRows: number
): Promise<{ sixel: string | null; error: string | null }> => {
  const mode = (process.env.KAGAMI_MODE || "ansi").toLowerCase();
  if (mode !== "sixel") return { sixel: null, error: null };

  const enabled = String(process.env.KAGAMI_MERMAID ?? "1").toLowerCase() !== "0";
  if (!enabled) return { sixel: null, error: null };

  const requestedRows = process.env.KAGAMI_MERMAID_ROWS;
  const rows = Math.max(
    1,
    Math.min(maxRows, requestedRows ? coerceEnvNumber(requestedRows, estimateRows(code, maxRows)) : estimateRows(code, maxRows))
  );

  const font = process.env.KAGAMI_FONT || "Menlo";
  const cellW = coerceEnvNumber(process.env.KAGAMI_CELL_W, 8);
  const cellH = coerceEnvNumber(process.env.KAGAMI_CELL_H, 16);
  const pxW = Math.max(1, cols * cellW);
  const pxH = Math.max(1, rows * cellH);

  const cacheKey = `${pxW}x${pxH}:${sha1(code)}`;
  const cached = mermaidCache.get(cacheKey);
  if (cached) return { sixel: cached, error: null };

  const mmdc = process.env.KAGAMI_MMDC || (await resolveLocalMmdc()) || "mmdc";

  const dir = await mkdtemp(path.join(tmpdir(), "kagami-mermaid-"));
  const inFile = path.join(dir, "diagram.mmd");
  const outFile = path.join(dir, "diagram.svg");

  try {
    await writeFile(inFile, `${code}\n`, "utf8");

    const mmdcRes = await run(mmdc, ["-i", inFile, "-o", outFile, "-t", "dark", "-b", "transparent"]);
    if (mmdcRes.code !== 0) {
      const msg = (mmdcRes.stderr || mmdcRes.stdout || "mmdc failed").trim();
      return { sixel: null, error: msg };
    }

    const magickRes = await run("magick", [
      "-background",
      "#0b0f14",
      "-fill",
      "#e6edf3",
      "-font",
      font,
      outFile,
      "-resize",
      `${pxW}x${pxH}`,
      "sixel:-",
    ]);
    if (magickRes.code !== 0) {
      const msg = (magickRes.stderr || magickRes.stdout || "magick failed").trim();
      return { sixel: null, error: msg };
    }

    mermaidCache.set(cacheKey, magickRes.stdout);
    if (mermaidCache.size > 60) mermaidCache.clear();

    return { sixel: magickRes.stdout, error: null };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
};

