"use client"
import { Box, Tooltip, Typography } from '@mui/material'
import { styled } from '@mui/material/styles'
import { addressForChain } from '@/config/addresses'

export interface AllocationSegment { chain: string; weight: number }

const colors: Record<string,string> = {
  ethereum: '#627EEA',
  tron: '#EB0029',
  cosmos: '#5064FB',
  stride: '#FF7F50',
  juno: '#B300FF',
  default: '#888'
}

const Bar = styled(Box)({
  display: 'flex',
  height: 18,
  borderRadius: 6,
  overflow: 'hidden',
  background: 'rgba(255,255,255,0.07)'
})

export function AllocationBar({ mix }: { mix: AllocationSegment[] }) {
  if (!mix?.length) return <Bar />
  return (
    <Box>
      <Bar>
        {mix.map(seg => (
          <Tooltip key={seg.chain} title={`${seg.chain}: ${(seg.weight*100).toFixed(2)}%`} placement="top" arrow>
            <Box sx={{ flex: seg.weight, background: colors[seg.chain] || colors.default }} />
          </Tooltip>
        ))}
      </Bar>
      {/* Address legend */}
      <Box sx={{ display:'flex', flexWrap:'wrap', gap:1, mt:1 }}>
        {mix.map(seg => {
          const addr = addressForChain(seg.chain.toUpperCase() as any) || null;
          return (
            <Box key={seg.chain} sx={{ minWidth:180 }}>
              <Typography variant="caption" sx={{ display:'block', fontWeight:600, lineHeight:1.2 }}>{seg.chain}</Typography>
              <Typography variant="caption" sx={{ fontFamily:'monospace', opacity:0.8 }}>{addr || '—'}</Typography>
            </Box>
          )
        })}
      </Box>
    </Box>
  )
}
