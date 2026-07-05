import type { CSSProperties } from "react";

/**
 * Hero device mockup: a phone frame showing the Drawer as a loosely-scattered,
 * overlapping pile of developed photos — deliberately NOT a grid. This scattered
 * layout is what reads differently from pico cam at a glance (spec §9.1).
 * Rendered as Tumble's own UI, not a screenshot.
 *
 * Each "photo" is a CSS-rendered little scene (sunset, blue hour, a park, a
 * portrait…) finished with instant-film treatment — vignette, warm aged grade,
 * grain and a sheen on the print — so it reads as a developed shot, not a swatch.
 */

// Reusable film grain, applied per-photo at low opacity.
const GRAIN =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")";

type Photo = {
  rotate: number;
  x: number; // % offset within the drawer area
  y: number;
  scene: string; // layered gradients that read as a photograph
  age: number; // 0–1: how much warm/faded aging to apply
  caption?: string;
};

const PHOTOS: Photo[] = [
  {
    // hazy morning beach — cool sky over warm sand
    rotate: -7,
    x: 4,
    y: 3,
    scene:
      "radial-gradient(80% 55% at 68% 22%, rgba(255,240,205,0.85), rgba(255,240,205,0) 60%), linear-gradient(180deg, #a9cfe0 0%, #c9dfe4 34%, #e7dcc2 56%, #d0a86a 78%, #b8895c 100%)",
    age: 0.45,
    caption: "morning",
  },
  {
    // golden-hour sun over water
    rotate: 7,
    x: 42,
    y: 8,
    scene:
      "radial-gradient(70% 60% at 50% 30%, rgba(255,214,140,0.95), rgba(255,170,110,0) 62%), linear-gradient(180deg, #f4b46a 0%, #e08a58 34%, #9c5a5c 54%, #40384a 72%, #263040 100%)",
    age: 0.2,
  },
  {
    // rooftop at blue hour — deep blue with a warm horizon
    rotate: -3,
    x: 19,
    y: 33,
    scene:
      "radial-gradient(90% 55% at 72% 82%, rgba(240,180,110,0.55), rgba(240,180,110,0) 60%), linear-gradient(180deg, #223d5c 0%, #315679 42%, #5c6f82 62%, #8a7566 82%, #c1946a 100%)",
    age: 0.7,
    caption: "rooftop",
  },
  {
    // sunlit park — greens with a warm sky
    rotate: 10,
    x: 47,
    y: 40,
    scene:
      "radial-gradient(70% 50% at 30% 18%, rgba(255,236,180,0.8), rgba(255,236,180,0) 58%), linear-gradient(180deg, #d7e6cf 0%, #a9c58f 38%, #6f8d55 66%, #3f5738 100%)",
    age: 0.15,
  },
  {
    // soft warm portrait — subject glow against a dark room
    rotate: -12,
    x: 9,
    y: 61,
    scene:
      "radial-gradient(62% 62% at 48% 40%, #ecc39a 0%, #c08a6c 46%, #6f4a48 78%, #3a2b30 100%)",
    age: 0.85,
  },
  {
    // pink dusk — the last shot of the day
    rotate: 4,
    x: 41,
    y: 66,
    scene:
      "radial-gradient(85% 60% at 50% 78%, rgba(255,200,150,0.7), rgba(255,200,150,0) 60%), linear-gradient(180deg, #6f7fa6 0%, #b98aa0 38%, #d99a86 62%, #caa06e 100%)",
    age: 0.35,
    caption: "last one",
  },
];

export default function DrawerMockup() {
  return (
    <section className="relative z-10 mx-auto flex max-w-5xl flex-col items-center justify-center px-6 py-14 md:py-18">
      <h2 className="mb-3 font-display text-3xl font-semibold text-cream sm:text-4xl">
        Your Drawer
      </h2>
      <p className="mb-8 max-w-md text-center text-cream/75">
        Not a camera roll. A drawer you toss prints into, and they age the way
        real photos do.
      </p>

      <div className="relative">
        {/* soft glow behind the phone */}
        <div className="absolute -inset-8 rounded-[3rem] bg-gold/20 blur-3xl" aria-hidden="true" />

        {/* Phone frame */}
        <div className="relative mx-auto aspect-[9/19] w-[240px] rounded-[2.6rem] border border-cream/15 bg-charcoal-deep/90 p-3 shadow-[0_40px_80px_-20px_rgba(0,0,0,0.7)] ring-1 ring-black/40 sm:w-[252px]">
          {/* notch */}
          <div className="absolute left-1/2 top-3 z-20 h-6 w-28 -translate-x-1/2 rounded-full bg-black/70" aria-hidden="true" />

          {/* screen */}
          <div className="relative h-full w-full overflow-hidden rounded-[2rem] bg-gradient-to-b from-[#2a3a49] to-[#182430]">
            <div className="px-5 pt-9 pb-3">
              <div className="font-display text-lg font-semibold text-cream">Drawer</div>
              <div className="text-[11px] text-cream/50">48 developed &middot; 7 left today</div>
            </div>

            {/* scattered pile */}
            <div className="relative mx-3 h-[74%]" aria-hidden="true">
              {PHOTOS.map((p, i) => (
                <DrawerPhoto key={i} photo={p} z={i} />
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function DrawerPhoto({ photo, z }: { photo: Photo; z: number }) {
  const style: CSSProperties = {
    left: `${photo.x}%`,
    top: `${photo.y}%`,
    transform: `rotate(${photo.rotate}deg)`,
    zIndex: z,
  };

  // Aged prints warm up and lose a little contrast over time.
  const agedGrade = `linear-gradient(160deg, rgba(214,150,90,${0.12 + photo.age * 0.24}), rgba(120,70,60,${0.06 + photo.age * 0.16}))`;

  return (
    <div
      className="absolute w-[47%] rounded-[5px] bg-[#f4ecda] p-[6%] pb-[15%] shadow-[0_12px_26px_-8px_rgba(0,0,0,0.65)] ring-1 ring-black/10"
      style={style}
    >
      <div className="relative aspect-square w-full overflow-hidden rounded-[2px] ring-1 ring-black/15">
        {/* the "photograph" */}
        <div className="absolute inset-0" style={{ background: photo.scene }} />
        {/* warm aged grade */}
        <div className="absolute inset-0 mix-blend-multiply" style={{ background: agedGrade }} />
        {/* film grain */}
        <div
          className="absolute inset-0 opacity-40 mix-blend-overlay"
          style={{ backgroundImage: GRAIN, backgroundSize: "100px 100px" }}
        />
        {/* vignette */}
        <div
          className="absolute inset-0"
          style={{
            background:
              "radial-gradient(120% 120% at 50% 44%, rgba(0,0,0,0) 50%, rgba(28,16,18,0.42) 100%)",
          }}
        />
        {/* soft sheen on the print */}
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(125deg, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0) 34%)",
          }}
        />
      </div>
      {photo.caption && (
        <div className="pt-[6%] text-center font-display text-[9px] italic text-ink/70">
          {photo.caption}
        </div>
      )}
    </div>
  );
}
