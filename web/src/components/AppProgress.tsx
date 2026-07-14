const SURFACES = [
  {
    name: "Quick capture",
    status: "Built",
    body: "Pull the camera from the Lock Screen or Dynamic Island — shoot without opening a feed.",
  },
  {
    name: "Daily roll logic",
    status: "Built",
    body: "Twelve free shots reset every day, with Plus and Unlimited as one-time unlocks.",
  },
  {
    name: "Shake to develop",
    status: "Built",
    body: "Fresh prints start blank. Shake your phone to bring the image up, or press and hold when motion is reduced.",
  },
  {
    name: "Private storage",
    status: "Built",
    body: "Photos stay on device. No account, no cloud, no analytics SDK.",
  },
];

export default function AppProgress() {
  return (
    <section className="relative z-10 mx-auto grid max-w-5xl gap-9 px-6 py-14 md:grid-cols-[0.9fr_1.1fr] md:items-center md:py-18">
      <div>
        <div className="mb-3 text-xs font-semibold uppercase tracking-widest text-gold">
          Live build
        </div>
        <h2 className="font-display text-3xl font-semibold leading-tight text-cream sm:text-4xl">
          The iPhone app is on the App Store.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          Tumble is no longer just a waitlist idea. The native iOS app is live
          with the daily roll, shake-to-develop, the private Drawer, and
          one-time unlocks.
        </p>
        <p className="mt-4 text-sm font-medium text-amber">
          Download it now and start with twelve free shots today.
        </p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        {SURFACES.map((surface) => (
          <article
            key={surface.name}
            className="border border-cream/14 bg-cream/[0.045] p-5 shadow-[0_18px_50px_-36px_rgba(0,0,0,0.9)] backdrop-blur-sm"
          >
            <div className="flex items-center justify-between gap-3">
              <h3 className="font-display text-xl font-semibold text-cream">
                {surface.name}
              </h3>
              <span className="shrink-0 rounded-full border border-amber/35 bg-amber/10 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-amber">
                {surface.status}
              </span>
            </div>
            <p className="mt-3 text-sm leading-relaxed text-cream/68">{surface.body}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
