"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import { Stamp } from "./FilmEdge";

const LOOKS = [
  { name: "Original", file: "after-dinner-original.jpg", strength: 0 },
  { name: "Faded Instant", file: "after-dinner-faded-instant.jpg", strength: 0.58 },
  { name: "Warm Archive", file: "after-dinner-warm-archive.jpg", strength: 0.64 },
  { name: "Silver", file: "after-dinner-silver.jpg", strength: 0.62 },
  { name: "Cross Process", file: "after-dinner-cross-process.jpg", strength: 0.56 },
  { name: "Light Leak", file: "after-dinner-light-leak.jpg", strength: 0.54 },
];

export default function FilmLooks() {
  const [active, setActive] = useState(2);
  const [visible, setVisible] = useState(false);
  const [paused, setPaused] = useState(false);
  const [manual, setManual] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const node = sectionRef.current;
    if (!node) return;
    const observer = new IntersectionObserver(([entry]) => setVisible(entry.isIntersecting), { threshold: 0.35 });
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!visible || paused || manual || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const timer = window.setInterval(() => setActive((index) => (index + 1) % LOOKS.length), 3500);
    return () => window.clearInterval(timer);
  }, [visible, paused, manual]);

  const choose = (index: number) => {
    setActive(index);
    setManual(true);
  };

  return (
    <section
      id="looks"
      ref={sectionRef}
      className="relative z-10 scroll-mt-24 border-y border-cream/10 bg-[#192530]/70 px-5 py-20 sm:px-6 md:py-28"
      onPointerEnter={() => setPaused(true)}
      onPointerLeave={() => setPaused(false)}
      onFocusCapture={() => setPaused(true)}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setPaused(false);
      }}
    >
      <div className="mx-auto grid max-w-7xl items-center gap-12 lg:grid-cols-[1.2fr_0.8fr] lg:gap-20">
        <div className="relative">
          <div className="absolute -inset-8 bg-[radial-gradient(circle_at_40%_50%,rgba(223,171,104,0.16),transparent_65%)]" aria-hidden="true" />
          <figure className="relative overflow-hidden rounded-[1.4rem] border border-cream/12 bg-black shadow-[0_35px_80px_-35px_rgba(0,0,0,0.9)]">
            <div className="relative aspect-[4/3]">
              <Image
                src="/editorial/after-dinner-original.jpg"
                alt="Three friends finishing dinner together."
                fill
                sizes="(min-width: 1024px) 60vw, 100vw"
                className="object-cover"
              />
              {LOOKS[active].strength > 0 && (
                <div className="absolute inset-0" style={{ opacity: LOOKS[active].strength }}>
                  <Image
                    key={LOOKS[active].file}
                    src={`/editorial/${LOOKS[active].file}`}
                    alt=""
                    aria-hidden="true"
                    fill
                    sizes="(min-width: 1024px) 60vw, 100vw"
                    className="animate-stock-in object-cover"
                  />
                </div>
              )}
            </div>
            <figcaption className="flex items-center justify-between gap-4 border-t border-white/10 bg-black/55 px-4 py-3 font-mono text-[10px] font-bold uppercase tracking-[0.16em] text-white/70 sm:px-5">
              <span>Same moment · film character preview</span>
              <span className="text-gold">{LOOKS[active].name}</span>
            </figcaption>
          </figure>
        </div>

        <div>
          <Stamp frame="21">Four rolls</Stamp>
          <h2 className="mt-5 max-w-xl font-display text-4xl font-extrabold leading-[0.95] tracking-tight text-cream sm:text-5xl lg:text-6xl">
            Not a filter.
            <span className="block text-gold">A film stock.</span>
          </h2>
          <p className="mt-6 max-w-lg text-lg leading-relaxed text-cream/72">
            Pick the character at develop time. Natural skin, softer contrast, subtle
            grain, and restrained colour keep the moment in front of the effect.
          </p>

          <div className="mt-8 grid grid-cols-2 gap-2 sm:grid-cols-3" role="group" aria-label="Preview a film stock">
            {LOOKS.map((look, index) => (
              <button
                key={look.name}
                type="button"
                onClick={() => choose(index)}
                aria-pressed={active === index}
                className={`rounded-xl border px-3 py-3 text-left font-mono text-[10px] font-bold uppercase tracking-[0.1em] transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gold ${
                  active === index
                    ? "border-gold bg-gold text-ink"
                    : "border-cream/12 bg-cream/[0.04] text-cream/65 hover:border-cream/35 hover:text-cream"
                }`}
              >
                {look.name}
              </button>
            ))}
          </div>
          <p className="mt-5 font-mono text-[10px] uppercase tracking-[0.14em] text-cream/42">
            The Roll · Ninety-Six · Darkroom · Long Summer
          </p>
        </div>
      </div>
    </section>
  );
}
