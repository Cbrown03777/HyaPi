"use client";
import { Card, CardContent, Box, Typography, Chip, Button, Stack, Tooltip } from '@mui/material';

export type Proposal = {
  proposal_id: string;
  title: string;
  description?: string|null;
  status: 'active'|'finalized'|'executed'|string;
  start_ts?: string;
  end_ts?: string;
  allocation?: Record<string, number>;
  for_power?: string; against_power?: string; abstain_power?: string;
  tally?: { for_power?: string; against_power?: string; abstain_power?: string };
};

type Support = 'for'|'against'|'abstain';

function e18ToNumStr(x?: string) {
  if (!x) return '0';
  try {
    const n = BigInt(x);
    const whole = n / 10n**18n;
    const frac = (n % 10n**18n).toString().padStart(18,'0').slice(0,4);
    return frac === '0000' ? whole.toString() : `${whole}.${frac}`.replace(/\.?0+$/,'');
  } catch {
    const f = Number(x); if (!Number.isFinite(f)) return '0';
    return (f/1e18).toFixed(4).replace(/\.?0+$/,'');
  }
}

function percent(a: bigint, total: bigint) {
  if (total === 0n) return 0;
  const p = Number((a * 10000n) / total) / 100;
  return Math.max(0, Math.min(100, p));
}

function StatusPill({ status }: { status: Proposal['status'] }) {
  const colorMap: Record<string, { label: string; color: 'primary' | 'warning' | 'success' | 'default' }> = {
    active: { label: 'active', color: 'primary' },
    finalized: { label: 'finalized', color: 'warning' },
    executed: { label: 'executed', color: 'success' },
  };
  const meta = colorMap[status] ?? { label: status, color: 'default' as const };
  return <Chip size="small" color={meta.color} label={meta.label} sx={{ textTransform: 'capitalize' }} />;
}

export default function ProposalCard({ p, onVote, onFinalize, onExecute, busy }: {
  p: Proposal;
  onVote: (id: string, support: Support)=>void;
  onFinalize?: (id: string)=>void;
  onExecute?:  (id: string)=>void;
  busy?: boolean;
}) {
  const forP = p.for_power ?? p.tally?.for_power ?? '0';
  const agP  = p.against_power ?? p.tally?.against_power ?? '0';
  const abP  = p.abstain_power ?? p.tally?.abstain_power ?? '0';

  let a=0n, b=0n, c=0n, total=0n;
  try {
    a = BigInt(forP||'0'); b = BigInt(agP||'0'); c = BigInt(abP||'0');
    total = a+b+c;
  } catch{}

  const pctFor = percent(a,total);
  const pctAg  = percent(b,total);
  const pctAb  = percent(c,total);

  return (
    <Card variant="outlined" sx={{ borderRadius: 3, transition: 'box-shadow .2s', '&:hover': { boxShadow: 6 } }}>
      <CardContent sx={{ pb: 2 }}>
        <Stack direction="row" alignItems="flex-start" justifyContent="space-between" spacing={2}>
          <Box flex={1} minWidth={0}>
            <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ mb: p.description ? 0.5 : 0 }}>
              {p.title}
            </Typography>
            {p.description && (
              <Typography variant="body2" color="text.secondary" sx={{ wordBreak: 'break-word' }}>
                {p.description}
              </Typography>
            )}
          </Box>
          <StatusPill status={p.status} />
        </Stack>

        {p.allocation && (
          <Stack direction="row" flexWrap="wrap" spacing={1} useFlexGap sx={{ mt: 2 }}>
            {Object.entries(p.allocation).map(([k, v], idx) => (
              <Chip
                key={k}
                size="small"
                label={`${k.toUpperCase()}: ${(v * 100).toFixed(0)}%`}
                variant="outlined"
                sx={{
                  fontSize: 11,
                  borderColor: 'divider',
                  bgcolor: 'action.hover',
                }}
              />
            ))}
          </Stack>
        )}

        <Box sx={{ mt: 3 }}>
          <Tooltip title={`For ${pctFor.toFixed(1)}% / Against ${pctAg.toFixed(1)}% / Abstain ${pctAb.toFixed(1)}%`} placement="top" arrow>
            <Box
              sx={{
                height: 8,
                width: '100%',
                borderRadius: 4,
                overflow: 'hidden',
                display: 'flex',
                bgcolor: 'background.default',
                boxShadow: (t) => `inset 0 0 0 1px ${t.palette.divider}`,
              }}
              aria-label="Vote distribution bar"
              role="img"
            >
              <Box sx={{ flex: pctFor || 0, bgcolor: 'success.main' }} />
              <Box sx={{ flex: pctAg || 0, bgcolor: 'error.main' }} />
              <Box sx={{ flex: pctAb || 0, bgcolor: 'warning.main' }} />
            </Box>
          </Tooltip>
          <Stack direction="row" spacing={2} sx={{ mt: 1 }} divider={<Box sx={{ width: 1, opacity: 0 }} />}> {/* spacer */}
            <Typography variant="caption" color="text.secondary">
              For: <Box component="span" fontWeight={600}>{e18ToNumStr(forP)}</Box> ({pctFor.toFixed(1)}%)
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Against: <Box component="span" fontWeight={600}>{e18ToNumStr(agP)}</Box> ({pctAg.toFixed(1)}%)
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Abstain: <Box component="span" fontWeight={600}>{e18ToNumStr(abP)}</Box> ({pctAb.toFixed(1)}%)
            </Typography>
          </Stack>
        </Box>

        <Stack direction="row" flexWrap="wrap" spacing={1} sx={{ mt: 3 }}>
          <Button size="small" disabled={!!busy} onClick={() => onVote(p.proposal_id, 'for')} color="success" variant="contained">Vote For</Button>
          <Button size="small" disabled={!!busy} onClick={() => onVote(p.proposal_id, 'against')} color="error" variant="contained">Against</Button>
          <Button size="small" disabled={!!busy} onClick={() => onVote(p.proposal_id, 'abstain')} color="warning" variant="contained">Abstain</Button>
          {onFinalize && (
            <Button size="small" disabled={!!busy} onClick={() => onFinalize(p.proposal_id)} variant="outlined" sx={{ ml: 'auto' }}>Finalize</Button>
          )}
          {onExecute && (
            <Button size="small" disabled={!!busy} onClick={() => onExecute(p.proposal_id)} variant="outlined">Execute</Button>
          )}
        </Stack>
      </CardContent>
    </Card>
  );
}
