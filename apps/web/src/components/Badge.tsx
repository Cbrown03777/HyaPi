"use client";
import { Chip } from '@mui/material';

type Tone = 'neutral' | 'primary' | 'accent' | 'success' | 'warn' | 'danger'

type Props = {
  tone?: Tone
  children: React.ReactNode
  className?: string
  icon?: React.ReactNode
  ariaLabel?: string
}

const toneMap: Record<Tone, { color: 'default' | 'primary' | 'success' | 'warning' | 'error'; variant: 'outlined' | 'filled' }> = {
  neutral: { color: 'default', variant: 'outlined' },
  primary: { color: 'primary', variant: 'outlined' },
  accent: { color: 'primary', variant: 'filled' },
  success: { color: 'success', variant: 'filled' },
  warn: { color: 'warning', variant: 'filled' },
  danger: { color: 'error', variant: 'filled' },
};

export function Badge({ tone = 'neutral', className = '', children, icon, ariaLabel }: Props) {
  const t = toneMap[tone];
  return (
    <Chip
      size="small"
      label={children}
      icon={icon as any}
      color={t.color}
      variant={t.variant}
      aria-label={ariaLabel || undefined}
      sx={{ fontSize: 11, height: 22, '& .MuiChip-label': { px: 1 } }}
      className={className}
    />
  );
}
