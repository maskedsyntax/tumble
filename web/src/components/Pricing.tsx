/**
 * Pricing: free to start, with two one-time unlocks (no subscriptions). The free
 * tier keeps Tumble's identity (the daily Roll) while paid tiers lift the
 * ceiling for people who want it. All one-time purchases per the "no
 * subscriptions" stance.
 */

type Tier = {
  name: string;
  price: string;
  priceNote?: string;
  shots: string;
  blurb: string;
  featured?: boolean;
};

const TIERS: Tier[] = [
  {
    name: "Free",
    price: "Free",
    shots: "12 shots a day",
    blurb:
      "The daily roll, shake-to-develop, and the whole Drawer. Everything that makes Tumble, Tumble.",
  },
  {
    name: "Plus",
    price: "$5.99",
    priceNote: "one-time",
    shots: "72 shots a day",
    blurb:
      "Six rolls a day for heavier shooters, still fresh every morning. Pay once, keep it forever.",
    featured: true,
  },
  {
    name: "Unlimited",
    price: "$11.99",
    priceNote: "one-time",
    shots: "Unlimited shots",
    blurb:
      "No daily limit at all. Shoot as much as you like, for as long as you like. One payment, done.",
  },
];

export default function Pricing() {
  return (
    <section className="relative z-10 mx-auto flex max-w-5xl flex-col justify-center px-6 py-14 md:py-18">
      <div className="mb-3 text-center text-xs font-semibold uppercase tracking-widest text-gold">
        Pay once. Never again.
      </div>
      <h2 className="text-center font-display text-3xl font-semibold text-cream sm:text-4xl">
        Free to start. Yours to keep.
      </h2>
      <p className="mx-auto mt-3 mb-12 max-w-md text-center text-cream/75">
        Tumble is free forever. Want more than twelve a day? Unlock it once. No
        subscriptions, no renewals, ever.
      </p>

      <div className="grid gap-5 sm:grid-cols-3">
        {TIERS.map((t) => (
          <div
            key={t.name}
            className={`relative flex flex-col rounded-2xl border p-6 backdrop-blur-sm ${
              t.featured
                ? "border-gold/60 bg-gold/[0.07] ring-1 ring-gold/40"
                : "border-cream/15 bg-cream/[0.04]"
            }`}
          >
            {t.featured && (
              <span className="absolute -top-3 left-6 rounded-full bg-gold px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-ink">
                Most popular
              </span>
            )}

            <div className="text-sm font-semibold uppercase tracking-widest text-cream/60">
              {t.name}
            </div>

            <div className="mt-3 flex items-baseline gap-2">
              <span className="font-display text-4xl font-semibold text-cream">
                {t.price}
              </span>
              {t.priceNote && (
                <span className="text-sm text-cream/50">{t.priceNote}</span>
              )}
            </div>

            <div className="mt-4 font-medium text-gold">{t.shots}</div>
            <p className="mt-2 text-sm leading-relaxed text-cream/70">{t.blurb}</p>
          </div>
        ))}
      </div>

      <p className="mt-8 text-center text-xs text-cream/45">
        One-time purchases · no subscriptions · restore anytime
      </p>
    </section>
  );
}
