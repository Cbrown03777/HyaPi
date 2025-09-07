'use client'
import clsx from 'clsx'

type Tone = 'neutral' | 'primary' | 'accent' | 'success' | 'warn' | 'danger'

type Props = {
  tone?: Tone
  children: React.ReactNode
  className?: string
  icon?: React.ReactNode
  ariaLabel?: string
}

const toneStyles: Record<Tone, string> = {
  neutral: 'border-white/20 bg-white/10 text-[var(--fg2)]',
  primary: 'border-[color:var(--pri)]/40 bg-[color:var(--pri)]/15 text-[var(--fg)]',
  accent: 'border-[color:var(--acc)]/40 bg-[color:var(--acc)]/15 text-[var(--fg)]',
  success: 'border-[color:var(--success)]/40 bg-[color:var(--success)]/15 text-[var(--fg)]',
  warn: 'border-[color:var(--warn)]/40 bg-[color:var(--warn)]/15 text-[var(--fg)]',
  danger: 'border-[color:var(--danger)]/40 bg-[color:var(--danger)]/15 text-[var(--fg)]',
}

export function Badge({ tone = 'neutral', className, children, icon, ariaLabel }: Props) {
  return (
    <span
      className={clsx(
        'inline-flex select-none items-center gap-1 rounded-full border px-2 py-0.5 text-xs',
        toneStyles[tone],
        className,
      )}
      aria-label={ariaLabel}
    >
      {icon ? <span aria-hidden>{icon}</span> : null}
      {children}
    </span>
  )
}
