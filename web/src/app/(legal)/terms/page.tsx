import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Terms · Tumble",
  description: "Terms for using the Tumble website and waitlist.",
};

export default function TermsPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Terms</h1>
      <p className="mt-2 text-sm text-cream/50">Placeholder. Full terms before App Store launch.</p>

      <div className="mt-8 space-y-5 leading-relaxed text-cream/80">
        <p>
          This site is a pre-launch page for Tumble, an iOS camera app in
          development. Everything here (screenshots, mockups, features, timing)
          is subject to change before release.
        </p>
        <p>
          Joining the waitlist signs you up to receive a launch notification by
          email. It isn&rsquo;t a purchase or a promise of access, and you can
          unsubscribe at any time.
        </p>
        <p>
          Questions?{" "}
          <a href="mailto:aftaab@aftab.dev" className="text-amber hover:underline">
            aftaab@aftab.dev
          </a>
          .
        </p>
      </div>
    </main>
  );
}
