import { Box, Text } from "ink";
import InkMarkdown from "ink-markdown";
import React from "react";

export const App = ({ markdown }: { markdown: string }) => (
  <Box flexDirection="column">
    <Box>
      <Text dimColor>Kagami</Text>
      <Text dimColor> </Text>
      <Text dimColor>(Ink preview)</Text>
    </Box>
    <Box flexDirection="column">
      {/* @ts-expect-error ink-markdown lacks proper type definitions */}
      <InkMarkdown>{markdown}</InkMarkdown>
    </Box>
  </Box>
);
