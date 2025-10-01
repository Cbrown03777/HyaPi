"use client"
import { Box, Typography, Link as MuiLink, IconButton, Tooltip } from '@mui/material'
import ContentCopyIcon from '@mui/icons-material/ContentCopy'
import { ADDRESSES } from '@/config/addresses'

interface Addr { label: string; address: string; href?: string }

const EXPLORERS: Record<string, (a:string)=>string> = {
  COSMOS: a=>`https://www.mintscan.io/cosmos/account/${a}`,
  ARBITRUM: a=>`https://arbiscan.io/address/${a}`,
  BASE: a=>`https://basescan.org/address/${a}`,
  TIA: a=>`https://www.mintscan.io/celestia/account/${a}`,
  TERRA: a=>`https://www.mintscan.io/terra/account/${a}`,
  JUNO: a=>`https://www.mintscan.io/juno/account/${a}`,
  BAND: a=>`https://www.mintscan.io/band/account/${a}`,
};

const addresses: Addr[] = Object.values(ADDRESSES).map(a => {
  const explorerFn = EXPLORERS[a.chain];
  return {
    label: `${a.chain} ${a.asset}`,
    address: a.address,
    href: explorerFn ? explorerFn(a.address) : undefined
  } as Addr;
});

export function PublicAddresses() {
  return (
    <Box>
      <Typography variant="subtitle2" sx={{ mb: 1, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>Public Addresses</Typography>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        {addresses.map(a => (
          <Box key={a.label} sx={{ fontSize: 13, lineHeight: 1.3, display:'flex', alignItems:'center', gap:0.5 }}>
            <Typography component="span" sx={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', mr: 0.75, minWidth:140 }}>{a.label}</Typography>
            {a.href ? (
              <MuiLink href={a.href} target="_blank" rel="noopener" underline="hover" sx={{ fontFamily: 'monospace', fontSize: 12 }}>
                {a.address}
              </MuiLink>
            ) : (
              <Typography component="span" sx={{ fontFamily: 'monospace', fontSize: 12 }}>{a.address}</Typography>
            )}
            <Tooltip title="Copy address"><span><IconButton size="small" onClick={()=> { navigator?.clipboard?.writeText(a.address).catch(()=>{}); }}><ContentCopyIcon fontSize="inherit" /></IconButton></span></Tooltip>
          </Box>
        ))}
      </Box>
    </Box>
  )
}
