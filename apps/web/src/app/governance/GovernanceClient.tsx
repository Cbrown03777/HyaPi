"use client";
import { useEffect, useMemo, useState } from 'react';
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
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import { useBoostConfig, useBoostMe, useCreateLock } from '@/hooks/useGovBoost';
import TextField from '@mui/material/TextField';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import { useGovProposals } from '@/hooks/useGovProposals';
import ProposalCard from '@/components/gov/ProposalCard';
import { GOV_API_BASE } from '@hyapi/shared';

// colors kept in case allocation bar is reintroduced later
const allocColors: Record<string, string> = { aave:'#B6509E', justlend:'#4F9CFD', stride:'#6DD3B7', lido:'#00A3FF', rocket:'#FF8A00' };

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

// Allocation bar removed in this iteration (list cards contain their own progress UI)

export default function GovernanceClient() {
  const [status, setStatus] = useState<'All'|'Open'|'Closed'>('All');
  const [quorum, setQuorum] = useState<string | null>(null);
  const boostCfg = useBoostConfig();
  const boostMe = useBoostMe();
  const createLock = useCreateLock();
  const [lockWeeks, setLockWeeks] = useState<26|52|104|0>(0);
  const [txUrl, setTxUrl] = useState('');
  const [open, setOpen] = useState(false);

  const proposalsQuery = useGovProposals({ status, pageSize: 20 });

  const loading = proposalsQuery.isLoading || proposalsQuery.isFetching && !proposalsQuery.data;
  const error = proposalsQuery.error as any;
  const items = proposalsQuery.items as any[];

  // Fetch quorum config (unchanged from previous)
  // Defer to client; keep it simple and avoid SSR
  useEffect(() => {
    (async () => {
      try {
        const cfg = await fetch(`${GOV_API_BASE}/v1/gov/config`).then(r=> r.ok ? r.json(): null).catch(()=>null);
        const q = cfg?.data?.quorumVotes ?? cfg?.quorumVotes;
        if (q != null) setQuorum(formatBig(q));
      } catch {}
    })();
  }, []);

  const header = useMemo(() => {
    const boostPct = boostMe.data?.data?.active ? (boostMe.data?.data?.boostPct || 0) : 0;
    return (
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 1 }}>
        <ToggleButtonGroup size="small" exclusive value={status} onChange={(_,v)=> v && setStatus(v)}>
          <ToggleButton value="All">All</ToggleButton>
          <ToggleButton value="Open">Open</ToggleButton>
          <ToggleButton value="Closed">Closed</ToggleButton>
        </ToggleButtonGroup>
        {boostPct > 0 && (
          <Chip size="small" color="secondary" label={`Boost +${Math.round(boostPct*100)}%`} />
        )}
      </Stack>
    );
  }, [status, boostMe.data?.data?.active, boostMe.data?.data?.boostPct]);

  const content = useMemo(() => {
    if (loading) {
      return (
        <Stack spacing={2}>
          {Array.from({ length: 3 }).map((_,i)=>(<Skeleton key={i} variant="rounded" height={120} />))}
        </Stack>
      );
    }
    if (error) return <Alert severity="error" variant="outlined">{String(error?.message||error)}</Alert>;
    if (!items.length) return <Alert severity="info" variant="outlined">No proposals yet. Be the first to create one.</Alert>;
    return (
      <>
        <Box display="grid" gridTemplateColumns={{ xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr' }} gap={2}>
          {items.map((p: any) => (
            <ProposalCard
              key={p.id}
              title={p.title}
              summary={p.summary||''}
              status={p.status}
              startTimeISO={p.startTimeISO||p.start_ts||new Date().toISOString()}
              endTimeISO={p.endTimeISO||p.end_ts||new Date().toISOString()}
              yes={Number(p.yes ?? p.for_votes ?? 0)}
              no={Number(p.no ?? p.against_votes ?? 0)}
              abstain={Number(p.abstain ?? p.abstain_votes ?? 0)}
            />
          ))}
        </Box>
        <Box display="flex" justifyContent="center" sx={{ mt: 2 }}>
          <Button variant="outlined" disabled={!proposalsQuery.hasNextPage || proposalsQuery.isFetchingNextPage} onClick={()=> proposalsQuery.fetchNextPage()}>
            {proposalsQuery.isFetchingNextPage ? 'Loading…' : (proposalsQuery.hasNextPage ? 'Load more' : 'No more')}
          </Button>
        </Box>
      </>
    );
  }, [loading, error, items, proposalsQuery.hasNextPage, proposalsQuery.isFetchingNextPage]);

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
  {header}
  {content}
      </Box>
      <Box width={{ xs: '100%', lg: 320 }} flexShrink={0} display="flex" flexDirection="column" gap={3}>
        {boostCard}
        <Card variant="outlined">
          <CardContent>
            <Stack spacing={2}>
              <Button fullWidth startIcon={<AddCircleOutlineIcon />} variant="contained" component={Link} href="/create" aria-label="Create new allocation proposal">Create Proposal</Button>
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
