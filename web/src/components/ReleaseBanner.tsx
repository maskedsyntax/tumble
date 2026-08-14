import { APP_STORE_URL } from "@/lib/app-store";

export default function ReleaseBanner() {
  return (
    <aside className="relative z-20 border-b border-cream/10 bg-ink/30 backdrop-blur-md" aria-label="Latest release">
      <a
        href={APP_STORE_URL}
        target="_blank"
        rel="noreferrer"
        className="group mx-auto flex w-full max-w-6xl items-center gap-3 px-6 py-2.5"
        aria-label="Tumble v1.2 is out now with postcard frames — view it on the App Store"
      >
        <span className="flex items-center gap-2 font-mono text-[11px] font-bold tracking-[0.18em] text-gold">
          <span className="relative flex h-1.5 w-1.5" aria-hidden="true">
            <span className="release-pulse absolute inline-flex h-full w-full rounded-full bg-gold opacity-70" />
            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-gold" />
          </span>
          V1.2
        </span>

        <span className="min-w-0 flex-1 truncate font-mono text-[11px] uppercase tracking-[0.14em] text-cream/70">
          <span className="text-cream">Out now</span>
          <span className="mx-2 text-cream/30" aria-hidden="true">
            /
          </span>
          Postcard frames &amp; handwritten notes
        </span>

        <span className="hidden shrink-0 items-center gap-1.5 font-mono text-[11px] font-bold uppercase tracking-[0.12em] text-gold transition group-hover:text-cream sm:inline-flex">
          Update
          <span aria-hidden="true" className="transition-transform duration-300 group-hover:translate-x-0.5">
            &rarr;
          </span>
        </span>
      </a>
    </aside>
  );
}
