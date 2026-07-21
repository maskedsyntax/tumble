import { APP_STORE_URL } from "@/lib/app-store";

export default function ReleaseBanner() {
  return (
    <aside
      className="relative z-20 overflow-hidden"
      aria-label="Latest release"
    >
      {/* Soft amber wash — brighter through the centre, fades at the edges */}
      <div
        className="absolute inset-0 bg-[radial-gradient(120%_140%_at_50%_0%,rgba(223,171,104,0.16),rgba(223,171,104,0.05)_48%,transparent_72%)]"
        aria-hidden="true"
      />
      <div
        className="absolute inset-0 bg-ink/20 backdrop-blur-md"
        aria-hidden="true"
      />

      {/* Hairline gold rules, like a print border */}
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-[linear-gradient(90deg,transparent,rgba(223,171,104,0.45)_20%,rgba(246,239,226,0.35)_50%,rgba(223,171,104,0.45)_80%,transparent)]"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute inset-x-0 bottom-0 h-px bg-[linear-gradient(90deg,transparent,rgba(223,171,104,0.35)_25%,rgba(223,171,104,0.55)_50%,rgba(223,171,104,0.35)_75%,transparent)]"
        aria-hidden="true"
      />

      <a
        href={APP_STORE_URL}
        target="_blank"
        rel="noreferrer"
        className="group relative mx-auto flex w-full max-w-3xl flex-col items-center justify-center gap-2.5 px-5 py-3.5 text-center sm:flex-row sm:gap-3.5 sm:py-3"
        aria-label="Tumble v1.1.0 is out now with nostalgic memory filters — view it on the App Store"
      >
        {/* Film-canister style version tablet */}
        <span className="inline-flex shrink-0 items-center gap-2 rounded-full border border-amber/40 bg-ink/55 px-3 py-1 shadow-[inset_0_1px_0_rgba(246,239,226,0.1),0_8px_24px_-16px_rgba(0,0,0,0.8)]">
          <span className="relative flex h-1.5 w-1.5" aria-hidden="true">
            <span className="release-pulse absolute inline-flex h-full w-full rounded-full bg-amber opacity-70" />
            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-amber shadow-[0_0_10px_rgba(223,171,104,0.95)]" />
          </span>
          <span className="font-display text-[11px] font-semibold tracking-[0.16em] text-amber uppercase">
            v1.1.0
          </span>
        </span>

        {/* Message — display italic for the product beat */}
        <span className="min-w-0 text-[13px] leading-snug text-cream/80 sm:text-sm">
          <span className="font-medium text-cream">Out now</span>
          <span className="mx-2 text-cream/30" aria-hidden="true">
            ·
          </span>
          <span className="font-display text-[15px] italic tracking-tight text-cream/95 sm:text-base">
            Nostalgic memory filters
          </span>
        </span>

        {/* CTA */}
        <span className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-amber/25 bg-amber/[0.08] px-3 py-1 text-[11px] font-semibold tracking-wide text-amber transition group-hover:border-amber/50 group-hover:bg-amber/[0.14] group-hover:text-cream sm:ml-0.5">
          Update on the App Store
          <span
            aria-hidden="true"
            className="transition-transform duration-300 group-hover:translate-x-0.5"
          >
            &rarr;
          </span>
        </span>
      </a>
    </aside>
  );
}
