import { APP_STORE_URL } from "@/lib/app-store";

const QR_PATH = [
  "M4 4.5h7m6 0h1m3 0h4m2 0h1m2 0h7",
  "M4 5.5h1m5 0h1m2 0h1m1 0h1m1 0h3m2 0h1m1 0h3m1 0h1m1 0h1m5 0h1",
  "M4 6.5h1m1 0h3m1 0h1m1 0h1m3 0h2m1 0h1m3 0h5m2 0h1m1 0h3m1 0h1",
  "M4 7.5h1m1 0h3m1 0h1m1 0h2m4 0h2m1 0h1m1 0h1m2 0h3m1 0h1m1 0h3m1 0h1",
  "M4 8.5h1m1 0h3m1 0h1m1 0h1m1 0h1m1 0h2m1 0h1m1 0h5m1 0h2m1 0h1m1 0h3m1 0h1",
  "M4 9.5h1m5 0h1m1 0h1m1 0h6m4 0h2m2 0h1m1 0h1m5 0h1",
  "M4 10.5h7m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h7",
  "M12 11.5h5m1 0h2m3 0h4",
  "M4 12.5h1m1 0h5m4 0h1m1 0h2m1 0h4m2 0h1m1 0h1m1 0h5",
  "M5 13.5h1m1 0h1m1 0h1m2 0h3m1 0h1m1 0h1m1 0h1m1 0h7m1 0h2m1 0h2m1 0h1",
  "M5 14.5h2m2 0h2m1 0h2m2 0h1m2 0h1m4 0h1m4 0h2m1 0h1m1 0h2",
  "M4 15.5h1m2 0h1m1 0h1m2 0h1m1 0h2m2 0h2m2 0h2m1 0h4m1 0h1m1 0h4",
  "M6 16.5h1m1 0h1m1 0h2m2 0h1m1 0h1m2 0h2m1 0h1m3 0h1m2 0h1m1 0h3m1 0h2",
  "M5 17.5h3m1 0h1m3 0h3m2 0h4m1 0h1m1 0h1m1 0h1m1 0h2m3 0h3",
  "M5 18.5h2m2 0h3m2 0h6m1 0h1m2 0h2m2 0h3m4 0h1",
  "M7 19.5h1m1 0h1m3 0h1m1 0h5m5 0h1m1 0h1m1 0h6",
  "M4 20.5h2m1 0h1m1 0h3m1 0h1m1 0h1m2 0h1m1 0h2m4 0h2m1 0h1m1 0h2m3 0h1",
  "M9 21.5h1m2 0h1m1 0h1m1 0h3m1 0h1m2 0h5m2 0h2m1 0h2m1 0h1",
  "M7 22.5h1m2 0h4m1 0h1m2 0h3m1 0h1m2 0h1m2 0h1m2 0h2m1 0h2",
  "M4 23.5h1m3 0h1m2 0h5m2 0h2m2 0h5m1 0h8",
  "M4 24.5h1m4 0h3m3 0h5m1 0h3m2 0h1m1 0h2m1 0h3m1 0h1",
  "M4 25.5h2m7 0h1m1 0h1m1 0h2m3 0h4m1 0h1m1 0h2m2 0h1m2 0h1",
  "M4 26.5h1m1 0h1m3 0h1m1 0h2m3 0h1m2 0h1m4 0h1m8 0h2",
  "M4 27.5h1m1 0h1m4 0h2m1 0h3m1 0h2m3 0h1m1 0h1m2 0h2m2 0h3m1 0h1",
  "M4 28.5h1m3 0h4m3 0h1m2 0h2m1 0h1m4 0h1m1 0h5m2 0h1",
  "M12 29.5h4m4 0h2m1 0h1m3 0h2m3 0h1m1 0h3",
  "M4 30.5h7m3 0h9m1 0h5m1 0h1m1 0h1m1 0h2",
  "M4 31.5h1m5 0h1m1 0h2m1 0h1m4 0h3m1 0h5m3 0h3",
  "M4 32.5h1m1 0h3m1 0h1m1 0h1m1 0h1m1 0h3m1 0h3m1 0h1m1 0h1m1 0h6m1 0h1",
  "M4 33.5h1m1 0h3m1 0h1m1 0h1m1 0h1m3 0h3m1 0h3m3 0h2m2 0h5",
  "M4 34.5h1m1 0h3m1 0h1m1 0h1m5 0h1m2 0h2m1 0h3m1 0h4m1 0h2",
  "M4 35.5h1m5 0h1m2 0h1m1 0h2m3 0h1m3 0h2m3 0h1m2 0h1m1 0h1",
  "M4 36.5h7m1 0h2m4 0h2m1 0h2m3 0h3m2 0h1m3 0h1",
].join("");

export default function AppStoreBadge() {
  return (
    <div className="flex w-full flex-col items-center gap-3">
      <div className="flex w-full max-w-[24rem] flex-col gap-2 rounded-2xl border border-cream/10 bg-cream/[0.055] p-2 shadow-[0_20px_60px_-36px_rgba(0,0,0,0.95)] backdrop-blur-md sm:max-w-[27rem]">
        <PlatformRow
          ariaLabel="Download Tumble on the App Store"
          icon={<AppleIcon />}
          eyebrow="Download on the"
          label="App Store"
        />
      </div>

      <p className="text-center text-xs text-cream/50">
        iPhone · free to start
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
    <a
      href={APP_STORE_URL}
      className="group flex w-full items-center justify-center gap-3"
      target="_blank"
      rel="noreferrer"
      aria-label={ariaLabel}
    >
      <div
        className="flex min-w-0 flex-1 items-center gap-3 rounded-xl border border-cream/15 bg-ink/65 px-4 py-2.5 text-left transition group-hover:border-amber/45 group-hover:bg-ink/80 sm:flex-none sm:basis-[18rem]"
      >
        {icon}
        <div className="min-w-0 flex-1 leading-tight">
          <div className="text-[10px] uppercase tracking-wide text-cream/60">{eyebrow}</div>
          <div className="text-lg font-semibold text-cream">{label}</div>
        </div>
        <ExternalLinkIcon />
      </div>

      <div
        className="grid h-20 w-20 shrink-0 place-items-center rounded-xl border border-cream/15 bg-ink/65 p-1 transition group-hover:border-amber/45 sm:h-24 sm:w-24"
        aria-hidden="true"
      >
        <AppStoreQr />
      </div>
    </a>
  );
}

function AppleIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor" className="text-cream" aria-hidden="true">
      <path d="M16.365 1.43c0 1.14-.42 2.2-1.12 3-.77.88-2.03 1.56-3.06 1.48-.14-1.1.4-2.24 1.05-2.96.74-.82 2.05-1.44 3.13-1.52.02.13.02.26.02.4l-.02-.4zM20.5 17.02c-.55 1.27-.82 1.84-1.53 2.96-.99 1.57-2.39 3.52-4.12 3.53-1.54.02-1.94-1-4.03-.99-2.09.01-2.52 1.01-4.06.99-1.73-.02-3.05-1.78-4.04-3.35C1.13 15.9.87 11.2 2.6 8.72c1.02-1.47 2.63-2.34 4.14-2.34 1.54 0 2.5 1.01 3.77 1.01 1.23 0 1.98-1.01 3.77-1.01 1.34 0 2.76.73 3.77 1.99-3.31 1.81-2.77 6.54.68 7.66l-.02-.01z" />
    </svg>
  );
}

function ExternalLinkIcon() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="shrink-0 text-amber transition group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
      aria-hidden="true"
    >
      <path d="M7 17 17 7" />
      <path d="M8 7h9v9" />
    </svg>
  );
}

function AppStoreQr() {
  return (
    <svg
      viewBox="0 0 41 41"
      shapeRendering="crispEdges"
      className="h-full w-full rounded-lg bg-cream"
      aria-hidden="true"
    >
      <path fill="currentColor" className="text-cream" d="M0 0h41v41H0z" />
      <path stroke="currentColor" className="text-ink" d={QR_PATH} />
    </svg>
  );
}
