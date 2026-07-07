/**
 * The Roll is the whole product thesis (spec §2.1) — scarcity, not a paywall.
 * This section makes that land clearly. Three plain beats: the limit, the
 * gesture, the archive.
 */
const BEATS = [
  {
    kicker: "The Roll",
    title: "Twelve shots a day.",
    body: "Your free roll resets every day. No ads, no watch-this unlocks, no feed disguised as a camera.",
  },
  {
    kicker: "Island camera",
    title: "Pull down to shoot.",
    body: "The camera lives as a small top handle. Drag it open, take the shot, and the print drops straight back into the Drawer.",
  },
  {
    kicker: "Shake to develop",
    title: "You have to wait for it.",
    body: "Fresh prints start blank. Shake your phone to develop them, or press and hold when motion is reduced.",
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
