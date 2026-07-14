const WINDOWS = [
  {
    label: "Live",
    title: "Tumble is out on iPhone.",
    body: "The App Store page is live, so the first roll is no longer waiting on review. Download it and start shooting today.",
  },
  {
    label: "First roll",
    title: "The daily roll is ready.",
    body: "Twelve free shots reset every morning. Shoot deliberately, then shake to develop the prints into your private Drawer.",
  },
  {
    label: "Own it",
    title: "Launch pricing stays simple.",
    body: "Tumble is free to start, with Plus and Unlimited available as one-time unlocks. No subscriptions, no renewal games.",
  },
];

export default function LaunchWindow() {
  return (
    <section className="relative z-10 mx-auto max-w-5xl px-6 py-12 md:py-16">
      <div className="mb-8 max-w-2xl">
        <div className="mb-3 text-xs font-semibold uppercase tracking-widest text-gold">
          Now available
        </div>
        <h2 className="font-display text-3xl font-semibold leading-tight text-cream sm:text-4xl">
          Tumble is open for its first real rolls.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          The iPhone app has cleared review and is live on the App Store. If you
          were waiting for the public link, this is it.
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
