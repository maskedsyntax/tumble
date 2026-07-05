/**
 * The Roll is the whole product thesis (spec §2.1) — scarcity, not a paywall.
 * This section makes that land clearly. Three plain beats: the limit, the
 * gesture, the archive.
 */
const BEATS = [
  {
    kicker: "The Roll",
    title: "Twelve shots a day.",
    body: "No ads, no unlocks, no “watch this for three more.” Just twelve, fresh each morning, enough to make every shot feel deliberate.",
  },
  {
    kicker: "Pay once",
    title: "Need more? Own more.",
    body: "If twelve is not enough, unlock more rolls with a small one-time payment. No monthly subscription, no renewal, no forever meter running in the background.",
  },
  {
    kicker: "Shake to develop",
    title: "You have to wait for it.",
    body: "Take a shot and it comes out blank, face-down. Give your phone a shake and watch it develop, washed-out at first, settling into full color like real instant film.",
  },
];

export default function RollExplainer() {
  return (
    <section className="relative z-10 mx-auto flex max-w-5xl flex-col justify-center px-6 py-8 md:py-10">
      <div className="grid gap-10 sm:grid-cols-3">
        {BEATS.map((b) => (
          <div key={b.kicker} className="text-center sm:text-left">
            <div className="mb-3 text-xs font-semibold uppercase tracking-widest text-amber">
              {b.kicker}
            </div>
            <h2 className="font-display text-2xl font-semibold leading-snug text-cream">
              {b.title}
            </h2>
            <p className="mt-3 text-[15px] leading-relaxed text-cream/75">{b.body}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
