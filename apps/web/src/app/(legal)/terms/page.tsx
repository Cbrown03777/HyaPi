import Link from 'next/link';
import { GOV_API_BASE } from '@hyapi/shared';

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
    <nav aria-label="Table of contents" className="text-sm">
      <div className="mb-2 font-medium text-white/80">On this page</div>
      <ul className="space-y-1">
        {items.map(([id, title]) => (
          <li key={id}>
            <a href={`#${id}`} className="text-white/70 hover:text-white underline-offset-4 hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[color:var(--acc)] rounded">
              {title}
            </a>
          </li>
        ))}
      </ul>
    </nav>
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
    <div className="mx-auto max-w-screen-lg px-4 sm:px-6 py-6">
      <h1 className="text-2xl sm:text-3xl font-semibold">HyaPi Terms of Service</h1>
      <p className="mt-2 text-white/70">Last updated: {last}</p>

      <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-[240px_1fr]">
        <div className="sm:sticky sm:top-24 h-max">
          <div className="rounded-lg border border-white/10 bg-white/5 p-3">
            <TOC />
          </div>
        </div>
        <article className="prose prose-invert max-w-none">
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
            <p className="mt-4 text-sm text-white/60">See also: <Link href="/privacy" className="underline">Privacy Policy</Link></p>
          </section>
        </article>
      </div>
    </div>
  );
}
