/**
 * Guardrails for Copilot:
 * - DO NOT modify @mui/* or @emotion/* dependencies or versions.
 * - Only emit add commands for missing packages/types discovered by tsc.
 * - Never change root overrides. Never upgrade Next/React.
 * - Keep installs scoped: use `pnpm -F <workspace> add ...`.
 */

import { execSync } from 'node:child_process';
import { createRequire } from 'node:module';
import * as fs from 'node:fs';
import * as path from 'node:path';

interface WorkspaceInfo {
  name: string;
  dir: string;
  pkgJson: any;
}

function readJSON(file: string) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function listWorkspaces(root: string): WorkspaceInfo[] {
  const results: WorkspaceInfo[] = [];
  try {
    const json = execSync('pnpm -r list --depth -1 --json', { cwd: root, stdio: 'pipe' }).toString();
    const arr = JSON.parse(json) as Array<{ name: string; path: string } | { path: string } | any>;
    for (const item of arr) {
      const dir = (item as any).path as string;
      if (!dir) continue;
      const pj = path.join(dir, 'package.json');
      if (!fs.existsSync(pj)) continue;
      const pkg = readJSON(pj);
      const name = pkg.name || path.basename(dir);
      results.push({ name, dir, pkgJson: pkg });
    }
  } catch (e) {
    // Fallback to manual discovery using common globs
    const globs = ['apps', 'packages'];
    for (const g of globs) {
      const baseDir = path.join(root, g);
      if (!fs.existsSync(baseDir)) continue;
      const entries = fs.readdirSync(baseDir, { withFileTypes: true });
      for (const d of entries) {
        if (!d.isDirectory()) continue;
        const dir = path.join(baseDir, d.name);
        const pj = path.join(dir, 'package.json');
        if (fs.existsSync(pj)) results.push({ name: readJSON(pj).name, dir, pkgJson: readJSON(pj) });
      }
    }
  }
  return results;
}

const MAPPINGS: Record<string, { runtime?: string; types?: string[] }> = {
  axios: { runtime: 'axios' },
  zod: { runtime: 'zod' },
  dotenv: { runtime: 'dotenv' },
  jsonwebtoken: { runtime: 'jsonwebtoken', types: ['@types/jsonwebtoken'] },
  uuid: { runtime: 'uuid', types: ['@types/uuid'] },
  express: { types: ['@types/express'] },
  cors: { types: ['@types/cors'] },
  morgan: { types: ['@types/morgan'] },
  node: { types: ['@types/node'] },
};

function isIgnoredImport(name: string) {
  if (!name) return true;
  if (name.startsWith('./') || name.startsWith('../')) return true;
  // Ignore Node builtins (node: scheme or common core modules)
  if (name.startsWith('node:')) return true;
  const core = new Set(['fs','path','url','http','https','crypto','zlib','stream','util','events','os','tty','dns','net','tls','module','assert','buffer','child_process','cluster','dgram','readline','repl','vm']);
  if (core.has(name)) return true;
  // Ignore MUI/Emotion explicitly
  if (name.startsWith('@mui/') || name.startsWith('@emotion/')) return true;
  return false;
}

function collectSuggestionsPerWorkspace(): Record<string, Set<string>> {
  const suggestions: Record<string, Set<string>> = {};
  for (const ws of WORKSPACES) {
    const hasScript = !!ws.pkgJson.scripts?.typecheck;
    if (!hasScript) continue;
    let out = '';
    try {
      execSync(`pnpm -F ${ws.name} run typecheck`, { stdio: 'pipe' });
    } catch (e: any) {
      out = (e.stdout?.toString() || '') + (e.stderr?.toString() || '');
    }
    if (!out) continue;
    const set = (suggestions[ws.name] ||= new Set());
    // Missing modules
    const modRe = /error TS2307: Cannot find module '([^']+)'/g;
    let m: RegExpExecArray | null;
    while ((m = modRe.exec(out))) {
      const mod = m[1];
      if (isIgnoredImport(mod)) continue;
      if (MAPPINGS[mod]?.runtime) set.add(MAPPINGS[mod].runtime!);
      else set.add(mod);
      if (MAPPINGS[mod]?.types) MAPPINGS[mod].types!.forEach(t => set.add(t));
    }
    // Missing type definition files
    const typesRe = /error TS2688: Cannot find type definition file for '([^']+)'/g;
    while ((m = typesRe.exec(out))) {
      const missing = m[1];
      if (missing === 'node') set.add('@types/node');
    }
  }
  return suggestions;
}

function extractFirstPathNear(text: string, idx: number): string | null {
  const start = Math.max(0, idx - 300);
  const end = Math.min(text.length, idx + 300);
  const chunk = text.slice(start, end);
  const m = chunk.match(/\n(\/[^\n]+\.\w+):\d+:\d+/);
  return m ? m[1] : null;
}

let WORKSPACES: WorkspaceInfo[] = [];
function workspaceForFile(file: string): WorkspaceInfo | null {
  if (!file) return null;
  for (const ws of WORKSPACES) {
    if (file.startsWith(ws.dir)) return ws;
  }
  return null;
}

function main() {
  const root = process.cwd();
  WORKSPACES = listWorkspaces(root);

  console.log('Running typecheck across workspaces...');
  const suggestionsByWs = collectSuggestionsPerWorkspace();

  // Filter out any packages already present in that workspace's package.json
  for (const ws of WORKSPACES) {
    const set = suggestionsByWs[ws.name];
    if (!set) continue;
    const existing = new Set([
      ...Object.keys(ws.pkgJson.dependencies || {}),
      ...Object.keys(ws.pkgJson.devDependencies || {}),
    ]);
    for (const pkg of Array.from(set)) {
      if (existing.has(pkg)) set.delete(pkg);
      if (pkg.startsWith('@mui/') || pkg.startsWith('@emotion/')) set.delete(pkg);
    }
  }

  console.log('\nSuggested install commands (grouped by workspace):');
  for (const ws of WORKSPACES) {
    const set = suggestionsByWs[ws.name];
    if (!set || set.size === 0) continue;
    const runtime: string[] = [];
    const types: string[] = [];
    for (const p of set) {
      if (p.startsWith('@types/')) types.push(p);
      else runtime.push(p);
    }
    if (runtime.length === 0 && types.length === 0) continue;
    console.log(`\n# ${ws.name}`);
    if (runtime.length) console.log(`pnpm -F ${ws.name} add ${runtime.join(' ')}`);
    if (types.length) console.log(`pnpm -F ${ws.name} add -D ${types.join(' ')}`);
  }
}

main();
