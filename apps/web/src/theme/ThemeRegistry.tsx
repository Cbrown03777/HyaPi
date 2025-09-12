"use client";
import * as React from 'react';
import { ThemeProvider, CssBaseline } from '@mui/material';
import createEmotionCache from './createEmotionCache';
import { CacheProvider } from '@emotion/react';
import theme from './theme';

const clientSideEmotionCache = createEmotionCache();

export default function ThemeRegistry({ children }: { children: React.ReactNode }) {
  // Migrated off deprecated Experimental_CssVarsProvider; ThemeProvider now handles css variables (MUI v7+).
  return (
    <CacheProvider value={clientSideEmotionCache}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </ThemeProvider>
    </CacheProvider>
  );
}
