"use client";
import React, { useEffect } from 'react';
import { Box, Paper, Stack, Typography, Button, Chip, Tooltip, IconButton } from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';
import { useAllocator } from '@/api/useAllocator';
import { formatUSD } from '@/lib/format';
import { makeClient } from '@/lib/http';

export default function AllocatorRow() {
  const [token, setToken] = React.useState('');
  useEffect(()=>{ try { const t = (globalThis as any).hyapiBearer || (typeof localStorage !== 'undefined' ? localStorage.getItem('hyapiBearer') : undefined); if (typeof t === 'string' && t.trim()) setToken(t.trim()); } catch {} },[]);
  const { summary, loading, error, refresh, suggestion, fetchSuggestion } = useAllocator(token);

  useEffect(()=>{ fetchSuggestion(); }, [fetchSuggestion]);

  const client = React.useMemo(()=> token ? makeClient(token) : null, [token]);

  const act = async () => {
    if (!client || !suggestion || !suggestion.endpoint || suggestion.method !== 'POST') return;
    try { await client.post(suggestion.endpoint, {}); await refresh(); } catch {}
  };

  return (
    <Paper variant="outlined" sx={{ p:2.5, borderRadius: 3 }}>
      <Stack direction={{ xs:'column', md:'row' }} spacing={2} alignItems={{ xs:'flex-start', md:'center' }} justifyContent="space-between">
        <Stack direction="row" spacing={3} flexWrap="wrap">
          <Box>
            <Typography variant="caption" sx={{opacity:0.6}}>Total TVL</Typography>
            <Typography fontWeight={600}>{summary ? formatUSD(summary.totalUsd) : '—'}</Typography>
          </Box>
          <Box>
            <Typography variant="caption" sx={{opacity:0.6}}>Deployed</Typography>
            <Typography fontWeight={600}>{summary ? formatUSD(summary.deployedUsd) : '—'}</Typography>
          </Box>
          <Box>
            <Typography variant="caption" sx={{opacity:0.6}}>Buffer</Typography>
            <Typography fontWeight={600}>{summary ? formatUSD(summary.bufferUsd) : '—'}</Typography>
          </Box>
          {summary && (
            <Box>
              <Typography variant="caption" sx={{opacity:0.6}}>Buffer Target</Typography>
              <Typography fontWeight={600}>{formatUSD(summary.buffer.target)}</Typography>
            </Box>
          )}
        </Stack>
        <Stack direction="row" spacing={1} alignItems="center">
          {suggestion && suggestion.kind !== 'none' && (
            <Tooltip title={suggestion.rationale || ''}>
              <span>
                <Button size="small" variant="contained" color="primary" disabled={!client} onClick={act}>{suggestion.label}</Button>
              </span>
            </Tooltip>
          )}
          <IconButton size="small" onClick={refresh} disabled={loading}><RefreshIcon fontSize="small" /></IconButton>
        </Stack>
      </Stack>
      {error && <Typography variant="caption" color="error" sx={{ mt:1, display:'block' }}>{error}</Typography>}
      {summary && (
        <Stack direction="row" spacing={1} mt={1} flexWrap="wrap" alignItems="center">
          <Typography variant="caption" sx={{opacity:0.6, mr:1}}>Drift</Typography>
          <Chip size="small" variant="outlined" label={`max ${summary.drift.maxDriftBps}bps`} />
          <Chip size="small" variant="outlined" label={`avg ${summary.drift.avgDriftBps}bps`} />
          <Chip size="small" variant="outlined" label={`targets: ${summary.activeTargetSource}`} />
          <Chip size="small" variant="outlined" label={`24h deposits: ${summary.deposits24hPi.toFixed(2)} Pi`} />
          <Chip size="small" variant="outlined" label={`24h withdraws: ${summary.withdraws24hPi.toFixed(2)} Pi`} />
          <Chip size="small" variant="outlined" label={`net: ${summary.net24hPi.toFixed(2)} Pi`} color={summary.net24hPi>=0 ? 'success' : 'warning'} />
        </Stack>
      )}
      <Box sx={{ mt: 1.5 }}>
        <Button href="/admin/alloc" size="small" variant="text">Open Allocation Planner</Button>
      </Box>
    </Paper>
  );
}
