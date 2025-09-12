import Link from 'next/link';
import { GOV_API_BASE } from '@hyapi/shared';
import { Box, Typography, Paper, Stack } from '@mui/material';

type LegalMeta = { terms_last_updated?: string } | null;

function TOC() {
  const items = [
    ['acceptance', '1) Acceptance'],
    ['who-we-are', '2) Who we are; what we are not'],
    ['eligibility', '3) Eligibility'],
    ['auth', '4) Access; accounts; Pi authentication'],
    ['service', '5) Service description'],
    ['custody', '6) Non-custodial / custody clarification'],
    ['fees', '7) Fees; pricing; taxes'],
    ['risk', '8) Risk disclosure'],
    ['prohibited', '9) Prohibited uses'],
    ['third-party', '10) Third-party services & links'],
    ['ip', '11) Intellectual property'],
    ['changes', '12) Changes; suspension'],
    ['warranty', '13) Warranty disclaimer'],
    ['liability', '14) Limitation of liability'],
    ['indemnity', '15) Indemnification'],
    ['law', '16) Governing law; dispute resolution'],
    ['misc', '17) Severability; entire agreement; assignment'],
    ['updates', '18) Updates'],
    ['contact', '19) Contact'],
  ] as const;
  return (
    <Box component="nav" aria-label="Table of contents" sx={{ fontSize: 13 }}>
      <Typography variant="subtitle2" sx={{ mb: 1, opacity: 0.8 }}>On this page</Typography>
      <Stack component="ul" spacing={0.5} sx={{ m:0, p:0, listStyle:'none' }}>
        {items.map(([id, title]) => (
          <Box key={id} component="li">
            <Typography component={Link} href={`#${id}`} sx={{
              color: 'text.secondary', textDecoration: 'none', fontSize: 13,
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

export default async function TermsPage() {
  const meta = await getMeta();
  const last = meta?.terms_last_updated ?? 'Sep 2025';

  return (
    <Box>
      <Typography variant="h4" fontWeight={600}>HyaPi Terms of Service</Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>Last updated: {last}</Typography>

      <Box sx={{ mt: 4, display: 'grid', gap: 4, gridTemplateColumns: { xs: '1fr', sm: '240px 1fr' } }}>
        <Box sx={{ position: { sm: 'sticky' }, top: { sm: 96 }, alignSelf: 'start' }}>
          <Paper variant="outlined" sx={{ p:2, borderRadius:2, background: 'linear-gradient(145deg, rgba(255,255,255,0.04), rgba(255,255,255,0.10))' }}>
            <TOC />
          </Paper>
        </Box>
        <Box component="article" sx={{ '& h2': { mt:4, mb:1.5, fontSize:20 }, '& h3': { mt:3, mb:1, fontSize:16 }, '& p': { mb:2, lineHeight:1.6 }, '& ul': { pl:3, mb:2 }, '& li': { mb:0.5 } }}>
          <section id="acceptance">
            <h2>1) Acceptance</h2>
            <p>By accessing or using HyaPi, you agree to these Terms and our Privacy Policy. If you don’t agree, don’t use HyaPi.</p>
          </section>

          <section id="who-we-are">
            <h2>2) Who we are; what we are not</h2>
            <p>
              HyaPi integrates with the Pi App Platform and may interact with public blockchains and third-party validators/venues. We are not the Pi Network or any underlying blockchain; we don’t control those networks or their availability.
            </p>
          </section>

          <section id="eligibility">
            <h2>3) Eligibility</h2>
            <p>You must be at least 18, capable of forming a contract, and not barred under applicable sanctions/export laws.</p>
          </section>

          <section id="auth">
            <h2>4) Access; accounts; Pi authentication</h2>
            <p>You authenticate via the Pi SDK (Pi.authenticate), and we may verify tokens server-side via the Pi Platform API. You’re responsible for safeguarding your device and Pi credentials.</p>
          </section>

          <section id="service">
            <h2>5) Service description (high level)</h2>
            <ul>
              <li><strong>Stake (U2A payment):</strong> You authorize a Pi payment; once the Pi Platform signals completion, our server credits your stake and mints/updates your hyaPi accounting balance.</li>
              <li><strong>Redemption (A2U payment):</strong> If liquidity is available (buffer), we initiate an app-to-user payment; otherwise, requests are queued and may require unbonding delays.</li>
              <li><strong>Governance:</strong> You may vote on allocation proposals; execution updates target venue weights.</li>
              <li><strong>Attestation/PPS:</strong> We publish NAV/PPS math and history for transparency (not a guarantee of returns).</li>
            </ul>
          </section>

          <section id="custody">
            <h2>6) Non-custodial / custody clarification</h2>
            <p>
              HyaPi coordinates programmatic actions among Pi payments, venues, and validators. Some funds may temporarily reside in operational wallets (e.g., buffers, exchanges) to fulfill redemptions. We do not take title to user assets; hyaPi is an accounting representation for your claim on the treasury. You retain all risks tied to network operation, venues, and counterparties.
            </p>
          </section>

          <section id="fees">
            <h2>7) Fees; pricing; taxes</h2>
            <ul>
              <li>Fees: initiation (e.g., 0.5%), early exit (e.g., 1%), venue fees (on-chain gas, exchange, validator commissions). Exact fees are disclosed in-app and may change via governance.</li>
              <li>No guaranteed APY: Any APY shown is an estimate; actual returns vary.</li>
              <li>Taxes: You’re responsible for your tax obligations.</li>
            </ul>
          </section>

          <section id="risk">
            <h2>8) Risk disclosure</h2>
            <p>
              Using HyaPi involves substantial risks, including market/liquidity risk, protocol/contract risk, counterparty risk, network risk, and regulatory risk. You could lose funds or experience delays. HyaPi does not provide investment advice or fiduciary services.
            </p>
          </section>

          <section id="prohibited">
            <h2>9) Prohibited uses</h2>
            <p>
              You agree not to use HyaPi for illegal purposes; to violate sanctions/export controls; to interfere with the service; or to engage in fraud, wash trading, market manipulation, or money laundering. You must comply with Pi’s developer/platform terms and any venue policies.
            </p>
          </section>

          <section id="third-party">
            <h2>10) Third-party services &amp; links</h2>
            <p>We’re not responsible for third-party sites, protocols, validators, or exchanges. You use them at your own risk.</p>
          </section>

          <section id="ip">
            <h2>11) Intellectual property</h2>
            <p>HyaPi owns the app UI, branding, and original content. You keep rights in your feedback but grant us a non-exclusive license to use it to improve the service.</p>
          </section>

          <section id="changes">
            <h2>12) Changes; suspension</h2>
            <p>We may change, suspend, or discontinue parts of HyaPi with or without notice, including for security, legal, or market-disruption reasons.</p>
          </section>

          <section id="warranty">
            <h2>13) Warranty disclaimer</h2>
            <p>HyaPi is provided “as is” and “as available” without warranties of any kind, express or implied.</p>
          </section>

          <section id="liability">
            <h2>14) Limitation of liability</h2>
            <p>To the maximum extent permitted by law, HyaPi is not liable for indirect or consequential damages; total liability is capped to fees paid in the prior 12 months.</p>
          </section>

          <section id="indemnity">
            <h2>15) Indemnification</h2>
            <p>You agree to indemnify and hold harmless HyaPi and its affiliates from claims arising out of your use of HyaPi, violation of these Terms, or laws.</p>
          </section>

          <section id="law">
            <h2>16) Governing law; dispute resolution</h2>
            <p>These Terms are governed by the laws of [Colorado, USA]. Disputes resolved by binding arbitration in [Denver, Colorado], except equitable relief for IP/confidentiality.</p>
          </section>

          <section id="misc">
            <h2>17) Severability; entire agreement; assignment</h2>
            <p>If a provision is unenforceable, the rest remains in effect. These Terms are the entire agreement. You may not assign without consent; we may assign in connection with a merger or sale.</p>
          </section>

          <section id="updates">
            <h2>18) Updates</h2>
            <p>We may update these Terms; continued use means acceptance of changes.</p>
          </section>

          <section id="contact">
            <h2>19) Contact</h2>
            <p>[Legal name / entity], [address], [email].</p>
            <p style={{ marginTop: '1rem', fontSize: 14, color: 'rgba(255,255,255,0.6)' }}>See also: <Link href="/privacy" className="underline">Privacy Policy</Link></p>
          </section>
        </Box>
      </Box>
    </Box>
  );
}
