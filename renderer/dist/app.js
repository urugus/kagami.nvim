import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from "ink";
import InkMarkdown from "ink-markdown";
export const App = ({ markdown }) => (_jsxs(Box, { flexDirection: "column", children: [_jsxs(Box, { children: [_jsx(Text, { dimColor: true, children: "Kagami" }), _jsx(Text, { dimColor: true, children: " " }), _jsx(Text, { dimColor: true, children: "(Ink preview)" })] }), _jsx(Box, { flexDirection: "column", children: _jsx(InkMarkdown, { children: markdown }) })] }));
