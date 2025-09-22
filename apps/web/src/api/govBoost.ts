import { API_BASE } from './config';

export async function fetchBoostMe(auth?: HeadersInit) {
  const r = await fetch(`${API_BASE}/v1/gov/boost/me`, { headers: auth ?? {}, cache: 'no-store' });
  return r.json();
}

export async function fetchBoostConfig() {
  const r = await fetch(`${API_BASE}/v1/gov/boost/config`, { cache: 'no-store' });
  return r.json();
}

export async function postLock(termWeeks: 26|52|104, txUrl?: string, auth?: HeadersInit) {
  const r = await fetch(`${API_BASE}/v1/gov/boost/lock`, {
    method: 'POST',
    headers: { 'Content-Type':'application/json', ...(auth||{}) },
    body: JSON.stringify({ termWeeks, txUrl })
  });
  return r.json();
}
