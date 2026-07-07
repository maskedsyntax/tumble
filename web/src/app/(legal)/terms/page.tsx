import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Terms · Tumble",
  description: "Terms for using the Tumble website, launch list, and iPhone app.",
};

export default function TermsPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Terms</h1>
      <p className="mt-2 text-sm text-cream/50">Last updated July 7, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Website and launch list
          </h2>
          <p className="mt-3">
            This site introduces Tumble and lets you sign up for the App Store
            launch email. Joining the launch list is free, is not a purchase,
            and does not promise early access or a specific release date.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            App availability
          </h2>
          <p className="mt-3">
            Tumble is in final App Store submission prep. Features, pricing,
            screenshots, and device support may still change before the App
            Store listing is live.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            The app is free to start and offers optional one-time in-app
            purchases for higher daily shot limits. Purchases are processed by
            Apple and are subject to Apple&rsquo;s App Store terms and policies.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Support
          </h2>
          <p className="mt-3">
            Questions?{" "}
            <a href="mailto:aftaab@aftab.dev" className="text-amber hover:underline">
              aftaab@aftab.dev
            </a>
            .
          </p>
        </section>
      </div>
    </main>
  );
}
