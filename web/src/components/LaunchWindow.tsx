const WINDOWS = [
  {
    label: "Dual launch",
    title: "iPhone and Android in the same window.",
    body: "The iOS build is in Apple review. Android is at feature parity and planned to ship alongside it, so the first wave is not iPhone-only.",
  },
  {
    label: "First roll",
    title: "Launch-week notes go to the waitlist first.",
    body: "People on the list will get both store links before we post wider. That makes the first wave feel like a small room, not a public drop.",
  },
  {
    label: "One chance",
    title: "The first cohort only happens once.",
    body: "Join now if you want to be part of the first group developing a Tumble roll as soon as either store page is live.",
  },
];

export default function LaunchWindow() {
  return (
    <section className="relative z-10 mx-auto max-w-5xl px-6 py-12 md:py-16">
      <div className="mb-8 max-w-2xl">
        <div className="mb-3 text-xs font-semibold uppercase tracking-widest text-gold">
          Launch window
        </div>
        <h2 className="font-display text-3xl font-semibold leading-tight text-cream sm:text-4xl">
          Tumble is close enough that joining now matters.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          iOS is in Apple review and Android is lined up for the same launch.
          This is the quiet window before the public links exist. The waitlist
          is the easiest way to be in the first wave instead of hearing about
          it later.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {WINDOWS.map((window) => (
          <article
            key={window.label}
            className="border border-cream/14 bg-cream/[0.045] p-5 backdrop-blur-sm"
          >
            <div className="text-xs font-semibold uppercase tracking-widest text-amber">
              {window.label}
            </div>
            <h3 className="mt-3 font-display text-xl font-semibold leading-snug text-cream">
              {window.title}
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-cream/70">{window.body}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
