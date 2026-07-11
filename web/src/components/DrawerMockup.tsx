import Image from "next/image";
import appMockup from "../../mocks/mock.png";

export default function DrawerMockup() {
  return (
    <section className="relative z-10 mx-auto flex max-w-5xl flex-col items-center justify-center px-6 py-14 md:py-18">
      <h2 className="mb-3 font-display text-3xl font-semibold text-cream sm:text-4xl">
        Your Drawer
      </h2>
      <p className="mb-8 max-w-md text-center text-cream/75">
        Not a camera roll and not a viewfinder-first app. Your home screen is a
        pile of prints from today, with older days tucked into collections.
      </p>

      <div className="relative">
        <div className="absolute -inset-8 rounded-[3rem] bg-gold/20 blur-3xl" aria-hidden="true" />
        <Image
          src={appMockup}
          alt="Tumble app mockup showing a saved instant print in the Drawer."
          sizes="(min-width: 768px) 360px, (min-width: 640px) 340px, 86vw"
          className="relative h-auto w-[min(86vw,340px)] rounded-[1.5rem] shadow-[0_40px_80px_-20px_rgba(0,0,0,0.7)] ring-1 ring-cream/15 md:w-[360px]"
        />
      </div>
    </section>
  );
}
