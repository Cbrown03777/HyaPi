"use client";
import React from 'react';
import { ButtonGroup, Button } from '@mui/material';

type Props = { balance: number; onPick: (amt:number)=>void };

export function RedeemPreset({ balance, onPick }: Props) {
  const opts = [0.25, 0.5, 0.75, 1.0];
  return (
    <ButtonGroup size="small" variant="outlined">
      {opts.map(p => (
        <Button key={p} onClick={()=>onPick(Number((balance*p).toFixed(6)))}>{(p*100).toFixed(0)}%</Button>
      ))}
    </ButtonGroup>
  );
}
