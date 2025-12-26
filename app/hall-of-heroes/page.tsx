import { getHeroes } from "@/app/actions/hero";
import { HeroGrid } from "@/components/heroes/hero-grid";
import { Flag } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function HallOfHeroesPage() {
    const heroes = await getHeroes();

    return (
        <div className="min-h-screen bg-zinc-950 text-amber-50 selection:bg-amber-500/30">
            {/* Hero Header */}
            <div className="relative py-20 px-6 overflow-hidden">
                <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/dark-matter.png')] opacity-50"></div>
                <div className="absolute inset-0 bg-gradient-to-b from-zinc-900 via-zinc-950 to-zinc-950"></div>

                <div className="relative max-w-7xl mx-auto text-center space-y-4">
                    <div className="flex justify-center mb-4">
                        <Flag className="text-amber-600 w-16 h-16 opacity-80" />
                    </div>
                    <h1 className="text-5xl md:text-7xl font-bold font-serif bg-clip-text text-transparent bg-gradient-to-b from-amber-200 via-amber-500 to-amber-700 drop-shadow-sm">
                        Hall of Heroes
                    </h1>
                    <h2 className="text-2xl md:text-3xl font-serif text-amber-500/80">
                        ฮีโร่ของพวกเรา
                    </h2>
                    <p className="max-w-2xl mx-auto text-zinc-400 mt-6 leading-relaxed">
                        Honoring the brave Thai soldiers who made the ultimate sacrifice in the Cambodian border conflict and other missions. Their courage lives on in our memories.
                    </p>
                </div>
            </div>

            <main className="max-w-7xl mx-auto px-6 pb-20">
                <HeroGrid heroes={heroes} />
            </main>
        </div>
    );
}
