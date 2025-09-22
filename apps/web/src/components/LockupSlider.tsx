"use client";
import React, { useId } from 'react';
import { Card, CardContent, Typography, Slider, Box, Stack, Tooltip } from '@mui/material';

// Updated tiers: slider only chooses lock duration; share of base APY now applied in stake page logic.
// Tiers correspond to: 0w=50%, 3w=60%, 26w(≈6mo)=70%, 52w=80%, 104w=90%.
type Tier = { weeks: number; label: string }
const TIERS: Tier[] = [
  { weeks: 0,   label: 'No lock' },
  { weeks: 26,  label: '6 mo'   },
  { weeks: 52,  label: '12 mo'  },
  { weeks: 104, label: '24 mo'  },
];

type Props = {
  valueWeeks: number;
  onChange: (weeks:number)=>void;
  baseApy?: number; // decimal (e.g. 0.15 for 15%) – gross or net depending on caller toggle
  lockCurve?: Array<{ weeks:number; share:number }>; // server-provided share schedule
}

export function LockupSlider({ valueWeeks, onChange, baseApy = 0, lockCurve }: Props) {
  const id = useId();
  const found = TIERS.findIndex(t => t.weeks === valueWeeks);
  const idx = found >= 0 ? found : 0;
  const active = TIERS[idx] ?? TIERS[0];

  const resolveShare = (w:number) => {
    if (lockCurve && lockCurve.length) {
      let s = lockCurve[0]?.share ?? 0;
      for (const pt of lockCurve) { if (w >= pt.weeks) s = pt.share; else break; }
      return s;
    }
    if (w >= 104) return 0.90; if (w >= 52) return 0.80; if (w >= 26) return 0.70; if (w >= 3) return 0.60; return 0.50;
  };
  const currentShare = resolveShare(active?.weeks ?? 0);
  const currentApyPct = baseApy > 0 ? (baseApy * currentShare * 100).toFixed(2) + '%' : '—';

  return (
    <Card variant="outlined" sx={{ p:1.5 }}>
      <CardContent sx={{ p:0, '&:last-child':{ pb:0 } }}>
        <Stack spacing={1.5}>
          <Stack direction="row" alignItems="center" justifyContent="space-between">
            <Typography variant="body2" fontWeight={600} component="label" htmlFor={id}>Lockup Duration</Typography>
            <Tooltip title="Derived from base APY and lock share" arrow>
              <Typography variant="caption" sx={{ opacity:0.75 }}>APY: <b>{currentApyPct}</b></Typography>
            </Tooltip>
          </Stack>
          <Slider
            id={id}
            value={idx < 0 ? 0 : idx}
            min={0}
            max={TIERS.length-1}
            step={1}
            onChange={(_,v)=>{
              const i = Math.min(TIERS.length - 1, Math.max(0, Number(v)));
              const t = TIERS[i];
              if (t) onChange(t.weeks);
            }}
            valueLabelDisplay="off"
            aria-valuetext={`${active?.label ?? ''} APY ${currentApyPct}`}
          />
          <Box display="flex" justifyContent="space-between" px={0.5}>
            {TIERS.map(t => <Typography key={t.weeks} variant="caption" sx={{ opacity:0.65 }}>{t.label}</Typography>)}
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
}
