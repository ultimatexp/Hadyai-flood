"use client";

import { Hero } from "@/app/actions/hero";
import { motion } from "framer-motion";
import Image from "next/image";
import { HeroDialog } from "./hero-dialog";

interface HeroCardProps {
    hero: Hero;
    onClick: (hero: Hero) => void;
}

export function HeroCard({ hero, onClick }: HeroCardProps) {
    return (
        <motion.div
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="relative group cursor-pointer"
            onClick={() => onClick(hero)}
        >
            {/* Gold Frame Container */}
            <div className="relative p-1 bg-gradient-to-b from-[#CFB53B] via-[#E6D28C] to-[#9E8424] rounded-lg shadow-xl shadow-amber-900/20">
                <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/gold-scale.png')] opacity-30 mix-blend-overlay"></div>

                {/* Inner Content */}
                <div className="relative bg-zinc-900 rounded-md overflow-hidden border border-[#B49B28]">
                    {/* Image Aspec Ratio */}
                    <div className="relative aspect-[3/4] overflow-hidden">
                        {hero.image_url ? (
                            <Image
                                src={hero.image_url}
                                alt={hero.name}
                                fill
                                className="object-cover transition-transform duration-500 group-hover:scale-110 sepia-[.3] group-hover:sepia-0"
                            />
                        ) : (
                            <div className="w-full h-full bg-zinc-800 flex items-center justify-center text-zinc-500">
                                No Image
                            </div>
                        )}

                        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-90"></div>

                        <div className="absolute bottom-0 left-0 right-0 p-4 transform translate-y-2 group-hover:translate-y-0 transition-transform duration-300">
                            {hero.rank && (
                                <p className="text-[#E6D28C] text-xs font-serif tracking-wider uppercase mb-1 drop-shadow-md">
                                    {hero.rank}
                                </p>
                            )}
                            <h3 className="text-white font-bold text-lg leading-tight drop-shadow-lg font-serif">
                                {hero.name}
                            </h3>
                        </div>
                    </div>
                </div>
            </div>

            {/* Decorative corners (CSS based simple ones) */}
            <div className="absolute -top-1 -left-1 w-6 h-6 border-t-2 border-l-2 border-[#FFE55C] rounded-tl-lg pointer-events-none"></div>
            <div className="absolute -top-1 -right-1 w-6 h-6 border-t-2 border-r-2 border-[#FFE55C] rounded-tr-lg pointer-events-none"></div>
            <div className="absolute -bottom-1 -left-1 w-6 h-6 border-b-2 border-l-2 border-[#FFE55C] rounded-bl-lg pointer-events-none"></div>
            <div className="absolute -bottom-1 -right-1 w-6 h-6 border-b-2 border-r-2 border-[#FFE55C] rounded-br-lg pointer-events-none"></div>

            {/* Edit Button - Top Right */}
            <div className="absolute top-2 right-2 z-20 opacity-0 group-hover:opacity-100 transition-opacity">
                <div onClick={(e) => e.stopPropagation()}>
                    <HeroDialog
                        hero={hero}
                        trigger={
                            <button className="p-2 bg-zinc-900/80 hover:bg-zinc-800 text-amber-500 rounded-full border border-amber-500/30 backdrop-blur-sm transition-colors">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z" /></svg>
                            </button>
                        }
                    />
                </div>
            </div>
        </motion.div>
    );
}
