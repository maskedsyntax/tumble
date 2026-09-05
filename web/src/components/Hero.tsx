import Image from "next/image";
import { APP_STORE_URL } from "@/lib/app-store";
import { Stamp } from "./FilmEdge";

export default function Hero() {
  return (
    <section id="top" className="relative z-10 scroll-mt-20 overflow-hidden">
      <div className="mx-auto grid min-h-[calc(100svh-4rem)] max-w-7xl items-center gap-12 px-5 py-12 sm:px-6 md:grid-cols-[0.88fr_1.12fr] md:gap-12 md:py-16 lg:gap-20">
        <div className="order-2 max-w-xl text-center md:order-1 md:text-left">
          <Stamp frame="36 EXP" className="justify-center md:justify-start">Film for iPhone + Android</Stamp>
          <h1 className="mt-6 font-display text-[clamp(3.6rem,12vw,7.2rem)] font-extrabold leading-[0.83] tracking-[-0.055em] text-cream">
            One shot.
            <span className="block text-gold">Every film.</span>
          </h1>
          <p className="mx-auto mt-7 max-w-lg text-lg leading-relaxed text-cream/78 md:mx-0 md:text-xl">
            A private film camera and Studio. Capture or import, choose from 21
            film looks, and finish every photo on your device.
          </p>
          <div className="mt-9 flex flex-col items-center gap-4 sm:flex-row sm:justify-center md:justify-start">
            <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="group inline-flex min-h-14 items-center gap-3 rounded-2xl bg-gold px-6 py-3 text-ink shadow-[0_20px_45px_-20px_rgba(223,171,104,0.9)] ring-1 ring-inset ring-cream/30 transition hover:-translate-y-0.5 hover:bg-cream focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-gold" aria-label="Download Tumble on the App Store">
              <AppleMark />
              <span className="text-left leading-none">
                <span className="block font-mono text-[9px] font-bold uppercase tracking-[0.18em] text-ink/55">Download on the</span>
                <span className="mt-1 block font-display text-lg font-extrabold tracking-tight">App Store</span>
              </span>
            </a>
            <span className="font-mono text-[10px] font-bold uppercase tracking-[0.15em] text-cream/45">Free to start · pay once</span>
          </div>
        </div>

        <div className="order-1 flex justify-center md:order-2 md:justify-end">
          <div className="relative w-full max-w-[34rem]">
            <div className="absolute -inset-10 bg-[radial-gradient(circle,rgba(223,171,104,0.2),transparent_68%)]" aria-hidden="true" />
            <div className="absolute -left-7 top-[15%] z-10 hidden -rotate-6 rounded-sm bg-[#f5eddc] px-4 py-3 shadow-2xl lg:block" aria-hidden="true">
              <span className="font-script text-xl text-ink/75">the good part</span>
            </div>
            <figure className="relative ml-auto w-[min(88vw,29rem)] rotate-[1.5deg] rounded-[0.9rem] bg-[#f5eddc] p-3 pb-14 shadow-[0_45px_95px_-30px_rgba(0,0,0,0.9)] sm:p-4 sm:pb-16">
              <div className="relative aspect-[3/4] overflow-hidden rounded-[0.35rem] bg-ink">
                <Image src="/editorial/hero-rainy-cinema-night.jpg" alt="Three friends laughing beneath an umbrella after a late movie, photographed with Tumble's Flash Night film look." fill priority loading="eager" sizes="(min-width: 1024px) 460px, (min-width: 768px) 42vw, 88vw" className="object-cover" />
                <span className="absolute right-4 bottom-4 rounded-sm bg-black/50 px-2 py-1 font-mono text-[9px] font-bold uppercase tracking-[0.16em] text-white/85 backdrop-blur-sm">Flash Night · 23:18</span>
              </div>
              <figcaption className="absolute inset-x-5 bottom-4 flex items-end justify-between gap-4 text-ink/70 sm:bottom-5">
                <span className="font-script text-[clamp(1.25rem,5vw,1.8rem)] leading-none">one more night out</span>
                <span className="font-mono text-[9px] font-bold uppercase tracking-[0.14em] text-[#bd7028]">Flash Night</span>
              </figcaption>
            </figure>
          </div>
        </div>
      </div>
    </section>
  );
}

function AppleMark() {
  return (
    <svg width="23" height="23" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M16.365 1.43c0 1.14-.42 2.2-1.12 3-.77.88-2.03 1.56-3.06 1.48-.14-1.1.4-2.24 1.05-2.96.74-.82 2.05-1.44 3.13-1.52.02.13.02.26.02.4l-.02-.4zM20.5 17.02c-.55 1.27-.82 1.84-1.53 2.96-.99 1.57-2.39 3.52-4.12 3.53-1.54.02-1.94-1-4.03-.99-2.09.01-2.52 1.01-4.06.99-1.73-.02-3.05-1.78-4.04-3.35C1.13 15.9.87 11.2 2.6 8.72c1.02-1.47 2.63-2.34 4.14-2.34 1.54 0 2.5 1.01 3.77 1.01 1.23 0 1.98-1.01 3.77-1.01 1.34 0 2.76.73 3.77 1.99-3.31 1.81-2.77 6.54.68 7.66l-.02-.01z" />
    </svg>
  );
}
