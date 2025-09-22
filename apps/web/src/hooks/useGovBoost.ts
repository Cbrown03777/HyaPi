"use client";
import { useCallback, useEffect, useMemo, useState } from 'react';
import { fetchBoostConfig, fetchBoostMe, postLock } from '@/api/govBoost';

function useAuthHeaders() {
  return useMemo(() => {
    try {
      const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : null);
      return t ? { Authorization: `Bearer ${t}` } : {};
    } catch {
      return {};
    }
  }, []);
}

export function useBoostConfig() {
  const [data, setData] = useState<{ terms: Array<{ weeks: number; boost: number }> } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    let stop = false;
    (async () => {
      try {
        setLoading(true); setError(null);
        const j = await fetchBoostConfig();
        if (!stop) setData(j);
      } catch (e:any) { if (!stop) setError(e.message || 'failed'); }
      finally { if (!stop) setLoading(false); }
    })();
    return () => { stop = true; };
  }, []);
  return { data, loading, error } as const;
}

export function useBoostMe() {
  const headers = useAuthHeaders();
  const [data, setData] = useState<{ success: boolean; data?: { boostPct: number; active: boolean; termWeeks?: 26|52|104; unlockAt?: string } } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);
  useEffect(() => {
    let stop = false;
    (async () => {
      try {
        setLoading(true); setError(null);
        const j = await fetchBoostMe(headers);
        if (!stop) setData(j);
      } catch (e:any) { if (!stop) setError(e.message || 'failed'); }
      finally { if (!stop) setLoading(false); }
    })();
    const id = setInterval(() => setTick(x => x+1), 60_000);
    return () => { stop = true; clearInterval(id); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(headers), tick]);
  const refetch = useCallback(() => setTick(x=>x+1), []);
  return { data, loading, error, refetch } as const;
}

export function useCreateLock() {
  const headers = useAuthHeaders();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mutate = useCallback(async (termWeeks: 26|52|104, txUrl?: string) => {
    setLoading(true); setError(null);
    try {
      const j = await postLock(termWeeks, txUrl, headers);
      if (j?.success === false) throw new Error(j?.error?.message || 'lock failed');
      return j;
    } catch (e:any) { setError(e.message || 'lock failed'); throw e; }
    finally { setLoading(false); }
  }, [headers]);
  return { mutate, loading, error } as const;
}
