import type { ReactNode } from "react";

/**
 * The site's signature device: film-edge rebate printing. Real film has tiny
 * stamped type and sprocket perforations running down its edge — Tumble borrows
 * that as the structural voice for eyebrows and section breaks, in place of the
 * generic uppercase label or 01/02/03 marker.
 */

/** A stamped mono label, the way a film stock is printed on the rebate edge. */
export function Stamp({
  children,
  frame,
  className = "",
}: {
  children: ReactNode;
  /** Optional frame counter, e.g. "22A" — the little number beside the sprocket. */
  frame?: string;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center gap-2 font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-gold ${className}`}
    >
      <span aria-hidden className="text-gold/70">
        &#9654;
      </span>
      {frame && <span className="text-gold/55">{frame}</span>}
      {children}
    </span>
  );
}

/** A run of sprocket perforations — the film edge itself, as a divider. */
export function Sprockets({ className = "" }: { className?: string }) {
  return (
    <div
      className={`flex h-4 w-full items-center gap-2 overflow-hidden ${className}`}
      aria-hidden
    >
      {Array.from({ length: 80 }).map((_, i) => (
        <span
          key={i}
          className="h-2 w-3 shrink-0 rounded-[2px] bg-cream/12"
        />
      ))}
    </div>
  );
}

/**
 * A full film-edge strip: a hairline-ruled band carrying a stamp on the left and
 * a sprocket run filling the rest — used to open or close a section.
 */
export function FilmEdge({
  label,
  frame,
  className = "",
}: {
  label: ReactNode;
  frame?: string;
  className?: string;
}) {
  return (
    <div
      className={`flex items-center gap-4 border-y border-cream/10 py-2.5 ${className}`}
    >
      <Stamp frame={frame} className="shrink-0">
        {label}
      </Stamp>
      <div className="flex h-3 min-w-0 flex-1 items-center gap-1.5 overflow-hidden" aria-hidden>
        {Array.from({ length: 80 }).map((_, i) => (
          <span key={i} className="h-1.5 w-2.5 shrink-0 rounded-[2px] bg-cream/10" />
        ))}
      </div>
    </div>
  );
}
