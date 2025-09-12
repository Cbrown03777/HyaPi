import Link from 'next/link';
import { GOV_API_BASE } from '@hyapi/shared';
import { Box, Typography, Paper, Stack, Divider } from '@mui/material';

type LegalMeta = { privacy_last_updated?: string } | null;

function TOC() {
  const items = [
    ['who-we-are', '1) Who we are'],
    ['scope', '2) Scope'],
    ['what-we-collect', '3) What we collect'],
    ['sources', '4) Sources'],
    ['purposes', '5) Why we use your data'],
    ['sharing', '6) Sharing'],
    ['transfers', '7) International transfers'],
    ['security', '8) Security'],
    ['retention', '9) Retention'],
    ['your-rights', '10) Your rights'],
    ['children', '11) Children'],
    ['third-party', '12) Third-party links & protocols'],
    ['changes', '13) Changes'],
    ['contact', '14) Contact'],
  ] as const;
  return (
    <Box component="nav" aria-label="Table of contents" sx={{ fontSize: 13 }}>
      <Typography variant="subtitle2" sx={{ mb: 1, opacity: 0.8 }}>On this page</Typography>
      <Stack component="ul" spacing={0.5} sx={{ listStyle: 'none', m: 0, p: 0 }}>
        {items.map(([id, title]) => (
          <Box component="li" key={id}>
            <Typography component={Link} href={`#${id}`} sx={{
              color: 'text.secondary',
              textDecoration: 'none',
              fontSize: 13,
              '&:hover': { color: 'text.primary', textDecoration: 'underline' },
              '&:focus-visible': { outline: '2px solid', outlineColor: 'primary.main', borderRadius: 1 }
            }}>{title}</Typography>
          </Box>
        ))}
      </Stack>
    </Box>
  );
}

async function getMeta(): Promise<LegalMeta> {
  try {
    const r = await fetch(`${GOV_API_BASE}/v1/metadata/legal`, { cache: 'no-store' });
    const j = await r.json().catch(() => ({}));
    return (j?.data ?? j) as LegalMeta;
  } catch {
    return null;
  }
}

export default async function PrivacyPage() {
  const meta = await getMeta();
  const last = meta?.privacy_last_updated ?? 'Sep 2025';

  return (
    <Box sx={{ px: { xs: 0, sm: 0 } }}>
      <Typography variant="h4" fontWeight={600}>HyaPi Privacy Policy</Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>Last updated: {last}</Typography>

      <Box sx={{ mt: 4, display: 'grid', gap: 4, gridTemplateColumns: { xs: '1fr', sm: '240px 1fr' } }}>
        <Box sx={{ position: { sm: 'sticky' }, top: { sm: 96 }, alignSelf: 'start' }}>
          <Paper variant="outlined" sx={{ p: 2, borderRadius: 2, background: 'linear-gradient(145deg, rgba(255,255,255,0.04), rgba(255,255,255,0.10))' }}>
            <TOC />
          </Paper>
        </Box>
        <Box component="article" sx={{ '& h2': { mt: 4, mb: 1.5, fontSize: 20 }, '& h3': { mt: 3, mb: 1, fontSize: 16 }, '& p': { mb: 2, lineHeight: 1.6 }, '& ul': { pl: 3, mb: 2 }, '& li': { mb: 0.5 } }}>
          <section id="who-we-are">
            <h2>1) Who we are</h2>
            <p>
              HyaPi (“we”, “our”, “us”) provides a Pi-native application that lets Pi holders lock Pi, receive hyaPi
              accounting units, and participate in governance of target yield venues. We are not the Pi Network, and we
              don’t control external blockchains or validators.
            </p>
            <p>
              We drafted this policy to explain what we collect, why, how we protect it, and your choices. We took inspiration
              from how leading DeFi teams explain their practices (e.g., Aave) while adapting to Pi’s SDK/Platform flows and
              your use of our services.
            </p>
          </section>

          <section id="scope">
            <h2>2) Scope</h2>
            <ul>
              <li>The HyaPi web app in Pi Browser (and any sandbox/testnet environment),</li>
              <li>Our public API endpoints, and</li>
              <li>Related sites, dashboards, and support channels.</li>
            </ul>
            <p>
              It does not cover third-party sites or protocols (Pi Network itself, exchanges, validators, wallets, analytics providers, etc.).
            </p>
          </section>

          <section id="what-we-collect">
            <h2>3) What we collect</h2>
            <p>We collect only what we need to authenticate you, process payments, operate staking/redemption, and secure the app:</p>
            <h3>Account &amp; identifiers</h3>
            <ul>
              <li>Pi-provided identifiers via the Pi App Platform SDK (e.g., username, uid) and session tokens; we do not receive your private keys.</li>
              <li>Internal user ID mapping (our DB’s users/pi_identities records).</li>
            </ul>
            <h3>Payments &amp; treasury</h3>
            <ul>
              <li>Pi payment IDs, directions (U2A/A2U), amounts, status, and related metadata/txids as returned by the Pi Platform/API; amounts are verified server-side.</li>
              <li>Staking/redemption records (amounts, lockup weeks, fees, snapshots, PPS).</li>
            </ul>
            <h3>On-chain/public</h3>
            <p>Public wallet addresses and on-chain events on target networks (e.g., Sui/Aptos/Cosmos) when we delegate/unstake; these are public by design.</p>
            <h3>Device &amp; usage</h3>
            <p>Basic HTTP request data (IP address, user-agent), timestamps, and app logs for security/debugging.</p>
            <p>Cookies/local storage only where strictly necessary (session, preferences). If you later add analytics or cookie banners, update this section.</p>
            <p>We do not intentionally collect government IDs, biometric data, or sensitive categories. If Pi KYC status becomes available to us, we will store only minimal status flags necessary to comply with Pi policies and risk controls.</p>
          </section>

          <section id="sources">
            <h2>4) Sources</h2>
            <ul>
              <li>You, via the app UI.</li>
              <li>Pi SDK (client) and Pi Platform API (server) for authentication and payments.</li>
              <li>Public blockchains for transaction and delegation data.</li>
            </ul>
          </section>

          <section id="purposes">
            <h2>5) Why we use your data (purposes + legal bases)</h2>
            <ul>
              <li>Provide the service: authenticate via Pi SDK, approve/complete payments, credit stakes/redemptions, show balances and history (contract necessity).</li>
              <li>Security &amp; fraud prevention: idempotency checks, audit logs, abuse/DoS detection (legitimate interests).</li>
              <li>Governance &amp; allocations: snapshots, proposals, votes, execution records (contract necessity/legitimate interests).</li>
              <li>Compliance: maintain financial/tax records and honor valid law-enforcement requests (legal obligation).</li>
              <li>Comms &amp; support: respond to requests, send critical service notices (legitimate interests/consent).</li>
            </ul>
            <p>If you later add marketing or analytics, obtain consent and update this page.</p>
          </section>

          <section id="sharing">
            <h2>6) Sharing</h2>
            <ul>
              <li>Pi Network servers to verify tokens and process U2A/A2U payments.</li>
              <li>Infrastructure vendors (hosting, storage, email/support) under confidentiality and security controls.</li>
              <li>Validators/venues: we interact on-chain using public addresses. We don’t send them your personal data.</li>
              <li>Regulators/law enforcement where required by law.</li>
            </ul>
            <p>We don’t sell personal information.</p>
          </section>

          <section id="transfers">
            <h2>7) International transfers</h2>
            <p>Our infrastructure may process data globally. Where required, we rely on appropriate safeguards (e.g., standard contractual clauses). Contact us for details.</p>
          </section>

          <section id="security">
            <h2>8) Security</h2>
            <p>
              We use industry-standard measures: TLS in transit, restricted secrets, least-privilege access, database controls, and server-side verification of payment amounts. Still, no system is 100% secure; users should secure their devices and Pi credentials.
            </p>
          </section>

          <section id="retention">
            <h2>9) Retention</h2>
            <ul>
              <li>Payment/stake/redemption records: retained as long as necessary for service/accounting/audit (commonly up to 7 years).</li>
              <li>Server logs: typically ≤ 30–90 days unless needed for an investigation.</li>
            </ul>
            <p>We’ll delete or anonymize data once no longer needed.</p>
          </section>

          <section id="your-rights">
            <h2>10) Your rights</h2>
            <p>
              Depending on your jurisdiction: access, correction, deletion, portability, restriction/objection, and complaint to a supervisory authority. To exercise rights, contact us (see §14). We may ask you to verify via Pi auth.
            </p>
          </section>

          <section id="children">
            <h2>11) Children</h2>
            <p>HyaPi is not intended for individuals under 18. If we learn we processed data of a minor, we’ll delete it.</p>
          </section>

          <section id="third-party">
            <h2>12) Third-party links &amp; protocols</h2>
            <p>We don’t control external protocols/websites. Use them at your own risk and review their policies.</p>
          </section>

          <section id="changes">
            <h2>13) Changes</h2>
            <p>We’ll post updates here and update the “Last updated” date.</p>
          </section>

          <section id="contact">
            <h2>14) Contact</h2>
            <p>[Legal name / entity], [address], [email].<br/>Data protection contact: [email].</p>
            <p style={{ marginTop: '1rem', fontSize: 14, color: 'rgba(255,255,255,0.6)' }}>See also: <Link href="/terms" className="underline">Terms of Service</Link></p>
          </section>
        </Box>
      </Box>
    </Box>
  );
}
