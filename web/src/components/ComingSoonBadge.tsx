/**
 * Pre-launch stand-in for the store CTA. No live listing yet, so the badge is
 * non-linking and muted, paired with a placeholder QR. Swap in the real App
 * Store badge + listing URL once the store is live.
 */
export default function ComingSoonBadge() {
  return (
    <div className="flex w-full flex-col items-stretch gap-3">
      <div className="flex w-full flex-col gap-2 rounded-2xl border border-cream/10 bg-cream/[0.055] p-2 shadow-[0_20px_60px_-36px_rgba(0,0,0,0.95)] backdrop-blur-md">
        <PlatformRow
          ariaLabel="Coming soon to the App Store"
          icon={<AppleIcon />}
          eyebrow="Coming soon to the"
          label="App Store"
        />
      </div>

      <p className="text-center text-xs text-cream/50">
        iPhone · App Store at launch
      </p>
    </div>
  );
}

function PlatformRow({
  ariaLabel,
  icon,
  eyebrow,
  label,
}: {
  ariaLabel: string;
  icon: React.ReactNode;
  eyebrow: string;
  label: string;
}) {
  return (
    <div className="flex w-full items-center gap-3">
      {/* Greyed "coming soon" platform badge */}
      <div
        className="flex min-w-0 flex-1 items-center gap-3 rounded-xl border border-cream/15 bg-ink/65 px-4 py-2.5 text-left"
        role="img"
        aria-label={ariaLabel}
      >
        {icon}
        <div className="leading-tight">
          <div className="text-[10px] uppercase tracking-wide text-cream/60">{eyebrow}</div>
          <div className="text-lg font-semibold text-cream">{label}</div>
        </div>
      </div>

      {/* Placeholder QR, greyed until there's a listing to point at */}
      <div
        className="grid h-16 w-16 shrink-0 place-items-center rounded-xl border border-cream/15 bg-ink/65"
        role="img"
        aria-label="QR code coming at launch"
      >
        <QrGlyph />
      </div>
    </div>
  );
}

function AppleIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor" className="text-cream" aria-hidden="true">
      <path d="M16.365 1.43c0 1.14-.42 2.2-1.12 3-.77.88-2.03 1.56-3.06 1.48-.14-1.1.4-2.24 1.05-2.96.74-.82 2.05-1.44 3.13-1.52.02.13.02.26.02.4l-.02-.4zM20.5 17.02c-.55 1.27-.82 1.84-1.53 2.96-.99 1.57-2.39 3.52-4.12 3.53-1.54.02-1.94-1-4.03-.99-2.09.01-2.52 1.01-4.06.99-1.73-.02-3.05-1.78-4.04-3.35C1.13 15.9.87 11.2 2.6 8.72c1.02-1.47 2.63-2.34 4.14-2.34 1.54 0 2.5 1.01 3.77 1.01 1.23 0 1.98-1.01 3.77-1.01 1.34 0 2.76.73 3.77 1.99-3.31 1.81-2.77 6.54.68 7.66l-.02-.01z" />
    </svg>
  );
}

function QrGlyph() {
  return (
    <svg width="34" height="34" viewBox="0 0 24 24" className="text-cream/50" aria-hidden="true">
      <g fill="currentColor">
        <path d="M3 3h6v6H3V3zm2 2v2h2V5H5zM15 3h6v6h-6V3zm2 2v2h2V5h-2zM3 15h6v6H3v-6zm2 2v2h2v-2H5z" />
        <path d="M13 13h2v2h-2v-2zm4 0h2v2h-2v-2zm2 2v2h-2v-2h2zm-6 2h2v2h-2v-2zm4 2h2v2h-2v-2z" />
      </g>
    </svg>
  );
}
