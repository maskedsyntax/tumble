import { Sprockets } from "./FilmEdge";

export default function Footer() {
  return (
    <footer className="relative z-10 px-6 pb-12 pt-6">
      <div className="mx-auto max-w-6xl">
        <Sprockets className="opacity-60" />

        <div className="mt-8 flex flex-col items-center justify-between gap-5 sm:flex-row">
          <div className="flex items-baseline gap-3">
            <span className="font-display text-lg font-bold tracking-tight text-cream">Tumble</span>
            <span className="font-mono text-[11px] uppercase tracking-[0.14em] text-cream/45">
              Film for iPhone
            </span>
          </div>

          <nav className="flex items-center gap-7 font-mono text-[11px] uppercase tracking-[0.12em] text-cream/60">
            <a href="/privacy" className="transition hover:text-cream">
              Privacy
            </a>
            <a href="/terms" className="transition hover:text-cream">
              Terms
            </a>
            <a href="/support" className="transition hover:text-cream">
              Support
            </a>
          </nav>
        </div>

        <p className="mt-6 text-center font-mono text-[10px] uppercase tracking-[0.14em] text-cream/35 sm:text-left">
          &copy; {new Date().getFullYear()} Tumble · Shake to see what you shot.
        </p>
      </div>
    </footer>
  );
}
