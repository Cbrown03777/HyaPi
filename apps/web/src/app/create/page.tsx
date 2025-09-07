'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { GOV_API_BASE } from '@hyapi/shared';

// If you already have this in /src/lib/pi.ts, it will be used.
// Otherwise this fallback returns the dev token in local only.
async function getBearer(): Promise<string> {
  try {
    const { signInWithPi } = await import('@/lib/pi');
    const token = await signInWithPi();
    if (typeof token === 'string') return token;
    if (token && typeof token === 'object' && 'accessToken' in token) return token.accessToken as string;
  } catch (_) {}
  // fallback dev token for local testing
  return 'dev pi_dev_address:1';
}

type FormState = {
  title: string;
  description: string;
  sui: string;     // keep as strings for easy controlled inputs
  aptos: string;
  cosmos: string;
};

export default function CreateProposalPage() {
  const router = useRouter();
  const [bearer, setBearer] = useState<string>('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  const [f, setF] = useState<FormState>({
    title: '',
    description: '',
    sui: '0.45',
    aptos: '0.30',
    cosmos: '0.25',
  });

  useEffect(() => {
    getBearer().then(setBearer);
  }, []);

  const weights = useMemo(() => {
    const n = (s: string) => {
      const v = Number(s);
      return Number.isFinite(v) ? v : 0;
    };
    const sui = n(f.sui);
    const aptos = n(f.aptos);
    const cosmos = n(f.cosmos);
    const sum = +(sui + aptos + cosmos).toFixed(6);
    return { sui, aptos, cosmos, sum };
  }, [f.sui, f.aptos, f.cosmos]);

  const sumOK = Math.abs(weights.sum - 1) < 1e-9;
  const titleOK = f.title.trim().length >= 3 && f.title.trim().length <= 140;
  const canSubmit = !!bearer && titleOK && sumOK && !submitting;

  function onChange<K extends keyof FormState>(k: K) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      setF((prev) => ({ ...prev, [k]: e.target.value }));
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setOkMsg(null);
    if (!canSubmit) return;

    setSubmitting(true);
    try {
      const idk = (globalThis.crypto?.randomUUID?.() ??
        Math.random().toString(36).slice(2)) as string;

      const res = await fetch(`${GOV_API_BASE}/v1/gov/proposals`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${bearer}`,
          'Idempotency-Key': idk,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: f.title.trim(),
          description: f.description.trim() || undefined,
          allocation: {
            sui: Number(f.sui),
            aptos: Number(f.aptos),
            cosmos: Number(f.cosmos),
          },
        }),
      });

      const json = await res.json().catch(() => ({}));
      if (!res.ok || json?.success === false) {
        const msg =
          json?.error?.message ||
          `HTTP ${res.status} ${res.statusText}`;
        throw new Error(msg);
      }

      setOkMsg('Proposal created! Redirecting…');
      // small delay so the toast is visible
      setTimeout(() => {
        // go back to main list (root) — adjust if your list is elsewhere
        router.push('/');
        router.refresh();
      }, 800);
    } catch (err: any) {
      setError(err?.message || 'Failed to create proposal');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="mx-auto max-w-2xl p-6">
      <h1 className="text-2xl font-semibold mb-4">Create Allocation Proposal</h1>

      <form onSubmit={onSubmit} className="space-y-5">
        <div>
          <label className="block text-sm font-medium mb-1">Title</label>
          <input
            className="w-full rounded border px-3 py-2"
            placeholder="Q4 Allocation: 45% Sui / 30% Aptos / 25% Cosmos"
            value={f.title}
            onChange={onChange('title')}
          />
          {!titleOK && (
            <p className="text-xs text-red-600 mt-1">
              Title must be 3–140 characters.
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Description (optional)</label>
          <textarea
            className="w-full rounded border px-3 py-2"
            rows={4}
            placeholder="Why this allocation improves yield/risk for hyaPi holders…"
            value={f.description}
            onChange={onChange('description')}
          />
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Sui</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              className="w-full rounded border px-3 py-2"
              value={f.sui}
              onChange={onChange('sui')}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Aptos</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              className="w-full rounded border px-3 py-2"
              value={f.aptos}
              onChange={onChange('aptos')}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Cosmos</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              className="w-full rounded border px-3 py-2"
              value={f.cosmos}
              onChange={onChange('cosmos')}
            />
          </div>
        </div>

        {/* Sum display */}
        <div className="text-sm">
          Sum:&nbsp;
          <span className={sumOK ? 'text-green-600' : 'text-red-600'}>
            {weights.sum.toFixed(2)}
          </span>
          {!sumOK && <span className="ml-2 text-red-600">Weights must sum to 1.00</span>}
        </div>

        {/* Progress bar */}
        <div className="h-2 w-full bg-gray-200 rounded">
          <div
            className={`h-2 rounded ${sumOK ? 'bg-green-500' : 'bg-red-500'}`}
            style={{ width: `${Math.min(100, Math.max(0, weights.sum * 100))}%` }}
          />
        </div>

        {error && (
          <div className="rounded border border-red-300 bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
        {okMsg && (
          <div className="rounded border border-green-300 bg-green-50 p-3 text-sm text-green-700">
            {okMsg}
          </div>
        )}

        <button
          type="submit"
          disabled={!canSubmit}
          className={`rounded px-4 py-2 text-white ${canSubmit ? 'bg-black' : 'bg-gray-400 cursor-not-allowed'}`}
          title={!bearer ? 'Sign in first' : (!sumOK ? 'Weights must sum to 1.0' : '')}
        >
          {submitting ? 'Creating…' : 'Create Proposal'}
        </button>
      </form>

      {/* Dev hint */}
      {!bearer && (
        <p className="mt-4 text-xs text-gray-500">
          Using dev token fallback. Ensure Pi sign‑in is wired in <code>/src/lib/pi.ts</code>.
        </p>
      )}
    </main>
  );
}
