import type { Metadata } from "next";
import Link from "next/link";
import styles from "../legal.module.css";

export const metadata: Metadata = {
  title: "Privacy",
  description: "How Tumble handles Android and iOS app photos, analytics, purchases, and support requests.",
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <main className={styles.wrap}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>
      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">Privacy</h1>
      <p className="mt-2 text-sm text-cream/50">Last updated September 2, 2026.</p>

      <div className="mt-8 space-y-8 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Photos and local storage
          </h2>
          <p className="mt-3">
            Tumble processes photos on your device and does not require an
            account. An unfinished edit is kept as one recoverable private
            draft. The draft source and recipe are removed after a successful
            save or when you choose Discard.
          </p>
          <p className="mt-3">
            Android draft files are excluded from cloud backup and device
            transfer. On iOS, photos created by older Tumble versions remain in
            the private Legacy Drawer until you export or delete them. Tumble
            does not upload draft or Legacy Drawer photos.
          </p>
          <p className="mt-3">
            Tapping Save or Share creates an image without source or location
            metadata. Images saved to the system photo library may sync through
            your own iCloud Photos, Google Photos, or other device settings;
            those services are controlled by you and are not Tumble cloud sync.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Camera and photo-library access
          </h2>
          <p className="mt-3">
            Tumble asks for camera permission only when you choose to use the
            camera. Import uses the iOS or Android system photo picker, so the
            app does not request broad access to your photo library. Camera and
            import remain separate choices if camera access is denied.
          </p>
          <p className="mt-3">
            Saving explicitly writes the finished JPEG to your photo library.
            A failed save leaves the private draft available so you can retry.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Optional analytics and diagnostics
          </h2>
          <p className="mt-3">
            Analytics is off by default on iOS and Android. After your first
            successful save, Tumble offers an optional choice to share anonymous
            product events, crash diagnostics, and masked session replay through
            PostHog. Nothing is sent to PostHog before you consent.
          </p>
          <p className="mt-3">
            Tumble never includes photo pixels, filenames, private draft IDs,
            crop contents, handwritten notes, or photo-library metadata in
            analytics events. Replay masks images and text; camera and Studio
            content is excluded or paused wherever masking cannot be verified.
          </p>
          <p className="mt-3">
            You can change this choice in Settings. Turning analytics off stops
            capture, clears queued events, and resets the anonymous analytics
            identity. Tumble does not use analytics for advertising or tracking
            across other companies&rsquo; apps and websites.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Purchases
          </h2>
          <p className="mt-3">
            Tumble Complete is a one-time purchase handled by Apple StoreKit or
            Google Play Billing. The app uses store transaction information to
            unlock premium films and restore purchases. Purchases do not transfer
            between iOS and Android because Tumble has no cross-platform account.
            Retired iOS products remain restorable for legacy ownership.
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
