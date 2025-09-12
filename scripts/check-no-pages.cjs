#!/usr/bin/env node
// Guard against accidental reintroduction of a legacy pages/ directory that conflicts with App Router.
const { existsSync, readdirSync } = require('node:fs');
const path = require('node:path');

const webDir = path.resolve(__dirname, '../apps/web');
const legacyPagesDir = path.join(webDir, 'pages');
if (existsSync(legacyPagesDir)) {
  const entries = readdirSync(legacyPagesDir).filter(f=>!f.startsWith('.'));
  console.error(`Error: legacy pages/ directory detected at apps/web/pages containing: ${entries.join(', ')}. Remove it to avoid App Router conflicts.`);
  process.exit(1);
}
console.log('OK: no legacy pages/ directory present.');
