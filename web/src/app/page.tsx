import Hero from "@/components/Hero";
import RollExplainer from "@/components/RollExplainer";
import DrawerMockup from "@/components/DrawerMockup";
import AppProgress from "@/components/AppProgress";
import Pricing from "@/components/Pricing";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <Hero />
      <RollExplainer />
      <DrawerMockup />
      <AppProgress />
      <Pricing />
      <Footer />
    </main>
  );
}
