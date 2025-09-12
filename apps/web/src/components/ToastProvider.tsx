"use client";
import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { Alert, Snackbar, Slide, Stack } from '@mui/material';

type Kind = 'success' | 'error' | 'info' | 'warn'
type Toast = { id: string; kind: Kind; message: string; ttlMs: number }

type Ctx = {
  show: (message: string, kind?: Kind, ttlMs?: number) => void
  success: (message: string, ttlMs?: number) => void
  error: (message: string, ttlMs?: number) => void
  info: (message: string, ttlMs?: number) => void
  warn: (message: string, ttlMs?: number) => void
}

const ToastCtx = createContext<Ctx | null>(null)

export function useToast(): Ctx {
  const ctx = useContext(ToastCtx)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<Toast[]>([])

  const remove = useCallback((id: string) => {
    setItems((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const show = useCallback((message: string, kind: Kind = 'info', ttlMs = 4000) => {
    const id = crypto.randomUUID()
    const t: Toast = { id, kind, message, ttlMs }
    setItems((prev) => [...prev, t])
    window.setTimeout(() => remove(id), ttlMs)
  }, [remove])

  const api = useMemo<Ctx>(() => ({
    show,
    success: (m, ttl) => show(m, 'success', ttl),
    error: (m, ttl) => show(m, 'error', ttl),
  info: (m, ttl) => show(m, 'info', ttl),
  warn: (m, ttl) => show(m, 'warn', ttl),
  }), [show])

  return (
    <ToastCtx.Provider value={api}>
      {children}
      <Stack sx={{ position: 'fixed', top: 12, right: 12, zIndex: 1300, width: 360, maxWidth: '100%' }} spacing={1}>
        {items.map(t => (
          <Slide in key={t.id} direction="down" mountOnEnter unmountOnExit>
            <Snackbar
              open
              anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
              onClose={() => remove(t.id)}
              autoHideDuration={t.ttlMs}
              ContentProps={{ sx: { p: 0 } }}
            >
              <Alert
                onClose={() => remove(t.id)}
                severity={t.kind === 'warn' ? 'warning' : t.kind === 'error' ? 'error' : t.kind === 'success' ? 'success' : 'info'}
                variant="outlined"
                sx={{ width: '100%', alignItems: 'flex-start' }}
              >
                {t.message}
              </Alert>
            </Snackbar>
          </Slide>
        ))}
      </Stack>
    </ToastCtx.Provider>
  );
}
