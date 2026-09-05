import { APP_STORE_URL } from "@/lib/app-store";
import { Stamp } from "./FilmEdge";

const TIERS = [
  { name: "Free", price: "Free", note: "Six film looks", body: "Unlimited capture, import, editing, postcards, saving, and sharing." },
  { name: "Tumble Complete", price: "$4.99", note: "All 21 film looks", body: "Fifteen premium films. One payment, yours for good.", featured: true },
];

export default function Pricing() {
  return (
    <section id="pricing" className="relative z-10 scroll-mt-24 px-5 py-20 sm:px-6 md:py-28">
      <div className="mx-auto max-w-7xl">
        <div className="mx-auto max-w-3xl text-center">
          <Stamp>Pay once. Never again.</Stamp>
          <h2 className="mt-5 font-display text-4xl font-extrabold leading-[0.95] tracking-tight text-cream sm:text-5xl lg:text-6xl">
            Free to start.
            <span className="block text-gold">Yours to keep.</span>
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-cream/72">
            Make as many photos as you like. Upgrade only when you want the full film shelf—never because a subscription renewed.
          </p>
        </div>

        <div className="mx-auto mt-12 grid max-w-4xl gap-4 md:grid-cols-2">
          {TIERS.map((tier) => (
            <article key={tier.name} className={`relative flex min-h-64 flex-col rounded-3xl border p-7 ${tier.featured ? "border-gold/65 bg-gold/[0.08] shadow-[0_28px_70px_-38px_rgba(223,171,104,0.65)]" : "border-cream/12 bg-cream/[0.035]"}`}>
              {tier.featured && <span className="absolute right-5 top-5 rounded-full bg-gold px-3 py-1 font-mono text-[9px] font-bold uppercase tracking-[0.12em] text-ink">Most popular</span>}
              <span className="font-mono text-[10px] font-bold uppercase tracking-[0.16em] text-cream/48">{tier.name}</span>
              <div className="mt-5 font-display text-5xl font-extrabold tracking-tight text-cream">{tier.price}</div>
              {tier.price !== "Free" && <span className="mt-1 text-sm text-cream/45">one-time</span>}
              <div className="mt-auto pt-8 font-display text-lg font-bold text-gold">{tier.note}</div>
              <p className="mt-2 text-sm leading-relaxed text-cream/65">{tier.body}</p>
            </article>
          ))}
        </div>

        <div className="mx-auto mt-5 flex max-w-4xl flex-col items-center justify-between gap-4 rounded-2xl border border-cream/12 bg-cream/[0.035] px-6 py-5 text-center sm:flex-row sm:text-left">
          <div>
            <div className="font-display text-lg font-bold text-cream">Use it on both platforms</div>
            <p className="mt-1 text-sm text-cream/60">Sign in only when you buy or link purchases. Camera and Studio stay account-free.</p>
          </div>
          <span className="shrink-0 font-mono text-[10px] font-bold uppercase tracking-[0.14em] text-gold">Restore anytime</span>
        </div>

        <div className="mt-14 rounded-[2rem] border border-gold/30 bg-gold/[0.09] px-6 py-10 text-center shadow-[0_30px_80px_-45px_rgba(223,171,104,0.65)] sm:px-10">
          <p className="font-script text-2xl text-gold sm:text-3xl">Your next photo is ready.</p>
          <a href={APP_STORE_URL} target="_blank" rel="noreferrer" className="mt-5 inline-flex min-h-14 items-center justify-center rounded-2xl bg-gold px-8 font-display text-lg font-extrabold text-ink transition hover:-translate-y-0.5 hover:bg-cream focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-gold">
            Download Tumble
          </a>
          <p className="mt-4 font-mono text-[10px] font-bold uppercase tracking-[0.14em] text-cream/45">iPhone + Android · free to start · no subscription</p>
        </div>
      </div>
    </section>
  );
}
