"use client";
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

export type ActivityKind = "stake" | "redeem" | "vote" | "finalize" | "execute";
export type ActivityStatus = "in-flight" | "success" | "error" | "pending";

export type ActivityItem = {
  id: string;
  ts: number; // epoch ms
  kind: ActivityKind;
  title: string;
  detail?: string | undefined;
  status: ActivityStatus;
};

type ActivityCtx = {
  items: ActivityItem[];
  log: (e: Omit<ActivityItem, "id" | "ts"> & { id?: string; ts?: number }) => string; // returns id
  update: (id: string, patch: Partial<ActivityItem>) => void;
  clear: () => void;
};

const Ctx = createContext<ActivityCtx | null>(null);

const LS_KEY = "hyapi:activity:v1";
const MAX = 25;

export function ActivityProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<ActivityItem[]>([]);

  // Load persisted
  useEffect(() => {
    try {
      const raw = localStorage.getItem(LS_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as ActivityItem[];
        if (Array.isArray(parsed)) setItems(parsed);
      }
    } catch {}
  }, []);

  // Persist on change
  useEffect(() => {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify(items));
    } catch {}
  }, [items]);

  const log = useCallback<ActivityCtx["log"]>((e) => {
    const id = e.id ?? crypto.randomUUID();
    const it: ActivityItem = {
      id,
      ts: e.ts ?? Date.now(),
      kind: e.kind,
      title: e.title,
      detail: e.detail,
      status: e.status,
    };
    setItems((prev) => {
      const idx = prev.findIndex((p) => p.id === id);
      if (idx >= 0) {
        const next = prev.slice();
        const merged = { ...next[idx], ...it } as ActivityItem;
        next.splice(idx, 1);
        return [merged, ...next].slice(0, MAX);
      }
      return [it, ...prev].slice(0, MAX);
    });
    return id;
  }, []);

  const update = useCallback<ActivityCtx["update"]>((id, patch) => {
    setItems((prev) => {
      const idx = prev.findIndex((p) => p.id === id);
      if (idx < 0) return prev;
      const next = prev.slice();
      next[idx] = { ...next[idx], ...patch } as ActivityItem;
      return next;
    });
  }, []);

  const clear = useCallback(() => setItems([]), []);

  const value = useMemo<ActivityCtx>(() => ({ items, log, update, clear }), [items, log, update, clear]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useActivity() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useActivity must be used within ActivityProvider");
  return ctx;
}
