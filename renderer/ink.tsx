import { Readable, Writable } from "node:stream";
import { render } from "ink";
import React from "react";
import { App } from "./app.tsx";

export class MemoryStdout extends Writable {
  public isTTY = true;
  public columns = 80;
  public rows = 10000;
  private buffer = "";
  private lastOutput = "";

  // biome-ignore lint/suspicious/noExplicitAny: Node stream signature
  public override _write(chunk: any, _enc: any, cb: (error?: Error | null) => void) {
    const str = chunk.toString();
    this.buffer += str;
    cb();
  }

  public getLastFrame(): string {
    // Inkは出力時にANSIエスケープでカーソル制御を行うので、
    // 最新の内容を取得するために、バッファから取得
    const output = this.buffer;
    this.lastOutput = output;
    this.buffer = "";
    return this.lastOutput;
  }

  public getOutput(): string {
    return this.lastOutput || this.buffer;
  }
}

class DummyStdin extends Readable {
  public isTTY = false;
  public isRaw = false;

  public setRawMode(_mode: boolean) {
    return this;
  }

  public override _read() {
    // no-op
  }
}

export const createInk = () => {
  const stdout = new MemoryStdout();
  const stdin = new DummyStdin();
  const ink = render(<App markdown="" />, {
    stdout: stdout as unknown as NodeJS.WriteStream,
    stdin: stdin as unknown as NodeJS.ReadStream,
    exitOnCtrlC: false,
    debug: false,
  });
  const rerender = (markdown: string) => {
    ink.rerender(<App markdown={markdown} />);
  };
  return { stdout, ink, rerender };
};
