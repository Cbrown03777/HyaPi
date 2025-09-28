"use client"
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Chip, Link, Tooltip } from '@mui/material'
import { useProof } from '@/hooks/useProof'
import { formatToken, formatUSD0 } from '@/lib/format'

function truncate(addr: string) {
  return addr.length > 18 ? addr.slice(0,10) + '…' + addr.slice(-6) : addr
}

export function ProofOfReservesPanel() {
  const { data, isLoading } = useProof()
  const items = data?.items || []
  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
        <Typography variant="h6" sx={{ flex: 1, fontWeight: 600 }}>Proof of Reserves</Typography>
        {data?.degraded && <Chip size="small" label="degraded" color="warning" />}
      </Box>
      <Table size="small" sx={{ '& th, & td': { border: 0 } }}>
        <TableHead>
          <TableRow>
            <TableCell>Chain</TableCell>
            <TableCell>Asset</TableCell>
            <TableCell>Address</TableCell>
            <TableCell align="right">Balance</TableCell>
            <TableCell align="right">USD</TableCell>
            <TableCell>Explorer</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {isLoading && (
            <TableRow><TableCell colSpan={6} sx={{ fontSize: 13, color: 'rgba(255,255,255,0.6)' }}>Loading…</TableCell></TableRow>
          )}
          {!isLoading && !items.length && (
            <TableRow><TableCell colSpan={6} sx={{ fontSize: 13, color: 'rgba(255,255,255,0.6)' }}>No data.</TableCell></TableRow>
          )}
          {items.map((r: any) => (
            <TableRow key={r.chain + r.address}>
              <TableCell sx={{ fontSize: 13 }}>{r.chain}</TableCell>
              <TableCell sx={{ fontSize: 13 }}>{r.asset}</TableCell>
              <TableCell sx={{ fontSize: 13, fontFamily: 'monospace' }}>
                <Tooltip title={r.address} placement="top" arrow>
                  <span>{truncate(r.address)}</span>
                </Tooltip>
              </TableCell>
              <TableCell align="right" sx={{ fontSize: 13 }}>{formatToken(r.balance, r.asset)}</TableCell>
              <TableCell align="right" sx={{ fontSize: 13 }}>{formatUSD0(r.usd)}</TableCell>
              <TableCell sx={{ fontSize: 13 }}>
                <Link href={r.explorer} target="_blank" rel="noopener" underline="hover">View</Link>
              </TableCell>
            </TableRow>
          ))}
          {data?.totals?.usd != null && (
            <TableRow>
              <TableCell colSpan={3} sx={{ fontSize: 13, fontWeight:600 }}>Totals</TableCell>
              <TableCell />
              <TableCell align="right" sx={{ fontSize: 13, fontWeight:600 }}>{formatUSD0(data.totals.usd)}</TableCell>
              <TableCell />
            </TableRow>
          )}
        </TableBody>
      </Table>
      <Typography variant="caption" sx={{ mt: 1, display:'block', color:'rgba(255,255,255,0.55)' }}>
        Balances refresh every ~60s; USD conversions optional & approximate.
      </Typography>
    </Box>
  )
}
