import Hero from "@/components/Hero";
import LaunchWindow from "@/components/LaunchWindow";
import RollExplainer from "@/components/RollExplainer";
import DrawerMockup from "@/components/DrawerMockup";
import AppProgress from "@/components/AppProgress";
import Pricing from "@/components/Pricing";
import Footer from "@/components/Footer";
import ReleaseBanner from "@/components/ReleaseBanner";

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <ReleaseBanner />
      <Hero />
      <LaunchWindow />
      <RollExplainer />
      <DrawerMockup />
      <AppProgress />
      <Pricing />
      <Footer />
    </main>
  );
}
