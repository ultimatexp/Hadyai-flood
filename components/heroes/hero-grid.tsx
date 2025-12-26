"use client";

import { Hero } from "@/app/actions/hero";
import { HeroCard } from "./hero-card";
import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { AddHeroDialog } from "./add-hero-dialog";
import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import Image from "next/image";

interface HeroGridProps {
    heroes: Hero[];
}

export function HeroGrid({ heroes }: HeroGridProps) {
    const [selectedHero, setSelectedHero] = useState<Hero | null>(null);
    const [searchQuery, setSearchQuery] = useState("");

    const filteredHeroes = heroes.filter(h =>
        h.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (h.biography && h.biography.toLowerCase().includes(searchQuery.toLowerCase()))
    );

    return (
        <div className="space-y-8">
            {/* Controls */}
            <div className="flex flex-col md:flex-row gap-4 justify-between items-center text-white">
                <div className="relative w-full md:w-96">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" size={18} />
                    <Input
                        className="pl-10 bg-zinc-900/50 border-zinc-700 text-white placeholder:text-zinc-500"
                        placeholder="Search heroes..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
                <AddHeroDialog />
            </div>

            {/* Grid */}
            {filteredHeroes.length === 0 ? (
                <div className="text-center py-20 text-zinc-500">
                    <p className="text-xl">No heroes found.</p>
                    <p className="text-sm">Be the first to add a hero.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
                    {filteredHeroes.map(hero => (
                        <HeroCard key={hero.id} hero={hero} onClick={setSelectedHero} />
                    ))}
                </div>
            )}

            {/* Detail Dialog */}
            <Dialog open={!!selectedHero} onOpenChange={(open) => !open && setSelectedHero(null)}>
                <DialogContent className="bg-zinc-900 border-amber-500/50 text-amber-50 max-w-2xl">
                    {selectedHero && (
                        <div className="grid md:grid-cols-2 gap-6">
                            <div className="relative aspect-[3/4] rounded-lg overflow-hidden border border-amber-500/30">
                                {selectedHero.image_url ? (
                                    <Image src={selectedHero.image_url} alt={selectedHero.name} fill className="object-cover" />
                                ) : (
                                    <div className="w-full h-full bg-zinc-800 flex items-center justify-center text-zinc-600">No Image</div>
                                )}
                            </div>
                            <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-2 custom-scrollbar">
                                <div>
                                    {selectedHero.rank && <div className="text-amber-500/80 font-serif text-sm uppercase tracking-widest">{selectedHero.rank}</div>}
                                    <DialogTitle className="text-3xl font-serif text-amber-500 mb-2">{selectedHero.name}</DialogTitle>
                                </div>

                                <div className="h-px bg-gradient-to-r from-amber-500/50 to-transparent" />

                                <div className="prose prose-invert prose-amber">
                                    <p className="whitespace-pre-wrap leading-relaxed text-zinc-300">
                                        {selectedHero.biography || "No biography available."}
                                    </p>
                                </div>

                                {selectedHero.social_link && (
                                    <div className="pt-4">
                                        <a
                                            href={selectedHero.social_link}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="text-indigo-400 hover:text-indigo-300 text-sm hover:underline"
                                        >
                                            Source / Reference
                                        </a>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    );
}
