"use client"
import { Box, Typography } from '@mui/material'
import { StatCard } from '@/components/StatCard'
import { fmtPercent } from '@/lib/format'

interface Props { pps: number; apy7d: number; lifetimeGrowth: number }

export function ApyCards({ pps, apy7d, lifetimeGrowth }: Props) {
  return (
    <Box sx={{ display: 'grid', gap: 1.5, gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, 1fr)' } }}>
      <StatCard label="Current PPS" value={pps.toFixed(4)} hint="Latest portfolio Pi per hyaPi share" />
      <StatCard label="7d EMA APY" value={fmtPercent(apy7d*100, 2, { sign:false })} hint="Annualized from 7d EMA of daily returns" tone="accent" />
      <StatCard label="Lifetime Growth" value={fmtPercent(lifetimeGrowth*100, 2, { sign:true })} hint="(Latest PPS / initial − 1)" tone="primary" />
    </Box>
  )
}
