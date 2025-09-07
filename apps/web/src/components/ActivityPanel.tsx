"use client";
import React, { useEffect } from "react";
import { useActivity } from "./ActivityProvider";
import { GOV_API_BASE } from "@hyapi/shared";
import { fmtCompact } from "@/lib/format";

function timeAgo(ts: number): string {
  const s = Math.max(0, Math.floor((Date.now() - ts) / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}

export function ActivityPanel() {
  const { items, clear, log } = useActivity();
  // On mount, fetch recent server history and merge (idempotently via log with id)
  useEffect(() => {
    let abort = false;
    (async () => {
      try {
        const token = (globalThis as any)?.hyapiBearer as string | undefined; // optional: set by pages when known
        const headers: HeadersInit = token ? { Authorization: `Bearer ${token}` } : {};
        const res = await fetch(`${GOV_API_BASE}/v1/activity/recent`, { headers });
        if (!res.ok) return;
        const j = await res.json();
        const srv = j?.data?.items as any[] | undefined;
        if (!srv || abort) return;
        for (const it of srv) {
          log({
            id: String(it.id ?? `${it.kind}:${it.ts}`),
            kind: it.kind,
            title: it.title,
            detail: it.detail,
            status: it.status,
            ts: typeof it.ts === 'string' ? new Date(it.ts).getTime() : (it.ts ?? Date.now()),
          });
        }
      } catch {}
    })();
    return () => { abort = true };
  }, [log]);
  if (!items.length) return null;
  return (
    <div className="mt-4 rounded-xl2 border border-base-200 bg-white/70 p-3 shadow-card backdrop-blur">
      <div className="mb-2 flex items-center justify-between">
        <div className="text-sm font-medium text-base-800">Recent activity</div>
        <button className="text-xs text-base-600 hover:text-base-800" onClick={clear}>Clear</button>
      </div>
      <ul className="divide-y divide-base-200">
        {items.slice(0, 8).map((e) => (
          <li key={e.id} className="flex items-start justify-between py-2 text-sm">
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span
                  className={
                    "inline-flex h-5 w-5 items-center justify-center rounded-full text-xs " +
                    (e.status === "success"
                      ? "bg-success/20 text-success"
                      : e.status === "error"
                      ? "bg-danger/20 text-danger"
                      : "bg-primary-100 text-primary-700")
                  }
                  aria-hidden
                >
                  {e.kind === "stake" ? "⇪" : e.kind === "redeem" ? "⇄" : e.kind === "vote" ? "✓" : e.kind === "finalize" ? "⚑" : "▶"}
                </span>
                <div className="truncate font-medium text-base-900">{e.title}</div>
              </div>
              {e.detail && (
                <div className="mt-0.5 truncate text-xs text-base-600">
                  {e.detail.replace(/(\d+(?:\.\d+)?)\s?(Pi|hyaPi)/gi, (_, num, unit) => `${fmtCompact(Number(num))} ${unit}`)}
                </div>
              )}
            </div>
            <div className="shrink-0 text-xs text-base-500">{timeAgo(e.ts)}</div>
          </li>
        ))}
      </ul>
    </div>
  );
}
