import WaitlistForm from "./WaitlistForm";
import ComingSoonBadge from "./ComingSoonBadge";

export default function Hero() {
  return (
    <section className="relative z-10 mx-auto flex min-h-[68dvh] max-w-2xl flex-col items-center justify-center px-6 pt-14 pb-12 text-center md:min-h-[70dvh] md:pt-20 md:pb-16">
      <span className="animate-fade-up mb-6 inline-flex items-center gap-2 rounded-full border border-cream/20 bg-cream/10 px-4 py-1.5 text-xs font-medium uppercase tracking-widest text-cream/80 backdrop-blur-sm">
        <span className="h-1.5 w-1.5 rounded-full bg-amber" />
        Final App Store prep · no monthly plan
      </span>

      <h1 className="animate-fade-up font-display text-5xl font-semibold leading-[1.05] tracking-tight text-cream sm:text-6xl md:text-7xl">
        A slower camera
        <br />
        <span className="italic text-amber">you can actually own.</span>
      </h1>

      <p className="animate-fade-up mx-auto mt-6 max-w-lg text-lg leading-relaxed text-cream/80">
        Pull the camera down from the Dynamic Island or Lock Screen, take one
        of twelve daily shots, then shake to develop it into your Drawer.
      </p>

      <p className="animate-fade-up mt-3 text-sm font-medium text-amber">
        On-device. No account. No cloud. One-time upgrades only.
      </p>

      <div className="animate-fade-up mt-9 w-full max-w-md">
        <WaitlistForm />
      </div>

      <div className="animate-fade-up mt-8">
        <ComingSoonBadge />
      </div>
    </section>
  );
}
