import { Stamp } from "./FilmEdge";

/**
 * The Roll is the whole product thesis: scarcity, not a paywall. Three plain
 * beats — the limit, the gesture, the archive — stamped like frames on a roll.
 */
const BEATS = [
  {
    frame: "01",
    kicker: "The Roll",
    title: "Twelve shots a day.",
    body: "A fresh roll every morning. Enough to notice, never enough to mindlessly collect. No ads, no watch-this unlocks, no feed disguised as a camera.",
  },
  {
    frame: "02",
    kicker: "Quick capture",
    title: "Shoot without opening a feed.",
    body: "Pull the camera from the Lock Screen or Dynamic Island. The same ritual, from wherever you already are.",
  },
  {
    frame: "03",
    kicker: "Shake to develop",
    title: "You have to wait for it.",
    body: "Fresh prints come up blank. Shake your phone to develop them, the way an instant print settles into colour.",
  },
];

export default function RollExplainer() {
  return (
    <section className="relative z-10 mx-auto max-w-6xl px-6 py-16 md:py-20">
      <div className="grid gap-x-8 gap-y-10 sm:grid-cols-3">
        {BEATS.map((b) => (
          <div key={b.kicker} className="border-t border-cream/12 pt-5">
            <Stamp frame={b.frame}>{b.kicker}</Stamp>
            <h2 className="mt-4 font-display text-2xl font-bold leading-snug text-cream">
              {b.title}
            </h2>
            <p className="mt-3 text-[15px] leading-relaxed text-cream/72">{b.body}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
