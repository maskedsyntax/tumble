import type { Metadata } from "next";
import Link from "next/link";
import styles from "../(legal)/legal.module.css";

const SUPPORT_EMAIL = "aftaab@aftab.dev";

export const metadata: Metadata = {
  title: "Support · Tumble",
  description: "Get help with Tumble, the slower iPhone camera for daily photo rolls.",
};

export default function SupportPage() {
  return (
    <main className={`${styles.wrap} max-w-3xl`}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>

      <section className="mt-8 grid gap-10 md:grid-cols-[1.1fr_0.9fr] md:items-center">
        <div>
          <p className="text-xs font-semibold uppercase tracking-widest text-amber">
            Support
          </p>
          <h1 className="mt-3 font-display text-5xl font-semibold leading-tight text-cream">
            Need a hand with your roll?
          </h1>
          <p className="mt-5 leading-relaxed text-cream/80">
            Tumble is still getting ready for launch. If something feels unclear,
            broken, or oddly exposed, send a note and we will help from there.
          </p>

          <a
            href={`mailto:${SUPPORT_EMAIL}`}
            className="mt-7 inline-flex items-center justify-center rounded-full border border-amber/50 bg-amber px-5 py-3 text-sm font-semibold text-ink transition hover:bg-cream"
          >
            Email support
          </a>
          <p className="mt-3 text-sm text-cream/55">{SUPPORT_EMAIL}</p>
        </div>

        <div className="relative mx-auto aspect-[4/5] w-full max-w-64">
          <div className="absolute inset-x-8 top-3 h-56 rotate-[-9deg] rounded-sm bg-cream/20" />
          <div className="absolute inset-x-4 top-8 h-64 rotate-[7deg] rounded-sm bg-cream/25" />
          <div className="absolute inset-x-0 top-0 rounded-sm bg-cream p-3 pb-12 text-ink shadow-2xl shadow-ink/35">
            <div className="aspect-square overflow-hidden rounded-[2px] bg-blue-deep">
              <div className="h-full w-full bg-[linear-gradient(145deg,rgba(223,171,104,0.88),rgba(46,64,82,0.88)),radial-gradient(circle_at_35%_30%,rgba(246,239,226,0.95),rgba(246,239,226,0)_18%)]" />
            </div>
            <p className="mt-4 text-center font-display text-xl font-semibold">
              Help is developing
            </p>
          </div>
        </div>
      </section>

      <section className="mt-14 grid gap-5 text-cream/80 sm:grid-cols-2">
        <article className="border-t border-cream/15 pt-5">
          <h2 className="font-display text-2xl font-semibold text-cream">
            App questions
          </h2>
          <p className="mt-3 leading-relaxed">
            Ask about daily rolls, developing photos, purchases, privacy, or the
            launch waitlist.
          </p>
        </article>
        <article className="border-t border-cream/15 pt-5">
          <h2 className="font-display text-2xl font-semibold text-cream">
            Press and feedback
          </h2>
          <p className="mt-3 leading-relaxed">
            Send product feedback, bug notes, or anything that helps make Tumble
            feel more like a real pocket camera.
          </p>
        </article>
      </section>
    </main>
  );
}
