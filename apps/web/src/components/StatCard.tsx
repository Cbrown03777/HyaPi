"use client";
import React from 'react';
import { Card, CardContent, Box, Typography, Tooltip } from '@mui/material';

type Props = { label: string; value: string; sub?: string; tone?: 'primary' | 'accent' | 'base'; hint?: string };

export function StatCard({ label, value, sub, tone = 'base', hint }: Props) {
  const gradient = tone === 'primary'
    ? (theme:any)=>`linear-gradient(90deg, ${theme.palette.primary.main}22, transparent)`
    : tone === 'accent'
    ? (theme:any)=>`linear-gradient(90deg, ${theme.palette.secondary?.main || theme.palette.primary.light}22, transparent)`
    : (theme:any)=>`linear-gradient(90deg, ${theme.palette.grey[500]}33, transparent)`;

  return (
    <Card variant="outlined" sx={{ display:'flex', flexDirection:'column', overflow:'hidden' }}>
      <Box px={2} py={1} sx={(theme)=>({ background: gradient(theme), borderBottom:`1px solid ${theme.palette.divider}` })}>
        <Box display="flex" alignItems="center" gap={0.75}>
          <Typography variant="caption" sx={{ opacity:0.8 }}>{label}</Typography>
          {hint && (
            <Tooltip title={hint} arrow>
              <Box component="span" aria-label={hint} sx={{ width:16, height:16, display:'inline-flex', alignItems:'center', justifyContent:'center', fontSize:10, border:'1px solid', borderColor:'divider', borderRadius:'50%', cursor:'help', opacity:0.7 }}>i</Box>
            </Tooltip>
          )}
        </Box>
      </Box>
      <CardContent sx={{ pt:2, pb:2 }}> 
        <Typography variant="h6" fontWeight={600} sx={{ fontVariantNumeric:'tabular-nums' }}>{value}</Typography>
        {sub && <Typography variant="caption" sx={{ mt:0.5, display:'block', opacity:0.7 }}>{sub}</Typography>}
      </CardContent>
    </Card>
  );
}
