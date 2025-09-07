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
      <body className={`min-h-screen bg-[radial-gradient(1200px_600px_at_50%_-100px,rgba(99,102,241,0.15),transparent),linear-gradient(180deg,#0b1020_0%,#0b0f1a_100%)] text-white ${inter.className}`}>
        <I18nProvider>
          {/* Initialize Pi SDK in client once available */}
          <PiInit />
          {/* If not in Pi Browser, show a small banner */}
          <PiBanner />
          <header className="sticky top-0 z-40 backdrop-blur border-b border-white/10 bg-black/40">
            <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-2">
              <NavBar />
            </div>
          </header>
          <ToastProvider>
            <ActivityProvider>
              <main>
                <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6 space-y-6">
                  {children}
                </div>
              </main>
              <BottomNav />
              <footer className="mt-10 border-t border-white/10 bg-black/30">
                <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6 text-sm text-white/70 flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-6">
                  <div className="flex-1">© {new Date().getFullYear()} HyaPi</div>
                  <nav className="flex items-center gap-4">
                    <a href="/privacy" className="hover:underline underline-offset-4 focus:outline-none focus-visible:ring-2 focus-visible:ring-[color:var(--acc)] rounded">Privacy</a>
                    <a href="/terms" className="hover:underline underline-offset-4 focus:outline-none focus-visible:ring-2 focus-visible:ring-[color:var(--acc)] rounded">Terms</a>
                  </nav>
                </div>
              </footer>
            </ActivityProvider>
          </ToastProvider>
        </I18nProvider>
      </body>
    </html>
  );
}
