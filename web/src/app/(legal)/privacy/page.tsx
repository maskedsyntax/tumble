import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Privacy · Tumble",
  description: "How Tumble handles app photos, purchases, waitlist emails, and support requests.",
};

export default function PrivacyPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Privacy</h1>
      <p className="mt-2 text-sm text-cream/50">Last updated July 7, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Tumble for iPhone
          </h2>
          <p className="mt-3">
            Tumble is built to keep your photos on your device. The app stores
            your prints, daily roll state, and entitlement state locally in the
            app container or shared app group so the main app, Lock Screen
            camera, Control Center control, and Dynamic Island status can work
            together.
          </p>
          <p className="mt-3">
            Tumble does not require an account, does not provide cloud sync, and
            does not include third-party analytics or advertising SDKs.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            Plus and Unlimited are one-time in-app purchases handled by Apple
            through StoreKit. Tumble uses Apple&rsquo;s transaction information to
            unlock the highest roll tier you own and to restore purchases.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Website and waitlist
          </h2>
          <p className="mt-3">
            If you join the launch list, we store your email address, signup
            source, timestamp, and browser user agent in Firebase so we can send
            the App Store launch email and reduce spam submissions.
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
            <a href="mailto:aftaab@aftab.dev" className="text-amber hover:underline">
              aftaab@aftab.dev
            </a>{" "}
            and we will delete your waitlist address or respond to your request.
          </p>
        </section>
      </div>
    </main>
  );
}
