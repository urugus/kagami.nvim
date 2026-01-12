import { jsx as _jsx } from "react/jsx-runtime";
import { Writable } from "node:stream";
import { render } from "ink";
import { App } from "./app.tsx";
export class MemoryStdout extends Writable {
    isTTY = true;
    columns = 80;
    rows = 10000;
    // biome-ignore lint/suspicious/noExplicitAny: Node stream signature
    _write(_chunk, _enc, cb) {
        cb();
    }
}
export const createInk = () => {
    const stdout = new MemoryStdout();
    const ink = render(_jsx(App, { markdown: "" }), {
        stdout: stdout,
        stdin: undefined,
        exitOnCtrlC: false,
    });
    const rerender = (markdown) => {
        ink.rerender(_jsx(App, { markdown: markdown }));
    };
    return { stdout, ink, rerender };
};
