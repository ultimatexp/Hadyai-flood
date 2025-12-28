"use client";

import Link from "next/link";
import { Users, PawPrint } from "lucide-react";

export default function LandingPage() {
    return (
        <main className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex flex-col items-center justify-center p-6">
            {/* Background Pattern */}
            <div className="absolute inset-0 opacity-10">
                <div className="absolute inset-0" style={{
                    backgroundImage: `radial-gradient(circle at 2px 2px, white 1px, transparent 0)`,
                    backgroundSize: '40px 40px'
                }} />
            </div>

            {/* Title */}
            <div className="text-center mb-12 z-10">
                <h1 className="text-4xl md:text-5xl font-bold text-white mb-4 drop-shadow-lg">
                    คนไทยช่วยกัน
                </h1>
                <p className="text-slate-300 text-lg">
                    เลือกประเภทความช่วยเหลือ
                </p>
            </div>

            {/* 3D Cards Container */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl w-full z-10 perspective-1000">
                {/* Help People Card */}
                <Link href="/home" className="block group">
                    <div className="relative transform-gpu transition-all duration-500 hover:scale-105 hover:-translate-y-2 hover:rotate-y-[-5deg]"
                        style={{ transformStyle: 'preserve-3d' }}>
                        {/* Card Shadow */}
                        <div className="absolute inset-0 bg-blue-600/30 rounded-3xl blur-xl translate-y-4 group-hover:translate-y-6 group-hover:blur-2xl transition-all" />

                        {/* Card */}
                        <div className="relative bg-gradient-to-br from-blue-500 via-blue-600 to-blue-700 rounded-3xl p-8 shadow-2xl border border-blue-400/30 overflow-hidden"
                            style={{ transform: 'translateZ(20px)' }}>
                            {/* Shine Effect */}
                            <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/20 to-white/0 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                            {/* Icon */}
                            <div className="w-24 h-24 bg-white/20 backdrop-blur rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg group-hover:scale-110 transition-transform duration-500"
                                style={{ transform: 'translateZ(40px)' }}>
                                <Users className="w-14 h-14 text-white drop-shadow-lg" />
                            </div>

                            {/* Text */}
                            <h2 className="text-3xl font-bold text-white text-center mb-3 drop-shadow-lg"
                                style={{ transform: 'translateZ(30px)' }}>
                                ช่วยคน
                            </h2>
                            <p className="text-blue-100 text-center text-sm"
                                style={{ transform: 'translateZ(25px)' }}>
                                ขอความช่วยเหลือ • เป็นอาสา • ค้นหาผู้ประสบภัย
                            </p>

                            {/* Decorative Elements */}
                            <div className="absolute -bottom-6 -right-6 w-32 h-32 bg-white/10 rounded-full blur-2xl" />
                            <div className="absolute -top-6 -left-6 w-24 h-24 bg-blue-300/20 rounded-full blur-xl" />
                        </div>
                    </div>
                </Link>

                {/* Help Animals Card */}
                <Link href="/find-pet" className="block group">
                    <div className="relative transform-gpu transition-all duration-500 hover:scale-105 hover:-translate-y-2 hover:rotate-y-[5deg]"
                        style={{ transformStyle: 'preserve-3d' }}>
                        {/* Card Shadow */}
                        <div className="absolute inset-0 bg-orange-500/30 rounded-3xl blur-xl translate-y-4 group-hover:translate-y-6 group-hover:blur-2xl transition-all" />

                        {/* Card */}
                        <div className="relative bg-gradient-to-br from-orange-400 via-orange-500 to-orange-600 rounded-3xl p-8 shadow-2xl border border-orange-300/30 overflow-hidden"
                            style={{ transform: 'translateZ(20px)' }}>
                            {/* Shine Effect */}
                            <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/20 to-white/0 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                            {/* Icon */}
                            <div className="w-24 h-24 bg-white/20 backdrop-blur rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg group-hover:scale-110 transition-transform duration-500"
                                style={{ transform: 'translateZ(40px)' }}>
                                <PawPrint className="w-14 h-14 text-white drop-shadow-lg" />
                            </div>

                            {/* Text */}
                            <h2 className="text-3xl font-bold text-white text-center mb-3 drop-shadow-lg"
                                style={{ transform: 'translateZ(30px)' }}>
                                ช่วยสัตว์
                            </h2>
                            <p className="text-orange-100 text-center text-sm"
                                style={{ transform: 'translateZ(25px)' }}>
                                ค้นหาสัตว์หาย • แจ้งพบสัตว์ • ศูนย์พักพิง
                            </p>

                            {/* Decorative Elements */}
                            <div className="absolute -bottom-6 -right-6 w-32 h-32 bg-white/10 rounded-full blur-2xl" />
                            <div className="absolute -top-6 -left-6 w-24 h-24 bg-orange-300/20 rounded-full blur-xl" />
                        </div>
                    </div>
                </Link>
            </div>

            {/* Hall of Heroes Banner */}
            <div className="mt-8 max-w-4xl w-full z-10 perspective-1000">
                <Link href="/hall-of-heroes" className="block group">
                    <div className="relative transform-gpu transition-all duration-500 hover:scale-[1.02] hover:-translate-y-1"
                        style={{ transformStyle: 'preserve-3d' }}>
                        {/* Banner Shadow */}
                        <div className="absolute inset-0 bg-amber-600/20 rounded-3xl blur-xl translate-y-4 group-hover:translate-y-6 group-hover:blur-2xl transition-all" />

                        {/* Banner Content */}
                        <div className="relative bg-gradient-to-r from-zinc-900 via-zinc-800 to-zinc-900 rounded-3xl p-6 md:p-8 shadow-2xl border border-amber-500/30 overflow-hidden flex flex-col md:flex-row items-center gap-6 md:gap-8"
                            style={{ transform: 'translateZ(20px)' }}>

                            {/* Shine Effect */}
                            <div className="absolute inset-0 bg-gradient-to-tr from-amber-500/0 via-amber-500/10 to-amber-500/0 opacity-0 group-hover:opacity-100 transition-opacity duration-1000 animate-pulse" />

                            {/* Icon Section */}
                            <div className="flex-shrink-0">
                                <div className="w-16 h-16 md:w-20 md:h-20 bg-amber-900/30 backdrop-blur rounded-2xl flex items-center justify-center border border-amber-500/30 group-hover:bg-amber-900/50 transition-colors"
                                    style={{ transform: 'translateZ(30px)' }}>
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-8 h-8 md:w-10 md:h-10 text-amber-500 drop-shadow-lg"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" x2="4" y1="22" y2="15" /></svg>
                                </div>
                            </div>

                            {/* Text Section */}
                            <div className="flex-grow text-center md:text-left z-10">
                                <h2 className="text-2xl md:text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-amber-200 via-amber-500 to-amber-700 mb-2 drop-shadow-sm font-serif">
                                    Hall of Heroes
                                </h2>
                                <p className="text-amber-100/80 text-sm md:text-base">
                                    สดุดีวีรชนผู้กล้า • ฮีโร่ของคนไทย
                                </p>
                            </div>

                            {/* Arrow Indicator */}
                            <div className="hidden md:flex items-center text-amber-500/50 group-hover:text-amber-500 group-hover:translate-x-2 transition-all duration-300">
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-8 h-8"><path d="M5 12h14" /><path d="m12 5 7 7-7 7" /></svg>
                            </div>

                            {/* Decorative Elements */}
                            <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3" />
                        </div>
                    </div>
                </Link>
            </div>

            {/* Footer */}
            <div className="mt-12 text-center z-10">
                <p className="text-slate-400 text-sm">
                    ระบบช่วยเหลือ ตามหา คนและสัตว์เลี้ยง
                </p>
            </div>
        </main>
    );
}
