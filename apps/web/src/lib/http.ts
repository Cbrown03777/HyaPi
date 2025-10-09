import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';

export function makeClient(token: string) {
  return axios.create({
    baseURL: GOV_API_BASE,
    headers: { Authorization: `Bearer ${token}` }
  });
}

// Lightweight fetch helper that auto-attaches Bearer from localStorage.hyapiBearer
export async function api(path: string, init: RequestInit = {}) {
  const base = process.env.NEXT_PUBLIC_API_BASE || GOV_API_BASE || '';
  const headers = new Headers(init.headers || {});
  headers.set('Content-Type', headers.get('Content-Type') || 'application/json');
  try {
    const token = (typeof window !== 'undefined') ? localStorage.getItem('hyapiBearer') : null;
    if (token && !headers.has('Authorization')) headers.set('Authorization', `Bearer ${token}`);
  } catch {}
  return fetch(`${base}${path}`, { ...init, headers });
}
