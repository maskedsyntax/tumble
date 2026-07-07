const SURFACES = [
  {
    name: "Lock Screen capture",
    status: "Built",
    body: "A LockedCameraCapture extension opens Tumble without turning the app into another feed.",
  },
  {
    name: "Dynamic Island camera",
    status: "Built",
    body: "Pull from the island, shoot, and watch the print fall back into the Drawer.",
  },
  {
    name: "Daily roll logic",
    status: "Built",
    body: "Twelve free shots reset daily, with Plus and Unlimited handled by StoreKit 2.",
  },
  {
    name: "Private storage",
    status: "Built",
    body: "Photos stay on device in the shared app container. No account, no cloud, no analytics SDK.",
  },
];

export default function AppProgress() {
  return (
    <section className="relative z-10 mx-auto grid max-w-5xl gap-9 px-6 py-14 md:grid-cols-[0.9fr_1.1fr] md:items-center md:py-18">
      <div>
        <div className="mb-3 text-xs font-semibold uppercase tracking-widest text-gold">
          Current build
        </div>
        <h2 className="font-display text-3xl font-semibold leading-tight text-cream sm:text-4xl">
          The app is in final submission prep.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          Tumble has moved from waitlist idea to native iOS app: camera
          extensions, Dynamic Island status, StoreKit purchases, privacy
          manifests, and the Drawer-first shooting flow are now in place.
        </p>
        <p className="mt-4 text-sm font-medium text-amber">
          Join the launch list and we will send one note when the App Store page
          is live.
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
