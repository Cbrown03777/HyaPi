'use client'
import clsx from 'clsx'
import { Badge as BaseBadge } from '@/components/Badge'

type Variant = 'primary' | 'success' | 'warn' | 'neutral'

export function Badge({ variant = 'neutral', className, children, ariaLabel }: { variant?: Variant; className?: string; children: React.ReactNode; ariaLabel?: string }) {
  const tone = variant === 'primary' ? 'primary' : variant === 'success' ? 'success' : variant === 'warn' ? 'warn' : 'neutral'
  const props: any = { tone: tone as any, className: clsx('rounded-full text-xs', className) }
  if (ariaLabel !== undefined) props.ariaLabel = ariaLabel
  return (
    <BaseBadge {...props}>
      {children}
    </BaseBadge>
  )
}
