"use client";
import React, { useEffect, useRef, useState } from 'react';
import { Box, Link as MuiLink, Typography } from '@mui/material';

export function BottomNav() {
  const [dim, setDim] = useState(false);
  const navRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    const target = document.getElementById('sticky-actions');
    if (!target) return;
    const io = new IntersectionObserver((entries) => {
      for (const e of entries) {
        if (e.isIntersecting) setDim(true); else setDim(false);
      }
    }, { threshold: 0.01 });
    io.observe(target);
    return () => io.disconnect();
  }, []);
  return (
    <Box
      component="nav"
      sx={{
        position: 'fixed',
        bottom: 8,
        right: 8,
        zIndex: 30,
        opacity: dim ? 0.4 : 1,
        pointerEvents: dim ? 'none' : 'auto',
        display: { xs: 'block', sm: 'none' },
        transition: 'opacity .25s',
      }}
    >
      <Box
        ref={navRef}
        sx={{
          display: 'flex',
            alignItems: 'stretch',
          gap: 1.5,
          border: '1px solid rgba(255,255,255,0.12)',
          bgcolor: 'rgba(18,24,35,0.85)',
          px: 1.5,
          py: 1,
          borderRadius: 3,
          boxShadow: 6,
          backdropFilter: 'blur(10px)'
        }}
      >
        <MuiLink href="/" underline="none" color="text.secondary" sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5, px: 1, '&:hover': { color: 'text.primary' } }}>
          <span aria-hidden>🏛️</span>
          <Typography sx={{ fontSize: 10 }}>Govern</Typography>
        </MuiLink>
        <MuiLink href="/stake" underline="none" color="text.secondary" sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5, px: 1, '&:hover': { color: 'text.primary' } }}>
          <span aria-hidden>📈</span>
          <Typography sx={{ fontSize: 10 }}>Stake</Typography>
        </MuiLink>
        <MuiLink href="/redeem" underline="none" color="text.secondary" sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5, px: 1, '&:hover': { color: 'text.primary' } }}>
          <span aria-hidden>↩️</span>
          <Typography sx={{ fontSize: 10 }}>Redeem</Typography>
        </MuiLink>
      </Box>
    </Box>
  );
}
