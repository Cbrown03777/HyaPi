"use client";
import React, { createContext, useContext, useState, useCallback, useMemo } from 'react';

type Locale = 'en' | 'es';
type Dict = Record<string, string>;

const dictionaries: Record<Locale, Dict> = {
  en: {
    home: 'Home',
    stake: 'Stake',
    governance: 'Governance',
    create: 'Create',
    portfolio: 'Portfolio',
    admin: 'Admin',
    allocation: 'Allocation',
    terms: 'Terms',
    language: 'Language',
    toggle_navigation: 'Toggle navigation'
  },
  es: {
    home: 'Inicio',
    stake: 'Participar',
    governance: 'Gobernanza',
    create: 'Crear',
    portfolio: 'Portafolio',
    admin: 'Admin',
    allocation: 'Asignación',
    terms: 'Términos',
    language: 'Idioma',
    toggle_navigation: 'Alternar navegación'
  }
};

interface I18nCtx {
  locale: Locale;
  t: (key: string) => string;
  setLocale: (l: Locale) => void;
}

const Ctx = createContext<I18nCtx | null>(null);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocale] = useState<Locale>('en');
  const t = useCallback((key: string) => dictionaries[locale][key] || key, [locale]);
  const value = useMemo(() => ({ locale, t, setLocale }), [locale, t]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useI18n() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useI18n must be used within I18nProvider');
  return ctx;
}
