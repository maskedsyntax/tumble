import Image from "next/image";
import { Stamp } from "./FilmEdge";

/**
 * "The app," positioned honestly: a phone showing the Drawer — a scatter of
 * developed prints, not a grid. Built from the same cream-stock print the app
 * renders (and the site's frames), so it reads as the real product surface
 * rather than a stock device render.
 */

type Print = {
  src: string;
  note: string;
  date: string;
  className: string;
};

const PRINTS: Print[] = [
  {
    src: "/frames/frame-1.jpg",
    note: "after the rain",
    date: "08·14",
    className: "left-[8%] top-[16%] w-[52%] -rotate-6",
  },
  {
    src: "/frames/frame-3.jpg",
    note: "long way down",
    date: "08·13",
    className: "right-[6%] top-[30%] w-[50%] rotate-[7deg]",
  },
  {
    src: "/frames/frame-4.jpg",
    note: "quiet afternoon",
    date: "08·11",
    className: "left-[18%] bottom-[10%] w-[54%] -rotate-2",
  },
];

function DrawerPrint({ src, note, date, className }: Print) {
  return (
    <div
      className={`absolute [container-type:inline-size] drop-shadow-[0_8cqw_10cqw_rgba(0,0,0,0.45)] ${className}`}
    >
      <div className="rounded-[3cqw] bg-[#f4ecda] p-[4cqw] pb-[11cqw]">
        <div className="relative aspect-square w-full overflow-hidden rounded-[1cqw] ring-1 ring-ink/15">
          <Image src={src} alt="" fill sizes="140px" className="object-cover" />
        </div>
        <div className="mt-[2.5cqw] flex items-end justify-between px-[0.5cqw]">
          <span className="truncate font-script text-[7cqw] leading-none text-ink/72">{note}</span>
          <span className="font-mono text-[3.4cqw] leading-none font-bold text-[#c67a2e]">{date}</span>
        </div>
      </div>
    </div>
  );
}

export default function AppShowcase() {
  return (
    <section className="relative z-10 mx-auto grid max-w-6xl items-center gap-12 px-6 py-16 md:grid-cols-2 md:gap-16 md:py-20">
      <div className="order-2 md:order-1">
        <Stamp frame="HOME">The Drawer</Stamp>
        <h2 className="mt-4 font-display text-3xl font-bold leading-tight text-cream sm:text-4xl">
          Your shots pile up,
          <br />
          not scroll past.
        </h2>
        <p className="mt-4 max-w-md leading-relaxed text-cream/75">
          Tumble opens to a drawer of prints, not a viewfinder and not an endless
          camera roll. Today&rsquo;s roll sits in a loose pile you can shuffle
          through; older days tuck themselves into collections.
        </p>

        <ul className="mt-6 space-y-2.5">
          {[
            "Tap a blank print and shake to develop it.",
            "Every print keeps its film stock, note, and date.",
            "Nothing leaves the device — no account, no cloud.",
          ].map((line) => (
            <li key={line} className="flex items-start gap-3 text-[15px] text-cream/72">
              <span aria-hidden className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-gold" />
              {line}
            </li>
          ))}
        </ul>
      </div>

      {/* Phone with the Drawer scatter */}
      <div className="order-1 flex justify-center md:order-2">
        <div className="relative w-[min(78vw,300px)]">
          <div className="absolute -inset-6 rounded-[3rem] bg-gold/15 blur-3xl" aria-hidden="true" />
          <div className="relative aspect-[9/19] w-full rounded-[2.6rem] border border-cream/15 bg-[#161f28] p-2.5 shadow-[0_44px_90px_-30px_rgba(0,0,0,0.8)]">
            <div className="relative h-full w-full overflow-hidden rounded-[2.1rem] bg-gradient-to-b from-[#1c2732] to-[#141c25]">
              {/* status bar + title */}
              <div className="flex items-center justify-between px-5 pt-4">
                <span className="font-mono text-[11px] font-bold text-cream/80">9:41</span>
                <span className="font-mono text-[11px] text-cream/45">▚ ▘ ▐</span>
              </div>
              <div className="px-5 pt-3">
                <div className="font-display text-lg font-bold tracking-tight text-gold">tumble</div>
                <div className="mt-0.5 font-mono text-[10px] uppercase tracking-[0.16em] text-cream/45">
                  Today&rsquo;s roll · 8 of 12
                </div>
              </div>
              {/* scatter */}
              <div className="relative mt-2 h-full w-full">
                {PRINTS.map((p) => (
                  <DrawerPrint key={p.src} {...p} />
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
