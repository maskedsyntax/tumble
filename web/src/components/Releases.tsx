import { APP_STORE_URL } from "@/lib/app-store";
import { Stamp } from "./FilmEdge";

/**
 * The release log — a real, typed sequence, so a timeline device is honest here.
 * Newest (and what's next) at the top. Version tags are set in the film-mono
 * voice, like frame numbers on a roll.
 */
const ENTRIES = [
  {
    tag: "NEXT",
    upcoming: true,
    title: "Film packs",
    body: "A shelf of film stocks — every print with its own look. Free everyday rolls, plus one-time packs for disposables, darkroom black & white, and summer leaks.",
  },
  {
    tag: "v1.2",
    title: "Postcard frames",
    body: "Mount a developed print in one of four finishes with a handwritten note, previewed at full size before it saves.",
  },
  {
    tag: "v1.1",
    title: "Memory filters",
    body: "Faded Instant and Warm Archive, applied to the print and carried into every export — the start of the film-stock idea.",
  },
  {
    tag: "v1.0",
    title: "The daily roll",
    body: "Twelve shots a day, shake-to-develop, quick capture from the Lock Screen, and the private Drawer.",
  },
];

const PROMISES = ["On device", "No account", "No cloud", "No subscriptions"];

export default function Releases() {
  return (
    <section className="relative z-10 mx-auto max-w-6xl px-6 py-16 md:py-20">
      <div className="grid gap-12 md:grid-cols-[0.85fr_1.15fr] md:gap-16">
        <div>
          <Stamp>Shipping log</Stamp>
          <h2 className="mt-4 font-display text-3xl font-bold leading-tight text-cream sm:text-4xl">
            On the App Store since July, and still developing.
          </h2>
          <p className="mt-4 leading-relaxed text-cream/75">
            The native iPhone app ships small, frequent releases — each one makes
            the camera a little slower in the ways that count.
          </p>

          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noreferrer"
            className="mt-7 inline-flex items-center gap-2 font-mono text-xs font-bold uppercase tracking-[0.14em] text-gold transition hover:text-cream"
          >
            Download on the App Store
            <span aria-hidden>&rarr;</span>
          </a>

          <div className="mt-8 flex flex-wrap gap-2">
            {PROMISES.map((p) => (
              <span
                key={p}
                className="rounded-full border border-cream/15 px-3 py-1 font-mono text-[10px] uppercase tracking-[0.12em] text-cream/60"
              >
                {p}
              </span>
            ))}
          </div>
        </div>

        {/* Timeline */}
        <ol className="relative border-l border-cream/12 pl-7">
          {ENTRIES.map((e) => (
            <li key={e.tag} className="relative pb-8 last:pb-0">
              <span
                aria-hidden
                className={`absolute -left-[calc(1.75rem+1px)] top-1.5 h-2.5 w-2.5 -translate-x-1/2 rounded-full ring-4 ring-[#243342] ${
                  e.upcoming ? "bg-gold" : "bg-cream/35"
                }`}
              />
              <div className="flex items-center gap-3">
                <span
                  className={`font-mono text-[11px] font-bold uppercase tracking-[0.14em] ${
                    e.upcoming ? "text-gold" : "text-cream/50"
                  }`}
                >
                  {e.tag}
                </span>
                <h3 className="font-display text-xl font-bold text-cream">{e.title}</h3>
              </div>
              <p className="mt-2 max-w-lg text-[15px] leading-relaxed text-cream/70">{e.body}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
