"use client";
import { Card, CardContent, Stack, Typography, Chip, Box } from '@mui/material';

type Props = {
  title: string; summary: string; status: string;
  endTimeISO: string; startTimeISO: string;
  yes: number; no: number; abstain: number;
};

function statusColor(s: string): 'default'|'primary'|'success'|'error'|'warning' {
  switch (s) {
    case 'Open': return 'primary';
    case 'Passed': return 'success';
    case 'Rejected': return 'error';
    case 'Failed': return 'warning';
    case 'Canceled': return 'default';
    case 'Closed': return 'default';
    default: return 'default';
  }
}

export default function ProposalCard({ title, summary, status, startTimeISO, endTimeISO, yes, no, abstain }: Props) {
  const total = Math.max(0, (yes||0) + (no||0) + (abstain||0));
  const yesPct = total > 0 ? (yes / total) * 100 : 0;
  const noPct = total > 0 ? (no / total) * 100 : 0;
  const abstainPct = total > 0 ? (abstain / total) * 100 : 0;
  const endDate = new Date(endTimeISO);
  const open = status === 'Open';
  return (
    <Card variant="outlined" sx={{ height: '100%' }}>
      <CardContent>
        <Stack spacing={1.2} height="100%">
          <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
            <Typography variant="subtitle1" fontWeight={600} sx={{ pr: 1, lineHeight: 1.2 }}>{title}</Typography>
            <Chip size="small" color={statusColor(status)} label={status} sx={{ textTransform:'capitalize' }} />
          </Stack>
          {summary && (
            <Typography variant="body2" color="text.secondary" sx={{ display:'-webkit-box', WebkitLineClamp:2, WebkitBoxOrient:'vertical', overflow:'hidden' }}>
              {summary}
            </Typography>
          )}
          <Box sx={{ mt: 0.5 }}>
            <Box aria-label="Vote distribution" sx={{ display:'flex', height: 10, width:'100%', overflow:'hidden', borderRadius: 5, outline: '1px solid rgba(255,255,255,0.08)' }}>
              <Box sx={{ width: `${yesPct}%`, backgroundColor: 'success.main' }} />
              <Box sx={{ width: `${noPct}%`, backgroundColor: 'error.main' }} />
              <Box sx={{ width: `${abstainPct}%`, backgroundColor: 'warning.main' }} />
            </Box>
            <Stack direction="row" justifyContent="space-between" sx={{ fontSize: 12, opacity: 0.85, mt: 0.5 }}>
              <span>Yes: {yes.toFixed(2)} ({yesPct.toFixed(1)}%)</span>
              <span>No: {no.toFixed(2)} ({noPct.toFixed(1)}%)</span>
              <span>Abstain: {abstain.toFixed(2)} ({abstainPct.toFixed(1)}%)</span>
            </Stack>
          </Box>
          <Box sx={{ mt: 'auto', pt: 1 }}>
            <Typography variant="caption" color="text.secondary">
              {open ? 'Closes on ' : 'Closed on '}{endDate.toLocaleDateString()}
            </Typography>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
}
