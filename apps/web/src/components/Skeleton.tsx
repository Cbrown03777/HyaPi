export function SkeletonBar({ className = '' }: { className?: string }) {
  return <div className={`animate-pulse animate-shimmer rounded-md bg-base-200 ${className}`} />
}

export function SkeletonCard({ lines = 3 }: { lines?: number }) {
  return (
    <div className="rounded-xl2 border border-base-200 bg-white/70 p-4 shadow-card backdrop-blur">
      <SkeletonBar className="h-4 w-2/5" />
      <div className="mt-3 space-y-2">
        {Array.from({ length: lines }).map((_, i) => (
          <SkeletonBar key={i} className="h-3 w-full" />
        ))}
      </div>
    </div>
  )
}
