import type { Metadata } from "next";
import Link from "next/link";
import { APP_STORE_URL } from "@/lib/app-store";
import { Sprockets, Stamp } from "@/components/FilmEdge";

export const metadata: Metadata = {
  title: "This frame isn't on the roll",
  robots: { index: false, follow: true },
};

const WELL_GRAIN =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")";

export default function NotFound() {
  return (
    <main className="relative z-10 min-h-dvh w-full overflow-x-hidden">
      <div className="mx-auto flex min-h-dvh w-full max-w-6xl flex-col px-6">
        <header className="flex items-center justify-between gap-4 pt-8">
          <Link
            href="/"
            className="shrink-0 font-display text-lg font-bold tracking-tight text-gold transition hover:text-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold focus-visible:ring-offset-2 focus-visible:ring-offset-blue"
          >
            tumble
          </Link>
          <div className="hidden sm:block">
            <Stamp frame="404">Void</Stamp>
          </div>
        </header>

        <div className="flex w-full min-w-0 flex-1 flex-col items-center justify-center py-10 text-center md:py-16">
          <div className="grid w-full min-w-0 max-w-[17rem] place-items-center overflow-hidden py-2 sm:max-w-[18rem]">
            <BlankPrint />
          </div>

          <h1 className="mt-8 w-full max-w-[18rem] font-display text-[1.95rem] font-extrabold leading-[0.95] tracking-tight text-cream sm:max-w-md sm:text-[clamp(2.4rem,5vw,3.6rem)]">
            This one never
            <br />
            came out.
          </h1>
          <p className="mt-5 w-full max-w-[18rem] text-[15px] leading-relaxed text-cream/75 sm:max-w-md sm:text-lg">
            That address isn&rsquo;t on this roll.
            <br className="sm:hidden" /> Go back to Tumble, or get the camera
            for iPhone.
          </p>

          <div className="mt-8 flex w-full max-w-[18rem] flex-col items-stretch gap-3 sm:mt-9 sm:max-w-md sm:flex-row sm:items-center sm:justify-center">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-2xl bg-gold px-5 py-3 font-display text-base font-extrabold tracking-tight text-ink shadow-[0_16px_38px_-16px_rgba(223,171,104,0.85)] ring-1 ring-inset ring-cream/30 transition duration-200 hover:-translate-y-0.5 hover:shadow-[0_22px_46px_-16px_rgba(223,171,104,0.95)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold focus-visible:ring-offset-2 focus-visible:ring-offset-blue"
          >
            Back to Tumble
          </Link>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center justify-center rounded-2xl border border-cream/20 px-5 py-3 font-display text-base font-bold tracking-tight text-cream transition hover:border-cream/45 hover:bg-cream/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold focus-visible:ring-offset-2 focus-visible:ring-offset-blue"
          >
            Get the app
          </a>
        </div>

        <p className="mt-8 font-mono text-[11px] uppercase tracking-[0.16em] text-cream/45">
          Questions?{" "}
          <Link
            href="/support"
            className="text-gold transition hover:text-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold focus-visible:ring-offset-2 focus-visible:ring-offset-blue"
          >
            Support
          </Link>
        </p>
      </div>

      <footer className="pb-10">
        <Sprockets className="opacity-50" />
        <p className="mt-5 text-center font-mono text-[10px] uppercase tracking-[0.14em] text-cream/35">
          &copy; {new Date().getFullYear()} Tumble · Twelve shots a day
        </p>
      </footer>
      </div>
    </main>
  );
}

/** The same cream-stock print the app shows for an undeveloped shot — pale
 *  chemical well, thick chin, no caption. VOID is rebate fogging, not a display number. */
function BlankPrint() {
  return (
    <figure
      className="animate-print-settle w-[min(100%,15.5rem)] sm:w-[min(100%,17.5rem)] [container-type:inline-size]"
      aria-hidden="true"
    >
      <div
        className="rounded-[2cqw] pt-[6cqw] pr-[6cqw] pb-[15cqw] pl-[6cqw] shadow-[0_28px_60px_-24px_rgba(0,0,0,0.75)]"
        style={{ backgroundColor: "#f4ecda" }}
      >
        <div
          className="relative aspect-square w-full overflow-hidden rounded-[0.8cqw] ring-1 ring-ink/15"
          style={{
            backgroundImage: [
              "radial-gradient(70% 55% at 22% 12%, rgba(255,255,255,0.42), transparent 62%)",
              "radial-gradient(48% 40% at 84% 90%, rgba(120,70,40,0.14), transparent 70%)",
              "linear-gradient(180deg, #e8dfcc, #d8cdb4)",
            ].join(", "),
          }}
        >
          <span
            className="absolute inset-0 opacity-[0.22] mix-blend-multiply"
            style={{ backgroundImage: WELL_GRAIN }}
          />
          <span className="absolute left-1/2 top-[46%] -translate-x-1/2 -translate-y-1/2 -rotate-[14deg] font-mono text-[12cqw] font-bold tracking-[0.42em] text-ink/18">
            VOID
          </span>
        </div>
      </div>
    </figure>
  );
}
