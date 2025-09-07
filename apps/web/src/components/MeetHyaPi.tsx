"use client";

export function MeetHyaPi() {
  const Tile = ({ title, desc, href }: { title: string; desc: string; href: string }) => (
    <a
      href={href}
      className="group rounded-xl border border-neutral-200 p-5 hover:bg-neutral-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-600"
      aria-label={`${title} – ${desc}`}
    >
      <div className="flex items-start justify-between">
        <div>
          <div className="text-lg font-semibold text-neutral-900">{title}</div>
          <p className="mt-1 text-sm text-neutral-600">{desc}</p>
        </div>
        <span className="text-neutral-400 group-hover:text-neutral-700" aria-hidden>
          ➔
        </span>
      </div>
    </a>
  );

  return (
    <section className="py-6 sm:py-8">
      <div className="max-w-6xl mx-auto px-4">
        <h3 className="text-lg font-semibold">Meet HyaPi</h3>
        <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Tile
            title="Stake"
            desc="Lock your Pi (or stay flexible) and earn programmatic yield from curated venues."
            href="/stake"
          />
          <Tile
            title="Redeem"
            desc="Exit any time. Instant from buffer; queued when rebalancing is needed."
            href="/redeem"
          />
        </div>
      </div>
    </section>
  );
}
