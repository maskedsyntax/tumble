import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Privacy · Tumble",
  description: "How Tumble handles your data. Short version: it mostly doesn't.",
};

export default function PrivacyPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Privacy</h1>
      <p className="mt-2 text-sm text-cream/50">Placeholder. Final policy before App Store launch.</p>

      <div className="mt-8 space-y-5 leading-relaxed text-cream/80">
        <p>
          Tumble the app is built to be private by default: photos and your daily
          roll live on your device. No account, no cloud sync, no third-party
          analytics that phone home.
        </p>
        <p>
          This waitlist page is the one exception. When you enter your email to
          join the waitlist, we store that email so we can notify you when Tumble
          launches. That&rsquo;s the only thing we collect here, and we won&rsquo;t
          share or sell it.
        </p>
        <p>
          Want off the list? Email{" "}
          <a href="mailto:aftaab@aftab.dev" className="text-amber hover:underline">
            aftaab@aftab.dev
          </a>{" "}
          and we&rsquo;ll delete your address.
        </p>
      </div>
    </main>
  );
}
