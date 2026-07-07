import Link from "next/link";

export default function NotFound() {
  return (
    <main className="relative z-10 mx-auto flex min-h-dvh max-w-5xl flex-col items-center justify-center px-6 py-16 text-center">
      <div className="relative mb-10 h-72 w-72 sm:h-80 sm:w-80" aria-hidden="true">
        <div className="absolute left-7 top-10 h-56 w-44 rotate-[-14deg] rounded-sm bg-cream/20" />
        <div className="absolute right-6 top-7 h-56 w-44 rotate-[12deg] rounded-sm bg-cream/25" />
        <div className="absolute left-1/2 top-0 h-64 w-48 -translate-x-1/2 rotate-[-2deg] rounded-sm bg-cream p-3 pb-14 text-ink shadow-2xl shadow-ink/40">
          <div className="flex aspect-square items-center justify-center overflow-hidden rounded-[2px] bg-blue-deep">
            <div className="relative h-full w-full bg-[linear-gradient(160deg,rgba(46,64,82,0.95),rgba(32,45,57,0.98))]">
              <span className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 font-display text-7xl font-semibold text-amber">
                404
              </span>
              <span className="absolute bottom-7 left-6 h-10 w-24 rotate-[-7deg] border-t-2 border-amber/70" />
              <span className="absolute right-7 top-8 h-8 w-8 rounded-full border border-cream/35" />
            </div>
          </div>
          <p className="mt-4 font-display text-xl font-semibold">No print found</p>
        </div>
      </div>

      <p className="text-xs font-semibold uppercase tracking-widest text-amber">
        Missing frame
      </p>
      <h1 className="mt-3 font-display text-5xl font-semibold leading-tight text-cream sm:text-6xl">
        This shot never developed.
      </h1>
      <p className="mt-5 max-w-xl leading-relaxed text-cream/80">
        The page you opened is not in this roll. Head back to Tumble and keep the
        camera close.
      </p>

      <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
        <Link
          href="/"
          className="inline-flex min-w-40 items-center justify-center rounded-full border border-amber/50 bg-amber px-5 py-3 text-sm font-semibold text-ink transition hover:bg-cream"
        >
          Back to Tumble
        </Link>
        <Link
          href="/support"
          className="inline-flex min-w-40 items-center justify-center rounded-full border border-cream/20 px-5 py-3 text-sm font-semibold text-cream transition hover:border-cream/45"
        >
          Contact support
        </Link>
      </div>
    </main>
  );
}
