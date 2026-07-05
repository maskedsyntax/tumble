const SUPPORT_EMAIL = "aftaab@aftab.dev";

export default function Footer() {
  return (
    <footer className="relative z-10 snap-start border-t border-cream/10 px-6 py-10">
      <div className="mx-auto flex max-w-5xl flex-col items-center justify-between gap-4 text-sm text-cream/60 sm:flex-row">
        <div className="flex items-center gap-2 font-display text-base font-semibold text-cream/85">
          Tumble
          <span className="font-sans text-xs font-normal text-cream/50">
            On-device. No account. No cloud.
          </span>
        </div>

        <nav className="flex items-center gap-6">
          <a href="/privacy" className="transition hover:text-cream">
            Privacy
          </a>
          <a href="/terms" className="transition hover:text-cream">
            Terms
          </a>
          <a href={`mailto:${SUPPORT_EMAIL}`} className="transition hover:text-cream">
            Support
          </a>
        </nav>
      </div>

      <p className="mx-auto mt-6 max-w-5xl text-center text-xs text-cream/40 sm:text-left">
        &copy; {new Date().getFullYear()} Tumble. Shake to see what you shot.
      </p>
    </footer>
  );
}
