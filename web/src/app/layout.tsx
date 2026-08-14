import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, Caveat, Hanken_Grotesk, Space_Mono } from "next/font/google";
import { APP_STORE_URL } from "@/lib/app-store";
import "./globals.css";

// Display — a humanist grotesque with optical character; analog, not a default serif.
const bricolage = Bricolage_Grotesque({
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
  variable: "--font-display",
  display: "swap",
});

// Body — warm, legible, and deliberately not Inter.
const hanken = Hanken_Grotesk({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
});

// Utility — the film voice: frame counters, date stamps, edge printing, prices.
const spaceMono = Space_Mono({
  subsets: ["latin"],
  weight: ["400", "700"],
  variable: "--font-mono",
  display: "swap",
});

// The same handwriting the app writes postcard notes in. Used sparingly.
const caveat = Caveat({
  subsets: ["latin"],
  weight: ["400", "500"],
  variable: "--font-script",
  display: "swap",
});

const SITE_URL = "https://gettumbleapp.com";
const DESCRIPTION =
  "Tumble is a private film camera for iPhone. Shoot a daily roll of twelve, shake to develop, and finish every shot on real film stock — from faded instant to hand-printed black & white. Free to start, one-time unlocks, no subscriptions.";

const TITLE = "Tumble · A film camera for iPhone";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: TITLE,
    template: "%s · Tumble",
  },
  description: DESCRIPTION,
  applicationName: "Tumble",
  keywords: [
    "film camera app",
    "film stocks",
    "film filters",
    "instant camera",
    "iPhone camera app",
    "analog camera app",
    "daily photo roll",
    "private camera",
    "film looks",
    "postcard frames",
    "polaroid app",
    "Tumble",
  ],
  authors: [{ name: "Tumble" }],
  creator: "Tumble",
  publisher: "Tumble",
  category: "photography",
  alternates: { canonical: "/" },
  formatDetection: { telephone: false, email: false, address: false },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  openGraph: {
    type: "website",
    url: SITE_URL,
    siteName: "Tumble",
    locale: "en_US",
    title: TITLE,
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
  },
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
    apple: [{ url: "/favicon.svg" }],
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Tumble",
  applicationCategory: "PhotoApplication",
  operatingSystem: "iOS",
  softwareVersion: "1.2.0",
  description: DESCRIPTION,
  url: SITE_URL,
  downloadUrl: APP_STORE_URL,
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  publisher: {
    "@type": "Organization",
    name: "Tumble",
    url: SITE_URL,
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
    <html
      lang="en"
      className={`${bricolage.variable} ${hanken.variable} ${spaceMono.variable} ${caveat.variable}`}
    >
      <body>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        {children}
      </body>
    </html>
  );
}
