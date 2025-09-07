'use client'

import { useEffect, useState } from 'react'

export function PiBanner() {
  const [hasPi, setHasPi] = useState<boolean>(true)
  useEffect(() => {
    const ok = typeof window !== 'undefined' && !!(window as any).Pi
    setHasPi(ok)
  }, [])
  if (hasPi) return null
  return (
    <div role="note" className="border-b border-yellow-600/30 bg-yellow-600/10 text-yellow-100">
      <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-2 text-sm">
        Open in Pi Browser to use payments.
      </div>
    </div>
  )
}
