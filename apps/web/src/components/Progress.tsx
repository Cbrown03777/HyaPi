'use client'
import clsx from 'clsx'

type Segment = { value: number; tone?: 'primary' | 'danger' | 'neutral' }

type Props = {
  segments: Segment[]
  label?: string
  className?: string
}

export function Progress({ segments, label, className }: Props) {
  const total = Math.max(1, segments.reduce((s, x) => s + (x.value || 0), 0))
  let acc = 0
  const bars = segments.map((seg, i) => {
    const pct = Math.max(0, Math.min(100, (seg.value / total) * 100))
    const left = acc
    acc += pct
    const tone = seg.tone ?? 'neutral'
    const color = tone === 'primary' ? 'bg-[color:var(--acc)]' : tone === 'danger' ? 'bg-[color:var(--danger)]' : 'bg-white/20'
    return (
      <div
        key={i}
        className={clsx('absolute top-0 h-full rounded-full transition-[width] duration-500 ease-out motion-reduce:transition-none', color)}
        style={{ left: `${left}%`, width: `${pct}%` }}
        aria-hidden
      />
    )
  })

  return (
    <div className={clsx('relative h-2 w-full overflow-hidden rounded-full bg-white/10', className)} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100}>
      {bars}
    </div>
  )
}
