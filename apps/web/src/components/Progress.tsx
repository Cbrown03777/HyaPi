"use client";
import { Box } from '@mui/material';

type Segment = { value: number; tone?: 'primary' | 'danger' | 'neutral' }

type Props = {
  segments: Segment[]
  label?: string
  className?: string
}

export function Progress({ segments, label, className }: Props) {
  const total = Math.max(1, segments.reduce((s, x) => s + (x.value || 0), 0))
  let acc = 0
  const bars = segments.map((seg, i) => {
    const pct = Math.max(0, Math.min(100, (seg.value / total) * 100))
    const left = acc
    acc += pct
    const tone = seg.tone ?? 'neutral'
    const color = tone === 'primary' ? 'primary.main' : tone === 'danger' ? 'error.main' : 'rgba(255,255,255,0.2)'
    return (
      <Box key={i} aria-hidden sx={{ position: 'absolute', top: 0, left: `${left}%`, width: `${pct}%`, height: '100%', borderRadius: 999, transition: 'width .5s ease-out', bgcolor: color }} />
    )
  })

  return (
    <Box className={className} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} sx={{ position: 'relative', height: 8, width: '100%', overflow: 'hidden', borderRadius: 999, background: 'rgba(255,255,255,0.1)' }}>
      {bars}
    </Box>
  )
}
