'use client'
import { useId } from 'react'

type Props = {
  label: string
  value: number
  onChange: (v:number)=>void
  min?: number
  max?: number
  step?: number
  balance?: number
}

export function NumberWithSlider({ label, value, onChange, min=0, max=100, step=0.01, balance }: Props) {
  const inputId = useId()
  const pct = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0

  return (
  <div className="rounded-xl2 border border-base-200 bg-white/70 backdrop-blur p-4 shadow-card">
      <label htmlFor={inputId} className="block text-sm font-medium text-base-700">{label}</label>
    <div className="mt-2 flex items-center gap-3">
        <input
          id={inputId}
          type="number"
          inputMode="decimal"
          min={min} max={max} step={step}
          value={Number.isFinite(value) ? value : 0}
          onChange={(e)=>onChange(Number(e.target.value))}
      className="w-full min-h-[44px] rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white/90 placeholder:text-white/50 focus:outline-none focus-visible:ring-2 focus-visible:ring-accent-500 focus-visible:ring-offset-2 focus-visible:ring-offset-black/20 hover:border-white/20"
          aria-describedby={balance != null ? `${inputId}-bal` : undefined}
        />
        {balance != null && (
          <span id={`${inputId}-bal`} className="text-xs text-base-500">
            Balance: <b>{balance.toFixed(2)} Pi</b>
          </span>
        )}
      </div>
    <div className="mt-3">
        <input
          type="range"
          min={min} max={max} step={step}
          value={Number.isFinite(value) ? value : 0}
          onChange={(e)=>onChange(Number(e.target.value))}
          aria-label={`${label} slider`}
      className="w-full accent-[var(--pri)]"
        />
        <div className="mt-1 text-right text-xs text-base-500">{pct.toFixed(0)}%</div>
      </div>
    </div>
  )
}
