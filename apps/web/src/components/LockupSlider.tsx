'use client'
import { useId } from 'react'

type Tier = { weeks: number; apyBps: number; label: string }
const TIERS: Tier[] = [
  { weeks: 0,   apyBps: 500,  label: 'No lock' },
  { weeks: 3,   apyBps: 700,  label: '3 wks'  },
  { weeks: 26,  apyBps: 1200, label: '6 mo'   },
  { weeks: 52,  apyBps: 1600, label: '12 mo'  },
  { weeks: 104, apyBps: 2000, label: '24 mo'  },
]

type Props = {
  valueWeeks: number
  onChange: (weeks:number, apyBps:number)=>void
}

export function LockupSlider({ valueWeeks, onChange }: Props) {
  const id = useId()
  const found = TIERS.findIndex(t => t.weeks === valueWeeks)
  const idx = found >= 0 ? found : 0
  const active = TIERS[idx] ?? TIERS[0]

  return (
    <div className="rounded-xl2 border border-base-200 bg-white/70 backdrop-blur p-4 shadow-card">
      <div className="flex items-center justify-between">
        <label htmlFor={id} className="text-sm font-medium text-base-700">Lockup Duration</label>
  <span className="text-xs text-base-500">APY: <b>{((active?.apyBps ?? 0)/100).toFixed(2)}%</b></span>
      </div>
      <input
        id={id}
        type="range"
        min={0} max={TIERS.length-1} step={1}
        value={idx < 0 ? 0 : idx}
        onChange={(e)=>{
          const i = Math.min(TIERS.length - 1, Math.max(0, Number(e.target.value)))
          const t = TIERS[i]
          if (!t) return
          onChange(t.weeks, t.apyBps)
        }}
        className="mt-3 w-full accent-primary-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-accent-500 focus-visible:ring-offset-2 focus-visible:ring-offset-white"
  aria-valuetext={`${active?.label ?? ''}, APY ${((active?.apyBps ?? 0)/100).toFixed(2)} percent`}
      />
      <div className="mt-2 flex justify-between text-xs text-base-500">
        {TIERS.map(t => <span key={t.weeks}>{t.label}</span>)}
      </div>
    </div>
  )
}
