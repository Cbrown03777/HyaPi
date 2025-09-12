"use client";
import { Button as MuiButton } from '@mui/material';
import React from 'react';

type Props = {
  variant?: 'primary' | 'secondary' | 'danger';
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  children?: React.ReactNode;
} & Omit<React.ComponentProps<typeof MuiButton>, 'variant' | 'color'>;

export function Button({ variant = 'primary', loading, leftIcon, rightIcon, children, disabled, ...rest }: Props) {
  const mapping: Record<string, { color: 'primary' | 'error' | 'inherit' | 'secondary'; muiVariant: 'contained' | 'outlined' | 'text'; }> = {
    primary: { color: 'primary', muiVariant: 'contained' },
    secondary: { color: 'primary', muiVariant: 'outlined' },
    danger: { color: 'error', muiVariant: 'contained' },
  };
  const m: { color: 'primary' | 'error' | 'inherit' | 'secondary'; muiVariant: 'contained' | 'outlined' | 'text'; } = (mapping as any)[variant] || mapping.primary;
  return (
    <MuiButton
      size="medium"
      color={m.color}
      variant={m.muiVariant}
      startIcon={leftIcon as any}
      endIcon={rightIcon as any}
      disabled={disabled || !!loading}
      {...rest}
      sx={{ borderRadius: 3, textTransform: 'none', fontWeight: 600, px: 2.5, height: 40, ...(rest.sx || {}) }}
    >
      {loading ? '…' : children}
    </MuiButton>
  );
}
