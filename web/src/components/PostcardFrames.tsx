import Image from "next/image";
import { Stamp } from "./FilmEdge";

/**
 * v1.2's headline feature: a developed print can be mounted in one of four
 * postcard frames before it leaves the app. These previews are CSS ports of
 * `TumbleKit/Postcard/*` — same cream stock, same chin, same burnt-in date —
 * so what the site promises is what the export actually produces.
 *
 * Each frame sizes its type in `cqw`, mirroring the app's `width * 0.0xx`
 * font scale, so a frame reads identically at any column width.
 */

const STOCK = "#f4ecda";

/** Deterministic jitter, so the deckle is identical on server and client. */
function deckledPath(): string {
  let seed = 0x5eed;
  const rand = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };
  const perSide = 11;
  const points: string[] = [];
  const push = (x: number, y: number) => points.push(`${x.toFixed(2)}% ${y.toFixed(2)}%`);
  const j = () => (rand() - 0.5) * 3.4;

  for (let i = 0; i < perSide; i++) push((i / perSide) * 100, Math.abs(j()));
  for (let i = 0; i < perSide; i++) push(100 - Math.abs(j()), (i / perSide) * 100);
  for (let i = perSide; i > 0; i--) push((i / perSide) * 100, 100 - Math.abs(j()));
  for (let i = perSide; i > 0; i--) push(Math.abs(j()), (i / perSide) * 100);

  return `polygon(${points.join(", ")})`;
}

const DECKLE = deckledPath();

type FrameProps = { src: string; alt: string };

function Photo({ src, alt, className = "" }: FrameProps & { className?: string }) {
  return (
    <Image
      src={src}
      alt={alt}
      fill
      sizes="(min-width: 1024px) 260px, (min-width: 640px) 40vw, 80vw"
      className={`object-cover ${className}`}
    />
  );
}

/** Classic Instant — the Tumble print itself: cream stock, thick chin. */
function ClassicInstant({ src, alt }: FrameProps) {
  return (
    <div className="w-full min-w-0 [container-type:inline-size]">
      <div
        className="relative w-full rounded-[2cqw] pt-[6cqw] pr-[6cqw] pb-[15cqw] pl-[6cqw] shadow-[0_5cqw_10cqw_-4cqw_rgba(0,0,0,0.55)]"
        style={{ backgroundColor: STOCK }}
      >
        <div className="relative aspect-square w-full overflow-hidden rounded-[0.8cqw] ring-1 ring-ink/15">
          <Photo src={src} alt={alt} />
        </div>
        <span className="absolute bottom-[4.6cqw] left-[7.5cqw] max-w-[60cqw] truncate font-script text-[5.2cqw] leading-none text-ink/75">
          keep this one.
        </span>
        <span className="absolute right-[7.5cqw] bottom-[4.5cqw] font-mono text-[2.4cqw] leading-none font-medium text-ink/38">
          18 JUL 26
        </span>
      </div>
    </div>
  );
}

/** Vintage Postcard — letterpress header, stamp box, postmark, writing side. */
function VintagePostcard({ src, alt }: FrameProps) {
  return (
    <div className="w-full min-w-0 [container-type:inline-size]">
      <div
        className="w-full rounded-[2cqw] p-[5cqw] shadow-[0_5cqw_10cqw_-4cqw_rgba(0,0,0,0.55)] ring-1 ring-ink/10"
        style={{ backgroundColor: STOCK }}
      >
        <div className="relative aspect-square w-full overflow-hidden rounded-[0.8cqw] ring-1 ring-ink/18">
          <Photo src={src} alt={alt} />
        </div>

        <div className="mt-[2cqw] px-[1cqw] pb-[0.5cqw]">
          <div className="flex min-w-0 items-start justify-between gap-[4cqw]">
            <div className="pt-[1cqw]">
              <div className="font-display text-[4.2cqw] leading-none font-semibold tracking-[0.8cqw] text-ink/72">
                POST CARD
              </div>
              <div className="mt-[1.2cqw] text-[2cqw] leading-none text-ink/42">
                Correspondence
            </div>
          </div>

          <div className="relative shrink-0">
            {/* Stamp box */}
            <div className="flex h-[11.5cqw] w-[15cqw] items-center justify-center border border-dashed border-ink/35 bg-white/50">
              <span className="text-[3.5cqw] leading-none text-amber/80">&#9673;</span>
            </div>
            {/* Postmark, struck over the stamp's inner edge */}
            <div className="absolute top-[-1.4cqw] left-[-6cqw] flex h-[11.5cqw] w-[11.5cqw] rotate-[-9deg] items-center justify-center rounded-full border border-ink/40">
              <div className="flex h-[8.8cqw] w-[8.8cqw] items-center justify-center rounded-full border-[0.5px] border-ink/30">
                <span className="font-mono text-[1.7cqw] leading-none font-semibold text-ink/55">
                  18 JUL
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-[1.6cqw] h-px w-full bg-ink/28" />

        <div className="mt-[2cqw] min-w-0 truncate font-script text-[5.2cqw] leading-none text-ink/78">
          Wish you were here.
        </div>
      </div>
      </div>
    </div>
  );
}

/** Bordered Film — full-bleed 4:5 print, note and burnt-in amber date. */
function BorderedFilm({ src, alt }: FrameProps) {
  return (
    <div className="w-full min-w-0 [container-type:inline-size]">
      <div
        className="w-full rounded-[1.2cqw] p-[3.5cqw] pb-[4.5cqw] shadow-[0_5cqw_10cqw_-4cqw_rgba(0,0,0,0.55)]"
        style={{ backgroundColor: "#fbf8f1" }}
      >
        <div className="relative aspect-4/5 w-full overflow-hidden">
          <Photo src={src} alt={alt} />
          <div className="absolute inset-x-0 bottom-0 flex min-w-0 items-end justify-between gap-[3cqw] bg-linear-to-b from-transparent to-black/35 px-[4cqw] pt-[8cqw] pb-[3cqw]">
            <span className="min-w-0 truncate font-script text-[5cqw] leading-none text-white/92 drop-shadow-[0_0.2cqw_0.6cqw_rgba(0,0,0,0.55)]">
              after the rain
            </span>
            <span className="font-mono text-[3.6cqw] leading-none font-semibold text-[#f2a65a]/90 drop-shadow-[0_0.1cqw_0.4cqw_rgba(0,0,0,0.4)]">
              18&#183;07&#183;26
            </span>
        </div>
      </div>
      </div>
    </div>
  );
}

/** Deckled Edge — hand-torn photo taped to a cream album page. */
function DeckledEdge({ src, alt }: FrameProps) {
  return (
    <div className="w-full min-w-0 [container-type:inline-size]">
      <div className="w-full rounded-[2cqw] bg-linear-to-b from-[#f4ecda] to-[#ede2c9] pt-[7.5cqw] pb-[8cqw] shadow-[0_5cqw_10cqw_-4cqw_rgba(0,0,0,0.55)]">
        <div className="relative mx-auto w-[82%] -rotate-[1.5deg]">
          <div
            className="relative aspect-square w-full drop-shadow-[0_1.2cqw_2cqw_rgba(0,0,0,0.3)]"
            style={{ clipPath: DECKLE }}
          >
            <Photo src={src} alt={alt} />
          </div>
          {/* Two strips of translucent tape, as in DeckledEdgeFrame */}
          <span className="absolute top-[-2.5cqw] left-[2%] h-[5.5cqw] w-[20cqw] rotate-[-14deg] rounded-[0.4cqw] border border-white/25 bg-[#fffdf4]/42 shadow-[0_0.3cqw_0.6cqw_rgba(0,0,0,0.12)]" />
          <span className="absolute top-[-2.5cqw] right-[2%] h-[5.5cqw] w-[20cqw] rotate-[11deg] rounded-[0.4cqw] border border-white/25 bg-[#fffdf4]/42 shadow-[0_0.3cqw_0.6cqw_rgba(0,0,0,0.12)]" />
        </div>
        <div className="mt-[5.5cqw] truncate px-[6cqw] text-center font-script text-[5.5cqw] leading-none text-ink/75">
          a quiet afternoon
        </div>
      </div>
    </div>
  );
}

const FRAMES = [
  {
    name: "Classic",
    full: "Classic Instant",
    tagline: "The Tumble print, cream stock and all.",
    render: <ClassicInstant src="/frames/frame-1.jpg" alt="A waterfall saved in the Classic Instant frame." />,
  },
  {
    name: "Vintage",
    full: "Vintage Postcard",
    tagline: "Stamp box, postmark, and room to write.",
    render: <VintagePostcard src="/frames/frame-2.jpg" alt="Flowers saved in the Vintage Postcard frame." />,
  },
  {
    name: "Film",
    full: "Bordered Film",
    tagline: "Full-bleed with a burnt-in date stamp.",
    render: <BorderedFilm src="/frames/frame-3.jpg" alt="Leaves saved in the Bordered Film frame." />,
  },
  {
    name: "Deckled",
    full: "Deckled Edge",
    tagline: "Torn paper edge, taped to the page.",
    render: <DeckledEdge src="/frames/frame-4.jpg" alt="Clouds saved in the Deckled Edge frame." />,
  },
];

const DETAILS = [
  {
    kicker: "In your own hand",
    body: "Sixty characters, written on the print itself. It rides along wherever the postcard goes.",
  },
  {
    kicker: "Filters come with it",
    body: "Faded Instant and Warm Archive export baked into the frame, not re-applied later.",
  },
  {
    kicker: "Nothing saved blind",
    body: "Every frame is previewed at full size before it reaches your photo library.",
  },
];

export default function PostcardFrames() {
  return (
    <section className="relative z-10 mx-auto max-w-5xl px-6 py-14 md:py-18">
      <div className="mb-10 max-w-2xl">
        <Stamp frame="v1.2">Postcard studio</Stamp>
        <h2 className="mt-4 font-display text-3xl leading-tight font-bold text-cream sm:text-4xl">
          Frame it like you felt it.
        </h2>
        <p className="mt-4 leading-relaxed text-cream/75">
          A developed print doesn&rsquo;t have to leave Tumble as a bare square.
          Pick one of four finishes, add a note in your own handwriting, and save
          the moment as a postcard that looks like it was kept, not exported.
        </p>
      </div>

      <ul className="grid grid-cols-2 gap-x-5 gap-y-9 sm:gap-x-7 lg:grid-cols-4">
        {FRAMES.map((frame) => (
          <li key={frame.name} className="flex min-w-0 flex-col">
            {/* Grid rows stretch, so centring the frame in a flex-1 box keeps
                every caption on the same baseline despite four aspect ratios. */}
            <div className="flex min-w-0 flex-1 items-center">{frame.render}</div>
            <div className="mt-5">
              <h3 className="font-display text-lg font-semibold text-cream">
                {frame.full}
              </h3>
              <p className="mt-1.5 text-sm leading-relaxed text-cream/68">
                {frame.tagline}
              </p>
            </div>
          </li>
        ))}
      </ul>

      <div className="mt-12 grid gap-4 border-t border-cream/12 pt-9 sm:grid-cols-3">
        {DETAILS.map((detail) => (
          <div key={detail.kicker}>
            <div className="font-mono text-[11px] font-bold uppercase tracking-[0.16em] text-amber">
              {detail.kicker}
            </div>
            <p className="mt-3 text-sm leading-relaxed text-cream/70">{detail.body}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
