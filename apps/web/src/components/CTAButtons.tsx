"use client";
import React from 'react';
import { Stack, Button, ButtonGroup } from '@mui/material';

export type CTAButtonsProps = {
  primaryLabel: string;
  primaryDisabled?: boolean;
  onPrimary: ()=>void;
  secondaryLabel?: string;
  secondaryDisabled?: boolean;
  onSecondary?: ()=>void;
  inline?: boolean; // if true render in ButtonGroup, else spaced stack
  primaryColor?: 'primary' | 'secondary' | 'success' | 'error';
  secondaryColor?: 'primary' | 'secondary' | 'success' | 'error';
};

export function CTAButtons({
  primaryLabel,
  primaryDisabled = false,
  onPrimary,
  secondaryLabel,
  secondaryDisabled = false,
  onSecondary,
  inline=false,
  primaryColor='primary',
  secondaryColor='secondary'
}: CTAButtonsProps) {
  if (inline) {
    return (
      <ButtonGroup fullWidth variant="contained">
        {secondaryLabel && (
          <Button color={secondaryColor} disabled={!!secondaryDisabled} onClick={onSecondary}>{secondaryLabel}</Button>
        )}
        <Button color={primaryColor} disabled={!!primaryDisabled} onClick={onPrimary}>{primaryLabel}</Button>
      </ButtonGroup>
    );
  }
  return (
    <Stack direction={{ xs:'column', sm:'row' }} spacing={2} width="100%">
      {secondaryLabel && (
        <Button fullWidth variant="outlined" color={secondaryColor} disabled={!!secondaryDisabled} onClick={onSecondary}>{secondaryLabel}</Button>
      )}
      <Button fullWidth variant="contained" color={primaryColor} disabled={!!primaryDisabled} onClick={onPrimary}>{primaryLabel}</Button>
    </Stack>
  );
}
