"use client";
import React, { useEffect, useRef, useState } from 'react'

export function BottomNav() {
  const [dim, setDim] = useState(false)
  const navRef = useRef<HTMLDivElement | null>(null)
  useEffect(() => {
    const target = document.getElementById('sticky-actions')
    if (!target) return
    const io = new IntersectionObserver((entries) => {
      for (const e of entries) {
        if (e.isIntersecting) setDim(true)
        else setDim(false)
      }
    }, { threshold: 0.01 })
    io.observe(target)
    return () => io.disconnect()
  }, [])
  return (
    <nav className={"fixed bottom-2 right-2 z-30 transition-opacity sm:hidden " + (dim ? 'opacity-40 pointer-events-none' : 'opacity-100')}>
      <div ref={navRef} className="flex items-stretch gap-2 rounded-xl border border-[rgba(255,255,255,0.12)] bg-[rgba(18,24,35,0.85)] px-2 py-1.5 shadow-lg backdrop-blur">
        <a href="/" className="flex flex-col items-center gap-1 px-2 text-[var(--text-700)] hover:text-[var(--text-900)]">
          <span aria-hidden>🏛️</span>
          <span className="text-[10px]">Govern</span>
        </a>
        <a href="/stake" className="flex flex-col items-center gap-1 px-2 text-[var(--text-700)] hover:text-[var(--text-900)]">
          <span aria-hidden>📈</span>
          <span className="text-[10px]">Stake</span>
        </a>
        <a href="/redeem" className="flex flex-col items-center gap-1 px-2 text-[var(--text-700)] hover:text-[var(--text-900)]">
          <span aria-hidden>↩️</span>
          <span className="text-[10px]">Redeem</span>
        </a>
      </div>
    </nav>
  )
}
