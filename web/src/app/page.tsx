import Hero from "@/components/Hero";
import RollExplainer from "@/components/RollExplainer";
import AppShowcase from "@/components/AppShowcase";
import PostcardFrames from "@/components/PostcardFrames";
import FilmPacks from "@/components/FilmPacks";
import Releases from "@/components/Releases";
import Pricing from "@/components/Pricing";
import Footer from "@/components/Footer";
import ReleaseBanner from "@/components/ReleaseBanner";

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <ReleaseBanner />
      <Hero />
      <RollExplainer />
      <AppShowcase />
      <PostcardFrames />
      <FilmPacks />
      <Releases />
      <Pricing />
      <Footer />
    </main>
  );
}
