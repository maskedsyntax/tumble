import Image from "next/image";
import { Stamp } from "./FilmEdge";

const FRAMES = [
  { src: "/editorial/morning-coffee-warm-archive.jpg", alt: "Morning coffee photographed with Tumble", stock: "Warm Archive" },
  { src: "/editorial/flower-walk-everyday.jpg", alt: "Flowers photographed on a walk with Tumble", stock: "Everyday" },
  { src: "/editorial/record-shop-date-stamp.jpg", alt: "Records photographed with Tumble", stock: "Date Stamp" },
  { src: "/editorial/rainy-bus-pool-party.jpg", alt: "A rainy bus window photographed with Tumble", stock: "Pool Party" },
  { src: "/editorial/hero-diner-flash-night.jpg", alt: "Friends at dinner photographed with Tumble", stock: "Flash Night" },
  { src: "/editorial/after-dinner-silver.jpg", alt: "Dinner photographed with Tumble's Silver film look", stock: "Silver" },
  { src: "/editorial/after-dinner-light-leak.jpg", alt: "Dinner photographed with Tumble's Light Leak film look", stock: "Light Leak" },
];

export default function ProductJourney() {
  return (
    <section id="how-it-works" className="relative z-10 scroll-mt-24 overflow-hidden px-5 py-20 sm:px-6 md:py-28">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_78%_46%,rgba(224,177,74,0.08),transparent_34%)]" />

      <div className="relative mx-auto max-w-7xl">
        <div className="grid items-end gap-8 lg:grid-cols-[1.05fr_0.95fr] lg:gap-20">
          <div className="max-w-4xl">
            <Stamp frame="12 EXP">The daily roll</Stamp>
            <h2 className="mt-5 font-display text-4xl font-extrabold leading-[0.94] tracking-tight text-cream sm:text-5xl lg:text-7xl">
              A day feels different with only
              <span className="text-gold"> twelve frames.</span>
            </h2>
          </div>
          <p className="max-w-xl text-lg leading-relaxed text-cream/72 lg:pb-2">
            A small roll makes every shutter press matter. Each shot lands hidden, comes alive when you shake it, and stays in your private Drawer—not a feed.
          </p>
        </div>

        <div className="mt-12 overflow-hidden rounded-[1.75rem] border border-cream/12 bg-[#111a22] shadow-[0_40px_100px_-48px_rgba(0,0,0,0.9)] sm:mt-16">
          <div className="flex items-center justify-between border-b border-cream/10 px-5 py-4 font-mono text-[10px] font-bold uppercase tracking-[0.16em] text-cream/48 sm:px-7">
            <span>Tumble · Daily roll</span>
            <span>07 / 12 exposed</span>
          </div>

          <div className="grid grid-cols-3 gap-px bg-cream/8 sm:grid-cols-4 lg:grid-cols-6">
            {Array.from({ length: 12 }, (_, index) => {
              const frame = FRAMES[index];
              return (
                <figure key={index} className="group relative aspect-square overflow-hidden bg-[#0c141a]">
                  {frame ? (
                    <>
                      <Image
                        src={frame.src}
                        alt={frame.alt}
                        fill
                        sizes="(min-width: 1024px) 16vw, (min-width: 640px) 25vw, 33vw"
                        className="object-cover transition duration-700 group-hover:scale-[1.035]"
                      />
                      <div className="absolute inset-0 bg-linear-to-t from-black/70 via-transparent to-transparent" />
                      <figcaption className="absolute inset-x-0 bottom-0 flex items-end justify-between gap-2 p-3 font-mono text-[9px] font-bold uppercase tracking-[0.12em] text-white/78">
                        <span>{String(index + 1).padStart(2, "0")}</span>
                        <span className="truncate text-right">{frame.stock}</span>
                      </figcaption>
                    </>
                  ) : (
                    <figcaption className="absolute inset-0 flex flex-col items-center justify-center gap-2 font-mono uppercase">
                      <span className="text-2xl text-cream/16">{String(index + 1).padStart(2, "0")}</span>
                      <span className="text-[8px] font-bold tracking-[0.18em] text-cream/28">Unexposed</span>
                    </figcaption>
                  )}
                </figure>
              );
            })}
          </div>
        </div>

        <ol className="mt-8 grid gap-0 border-y border-cream/12 md:grid-cols-3">
          <RitualItem number="01" title="Shoot what matters" body="Twelve chances, refreshed each day." />
          <RitualItem number="02" title="Shake it awake" body="The image rises through the print." />
          <RitualItem number="03" title="Keep the roll" body="Your Drawer is private and feed-free." />
        </ol>
      </div>
    </section>
  );
}

function RitualItem({ number, title, body }: { number: string; title: string; body: string }) {
  return (
    <li className="flex gap-4 border-b border-cream/12 py-6 last:border-b-0 md:border-r md:border-b-0 md:px-7 md:first:pl-0 md:last:border-r-0 md:last:pr-0">
      <span className="pt-1 font-mono text-[10px] font-bold tracking-[0.16em] text-gold">{number}</span>
      <div>
        <h3 className="font-display text-xl font-bold text-cream">{title}</h3>
        <p className="mt-1 text-sm leading-relaxed text-cream/58 sm:text-base">{body}</p>
      </div>
    </li>
  );
}
