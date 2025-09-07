import { Card } from './Card'

type Props = { label: string; value: string; sub?: string; tone?: 'primary' | 'accent' | 'base'; hint?: string }
export function StatCard({ label, value, sub, tone='base', hint }: Props) {
  const headerTint =
    tone === 'primary'
      ? 'from-[color:var(--pri)]/20 to-transparent'
      : tone === 'accent'
      ? 'from-[color:var(--acc)]/20 to-transparent'
      : 'from-white/10 to-transparent'
  return (
    <Card className="overflow-hidden p-0">
      <div className={"bg-gradient-to-r px-4 py-2 text-xs text-white/70 " + headerTint}>
        <div className="flex items-center gap-1">
          <span>{label}</span>
          {hint && (
            <span
              className="ml-0.5 inline-flex h-4 w-4 items-center justify-center rounded-full border border-white/20 text-[10px] text-white/70 hover:text-white/90 hover:border-white/40 cursor-help"
              title={hint}
              aria-label={hint}
            >
              i
            </span>
          )}
        </div>
      </div>
      <div className="p-4">
        <div className="mt-1 text-xl font-semibold text-[var(--fg)] tabular-nums">{value}</div>
        {sub && <div className="mt-0.5 text-xs text-white/60">{sub}</div>}
      </div>
    </Card>
  )
}
