"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import { APP_STORE_URL } from "@/lib/app-store";
import { Stamp } from "./FilmEdge";

const SAMPLE = "/frames/frame-1.jpg";

type Overlay = "leakCorner" | "flare";
type Look = { name: string; filter: string; overlay?: Overlay };

/** A spread across the catalog — colour, warmth, mono, a leak — so the hero
 *  reads as "every film," not a set of near-identical presets. */
const LOOKS: Look[] = [
  { name: "Original", filter: "none" },
  { name: "Faded Instant", filter: "saturate(0.62) contrast(0.85) brightness(1.05) sepia(0.12)" },
  { name: "Golden Hour", filter: "sepia(0.3) saturate(1.16) brightness(1.03)", overlay: "flare" },
  { name: "Silver", filter: "grayscale(1) contrast(1.12)" },
  { name: "Cross Process", filter: "saturate(1.42) contrast(1.28) hue-rotate(-16deg)" },
  { name: "Light Leak", filter: "saturate(1.1) sepia(0.14) brightness(1.03)", overlay: "leakCorner" },
];

function LookOverlay({ overlay }: { overlay?: Overlay }) {
  if (overlay === "leakCorner") {
    return (
      <span
        className="pointer-events-none absolute inset-0"
        style={{ background: "radial-gradient(58% 58% at 92% 88%, rgba(255,150,60,0.5), transparent 70%)" }}
      />
    );
  }
  if (overlay === "flare") {
    return (
      <span
        className="pointer-events-none absolute inset-0"
        style={{ background: "linear-gradient(180deg, rgba(255,238,205,0.42), transparent 52%)" }}
      />
    );
  }
  return null;
}

export default function Hero() {
  const [active, setActive] = useState(0);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);

  // Auto-advance through the stocks, unless the visitor prefers reduced motion.
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    timer.current = setInterval(() => setActive((i) => (i + 1) % LOOKS.length), 2400);
    return () => {
      if (timer.current) clearInterval(timer.current);
    };
  }, []);

  const pick = (i: number) => {
    setActive(i);
    if (timer.current) clearInterval(timer.current); // hand control to the visitor
  };

  const look = LOOKS[active];

  return (
    <section className="relative z-10 mx-auto grid max-w-6xl items-center gap-12 px-6 pt-16 pb-14 md:grid-cols-[1.02fr_0.98fr] md:gap-10 md:pt-24 md:pb-20">
      {/* Copy */}
      <div className="order-2 text-center md:order-1 md:text-left">
        <Stamp frame="36 EXP" className="justify-center md:justify-start">
          Film for iPhone
        </Stamp>

        <h1 className="mt-6 font-display text-[clamp(3.2rem,13vw,6rem)] font-extrabold leading-[0.9] tracking-tight text-cream">
          One shot.
          <span className="block text-gold">Every film.</span>
        </h1>

        <p className="mx-auto mt-6 max-w-md text-lg leading-relaxed text-cream/75 md:mx-0">
          A private film camera for iPhone. Shoot a daily roll of twelve, shake
          to develop, and finish every shot on real film stock.
        </p>

        <div className="mt-9 flex flex-col items-center gap-4 md:items-start">
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noreferrer"
            className="group inline-flex items-center gap-3 rounded-2xl bg-gold px-5 py-3 text-ink shadow-[0_16px_38px_-16px_rgba(223,171,104,0.85)] ring-1 ring-inset ring-cream/30 transition duration-200 hover:-translate-y-0.5 hover:shadow-[0_22px_46px_-16px_rgba(223,171,104,0.95)]"
            aria-label="Download Tumble on the App Store"
          >
            <AppleMark />
            <span className="text-left leading-none">
              <span className="block font-mono text-[9px] font-bold uppercase tracking-[0.2em] text-ink/55">
                Download on the
              </span>
              <span className="mt-1 block font-display text-lg font-extrabold tracking-tight">
                App Store
              </span>
            </span>
          </a>

          <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-cream/45">
            Free to start · one-time unlocks · no subscriptions
          </p>
        </div>
      </div>

      {/* The pivot, made live: one print, every film. */}
      <div className="order-1 flex flex-col items-center md:order-2">
        <figure className="w-full max-w-[19rem] [container-type:inline-size]">
          <div
            className="rounded-[2cqw] pt-[6cqw] pr-[6cqw] pb-[15cqw] pl-[6cqw] shadow-[0_28px_60px_-24px_rgba(0,0,0,0.75)]"
            style={{ backgroundColor: "#f4ecda" }}
          >
            <div className="relative aspect-square w-full overflow-hidden rounded-[0.8cqw] ring-1 ring-ink/15">
              <Image
                src={SAMPLE}
                alt={`A waterfall shot, developed on the ${look.name} film stock.`}
                fill
                priority
                sizes="(min-width: 768px) 300px, 80vw"
                className="object-cover transition-[filter] duration-500 ease-out"
                style={{ filter: look.filter }}
              />
              <LookOverlay overlay={look.overlay} />
            </div>
            <div className="mt-[4cqw] flex items-end justify-between px-[1cqw]">
              <span className="font-script text-[6cqw] leading-none text-ink/70">
                one of twelve
              </span>
              <span className="font-mono text-[3cqw] leading-none font-bold tracking-tight text-[#c67a2e]">
                2026&#183;08&#183;14
              </span>
            </div>
          </div>
        </figure>

        {/* Film-strip selector — the whole catalog idea in one row. */}
        <div className="mt-6 w-full max-w-[22rem]">
          <div className="mb-2.5 text-center font-mono text-[11px] font-bold uppercase tracking-[0.2em] text-gold">
            {look.name}
          </div>
          <div className="flex justify-center gap-2">
            {LOOKS.map((l, i) => (
              <button
                key={l.name}
                onClick={() => pick(i)}
                aria-label={`Preview the ${l.name} film stock`}
                aria-pressed={i === active}
                className={`relative aspect-square w-11 shrink-0 overflow-hidden rounded-md ring-1 transition sm:w-12 ${
                  i === active
                    ? "ring-2 ring-gold"
                    : "opacity-70 ring-cream/15 hover:opacity-100"
                }`}
              >
                <Image
                  src={SAMPLE}
                  alt=""
                  fill
                  sizes="48px"
                  className="object-cover"
                  style={{ filter: l.filter }}
                />
                <LookOverlay overlay={l.overlay} />
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function AppleMark() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M16.365 1.43c0 1.14-.42 2.2-1.12 3-.77.88-2.03 1.56-3.06 1.48-.14-1.1.4-2.24 1.05-2.96.74-.82 2.05-1.44 3.13-1.52.02.13.02.26.02.4l-.02-.4zM20.5 17.02c-.55 1.27-.82 1.84-1.53 2.96-.99 1.57-2.39 3.52-4.12 3.53-1.54.02-1.94-1-4.03-.99-2.09.01-2.52 1.01-4.06.99-1.73-.02-3.05-1.78-4.04-3.35C1.13 15.9.87 11.2 2.6 8.72c1.02-1.47 2.63-2.34 4.14-2.34 1.54 0 2.5 1.01 3.77 1.01 1.23 0 1.98-1.01 3.77-1.01 1.34 0 2.76.73 3.77 1.99-3.31 1.81-2.77 6.54.68 7.66l-.02-.01z" />
    </svg>
  );
}
