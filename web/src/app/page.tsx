import Hero from "@/components/Hero";
import SiteHeader from "@/components/SiteHeader";
import FilmLooks from "@/components/FilmLooks";
import ProductJourney from "@/components/ProductJourney";
import PostcardFrames from "@/components/PostcardFrames";
import Pricing from "@/components/Pricing";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="relative overflow-x-clip">
      <SiteHeader />
      <Hero />
      <FilmLooks />
      <ProductJourney />
      <PostcardFrames />
      <Pricing />
      <Footer />
    </main>
  );
}
