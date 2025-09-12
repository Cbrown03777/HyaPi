"use client";
import { Box } from '@mui/material';

type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  asChild?: boolean
}

export function Card({ className, children, ...rest }: CardProps) {
  return (
    <Box
      className={className}
      sx={{
        position: 'relative',
        borderRadius: 4,
        border: '1px solid rgba(255,255,255,0.1)',
        backdropFilter: 'blur(6px)',
        background: 'linear-gradient(145deg, rgba(255,255,255,0.04), rgba(255,255,255,0.08))',
        boxShadow: '0 4px 32px -8px rgba(0,0,0,0.6),0 2px 8px -2px rgba(0,0,0,0.5)',
        transition: 'box-shadow .25s',
        '&:hover': {
          boxShadow: '0 6px 40px -6px rgba(0,0,0,0.7),0 3px 12px -2px rgba(0,0,0,0.55)'
        },
        overflow: 'hidden'
      }}
      onMouseMove={(e) => {
        const r = (e.currentTarget as HTMLDivElement).getBoundingClientRect();
        (e.currentTarget as HTMLDivElement).style.setProperty('--x', `${e.clientX - r.left}px`);
        (e.currentTarget as HTMLDivElement).style.setProperty('--y', `${e.clientY - r.top}px`);
      }}
      {...rest}
    >
      {children}
    </Box>
  );
}
