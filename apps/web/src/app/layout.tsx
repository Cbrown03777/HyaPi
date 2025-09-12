import Script from 'next/script';
import './global.css'
import { I18nProvider } from '@/components/I18nProvider'
import { ToastProvider } from '@/components/ToastProvider'
import { ActivityProvider } from '@/components/ActivityProvider'
import { NavBar } from '@/components/NavBar'
import { BottomNav } from '@/components/BottomNav'
import { Inter } from 'next/font/google'
import { PiInit } from '@/components/PiInit'
import { PiBanner } from '@/components/PiBanner'
import ThemeRegistry from '@/theme/ThemeRegistry';
import { AppBar, Box, Container, Link as MuiLink, Toolbar, Typography } from '@mui/material';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' })


export const metadata = {
  title: 'hyaPi Governance',
  description: 'Governance dApp for allocation proposals',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="h-full" data-theme="dark">
      <head>
  <Script src="https://sdk.minepi.com/pi-sdk.js" strategy="beforeInteractive" />
      </head>
  <body className={`${inter.className}`}>
        <ThemeRegistry>
          <I18nProvider>
            {/* Initialize Pi SDK in client once available */}
            <PiInit />
            {/* If not in Pi Browser, show a small banner */}
            <PiBanner />
            <AppBar position="sticky" elevation={0} color="transparent" sx={{ backdropFilter: 'blur(10px)', borderBottom: '1px solid rgba(255,255,255,0.1)', backgroundColor: 'rgba(0,0,0,0.4)' }}>
              <Toolbar disableGutters sx={{ minHeight: 56 }}>
                <Container maxWidth="lg" sx={{ px: { xs: 2, sm: 3 }, py: 1 }}>
                  <NavBar />
                </Container>
              </Toolbar>
            </AppBar>
            <ToastProvider>
              <ActivityProvider>
                <Box component="main" sx={{ py: { xs: 4, sm: 6 } }}>
                  <Container maxWidth="lg" sx={{ px: { xs: 2, sm: 3 }, display: 'flex', flexDirection: 'column', gap: 4 }}>
                    {children}
                  </Container>
                </Box>
                <BottomNav />
                <Box component="footer" sx={{ mt: 10, borderTop: '1px solid rgba(255,255,255,0.1)', background: 'rgba(0,0,0,0.3)' }}>
                  <Container maxWidth="lg" sx={{ px: { xs: 2, sm: 3 }, py: 4, display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, alignItems: { xs: 'flex-start', sm: 'center' }, gap: { xs: 2, sm: 4 }, color: 'text.secondary', fontSize: 14 }}>
                    <Typography sx={{ flex: 1 }}>© {new Date().getFullYear()} HyaPi</Typography>
                    <Box component="nav" sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                      <MuiLink href="/privacy" underline="hover" color="inherit" sx={{ fontSize: 14 }}>Privacy</MuiLink>
                      <MuiLink href="/terms" underline="hover" color="inherit" sx={{ fontSize: 14 }}>Terms</MuiLink>
                    </Box>
                  </Container>
                </Box>
              </ActivityProvider>
            </ToastProvider>
          </I18nProvider>
        </ThemeRegistry>
      </body>
    </html>
  );
}
