import type { Metadata } from "next";
import Link from "next/link";
import styles from "../(legal)/legal.module.css";

const SUPPORT_EMAIL = "aftaab@aftaab.dev";

export const metadata: Metadata = {
  title: "Delete your Tumble account",
  description:
    "Delete a Tumble account and the Firebase and RevenueCat data associated with it.",
  alternates: { canonical: "/account-deletion" },
};

export default function AccountDeletionPage() {
  return (
    <main className={`${styles.wrap} max-w-3xl`}>
      <Link href="/" className="text-sm text-amber hover:underline">
        &larr; Back to Tumble
      </Link>

      <h1 className="mt-6 font-display text-4xl font-semibold text-cream">
        Delete your Tumble account
      </h1>
      <p className="mt-4 leading-relaxed text-cream/80">
        Tumble accounts are optional and are used to link eligible film
        purchases across iOS and Android. You can delete your account inside the
        app or ask us to delete it for you.
      </p>

      <div className="mt-10 space-y-9 leading-relaxed text-cream/80">
        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Delete it in the app
          </h2>
          <ol className="mt-3 list-decimal space-y-2 pl-6">
            <li>Open Tumble and tap Settings on the camera screen.</li>
            <li>Open Account &amp; linked purchases.</li>
            <li>Tap Delete account and confirm.</li>
            <li>
              If prompted, sign in again with Apple or Google, then repeat the
              deletion.
            </li>
          </ol>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Request deletion by email
          </h2>
          <p className="mt-3">
            Email{" "}
            <a
              href={`mailto:${SUPPORT_EMAIL}?subject=Tumble%20account%20deletion`}
              className="text-amber hover:underline"
            >
              {SUPPORT_EMAIL}
            </a>{" "}
            from the address associated with your Tumble sign-in and use the
            subject “Tumble account deletion”. We may ask you to verify control
            of the linked Apple or Google account before deleting it.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            What is deleted
          </h2>
          <p className="mt-3">
            Deletion removes your Firebase Authentication account and the
            account link used by RevenueCat for cross-platform entitlement
            syncing. Any queued optional analytics events associated with the
            app&apos;s anonymous analytics identity are cleared when analytics is
            disabled or the app is reset.
          </p>
          <p className="mt-3">
            Photos and drafts are stored only on your device and are not part of
            the online account. Deleting the account does not delete photos you
            already saved to your device, and it does not cancel or erase the
            purchase record held by Apple or Google. Store transaction records
            may be retained by those providers under their own legal and
            accounting obligations.
          </p>
        </section>

        <section>
          <h2 className="font-display text-2xl font-semibold text-cream">
            Timing
          </h2>
          <p className="mt-3">
            In-app deletion begins immediately. Email requests are handled
            within 30 days after any required identity verification. We retain
            only records required for fraud prevention, security, tax, or other
            legal obligations, and only for the period those obligations
            require.
          </p>
        </section>
      </div>
    </main>
  );
}
