export const metadata = { title: 'Governance | HyaPi' };

export default function GovernancePage() {
  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">Governance</h1>
        <p className="text-sm text-white/60 max-w-prose">Propose, review and vote on allocation or protocol parameter changes. (Demo placeholder page)</p>
      </header>
      <section className="rounded border border-white/15 bg-white/5 p-4 text-sm text-white/70">
        Governance modules would surface here (proposals list, status, create flow). This stub fixes the 404 so navigation works during the demo.
      </section>
    </div>
  );
}