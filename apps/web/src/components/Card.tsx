'use client'
import clsx from 'clsx'

type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  asChild?: boolean
}

export function Card({ className, children, ...rest }: CardProps) {
  return (
    <div
      className={clsx(
        'rounded-2xl bg-white/[0.02] border border-white/10 backdrop-blur-sm shadow-[0_4px_32px_-8px_rgba(0,0,0,0.6),0_2px_8px_-2px_rgba(0,0,0,0.5)] hover:shadow-[0_6px_40px_-6px_rgba(0,0,0,0.7),0_3px_12px_-2px_rgba(0,0,0,0.55)] transition-shadow',
        className
      )}
      onMouseMove={(e) => {
        const r = (e.currentTarget as HTMLDivElement).getBoundingClientRect();
        (e.currentTarget as HTMLDivElement).style.setProperty('--x', `${e.clientX - r.left}px`);
        (e.currentTarget as HTMLDivElement).style.setProperty('--y', `${e.clientY - r.top}px`);
      }}
      {...rest}
    >
      {children}
    </div>
  )
}
