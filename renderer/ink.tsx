import { Writable } from "node:stream";
import { render } from "ink";
import React from "react";
import { App } from "./app.tsx";

export class MemoryStdout extends Writable {
  public isTTY = true;
  public columns = 80;
  public rows = 10000;

  // biome-ignore lint/suspicious/noExplicitAny: Node stream signature
  public override _write(_chunk: any, _enc: any, cb: (error?: Error | null) => void) {
    cb();
  }
}

export const createInk = () => {
  const stdout = new MemoryStdout();
  const ink = render(<App markdown="" />, {
    stdout: stdout as unknown as NodeJS.WriteStream,
    stdin: undefined,
    exitOnCtrlC: false,
  });
  const rerender = (markdown: string) => {
    ink.rerender(<App markdown={markdown} />);
  };
  return { stdout, ink, rerender };
};
