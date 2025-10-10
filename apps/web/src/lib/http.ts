import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';

export function makeClient(token: string) {
  return axios.create({
    baseURL: GOV_API_BASE,
    headers: { Authorization: `Bearer ${token}` }
  });
}

// Lightweight fetch helper that auto-attaches Bearer from localStorage.hyapiBearer
function readCookie(name: string): string | null {
  if (typeof document === 'undefined') return null;
  const m = document.cookie.match(new RegExp('(?:^|; )' + name.replace(/[.$?*|{}()\[\]\\\/\+^]/g, '\\$&') + '=([^;]*)'));
  return m && typeof m[1] === 'string' ? decodeURIComponent(m[1] as string) : null;
}

export async function api(path: string, init: RequestInit = {}) {
  const base = process.env.NEXT_PUBLIC_API_BASE || GOV_API_BASE || '';
  const headers = new Headers(init.headers || {});
  headers.set('Content-Type', headers.get('Content-Type') || 'application/json');
  try {
    // Do not attach Authorization for public Pi callback endpoints
    const isPiPublic = /\/v1\/pi\/(approve|complete|payments\/[^/]+\/(approve|complete))$/.test(path);
    let token: string | null = null;
    if (typeof window !== 'undefined') token = localStorage.getItem('hyapiBearer');
    if (!token) token = readCookie('hyapiBearer');
    if (!isPiPublic && token && !headers.has('Authorization')) headers.set('Authorization', `Bearer ${token}`);
  } catch {}
  return fetch(`${base}${path}`, { ...init, headers });
}

export async function get(path: string, init: RequestInit = {}) {
  return api(path, { ...init, method: 'GET' });
}
export async function post(path: string, body?: any, init: RequestInit = {}) {
  const headers = new Headers(init.headers || {});
  headers.set('Content-Type', headers.get('Content-Type') || 'application/json');
  const req: RequestInit = { ...init, method: 'POST', headers } as RequestInit;
  if (body != null) (req as any).body = JSON.stringify(body);
  return api(path, req);
}
export async function del(path: string, init: RequestInit = {}) {
  return api(path, { ...init, method: 'DELETE' });
}
