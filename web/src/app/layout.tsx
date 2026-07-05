import type { Metadata, Viewport } from "next";
import { Fraunces, Inter } from "next/font/google";
import "./globals.css";

const fraunces = Fraunces({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  style: ["normal", "italic"],
  variable: "--font-display",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
});

const SITE_URL = "https://gettumbleapp.com";
const DESCRIPTION =
  "Tumble is a tiny lock-screen camera that makes you wait to see what you shot. Twelve shots a day. Shake to develop. Join the waitlist.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "Tumble · A camera that makes you wait",
  description: DESCRIPTION,
  applicationName: "Tumble",
  keywords: ["camera", "film camera", "iPhone", "lock screen", "instant photo", "Tumble"],
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: "Tumble",
    title: "Tumble · A camera that makes you wait",
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: "Tumble · A camera that makes you wait",
    description: DESCRIPTION,
  },
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#2e4052",
  colorScheme: "dark",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${fraunces.variable} ${inter.variable}`}>
      <body>{children}</body>
    </html>
  );
}
