import { Box, Text } from "ink";
import { Marked } from "marked";
import { markedTerminal } from "marked-terminal";
import React, { useMemo } from "react";

const marked = new Marked(markedTerminal());

export const App = ({ markdown }: { markdown: string }) => {
  const rendered = useMemo(() => {
    if (!markdown) return "";
    return marked.parse(markdown, { async: false }) as string;
  }, [markdown]);

  return (
    <Box flexDirection="column">
      <Box>
        <Text dimColor>Kagami</Text>
        <Text dimColor> </Text>
        <Text dimColor>(Ink preview)</Text>
      </Box>
      <Box flexDirection="column">
        <Text>{rendered}</Text>
      </Box>
    </Box>
  );
};
