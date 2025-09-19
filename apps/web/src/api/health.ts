import { API_BASE } from './config';

export async function checkApiHealth(): Promise<{ ok: boolean }> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), 3000);
  try {
    const res = await fetch(`${API_BASE}/v1/health`, { signal: controller.signal, cache: 'no-store' });
    clearTimeout(id);
    if (!res.ok) return { ok: false };
    const data = await res.json().catch(() => null);
    return { ok: Boolean(data?.ok) };
  } catch {
    clearTimeout(id);
    return { ok: false };
  }
}
