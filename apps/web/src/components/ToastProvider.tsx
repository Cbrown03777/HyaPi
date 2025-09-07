'use client'
import React, { createContext, useCallback, useContext, useMemo, useState } from 'react'

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
      <div className="pointer-events-none fixed inset-x-0 top-3 z-[1000] flex justify-center px-3 sm:inset-auto sm:right-3 sm:top-3 sm:left-auto sm:w-[360px]">
        <div className="flex w-full flex-col gap-2">
          {items.map((t) => (
            <div
              key={t.id}
              className={
                'pointer-events-auto toast-in flex items-start gap-2 rounded-xl2 border p-3 shadow-card backdrop-blur ' +
                (t.kind === 'success'
                  ? 'border-success/30 bg-success/10 text-base-900'
                  : t.kind === 'error'
                  ? 'border-danger/30 bg-danger/10 text-base-900'
                  : t.kind === 'warn'
                  ? 'border-warn/30 bg-warn/10 text-base-900'
                  : 'border-primary-200 bg-primary-50/80 text-base-900')
              }
              role="status"
              onClick={() => remove(t.id)}
            >
              <div aria-hidden className="select-none text-lg leading-none">
                {t.kind === 'success' ? '⚡' : t.kind === 'error' ? '⛔' : t.kind === 'warn' ? '⏳' : 'ℹ️'}
              </div>
              <div className="min-w-0 flex-1 text-sm">{t.message}</div>
              <button
                type="button"
                className="ml-2 inline-flex h-6 w-6 items-center justify-center rounded-md text-base-700 hover:bg-white/40"
                aria-label="Dismiss"
                onClick={(e) => { e.stopPropagation(); remove(t.id) }}
              >
                ×
              </button>
            </div>
          ))}
        </div>
      </div>
    </ToastCtx.Provider>
  )
}
