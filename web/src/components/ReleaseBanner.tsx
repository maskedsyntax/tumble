import { APP_STORE_URL } from "@/lib/app-store";

export default function ReleaseBanner() {
  return (
    <aside
      className="relative z-20 border-b border-amber/20 bg-amber/[0.09] px-4 py-2.5 backdrop-blur-md"
      aria-label="Latest release"
    >
      <a
        href={APP_STORE_URL}
        target="_blank"
        rel="noreferrer"
        className="group mx-auto flex w-fit items-center justify-center gap-2 text-center text-sm font-medium text-cream/90 transition hover:text-cream"
        aria-label="Tumble v1.1.0 is out now — view it on the App Store"
      >
        <span
          className="h-1.5 w-1.5 rounded-full bg-amber shadow-[0_0_12px_rgba(223,171,104,0.8)]"
          aria-hidden="true"
        />
        <span>
          <span className="font-semibold text-amber">v1.1.0</span> is out now!
        </span>
        <span
          className="text-amber transition-transform group-hover:translate-x-0.5"
          aria-hidden="true"
        >
          &rarr;
        </span>
      </a>
    </aside>
  );
}
