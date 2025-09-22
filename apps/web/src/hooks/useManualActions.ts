"use client";
import { useCallback, useEffect, useMemo, useState } from 'react';
import type { ManualStatus, PlannedAction, ConfirmFillInput } from '@/api/manualActions';
import { listActions, createAction, confirmAction } from '@/api/manualActions';

function getToken(): string | null {
  try { return (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : null); } catch { return null; }
}

export function useManualActions(status: ManualStatus) {
  const token = useMemo(()=> getToken() || '', []);
  const [data, setData] = useState<PlannedAction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string|undefined>();

  const fetchList = useCallback(async () => {
    if (!token) return;
    setLoading(true); setError(undefined);
    try {
      const rows = await listActions(token, status);
      setData(rows);
    } catch (e:any) {
      setError(e.message || 'load failed');
    } finally { setLoading(false); }
  }, [token, status]);

  useEffect(()=> { fetchList(); const id = setInterval(fetchList, 60_000); return ()=> clearInterval(id); }, [fetchList]);

  const create = useCallback(async (venue: string, amountPI: number, note?: string) => {
    if (!token) throw new Error('no token');
    const row = await createAction(token, venue, amountPI, note);
    await fetchList();
    return row;
  }, [token, fetchList]);

  const confirm = useCallback(async (id: string, body: ConfirmFillInput) => {
    if (!token) throw new Error('no token');
    await confirmAction(token, id, body);
    await fetchList();
  }, [token, fetchList]);

  return { data, loading, error, refresh: fetchList, create, confirm };
}
