'use client'
import clsx from 'clsx'

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'danger'
  loading?: boolean
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

export function Button({ variant='primary', loading, leftIcon, rightIcon, className, children, ...rest }: Props) {
  const base = 'inline-flex items-center justify-center gap-1 rounded-xl font-medium text-sm px-4 h-10 disabled:opacity-60 disabled:cursor-not-allowed focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/50 focus-visible:ring-offset-2 focus-visible:ring-offset-black/30 transition-all shadow-[0_1px_2px_rgba(0,0,0,0.5)]'
  const styles = {
    primary:  'bg-brand-600/90 hover:bg-brand-500 text-white shadow-[0_4px_12px_-2px_rgba(99,102,241,0.4)]',
    secondary:'bg-white/10 hover:bg-white/15 text-white/90 border border-white/10',
    danger:   'bg-red-500/15 hover:bg-red-500/25 text-red-300 border border-red-500/40',
  }[variant]

  return (
    <button
      className={clsx(base, styles, className)}
      aria-busy={loading ? 'true' : undefined}
      {...rest}
    >
      {loading ? '…' : (
        <>
          {leftIcon && <span aria-hidden className="-ml-1 inline-flex h-4 w-4 items-center justify-center">{leftIcon}</span>}
          <span>{children}</span>
          {rightIcon && <span aria-hidden className="-mr-1 inline-flex h-4 w-4 items-center justify-center">{rightIcon}</span>}
        </>
      )}
    </button>
  )
}
