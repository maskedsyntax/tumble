import { APP_STORE_URL } from "@/lib/app-store";

export default function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-cream/10 bg-blue-deep/85 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-6 px-5 sm:px-6">
        <a href="/#top" className="font-display text-xl font-extrabold tracking-tight text-cream transition hover:text-gold" aria-label="Tumble home">
          Tumble<span className="text-gold">.</span>
        </a>
        <nav className="hidden items-center gap-7 font-mono text-[11px] font-bold uppercase tracking-[0.14em] text-cream/60 md:flex" aria-label="Primary navigation">
          <a href="/#looks" className="transition hover:text-cream">Looks</a>
          <a href="/#how-it-works" className="transition hover:text-cream">How it works</a>
          <a href="/#pricing" className="transition hover:text-cream">Pricing</a>
        </nav>
        <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="inline-flex min-h-10 items-center justify-center rounded-full bg-gold px-4 font-display text-sm font-bold text-ink shadow-[0_10px_30px_-16px_rgba(223,171,104,0.9)] transition hover:-translate-y-0.5 hover:bg-cream focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-gold sm:px-5">
          Download
        </a>
      </div>
    </header>
  );
}
