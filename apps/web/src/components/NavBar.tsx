"use client";
import * as React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useI18n } from './I18nProvider';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Container from '@mui/material/Container';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Drawer from '@mui/material/Drawer';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import Divider from '@mui/material/Divider';
import Tooltip from '@mui/material/Tooltip';
import { useTheme } from '@mui/material/styles';
import MenuIcon from '@mui/icons-material/Menu';
import TranslateIcon from '@mui/icons-material/Translate';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';

// Base nav link configuration
const baseLinksRaw = [
  { href: '/', key: 'home' },
  { href: '/stake', key: 'stake' },
  { href: '/governance', key: 'governance' },
  { href: '/create', key: 'create' },
  { href: '/portfolio', key: 'portfolio' },
];

export function NavBar() {
  const pathname = usePathname();
  const { t, locale, setLocale } = useI18n();
  const theme = useTheme();

  const [drawerOpen, setDrawerOpen] = React.useState(false);
  const [isAdmin, setIsAdmin] = React.useState(false);
  const [langMenuAnchor, setLangMenuAnchor] = React.useState<null | HTMLElement>(null);
  const langMenuOpen = Boolean(langMenuAnchor);
  const [modeStub, setModeStub] = React.useState<'dark' | 'light'>('dark'); // placeholder until real color mode toggle wired

  React.useEffect(() => {
    try {
      const token = (globalThis as any).hyapiBearer as string | undefined;
      const persisted = typeof localStorage !== 'undefined' ? localStorage.getItem('adminMode') : null;
      if (token?.startsWith('dev ') || process.env.NEXT_PUBLIC_ENABLE_ADMIN === '1' || persisted === '1') setIsAdmin(true);
    } catch {}
  }, []);

  // Hotkey: Alt+Shift+A to toggle admin mode (persist)
  React.useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.altKey && e.shiftKey && (e.key === 'A' || e.key === 'a')) {
        e.preventDefault();
        setIsAdmin(v => {
          const next = !v; try { localStorage.setItem('adminMode', next ? '1' : '0'); } catch {}
          return next;
        });
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, []);

  const baseLinks = baseLinksRaw.map(l => ({ href: l.href, label: t(l.key) }));
  const links = isAdmin
    ? [...baseLinks, { href: '/admin', label: t('admin') }, { href: '/admin/alloc', label: t('allocation') }]
    : baseLinks;

  const handleLangButton = (e: React.MouseEvent<HTMLElement>) => setLangMenuAnchor(e.currentTarget);
  const closeLangMenu = () => setLangMenuAnchor(null);
  const changeLocale = (loc: string) => { setLocale(loc as any); closeLangMenu(); };

  const toggleModeStub = () => setModeStub(m => m === 'dark' ? 'light' : 'dark');

  // Helper for active nav styling
  const isActive = (href: string) => href === pathname;

  return (
    <AppBar
      position="sticky"
      elevation={0}
      sx={{
        backdropFilter: 'blur(12px)',
        backgroundColor: 'rgba(15,15,16,0.72)',
        borderBottom: '1px solid rgba(255,255,255,0.08)',
      }}
    >
      <Toolbar disableGutters sx={{ minHeight: 56 }}>
        <Container maxWidth="lg" sx={{ display: 'flex', alignItems: 'center', gap: 2 }}> 
          {/* Left: brand & mobile menu */}
          <Box sx={{ display: { xs: 'flex', md: 'none' }, alignItems: 'center' }}>
            <IconButton
              color="inherit"
              aria-label={t('toggle_navigation')}
              onClick={() => setDrawerOpen(true)}
              size="large"
            >
              <MenuIcon />
            </IconButton>
          </Box>
          <Box component={Link} href="/" sx={{ display: 'flex', alignItems: 'center', textDecoration: 'none', color: 'inherit', mr: 1 }}> 
            <Box sx={{ width: 28, height: 28, bgcolor: 'primary.main', borderRadius: 1.5, mr: 1 }} aria-hidden />
            <Typography variant="h6" sx={{ fontWeight: 600, letterSpacing: '-0.5px' }}>HyaPi</Typography>
          </Box>

          {/* Center nav (desktop) */}
          <Box component="nav" aria-label="Main navigation" sx={{ display: { xs: 'none', md: 'flex' }, gap: 0.5, flex: 1 }}>
            {links.map(link => {
              const active = isActive(link.href);
              return (
                <Button
                  key={link.href}
                  component={Link}
                  href={link.href}
                  aria-current={active ? 'page' : undefined}
                  size="small"
                  sx={{
                    px: 2.25,
                    py: 1,
                    borderRadius: 2,
                    fontWeight: 500,
                    fontSize: '0.85rem',
                    color: active ? 'primary.contrastText' : 'text.secondary',
                    backgroundColor: active ? 'primary.main' : 'transparent',
                    '&:hover': {
                      backgroundColor: active ? 'primary.main' : 'rgba(255,255,255,0.08)',
                      color: 'text.primary'
                    }
                  }}
                >{link.label}</Button>
              );
            })}
          </Box>

          {/* Right actions (desktop) */}
            <Box sx={{ display: { xs: 'none', md: 'flex' }, alignItems: 'center', gap: 1.5 }}>
              {/* Language menu stub */}
              <Tooltip title={t('language')}>
                <IconButton
                  id="lang-btn"
                  aria-controls={langMenuOpen ? 'lang-menu' : undefined}
                  aria-haspopup="true"
                  aria-expanded={langMenuOpen ? 'true' : undefined}
                  onClick={handleLangButton}
                  size="small"
                  sx={{ bgcolor: 'rgba(255,255,255,0.08)', '&:hover': { bgcolor: 'rgba(255,255,255,0.15)' } }}
                >
                  <TranslateIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Menu
                id="lang-menu"
                anchorEl={langMenuAnchor}
                open={langMenuOpen}
                onClose={closeLangMenu}
                MenuListProps={{ 'aria-labelledby': 'lang-btn' }}
              >
                {['en','es'].map(loc => (
                  <MenuItem key={loc} selected={loc === locale} onClick={() => changeLocale(loc)}>{loc.toUpperCase()}</MenuItem>
                ))}
              </Menu>

              {/* Color mode toggle stub */}
              <Tooltip title="Toggle color mode (stub)">
                <IconButton
                  size="small"
                  aria-label="toggle color mode"
                  onClick={toggleModeStub}
                  sx={{ bgcolor: 'rgba(255,255,255,0.08)', '&:hover': { bgcolor: 'rgba(255,255,255,0.15)' } }}
                >
                  {modeStub === 'dark' ? <Brightness7Icon fontSize="small" /> : <Brightness4Icon fontSize="small" />}
                </IconButton>
              </Tooltip>

              <Button
                component={Link}
                href="/stake"
                variant="contained"
                size="small"
                sx={{
                  borderRadius: 2,
                  fontWeight: 600,
                  textTransform: 'none'
                }}
              >
                {t('stake')}
              </Button>
              <Button
                component={Link}
                href="/terms"
                size="small"
                sx={{ color: 'text.secondary', '&:hover': { color: 'text.primary', backgroundColor: 'rgba(255,255,255,0.06)' } }}
              >
                {t('terms')}
              </Button>
            </Box>
        </Container>
      </Toolbar>

      {/* Mobile Drawer */}
      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        ModalProps={{ keepMounted: true }}
        PaperProps={{ sx: { width: 260, backgroundColor: '#121214', color: 'text.primary' } }}
      >
        <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box sx={{ width: 28, height: 28, bgcolor: 'primary.main', borderRadius: 1.5 }} aria-hidden />
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>HyaPi</Typography>
        </Box>
        <Divider sx={{ borderColor: 'rgba(255,255,255,0.08)' }} />
        <List component="nav" aria-label="Mobile navigation" sx={{ py: 1 }}>
          {links.map(link => {
            const active = isActive(link.href);
            return (
              <ListItemButton
                key={link.href}
                component={Link}
                href={link.href}
                selected={active}
                onClick={() => setDrawerOpen(false)}
                sx={{
                  borderRadius: 1.5,
                  mx: 1,
                  my: 0.25,
                  '&.Mui-selected': { backgroundColor: 'primary.main', '&:hover': { backgroundColor: 'primary.main' }, color: 'primary.contrastText' }
                }}
              >
                <ListItemText primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: 500 }} primary={link.label} />
              </ListItemButton>
            );
          })}
        </List>
        <Divider sx={{ borderColor: 'rgba(255,255,255,0.08)' }} />
        <Box sx={{ p: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Button size="small" variant="contained" component={Link} href="/stake" onClick={() => setDrawerOpen(false)} sx={{ flexGrow: 1, borderRadius: 2 }}>{t('stake')}</Button>
          <Button size="small" component={Link} href="/terms" onClick={() => setDrawerOpen(false)} sx={{ color: 'text.secondary', flexGrow: 1 }}>{t('terms')}</Button>
          <Box sx={{ width: '100%', display: 'flex', gap: 1 }}>
            <IconButton aria-label={t('language')} onClick={handleLangButton} size="small" sx={{ bgcolor: 'rgba(255,255,255,0.1)', '&:hover': { bgcolor: 'rgba(255,255,255,0.18)' } }}>
              <TranslateIcon fontSize="small" />
            </IconButton>
            <IconButton aria-label="toggle color mode" onClick={toggleModeStub} size="small" sx={{ bgcolor: 'rgba(255,255,255,0.1)', '&:hover': { bgcolor: 'rgba(255,255,255,0.18)' } }}>
              {modeStub === 'dark' ? <Brightness7Icon fontSize="small" /> : <Brightness4Icon fontSize="small" />}
            </IconButton>
          </Box>
        </Box>
      </Drawer>
    </AppBar>
  );
}
