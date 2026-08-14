import Image from "next/image";
import { Stamp } from "./FilmEdge";

/**
 * Teaser for the next release: film stocks, sold in one-time packs. Each print
 * gets its own look, picked from a shelf of film — mirroring the app's look
 * picker ("one shot, every film"). Names and blurbs are ported verbatim from
 * `TumbleKit/Filter/FilmStock.swift` so the site and the app stay in step.
 *
 * The look thumbnails are CSS approximations over one shared sample photo — the
 * same idea as the app, but the real grade runs through Core Image on device.
 * They're honest impressions, not pixel-exact renders.
 *
 * PRICING: packs are $1.99 each, or $4.99 for all three — one-time, never a
 * subscription. Keep these in step with `app/Tumble.storekit` and App Store
 * Connect; Apple converts to local currency automatically.
 */

const SAMPLE = "/frames/frame-1.jpg";

type Overlay = "dateStamp" | "leakCorner" | "leakEdge" | "flare" | "scanlines" | "flash";

type Look = { name: string; filter: string; overlay?: Overlay };

type Pack = {
  id: string;
  name: string;
  blurb: string;
  /** true = bundled free with the app. */
  free: boolean;
  /** Paid packs only; null on the free pack. */
  price: string | null;
  looks: Look[];
};

const PACKS: Pack[] = [
  {
    id: "core",
    name: "The Roll",
    blurb: "The everyday stocks, free with the app.",
    free: true,
    price: null,
    looks: [
      { name: "Original", filter: "none" },
      { name: "Faded Instant", filter: "saturate(0.62) contrast(0.85) brightness(1.05) sepia(0.12)" },
      { name: "Warm Archive", filter: "sepia(0.34) saturate(1.1) contrast(1.02)" },
      { name: "Overcast", filter: "saturate(0.82) contrast(0.95) brightness(1.02) hue-rotate(-10deg)" },
      { name: "Sunbleached", filter: "saturate(0.72) contrast(0.9) brightness(1.09) sepia(0.22)" },
      { name: "Everyday", filter: "saturate(1.1) contrast(1.05)" },
    ],
  },
  {
    id: "nineties",
    name: "Ninety-Six",
    blurb: "Drugstore disposables, flash and all.",
    free: false,
    price: "$1.99",
    looks: [
      { name: "Disposable", filter: "saturate(1.2) contrast(1.12) sepia(0.16) brightness(1.02)" },
      { name: "Flash Night", filter: "contrast(1.32) saturate(1.1) brightness(0.98)", overlay: "flash" },
      { name: "Date Stamp", filter: "saturate(1.14) contrast(1.08) sepia(0.2)", overlay: "dateStamp" },
      { name: "Pool Party", filter: "saturate(1.28) hue-rotate(-14deg) brightness(1.05)" },
      { name: "Camcorder", filter: "saturate(0.94) contrast(1.16) brightness(1.02)", overlay: "scanlines" },
    ],
  },
  {
    id: "darkroom",
    name: "Darkroom",
    blurb: "Black and white, printed by hand.",
    free: false,
    price: "$1.99",
    looks: [
      { name: "Silver", filter: "grayscale(1) contrast(1.12)" },
      { name: "Charcoal", filter: "grayscale(1) contrast(1.5) brightness(0.94)" },
      { name: "Sepia Print", filter: "grayscale(1) sepia(0.62) contrast(1.04)" },
      { name: "Platinum", filter: "grayscale(1) contrast(0.9) brightness(1.06)" },
      { name: "Newsprint", filter: "grayscale(0.96) contrast(1.26) brightness(1.02)" },
    ],
  },
  {
    id: "summer",
    name: "Long Summer",
    blurb: "Leaks, flares and blown-out afternoons.",
    free: false,
    price: "$1.99",
    looks: [
      { name: "Light Leak", filter: "saturate(1.1) sepia(0.14) brightness(1.03)", overlay: "leakCorner" },
      { name: "Golden Hour", filter: "sepia(0.3) saturate(1.16) brightness(1.03)" },
      { name: "Fogged", filter: "saturate(0.98) contrast(0.94) brightness(1.05) sepia(0.2)", overlay: "leakEdge" },
      { name: "Cross Process", filter: "saturate(1.42) contrast(1.28) hue-rotate(-16deg)" },
      { name: "Hazy", filter: "saturate(0.92) contrast(0.84) brightness(1.12) sepia(0.14)", overlay: "flare" },
    ],
  },
];

function LookOverlay({ overlay }: { overlay: Overlay }) {
  switch (overlay) {
    case "dateStamp":
      return (
        <span className="pointer-events-none absolute right-[6%] bottom-[6%] font-mono text-[9px] leading-none font-semibold tracking-tight text-[#ff8c2a] drop-shadow-[0_0_3px_rgba(255,140,42,0.7)]">
          2026 8 14
        </span>
      );
    case "leakCorner":
      return (
        <span
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(60% 60% at 92% 88%, rgba(255,150,60,0.55), transparent 70%)" }}
        />
      );
    case "leakEdge":
      return (
        <span
          className="pointer-events-none absolute inset-0"
          style={{ background: "linear-gradient(90deg, rgba(255,45,30,0.5), transparent 34%)" }}
        />
      );
    case "flare":
      return (
        <span
          className="pointer-events-none absolute inset-0"
          style={{ background: "linear-gradient(180deg, rgba(255,238,205,0.55), transparent 55%)" }}
        />
      );
    case "scanlines":
      return (
        <span
          className="pointer-events-none absolute inset-0 opacity-40 mix-blend-overlay"
          style={{ background: "repeating-linear-gradient(0deg, rgba(0,0,0,0.35) 0 1px, transparent 1px 3px)" }}
        />
      );
    case "flash":
      return (
        <span
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(70% 70% at 50% 42%, transparent 40%, rgba(0,0,0,0.5) 100%)" }}
        />
      );
  }
}

function LookTile({ look }: { look: Look }) {
  return (
    <figure className="min-w-0">
      <div className="relative aspect-square w-full overflow-hidden rounded-[0.55rem] ring-1 ring-cream/12">
        <Image
          src={SAMPLE}
          alt=""
          fill
          sizes="(min-width: 1024px) 130px, 26vw"
          className="object-cover"
          style={{ filter: look.filter }}
        />
        {look.overlay && <LookOverlay overlay={look.overlay} />}
      </div>
      <figcaption className="mt-1.5 truncate text-center text-[11px] font-medium text-cream/62">
        {look.name}
      </figcaption>
    </figure>
  );
}

function PackCard({ pack }: { pack: Pack }) {
  const free = pack.free;
  return (
    <article
      className={`flex flex-col rounded-2xl border p-5 backdrop-blur-sm sm:p-6 ${
        free ? "border-gold/45 bg-gold/[0.06]" : "border-cream/14 bg-cream/[0.04]"
      }`}
    >
      <div className="mb-4 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="font-display text-xl font-semibold text-cream">{pack.name}</h3>
          <p className="mt-1 text-sm leading-relaxed text-cream/68">{pack.blurb}</p>
        </div>
        <span
          className={`shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider ${
            free
              ? "border-gold/40 bg-gold/10 text-gold"
              : "border-amber/35 bg-amber/10 text-amber"
          }`}
        >
          {free ? "Free" : pack.price ?? "One-time"}
        </span>
      </div>

      <div className="grid grid-cols-3 gap-2.5 sm:grid-cols-5">
        {pack.looks.map((look) => (
          <LookTile key={look.name} look={look} />
        ))}
      </div>

      <p className="mt-4 text-xs text-cream/45">
        {free
          ? `${pack.looks.length} looks · yours from day one`
          : `${pack.looks.length} looks · one-time unlock, no subscription`}
      </p>
    </article>
  );
}

export default function FilmPacks() {
  return (
    <section className="relative z-10 mx-auto max-w-5xl px-6 py-14 md:py-18">
      <div className="mb-10 max-w-2xl">
        <Stamp>Coming next</Stamp>
        <h2 className="mt-4 font-display text-3xl leading-tight font-bold text-cream sm:text-4xl">
          Load a different roll.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          Every print carries its own film stock — pick the look at develop time
          and it&rsquo;s baked in, on screen and in every export. The everyday
          stocks are free; new packs arrive as one-time unlocks, never a
          subscription.
        </p>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        {PACKS.map((pack) => (
          <PackCard key={pack.id} pack={pack} />
        ))}
      </div>

      <p className="mt-8 text-center text-sm text-cream/70">
        <span className="font-semibold text-gold">$1.99</span> a pack, or{" "}
        <span className="font-semibold text-gold">$4.99</span> for all three &mdash;
        fifteen looks, one payment.
      </p>
      <p className="mt-2 text-center font-mono text-[11px] uppercase tracking-[0.14em] text-cream/45">
        In the works · one-time unlocks · restore anytime
      </p>
    </section>
  );
}
