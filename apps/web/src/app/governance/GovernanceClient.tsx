"use client";
import { useEffect, useMemo, useState } from 'react';
import { GOV_API_BASE } from '@hyapi/shared';
import Link from 'next/link';
import {
  Box,
  Card,
  CardHeader,
  CardContent,
  Typography,
  Chip,
  Stack,
  Button,
  Alert,
  Skeleton,
  Divider,
  Tooltip
} from '@mui/material';
import LaunchIcon from '@mui/icons-material/Launch';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import { useBoostConfig, useBoostMe, useCreateLock } from '@/hooks/useGovBoost';
import TextField from '@mui/material/TextField';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';

export type Proposal = {
  id: string | number;
  title: string;
  status: string;
  created_ts?: number;
  for_votes?: string | number;
  against_votes?: string | number;
  abstain_votes?: string | number;
  allocation?: Array<{ key: string; weight: number }>;
};

const allocColors: Record<string, string> = {
  aave: '#B6509E',
  justlend: '#4F9CFD',
  stride: '#6DD3B7',
  lido: '#00A3FF',
  rocket: '#FF8A00',
};

function formatBig(v: any): string {
  if (v === null || v === undefined) return '0';
  const n = typeof v === 'bigint' ? v : (typeof v === 'string' && /^\d+$/.test(v) ? BigInt(v) : BigInt(Math.max(0, Number(v) || 0)));
  const abs = n < 0n ? -n : n;
  if (abs >= 1_000_000_000_000n) return (Number(n) / 1e12).toFixed(2) + 'T';
  if (abs >= 1_000_000_000n) return (Number(n) / 1e9).toFixed(2) + 'B';
  if (abs >= 1_000_000n) return (Number(n) / 1e6).toFixed(2) + 'M';
  if (abs >= 10_000n) return (Number(n) / 1e3).toFixed(1) + 'k';
  return n.toString();
}

function statusChipColor(status: string) {
  switch (status) {
    case 'active': return 'success';
    case 'finalized': return 'warning';
    case 'executed': return 'default';
    case 'pending': return 'info';
    default: return 'default';
  }
}

function AllocationBar({ allocation }: { allocation?: Proposal['allocation'] }) {
  if (!allocation || !allocation.length) return <Typography variant="caption" sx={{ opacity: 0.6 }}>No allocation changes</Typography>;
  const total = allocation.reduce((a, b) => a + (b.weight || 0), 0) || 1;
  return (
    <Box aria-label="Allocation target weights" sx={{ display: 'flex', width: '100%', height: 10, borderRadius: 5, overflow: 'hidden', outline: '1px solid rgba(255,255,255,0.08)' }}>
      {allocation.map(seg => {
        const prefix: string = (seg.key || '').split(':')[0] || 'other';
        const color = allocColors[prefix] || '#444';
        const pct = (seg.weight / total) * 100;
        return (
          <Tooltip key={seg.key} title={`${seg.key} ${(seg.weight * 100).toFixed(1)}%`} arrow placement="top">
            <Box
              component="span"
              sx={{ flex: `${pct} 0 0`, background: color, display: 'inline-block' }}
              aria-label={`${seg.key} ${(seg.weight * 100).toFixed(1)} percent`}
            />
          </Tooltip>
        );
      })}
    </Box>
  );
}

export default function GovernanceClient() {
  const [loading, setLoading] = useState(true);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [quorum, setQuorum] = useState<string | null>(null);
  const boostCfg = useBoostConfig();
  const boostMe = useBoostMe();
  const createLock = useCreateLock();
  const [lockWeeks, setLockWeeks] = useState<26|52|104|0>(0);
  const [txUrl, setTxUrl] = useState('');
  const [open, setOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        setLoading(true);
        setError(null);
        const res = await fetch(`${GOV_API_BASE}/v1/gov/proposals`, { cache: 'no-store' }).catch(()=>null);
        let list: Proposal[] = [];
        if (res && res.ok) {
          const json = await res.json().catch(()=>null);
          const raw = json?.data;
          if (Array.isArray(raw)) {
            list = raw.map((p: any) => ({
              id: p.id ?? p.proposal_id ?? Math.random().toString(36).slice(2),
              title: p.title || p.name || 'Untitled proposal',
              status: (p.status || p.state || 'active').toLowerCase(),
              created_ts: p.created_ts || p.createdAt || undefined,
              for_votes: p.for_votes ?? p.forVotes ?? '0',
              against_votes: p.against_votes ?? p.againstVotes ?? '0',
              abstain_votes: p.abstain_votes ?? p.abstainVotes ?? '0',
              allocation: Array.isArray(p.allocation) ? p.allocation : (Array.isArray(p.target_allocation) ? p.target_allocation : []),
            }));
          }
        }
        try {
          const cfg = await fetch(`${GOV_API_BASE}/v1/gov/config`).then(r=> r.ok ? r.json(): null).catch(()=>null);
          const q = cfg?.data?.quorumVotes ?? cfg?.quorumVotes;
          if (q != null) setQuorum(formatBig(q));
        } catch {}
        if (!cancelled) setProposals(list);
      } catch (e: any) {
        if (!cancelled) setError(e.message || 'Failed to load proposals');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, []);

  const content = useMemo(() => {
    if (loading) {
      return (
        <Stack spacing={2}>
          {Array.from({ length: 3 }).map((_,i)=>(<Skeleton key={i} variant="rounded" height={120} />))}
        </Stack>
      );
    }
    if (error) return <Alert severity="error" variant="outlined">{error}</Alert>;
    if (!proposals.length) return <Alert severity="info" variant="outlined">No proposals yet. Be the first to create one.</Alert>;
    const boostPct = boostMe.data?.data?.active ? (boostMe.data?.data?.boostPct || 0) : 0;
    return (
      <Stack spacing={2}>
        {proposals.map(p => {
          // Show on-chain/community tallies as-is; boost applies to YOUR vote weight only.
          const forV = formatBig(p.for_votes);
          const againstV = formatBig(p.against_votes);
          const abstainV = formatBig(p.abstain_votes);
          return (
            <Card key={p.id} variant="outlined" aria-labelledby={`proposal-${p.id}-title`} sx={{ position: 'relative' }}>
              <CardHeader
                titleTypographyProps={{ variant: 'subtitle1', fontWeight: 600 }}
                title={<span id={`proposal-${p.id}-title`}>{p.title}</span>}
                action={<Stack direction="row" spacing={1} alignItems="center">
                  {boostPct > 0 && (
                    <Chip size="small" color="secondary" label={`Boost +${Math.round(boostPct*100)}%`} aria-label={`Your voting power is boosted by ${Math.round(boostPct*100)} percent`} />
                  )}
                  <Chip size="small" label={p.status} color={statusChipColor(p.status) as any} sx={{ textTransform: 'capitalize' }} aria-label={`Status ${p.status}`} />
                </Stack>}
              />
              <CardContent sx={{ pt: 0 }}>
                <Stack spacing={1.2}>
                  <Box>
                    <AllocationBar allocation={p.allocation} />
                  </Box>
                  <Stack direction="row" spacing={2} flexWrap="wrap" fontSize={12} aria-label="Vote tallies">
                    <Box><Typography component="span" variant="caption" color="success.main">For </Typography><strong>{forV}</strong></Box>
                    <Box><Typography component="span" variant="caption" color="error.main">Against </Typography><strong>{againstV}</strong></Box>
                    <Box><Typography component="span" variant="caption" color="text.secondary">Abstain </Typography><strong>{abstainV}</strong></Box>
                    {quorum && <Box><Typography component="span" variant="caption" color="text.secondary">Quorum </Typography><strong>{quorum}</strong></Box>}
                  </Stack>
                  <Divider flexItem light sx={{ my: 0.5 }} />
                  <Box display="flex" justifyContent="flex-end">
                    <Button size="small" endIcon={<LaunchIcon fontSize="inherit" />} component={Link} href={`/governance/${p.id}`} aria-label={`Open proposal ${p.title}`}>
                      Open
                    </Button>
                  </Box>
                </Stack>
              </CardContent>
            </Card>
          );
        })}
      </Stack>
    );
  }, [loading, error, proposals, quorum]);

  const boostCard = (
    <Card variant="outlined">
      <CardHeader title={<Typography variant="subtitle2" fontWeight={600}>Boosted Governance</Typography>} />
      <CardContent sx={{ pt: 0 }}>
        <Stack spacing={2}>
          <Typography variant="caption" sx={{ opacity: 0.75 }}>
            Boost increases your voting power only; yield/APY is unaffected.
          </Typography>
          <Stack direction="row" spacing={1} flexWrap="wrap">
            {[26,52,104].map((w) => (
              <Button key={w} size="small" variant={lockWeeks===w? 'contained':'outlined'} onClick={()=>setLockWeeks(w as 26|52|104)}>
                {w} weeks
              </Button>
            ))}
          </Stack>
          <Stack direction="row" alignItems="center" spacing={1}>
            <Typography variant="body2">Your current boost:</Typography>
            <Chip size="small" label={boostMe.data?.data?.active ? `+${Math.round((boostMe.data?.data?.boostPct||0)*100)}%` : 'None'} />
            {boostMe.data?.data?.active && boostMe.data?.data?.unlockAt && (
              <Typography variant="caption" sx={{ opacity: 0.7 }}>until {new Date(boostMe.data.data.unlockAt).toLocaleDateString()}</Typography>
            )}
          </Stack>
          <Stack direction="row" spacing={1}>
            <Button size="small" variant="contained" disabled={!lockWeeks} onClick={()=> setOpen(true)}>Activate lock</Button>
            <Button size="small" variant="outlined" onClick={()=> boostMe.refetch()}>Refresh</Button>
            <Box flex={1} />
            <Button size="small" variant="text" onClick={()=> window.open('/docs/boost', '_blank')}>Learn more</Button>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );

  return (
    <Box display="flex" flexDirection={{ xs: 'column', lg: 'row' }} gap={4} alignItems="flex-start">
      <Box flex={1} minWidth={0}>
        <Typography variant="h5" fontWeight={600} gutterBottom>Governance</Typography>
        <Typography variant="body2" sx={{ opacity: 0.65, mb: 3, maxWidth: 720 }}>
          Propose, review and vote on allocation or protocol parameter changes.
        </Typography>
        {content}
      </Box>
      <Box width={{ xs: '100%', lg: 320 }} flexShrink={0} display="flex" flexDirection="column" gap={3}>
        {boostCard}
        <Card variant="outlined">
          <CardContent>
            <Stack spacing={2}>
              <Button
                fullWidth
                startIcon={<AddCircleOutlineIcon />}
                variant="contained"
                component={Link}
                href="/create"
                aria-label="Create new allocation proposal"
              >
                Create Proposal
              </Button>
              <Alert severity="info" variant="outlined" sx={{ fontSize: 13 }} aria-live="polite">
                {quorum ? (
                  <>Quorum: <strong>{quorum}</strong> for-votes required to finalize. Allocation bar shows target weights per venue.</>
                ) : (
                  <>Quorum configuration loading… Allocation bar segments visualize proposed target weights.</>
                )}
              </Alert>
            </Stack>
          </CardContent>
        </Card>
        <Card variant="outlined">
          <CardHeader title={<Typography variant="subtitle2" fontWeight={600}>Help</Typography>} />
          <CardContent sx={{ pt: 0 }}>
            <Typography variant="caption" component="div" sx={{ lineHeight: 1.4 }}>
              Each segment represents a venue/chain target weight. Vote tallies display compact numbers. A proposal moves from Active → Finalized → Executed.
            </Typography>
          </CardContent>
        </Card>
      </Box>
      <Dialog open={open} onClose={()=>setOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Activate governance lock</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2}>
            <Typography variant="body2">Lock term: <b>{lockWeeks} weeks</b></Typography>
            <TextField label="Optional Tx URL" placeholder="https://..." fullWidth value={txUrl} onChange={(e)=> setTxUrl(e.target.value)} />
            <Typography variant="caption" sx={{ opacity: 0.7 }}>This reference helps trace your on-chain or internal action.</Typography>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button variant="outlined" onClick={()=> setOpen(false)}>Cancel</Button>
          <Button variant="contained" disabled={!lockWeeks || createLock.loading} onClick={async ()=>{
            try {
              await createLock.mutate(lockWeeks as 26|52|104, txUrl || undefined);
              setOpen(false); setTxUrl('');
              await boostMe.refetch();
            } catch {}
          }}>Confirm</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
