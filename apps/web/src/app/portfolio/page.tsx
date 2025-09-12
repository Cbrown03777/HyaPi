'use client'
import { useEffect, useMemo, useState } from 'react'
import { GOV_API_BASE } from '@hyapi/shared'
import { signInWithPi } from '@/lib/pi'
import { StatCard } from '@/components/StatCard'
import { Card } from '@/components/Card'
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Chip } from '@mui/material'
import { useActivity } from '@/components/ActivityProvider'
import { fmtNumber, fmtPercent, fmtCompact } from '@/lib/format'

type PpsRow = { as_of_date: string; pps_1e18: string }

export default function PortfolioPage() {
  const [token, setToken] = useState('')
  const [hyapi, setHyapi] = useState<number | null>(null)
  const [piValue, setPiValue] = useState<number | null>(null)
  const [pps1e18, setPps1e18] = useState<string | null>(null)
  const [series, setSeries] = useState<PpsRow[]>([])
  const { items } = useActivity()

  useEffect(() => {
    (async () => {
      const maybe = await signInWithPi()
      const t = typeof maybe === 'string' ? maybe : (maybe as any)?.accessToken ?? ''
      setToken(t)
      if (t) (globalThis as any).hyapiBearer = t
      try {
        const res = await fetch(`${GOV_API_BASE}/v1/portfolio`, { headers: { Authorization: `Bearer ${t}` } })
        const j = await res.json()
        if (res.ok && j?.success) {
          const data = j.data
          setHyapi(Number(data?.hyapi_amount ?? '0'))
          setPiValue(Number(data?.effective_pi_value ?? '0'))
          setPps1e18(String(data?.pps_1e18 ?? '1000000000000000000'))
          setSeries((data?.pps_series ?? []) as PpsRow[])
        }
      } catch {}
    })()
  }, [])

  const pps = useMemo(() => {
    const n = Number(pps1e18 ?? '1000000000000000000') / 1e18
    return Number.isFinite(n) ? n : 1
  }, [pps1e18])

  const dailyDeltaPct = useMemo(() => {
    if (!series || series.length < 2) return null
  const lastRow = series[series.length - 1]
  const prevRow = series[series.length - 2]
  if (!lastRow || !prevRow) return null
  const last = Number(lastRow.pps_1e18) / 1e18
  const prev = Number(prevRow.pps_1e18) / 1e18
    if (!Number.isFinite(last) || !Number.isFinite(prev) || prev === 0) return null
    return ((last / prev) - 1) * 100
  }, [series])

  return (
    <Box sx={{ mx: 'auto', maxWidth: 'lg', px: { xs: 2, sm: 3 }, py: 4 }}>
      <Typography variant="h5" fontWeight={600} gutterBottom>Your Portfolio</Typography>

      <Box sx={{ display: 'grid', gap: 1.5, gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, 1fr)' }, mt: 0.5 }}>
        <StatCard label="hyaPi balance" value={`${(hyapi ?? 0) >= 10000 ? fmtCompact(hyapi ?? 0) : fmtNumber(hyapi)} hyaPi`} tone="primary" />
        <StatCard label="Estimated Pi value" value={`${(piValue ?? 0) >= 10000 ? fmtCompact(piValue ?? 0) : fmtNumber(piValue)} Pi`} tone="accent" />
        <StatCard
          label="Growth vs Pi"
            value={fmtPercent((pps - 1) * 100, 2, { sign: true })}
            hint="Computed as (PPS ÷ 1.0 − 1) × 100. PPS represents Pi per 1 hyaPi."
            {...(dailyDeltaPct == null
              ? {}
              : { sub: `${dailyDeltaPct >= 0 ? '▲' : '▼'} ${fmtPercent(Math.abs(dailyDeltaPct))} since last` })}
        />
      </Box>

      <Box sx={{ display: 'grid', gap: 1.5, gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' }, mt: 1 }}>
        <Card>
          <Box sx={{ px: 2.5, py: 1.25, background: 'linear-gradient(90deg, rgba(255,255,255,0.08), transparent)' }}>
            <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>Allocation</Typography>
          </Box>
          <Box sx={{ p: 2.5, pt: 1.5, typography: 'body2', color: 'rgba(255,255,255,0.8)' }}>
            Allocation data isn’t available yet. Governance proposals will define target weights across chains.
          </Box>
        </Card>
        <Card>
          <Box sx={{ px: 2.5, py: 1.25, background: 'linear-gradient(90deg, rgba(123,140,255,0.25), transparent)' }}>
            <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>Recent activity</Typography>
          </Box>
          <Box sx={{ p: 1.25, pt: 0.5 }}>
            <Table size="small" sx={{ '& th, & td': { border: 0 } }}>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>When</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Type</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Detail</TableCell>
                  <TableCell sx={{ color: 'rgba(255,255,255,0.65)', fontSize: 12 }}>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {items.slice(0, 10).map(e => {
                  const color = e.status === 'success' ? 'success' : e.status === 'error' ? 'error' : 'default'
                  return (
                    <TableRow key={e.id} sx={{ '&:last-child td': { pb: 1.5 } }}>
                      <TableCell sx={{ whiteSpace: 'nowrap', color: 'rgba(255,255,255,0.65)', fontSize: 13 }}>{new Date(e.ts).toLocaleString()}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap', fontSize: 13 }}>{e.kind}</TableCell>
                      <TableCell sx={{ fontSize: 13 }}>{e.title}{e.detail ? ` — ${e.detail}` : ''}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        <Chip label={e.status} size="small" color={color as any} variant={color === 'default' ? 'outlined' : 'filled'} sx={{ fontSize: 11, height: 22 }} />
                      </TableCell>
                    </TableRow>
                  )
                })}
                {!items.length && (
                  <TableRow>
                    <TableCell colSpan={4} sx={{ color: 'rgba(255,255,255,0.55)', fontSize: 13 }}>No recent activity.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </Box>
        </Card>
      </Box>
    </Box>
  )
}
