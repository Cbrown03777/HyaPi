Internationalization (i18n) Setup
=================================

Library: next-intl (App Router).

Locales enabled:
- en (default)
- es
- ko
- vi
- hi
- tl

Directory Structure:
- messages/<locale>.json : Flat JSON key-value pairs.
- app/[locale]/layout.tsx : Locale-aware root layout providing NextIntlClientProvider.
- middleware.ts : Handles locale detection and routing. Locale prefix is added as-needed (default locale can omit prefix).

Adding a New Locale
-------------------
1. Create messages/<new>.json copying en.json structure.
2. Add the locale code to locales array in:
   - messages definition (if referenced elsewhere)
   - app/[locale]/layout.tsx (locales const)
   - src/middleware.ts (locales array)
3. (Optional) Provide route for localized static pages if any custom handling.
4. Restart dev server (Next needs middleware reload).

Using Translations
------------------
Client component:
  import {useTranslations} from 'next-intl';
  const t = useTranslations();
  return <span>{t('nav.home')}</span>

Server component:
  import {getTranslations} from 'next-intl/server';
  const t = await getTranslations();
  return <h1>{t('nav.home')}</h1>

Key Naming
----------
Namespaced with dot segments for grouping (nav., footer., action., a11y., theme.). Keep them short and consistent.

Skip Link & Accessibility
-------------------------
`SkipLink` component adds an accessible focusable link to jump to `#main-content`.
Ensure the main content container keeps id="main-content" and role="main".

Locale Switching
----------------
The NavBar rewrites the pathname replacing the first segment if it matches a locale code. Default fallback navigates to /<locale>.

Missing Keys
------------
If a key is absent the key itself is rendered, signaling a gap. Consider adding a simple development wrapper in future to highlight missing keys.

Adding Dynamic Page Content
---------------------------
For dynamic server pages, call `getTranslations()` in the segment and pass strings down as needed or rely on client hooks.

Future Enhancements
-------------------
- Consider extraction tooling or lint rule to prevent orphan keys.
- Add ICU message formatting for pluralization if required.
- Persist user-selected locale via cookie (middleware can read) for improved default on return visits.
