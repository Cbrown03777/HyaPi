export function assertMUIv6() {
  try {
    // @ts-ignore
    const v = require('@mui/material/package.json')?.version ?? '';
    if (!/^6\./.test(v)) {
      // eslint-disable-next-line no-console
      console.error('[HyaPi] MUI version drift detected:', v);
      if (process.env.NODE_ENV !== 'production') {
        throw new Error(`MUI 6.x required, found ${v}. Clean node_modules/.next and reinstall.`);
      }
    }
  } catch {
    // ignore in prod
  }
}
