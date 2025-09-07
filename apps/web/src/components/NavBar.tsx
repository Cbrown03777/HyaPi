"use client";
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import clsx from 'clsx';
import { useI18n } from './I18nProvider';

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
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 6);
    onScroll();
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const [isAdmin, setIsAdmin] = useState(false);
  useEffect(() => {
    try {
      const token = (globalThis as any).hyapiBearer as string | undefined;
      const persisted = typeof localStorage !== 'undefined' ? localStorage.getItem('adminMode') : null;
      if (token?.startsWith('dev ') || process.env.NEXT_PUBLIC_ENABLE_ADMIN === '1' || persisted === '1') setIsAdmin(true);
    } catch {}
  }, []);

  // Hotkey: Alt+Shift+A (avoid Chrome Ctrl+Shift+A conflict)
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.altKey && e.shiftKey && (e.key === 'A' || e.key === 'a')) {
        e.preventDefault();
        setIsAdmin(v => {
          const next = !v; try { localStorage.setItem('adminMode', next ? '1':'0'); } catch {}
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

  return (
    <header className={clsx(
      'sticky top-0 z-50 backdrop-blur transition-shadow text-slate-100',
      scrolled ? 'bg-black/70 shadow-[0_2px_8px_-2px_rgba(0,0,0,0.4),0_1px_3px_rgba(0,0,0,0.2)]' : 'bg-black/40'
    )}>
      <div className="mx-auto max-w-screen-lg px-4 sm:px-6 flex h-14 items-center justify-between gap-4">
        {/* Left: brand */}
        <Link href="/" className="flex items-center gap-2">
          <div className="h-6 w-6 rounded-md bg-brand-500" aria-hidden />
          <span className="font-semibold tracking-tight">HyaPi</span>
        </Link>

        {/* Center: nav (md+) */}
  <nav className="hidden md:flex items-center gap-1" aria-label="Main navigation">
          {links.map((l) => {
            const active = pathname === l.href;
            return (
              <Link
                key={l.href}
                href={l.href}
                className={clsx(
                  'px-3 py-2 text-sm rounded-lg font-medium focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60 focus-visible:ring-offset-2 focus-visible:ring-offset-black/20 transition-colors',
                  active
                    ? 'bg-white/10 text-white shadow-inner'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                )}
                aria-current={active ? 'page' : undefined}
              >
                {l.label}
              </Link>
            );
          })}
        </nav>

        {/* Right: actions */}
        <div className="hidden md:flex items-center gap-3">
          <label className="sr-only" htmlFor="lang-select">{t('language')}</label>
          <select
            id="lang-select"
            value={locale}
            onChange={(e)=>setLocale(e.target.value as any)}
            className="bg-black/40 text-xs rounded-md border border-white/10 px-2 py-1 text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60"
            aria-label={t('language')}
          >
            <option value="en">EN</option>
            <option value="es">ES</option>
          </select>
          <Link
            href="/stake"
            className="inline-flex items-center rounded-lg bg-brand-600/90 hover:bg-brand-500 px-4 h-9 text-sm font-semibold shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400/70"
          >
            {t('stake')}
          </Link>
          <Link href="/terms" className="text-sm text-white/70 hover:text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60 rounded-md px-2 py-1">
            {t('terms')}
          </Link>
        </div>

        {/* Mobile hamburger */}
        <button
          className="md:hidden inline-flex h-10 w-10 items-center justify-center rounded-lg border border-white/10 text-white/80 hover:text-white hover:bg-white/10 focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60"
          aria-label={t('toggle_navigation')}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-slate-800"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
        </button>
      </div>

      {/* Mobile drawer */}
      {open && (
        <div className="md:hidden border-t border-white/10 bg-black/80 backdrop-blur">
          <nav className="mx-auto max-w-screen-lg px-4 sm:px-6 py-3 flex flex-col gap-1" aria-label="Mobile navigation">
            {links.map((l) => {
              const active = pathname === l.href;
              return (
                <Link
                  key={l.href}
                  href={l.href}
                  className={clsx(
                    'px-3 py-2 rounded-lg text-sm font-medium focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60 transition-colors',
                    active ? 'bg-white/10 text-white' : 'text-white/70 hover:bg-white/10'
                  )}
                  onClick={() => setOpen(false)}
                >
                  {l.label}
                </Link>
              );
            })}
            <div className="mt-3 flex flex-wrap gap-3 items-center">
              <select
                value={locale}
                onChange={(e)=>setLocale(e.target.value as any)}
                className="bg-black/40 text-xs rounded-md border border-white/10 px-2 py-1 text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60"
                aria-label={t('language')}
              >
                <option value="en">EN</option>
                <option value="es">ES</option>
              </select>
              <Link
                href="/stake"
                className="inline-flex items-center rounded-lg bg-brand-600/90 hover:bg-brand-500 px-4 h-9 text-sm font-semibold shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400/70"
                onClick={() => setOpen(false)}
              >
                {t('stake')}
              </Link>
              <Link
                href="/terms"
                className="text-sm text-white/70 hover:text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-500/60 rounded-md px-2 py-1"
                onClick={() => setOpen(false)}
              >
                {t('terms')}
              </Link>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}
