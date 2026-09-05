import type { Metadata } from "next";
import SiteHeader from "@/components/SiteHeader";
import Releases from "@/components/Releases";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Updates",
  description: "What is new in Tumble, the private film camera for iPhone.",
};

export default function UpdatesPage() {
  return (
    <main className="relative min-h-screen overflow-x-clip">
      <SiteHeader />
      <div className="mx-auto max-w-6xl px-6 pt-16 md:pt-24">
        <p className="font-mono text-[11px] font-bold uppercase tracking-[0.18em] text-gold">Developing notes</p>
        <h1 className="mt-5 max-w-3xl font-display text-5xl font-extrabold leading-[0.9] tracking-tight text-cream sm:text-6xl lg:text-7xl">What&rsquo;s new in Tumble.</h1>
        <p className="mt-6 max-w-2xl text-lg leading-relaxed text-cream/70">Small releases, honest notes, and a camera that keeps getting slower in the ways that count.</p>
      </div>
      <Releases />
      <Footer />
    </main>
  );
}
