"use client";
import { useEffect, useMemo, useState, useCallback } from 'react';
import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';

export type AllocatorSummary = {
  totalUsd: number;
  deployedUsd: number;
  bufferUsd: number;
  buffer: { target: number; upper: number; lower: number; routeExcessEligible: boolean; topUpEligible: boolean };
  drift: { maxDriftBps: number; avgDriftBps: number };
  venues: Array<{ key: string; usd: number; weightActual: number; weightTarget: number; driftBps: number }>;
  activeTargetSource: 'none' | 'override' | 'gov';
  deposits24hPi: number;
  withdraws24hPi: number;
  net24hPi: number;
};

export type Suggestion = { kind: string; label: string; endpoint?: string; method?: 'POST'|'GET'; rationale?: string };

export function useAllocator(token?: string) {
  const client = useMemo(() => token ? axios.create({ baseURL: GOV_API_BASE, headers: { Authorization: `Bearer ${token}` } }) : null, [token]);
  const [summary, setSummary] = useState<AllocatorSummary | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [suggestion, setSuggestion] = useState<Suggestion | null>(null);

  const fetchSummary = useCallback(async () => {
    if (!client) return;
    setLoading(true);
    setError(null);
    try {
      const { data } = await client.get('/v1/admin/allocator/summary');
      if (!data?.success) throw new Error(data?.error?.message || 'summary failed');
      setSummary(data.data as AllocatorSummary);
    } catch (e: any) {
      setError(e.message || 'summary failed');
    } finally {
      setLoading(false);
    }
  }, [client]);

  const fetchSuggestion = useCallback(async () => {
    if (!client) return;
    try {
      const { data } = await client.post('/v1/admin/allocator/suggest', {});
      if (!data?.success) throw new Error(data?.error?.message || 'suggest failed');
      setSuggestion(data.data as Suggestion);
    } catch (e: any) {
      // Swallow suggestion errors; keep UI minimal
    }
  }, [client]);

  useEffect(() => { fetchSummary(); }, [fetchSummary]);

  return { summary, loading, error, refresh: fetchSummary, suggestion, fetchSuggestion };
}
