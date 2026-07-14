import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Terms",
  description: "Terms for using the Tumble website, launch list, and apps.",
  alternates: { canonical: "/terms" },
};

export default function TermsPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Terms</h1>
      <p className="mt-2 text-sm text-cream/50">Last updated July 14, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Website and launch list
          </h2>
          <p className="mt-3">
            This site introduces Tumble and links to the App Store listing.
            If you joined the launch list before release, that signup was free,
            was not a purchase, and did not promise early access or a specific
            release date.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            App availability
          </h2>
          <p className="mt-3">
            Tumble is available for iPhone on the App Store. Features, pricing,
            screenshots, and device support may change over time.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            The app is free to start and offers optional one-time in-app
            purchases for higher daily shot limits. Purchases are processed by
            Apple on the App Store and are subject to the App Store&rsquo;s terms
            and policies.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Support
          </h2>
          <p className="mt-3">
            Questions?{" "}
            <a href="mailto:aftaab@aftaab.dev" className="text-amber hover:underline">
              aftaab@aftaab.dev
            </a>
            .
          </p>
        </section>
      </div>
    </main>
  );
}
