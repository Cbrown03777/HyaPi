"use client";
import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { GOV_API_BASE } from '@hyapi/shared';
import {
  Box,
  TextField,
  Typography,
  Slider,
  Stack,
  Card,
  CardContent,
  CardHeader,
  Button,
  Chip,
  Alert,
  IconButton,
  Tooltip,
  CircularProgress
} from '@mui/material';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import EqualizerIcon from '@mui/icons-material/Equalizer';

async function getBearer(): Promise<string> {
  try {
    const { signInWithPi } = await import('@/lib/pi');
    return await signInWithPi();
  } catch {
    return 'dev pi_dev_address:1';
  }
}

type AllocRow = { key: string; weight: number };

export default function CreateProposalPage() {
  const router = useRouter();
  const [bearer, setBearer] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [rows, setRows] = useState<AllocRow[]>([]);
  const [availableKeys, setAvailableKeys] = useState<string[]>([]);
  const [loadingKeys, setLoadingKeys] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  // Load keys and initialize first 3
  useEffect(() => {
    (async () => {
      try {
        const r = await fetch(`${GOV_API_BASE}/v1/alloc/keys`, { cache: 'no-store' });
        const j = await r.json().catch(() => null);
        const keys: string[] = Array.isArray(j?.data) ? j.data : [];
        const uniq = Array.from(new Set(keys.length ? keys : ['aave:USDT', 'justlend:USDT', 'stride:stATOM']));
        setAvailableKeys(uniq);
        if (!rows.length) {
          const pick = uniq.slice(0, 3);
          const w = 1 / Math.max(1, pick.length);
          setRows(pick.map(k => ({ key: k, weight: w })));
        }
      } catch {
        // silent
      } finally {
        setLoadingKeys(false);
      }
    })();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { getBearer().then(setBearer); }, []);

  const sum = useMemo(() => rows.reduce((a, b) => a + (b.weight || 0), 0), [rows]);
  const tolerance = 1e-6;
  const sumOK = Math.abs(sum - 1) <= tolerance;
  const titleOK = title.trim().length >= 3 && title.trim().length <= 140;
  const canSubmit = bearer && titleOK && sumOK && !submitting;

  function updateWeight(i: number, w: number) {
    setRows(prev => prev.map((r, idx) => idx === i ? { ...r, weight: w } : r));
  }
  function updateKey(i: number, key: string) {
    setRows(prev => prev.map((r, idx) => idx === i ? { ...r, key } : r));
  }
  function removeRow(i: number) {
    setRows(prev => prev.filter((_, idx) => idx !== i));
  }
  function equalize() {
    if (!rows.length) return;
    const w = 1 / rows.length;
    setRows(prev => prev.map(r => ({ ...r, weight: w })));
  }
  function addRow() {
    const nextKey = availableKeys.find(k => !rows.some(r => r.key === k));
    if (!nextKey) return;
    setRows(prev => [...prev, { key: nextKey, weight: 0 }]);
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!canSubmit) return;
    setError(null); setOkMsg(null); setSubmitting(true);
    try {
      const idk = (globalThis.crypto?.randomUUID?.() || Math.random().toString(36).slice(2));
      const res = await fetch(`${GOV_API_BASE}/v1/gov/proposals`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${bearer}`,
          'Idempotency-Key': idk as string,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          title: title.trim(),
          description: description.trim() || undefined,
          allocation: rows.map(r => ({ key: r.key, weight: r.weight }))
        })
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok || json?.success === false) {
        throw new Error(json?.error?.message || `HTTP ${res.status}`);
      }
      setOkMsg('Proposal created! Redirecting…');
      setTimeout(() => { router.push('/governance'); router.refresh(); }, 800);
    } catch (err: any) {
      setError(err?.message || 'Failed to create proposal');
    } finally { setSubmitting(false); }
  }

  return (
    <Box maxWidth={900} mx="auto" px={{ xs: 2, md: 4 }} py={4} component="form" onSubmit={onSubmit}>
      <Typography variant="h5" fontWeight={600} gutterBottom>Create Allocation Proposal</Typography>
      <Stack spacing={3}>
        <Card variant="outlined">
          <CardContent>
            <Stack spacing={2}>
              <TextField
                label="Title"
                value={title}
                onChange={e => setTitle(e.target.value)}
                error={!titleOK && !!title}
                helperText={!titleOK && !!title ? '3–140 characters.' : ' '} // keep space for layout
                fullWidth
              />
              <TextField
                label="Description"
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Why this allocation improves yield/risk…"
                multiline
                minRows={3}
                fullWidth
              />
            </Stack>
          </CardContent>
        </Card>

        <Card variant="outlined">
          <CardHeader
            title={
              <Stack direction="row" alignItems="center" spacing={1}>
                <Typography variant="subtitle1" fontWeight={600}>Allocation Weights</Typography>
                <Chip size="small" label={`Sum ${sum.toFixed(4)}`} color={sumOK ? 'success' : 'warning'} variant={sumOK ? 'filled' : 'outlined'} aria-label={`Weights sum ${sum.toFixed(4)}`} />
              </Stack>
            }
            action={
              <Stack direction="row" spacing={1}>
                <Tooltip title="Equalize weights"><IconButton size="small" onClick={equalize} aria-label="Equalize weights"><EqualizerIcon fontSize="small" /></IconButton></Tooltip>
              </Stack>
            }
          />
          <CardContent>
            <Stack spacing={2}>
              {loadingKeys && <Box display="flex" alignItems="center" gap={1}><CircularProgress size={16} /><Typography variant="caption">Loading keys…</Typography></Box>}
              {!loadingKeys && !rows.length && <Alert severity="info" variant="outlined">No targets yet.</Alert>}
              {rows.map((row, i) => {
                const selectable = availableKeys.filter(k => !rows.some((r, idx) => idx !== i && r.key === k) || k === row.key);
                return (
                  <Box key={i} border="1px solid" borderColor="divider" p={1.5} borderRadius={1}>
                    <Stack spacing={1}>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <TextField
                          select
                          label="Target"
                          value={row.key}
                          onChange={e => updateKey(i, e.target.value)}
                          SelectProps={{ native: true }}
                          sx={{ minWidth: 200 }}
                        >
                          <option value="">Select…</option>
                          {selectable.map(k => <option key={k} value={k}>{k}</option>)}
                        </TextField>
                        <TextField
                          label="Weight"
                          type="number"
                          value={row.weight.toFixed(4)}
                          inputProps={{ step: 0.0001, min: 0, max: 1 }}
                          onChange={e => updateWeight(i, Math.min(1, Math.max(0, Number(e.target.value) || 0)))}
                          sx={{ width: 120 }}
                          error={row.weight < 0 || row.weight > 1}
                        />
                        {rows.length > 1 && (
                          <Tooltip title="Remove row">
                            <IconButton size="small" onClick={() => removeRow(i)} aria-label="Remove target"><DeleteOutlineIcon fontSize="small" /></IconButton>
                          </Tooltip>
                        )}
                      </Stack>
                      <Slider
                        size="small"
                        value={row.weight}
                        onChange={(_, v) => typeof v === 'number' && updateWeight(i, v)}
                        min={0}
                        max={1}
                        step={0.005}
                        valueLabelDisplay="auto"
                        aria-label={`Weight slider for ${row.key || 'target'} row ${i+1}`}
                      />
                    </Stack>
                  </Box>
                );
              })}
              <Box>
                <Button size="small" variant="outlined" onClick={addRow} disabled={availableKeys.length <= rows.length}>Add Target</Button>
              </Box>
              {!sumOK && (
                <Typography variant="caption" color="warning.main">Weights must sum to 1.0 (±{tolerance}). Adjust sliders or use Equalize.</Typography>
              )}
            </Stack>
          </CardContent>
        </Card>

        {error && <Alert severity="error" variant="outlined">{error}</Alert>}
        {okMsg && <Alert severity="success" variant="outlined">{okMsg}</Alert>}

        <Box>
          <Button type="submit" variant="contained" disabled={!canSubmit} aria-disabled={!canSubmit} aria-label="Create allocation proposal">
            {submitting ? 'Creating…' : 'Create Proposal'}
          </Button>
          {!bearer && <Typography variant="caption" sx={{ display: 'block', mt: 1, opacity: 0.7 }}>Using dev token fallback. Ensure Pi sign‑in is set up.</Typography>}
        </Box>
      </Stack>
    </Box>
  );
}
