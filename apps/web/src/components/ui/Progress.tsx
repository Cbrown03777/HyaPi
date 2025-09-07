'use client'
import clsx from 'clsx'
import { Progress as BaseProgress } from '@/components/Progress'

type Props = {
  value: number
  max?: number
  className?: string
  label?: string
}

export function Progress({ value, max = 100, className, label }: Props) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100))
  return (
    <div className={clsx('w-full', className)}>
      <BaseProgress segments={[{ value: pct, tone: 'primary' }]} label={label ?? `${Math.round(pct)}%`} />
      <div className="mt-1 text-right text-xs text-white/60 tabular-nums" aria-hidden>
        {Math.round(pct)}%
      </div>
    </div>
  )
}
