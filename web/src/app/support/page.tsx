import type { Metadata } from "next";
import Link from "next/link";
import styles from "../(legal)/legal.module.css";

const SUPPORT_EMAIL = "aftaab@aftaab.dev";

export const metadata: Metadata = {
  title: "Support",
  description:
    "Get help with Tumble, the private camera for daily photo rolls on iPhone.",
  alternates: { canonical: "/support" },
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
            Tumble is live on iPhone. For purchase restores, privacy requests,
            bug reports, or launch questions, email support and we will help
            from there.
          </p>

          <a
            href={`mailto:${SUPPORT_EMAIL}`}
            className="group mt-8 flex max-w-sm items-center gap-4 rounded-2xl border border-cream/15 bg-cream/[0.06] p-2 pr-5 shadow-[0_18px_50px_-36px_rgba(0,0,0,0.9)] backdrop-blur-md transition hover:border-amber/40 hover:bg-cream/[0.1]"
          >
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-amber text-ink shadow-[0_10px_24px_-14px_rgba(223,171,104,0.95)] transition group-hover:bg-cream">
              <MailIcon />
            </span>
            <span className="min-w-0 text-left">
              <span className="block text-[10px] font-semibold uppercase tracking-widest text-cream/55">
                Email support
              </span>
              <span className="mt-0.5 block truncate font-medium text-cream transition group-hover:text-amber">
                {SUPPORT_EMAIL}
              </span>
            </span>
          </a>
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
            App Store release.
          </p>
        </article>
        <article className="border-t border-cream/15 pt-5">
          <h2 className="font-display text-2xl font-semibold text-cream">
            Press and feedback
          </h2>
          <p className="mt-3 leading-relaxed">
            Send product feedback, bug notes, press questions, or review-copy
            requests now that Tumble is live.
          </p>
        </article>
      </section>
    </main>
  );
}

function MailIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="m3 7 9 6 9-6" />
    </svg>
  );
}
