"use client";
import React, { useId } from 'react';
import { Box, Card, CardContent, Stack, TextField, Slider, Typography } from '@mui/material';

type Props = {
  label: string;
  value: number;
  onChange: (v:number)=>void;
  min?: number;
  max?: number;
  step?: number;
  balance?: number;
};

export function NumberWithSlider({ label, value, onChange, min=0, max=100, step=0.01, balance }: Props) {
  const inputId = useId();
  const pct = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0;

  return (
    <Card variant="outlined" sx={{ p:1.5 }}>
      <CardContent sx={{ p:0, '&:last-child':{ pb:0 } }}>
        <Stack spacing={1.5}>
          <Stack direction="row" alignItems="center" spacing={2}>
            <TextField
              id={inputId}
              size="small"
              label={label}
              type="number"
              inputMode="decimal"
              value={Number.isFinite(value) ? value : 0}
              onChange={(e)=>onChange(Number(e.target.value))}
              inputProps={{ min, max, step }}
              fullWidth
            />
            {balance != null && (
              <Typography variant="caption" sx={{ whiteSpace:'nowrap', opacity:0.7 }}>Bal: <b>{balance.toFixed(2)} Pi</b></Typography>
            )}
          </Stack>
          <Box px={1}>
            <Slider
              aria-label={label}
              min={min}
              max={max}
              step={step}
              value={Number.isFinite(value) ? value : 0}
              onChange={(_,v)=> onChange(Number(v))}
            />
            <Typography variant="caption" sx={{ display:'block', textAlign:'right', opacity:0.65 }}>{pct.toFixed(0)}%</Typography>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
}
