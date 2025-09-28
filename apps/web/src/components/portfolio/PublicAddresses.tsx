"use client"
import { Box, Typography, Link as MuiLink } from '@mui/material'

interface Addr { label: string; address: string; href?: string }

// Placeholder static list; can be replaced by /metadata endpoint later.
const addresses: Addr[] = [
  { label: 'Treasury Multisig (Cosmos)', address: 'cosmos1xxxxxxxxxxxxxxxxxxxx', href: 'https://www.mintscan.io/cosmos/account/cosmos1xxxxxxxxxxxxxxxxxxxx' },
  { label: 'Bridge Escrow (Ethereum)', address: '0x1234...abcd', href: 'https://etherscan.io/address/0x1234...abcd' }
]

export function PublicAddresses() {
  return (
    <Box>
      <Typography variant="subtitle2" sx={{ mb: 1, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>Public Addresses</Typography>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        {addresses.map(a => (
          <Box key={a.label} sx={{ fontSize: 13, lineHeight: 1.3 }}>
            <Typography component="span" sx={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', mr: 0.75 }}>{a.label}</Typography>
            {a.href ? (
              <MuiLink href={a.href} target="_blank" rel="noopener" underline="hover" sx={{ fontFamily: 'monospace', fontSize: 12 }}>
                {a.address}
              </MuiLink>
            ) : (
              <Typography component="span" sx={{ fontFamily: 'monospace', fontSize: 12 }}>{a.address}</Typography>
            )}
          </Box>
        ))}
      </Box>
    </Box>
  )
}
