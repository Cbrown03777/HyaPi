'use client'

import { useEffect, useState } from 'react'
import { Box } from '@mui/material'

export function PiBanner() {
  const [hasPi, setHasPi] = useState<boolean>(true)
  useEffect(() => {
    const ok = typeof window !== 'undefined' && !!(window as any).Pi
    setHasPi(ok)
  }, [])
  if (hasPi) return null
  return (
    <Box role="note" sx={{ borderBottom: '1px solid rgba(234,179,8,0.3)', bgcolor: 'rgba(234,179,8,0.10)', color: 'rgba(255,234,160,0.95)' }}>
      <Box sx={{ mx: 'auto', maxWidth: 'lg', px: { xs: 2, sm: 3 }, py: 1, fontSize: 14 }}>
        Open in Pi Browser to use payments.
      </Box>
    </Box>
  )
}
