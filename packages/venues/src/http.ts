import { request } from 'undici';

export type HttpLike = (url: string, init?: any) => Promise<any>;

// httpJSON will attempt undici.request, but falls back to global fetch when provided
export async function httpJSON<T>(url: string, init?: any, inject?: HttpLike): Promise<T> {
	if (inject) {
		const res = await inject(url, init);
		return res as T;
	}
	// If global fetch is monkey patched and method is POST with body JSON, we can use fetch for tests
	if (typeof (globalThis as any).fetch === 'function') {
		const r = await (globalThis as any).fetch(url, init);
		if (!r.ok) throw new Error(`HTTP ${r.status} ${url}`);
		return r.json() as Promise<T>;
	}
	const res = await request(url, {
		method: init?.method || 'GET',
		headers: { 'content-type':'application/json', ...(init?.headers||{}) },
		body: init?.body,
		...init,
	});
	if (res.statusCode < 200 || res.statusCode >= 300) {
		const text = await res.body.text();
		throw new Error(`HTTP ${res.statusCode} ${url} :: ${text}`);
	}
	const data = await res.body.json();
	return data as T;
}
