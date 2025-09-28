"use client"
import { Box, Tooltip } from '@mui/material'
import { styled } from '@mui/material/styles'

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
    <Bar>
      {mix.map(seg => (
        <Tooltip key={seg.chain} title={`${seg.chain}: ${(seg.weight*100).toFixed(2)}%`} placement="top" arrow>
          <Box sx={{ flex: seg.weight, background: colors[seg.chain] || colors.default }} />
        </Tooltip>
      ))}
    </Bar>
  )
}
