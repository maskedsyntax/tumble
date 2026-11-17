import Image from "next/image";

/** The app icon as a rounded tile — the same mark people see on their home screen. */
export default function BrandMark({ size = 32, className = "" }: { size?: number; className?: string }) {
  return (
    <Image
      src="/logo.png"
      alt=""
      width={size}
      height={size}
      aria-hidden="true"
      className={`shrink-0 rounded-[22.5%] shadow-[0_6px_16px_-8px_rgba(0,0,0,0.8)] ring-1 ring-cream/15 ${className}`}
    />
  );
}
