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
      <p className="mt-2 text-sm text-cream/50">Last updated July 11, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Website and launch list
          </h2>
          <p className="mt-3">
            This site introduces Tumble and lets you sign up for the launch
            email when the App Store and Google Play listings go live. Joining
            the launch list is free, is not a purchase, and does not promise
            early access or a specific release date.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            App availability
          </h2>
          <p className="mt-3">
            Tumble is planned for iPhone and Android in the same launch window.
            The iOS build is currently in Apple review; the Android build is
            planned to ship alongside it. Features, pricing, screenshots, and
            device support may still change before either store listing is live.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            The app is free to start and offers optional one-time in-app
            purchases for higher daily shot limits. Purchases are processed by
            Apple on the App Store and by Google on Google Play, and are subject
            to each store&rsquo;s terms and policies.
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
