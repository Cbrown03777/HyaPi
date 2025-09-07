'use client'
import clsx from 'clsx'
import { Card as BaseCard } from '@/components/Card'

type Props = React.HTMLAttributes<HTMLDivElement> & {
  title?: React.ReactNode
  sub?: React.ReactNode
}

export function Card({ className, title, sub, children, ...rest }: Props) {
  // Wrap the existing Card to add optional title/sub without duplicating styles
  return (
    <BaseCard className={clsx('rounded-2xl border border-white/10 bg-white/5 shadow-[0_8px_24px_rgba(2,6,23,.25)]', className)} {...rest}>
      {(title || sub) && (
        <div className="px-4 pt-3">
          {title && <div className="text-base sm:text-lg font-semibold leading-snug text-white">{title}</div>}
          {sub && <div className="mt-0.5 text-xs text-white/70">{sub}</div>}
        </div>
      )}
      {children}
    </BaseCard>
  )}
