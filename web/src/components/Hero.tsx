import Image from "next/image";
import AppStoreBadge from "./AppStoreBadge";

export default function Hero() {
  return (
    <section className="relative z-10 mx-auto flex min-h-[68dvh] max-w-4xl flex-col items-center justify-center px-6 pt-14 pb-12 text-center md:min-h-[70dvh] md:pt-20 md:pb-16">
      <Image
        src="/logo.png"
        alt="Tumble app icon"
        width={160}
        height={160}
        priority
        className="animate-fade-up mb-10 h-32 w-32 rounded-[1.75rem] shadow-[0_18px_56px_-16px_rgba(0,0,0,0.9)] ring-1 ring-cream/15 md:mb-12 md:h-40 md:w-40 md:rounded-[2rem]"
      />

      <span className="animate-fade-up mb-6 inline-flex items-center gap-2 rounded-full border border-cream/20 bg-cream/10 px-4 py-1.5 text-xs font-medium uppercase tracking-widest text-cream/80 backdrop-blur-sm">
        <span className="h-1.5 w-1.5 rounded-full bg-amber" />
        iPhone · available now
      </span>

      <h1 className="animate-fade-up font-display text-[clamp(1.55rem,9.8vw,4.5rem)] font-semibold leading-none tracking-tight text-cream">
        <span className="block whitespace-nowrap">Shoot today&rsquo;s first roll</span>
        <span className="block whitespace-nowrap italic text-amber">with Tumble on iPhone.</span>
      </h1>

      <p className="animate-fade-up mx-auto mt-6 max-w-md text-lg leading-relaxed text-cream/80">
        Twelve shots a day. Shake to develop. Private on iPhone.
      </p>

      <p className="animate-fade-up mt-3 text-sm font-medium text-amber">
        Free to start. One-time unlocks. No subscriptions.
      </p>

      <div className="animate-fade-up mt-9 flex w-full max-w-md flex-col items-stretch">
        <AppStoreBadge />
      </div>
    </section>
  );
}
