import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Privacy",
  description: "How Tumble handles app photos, purchases, waitlist emails, and support requests.",
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Privacy</h1>
      <p className="mt-2 text-sm text-cream/50">Last updated August 30, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Tumble on your phone
          </h2>
          <p className="mt-3">
            Tumble is built to keep your photos on your device. The app stores
            your prints, daily roll state, and entitlement state locally so the
            main app and quick-capture entry points can work together without a
            cloud account.
          </p>
          <p className="mt-3">
            That includes the shared app group used by Lock Screen capture,
            Control Center, and Dynamic Island status.
          </p>
          <p className="mt-3">
            Tumble does not require an account or provide photo cloud sync. Your
            photos, photo filenames, and postcard text are not sent to our
            analytics provider.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Anonymous analytics and diagnostics
          </h2>
          <p className="mt-3">
            Tumble uses PostHog to understand anonymous product interactions,
            screen visits, purchase outcomes, and crashes. PostHog assigns a
            random installation identifier; Tumble does not attach a name,
            email address, account, advertising identifier, photo, or postcard
            text to it.
          </p>
          <p className="mt-3">
            A small sample of sessions may be replayed to help us find confusing
            or broken experiences. Replay masks all text and images, excludes
            the live camera, and does not collect console logs or network
            request contents. Replays are retained for no more than 30 days.
          </p>
          <p className="mt-3">
            Analytics is enabled by default. You can stop future collection at
            any time from Plans &amp; About by switching off Anonymous analytics.
            We do not use this data for advertising or tracking across other
            companies&rsquo; apps and websites.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            Plus and Unlimited are one-time in-app purchases, handled by Apple
            through StoreKit. Tumble uses the store&rsquo;s transaction
            information to unlock the highest roll tier you own and to restore
            purchases.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Website and waitlist
          </h2>
          <p className="mt-3">
            If you joined the launch list, we stored your email address, signup
            source, timestamp, and browser user agent in Firebase so we could
            send the App Store launch email and reduce spam submissions.
          </p>
          <p className="mt-3">
            If you email support, we receive the contact information and message
            you choose to send.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Your choices
          </h2>
          <p className="mt-3">
            Want off the launch list or need a privacy request handled? Email{" "}
            <a href="mailto:aftaab@aftaab.dev" className="text-amber hover:underline">
              aftaab@aftaab.dev
            </a>{" "}
            and we will delete your waitlist address or respond to your request.
          </p>
        </section>
      </div>
    </main>
  );
}
