"use client";

import { useState, useEffect } from "react";
import { getShelters } from "@/app/actions/shelter";
import { ArrowLeft, Plus, MapPin, Dog, Cat, ExternalLink } from "lucide-react";
import Link from "next/link";
import { ThaiButton } from "@/components/ui/thai-button";

export default function SheltersPage() {
    const [shelters, setShelters] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchShelters = async () => {
            const result = await getShelters();
            if (result.success && result.data) {
                setShelters(result.data);
            }
            setLoading(false);
        };
        fetchShelters();
    }, []);

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <div className="bg-white shadow-sm p-4 sticky top-0 z-50">
                <div className="max-w-5xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <Link href="/find-pet">
                            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                                <ArrowLeft className="w-6 h-6 text-gray-700" />
                            </button>
                        </Link>
                        <h1 className="text-xl font-bold text-gray-900">ศูนย์พักพิงน้อง</h1>
                    </div>
                    <Link href="/shelters/new">
                        <ThaiButton className="bg-orange-500 hover:bg-orange-600 shadow-orange-200">
                            <Plus className="w-5 h-5 mr-1" />
                            ลงทะเบียนศูนย์
                        </ThaiButton>
                    </Link>
                </div>
            </div>

            <div className="max-w-5xl mx-auto p-4">
                {loading ? (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="bg-white rounded-xl h-80 animate-pulse" />
                        ))}
                    </div>
                ) : shelters.length === 0 ? (
                    <div className="text-center py-20 text-gray-500">
                        <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <HomeIcon className="w-10 h-10 text-gray-300" />
                        </div>
                        <h3 className="text-lg font-bold mb-2">ยังไม่มีข้อมูลศูนย์พักพิง</h3>
                        <p>ร่วมเป็นส่วนหนึ่งในการช่วยเหลือสัตว์เลี้ยง</p>
                    </div>
                ) : (
                    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                        {shelters.map((shelter) => (
                            <Link href={`/shelters/${shelter.id}`} key={shelter.id} className="block group">
                                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-all h-full flex flex-col">
                                    <div className="aspect-video relative bg-gray-100 overflow-hidden">
                                        {shelter.images && shelter.images[0] ? (
                                            <img
                                                src={shelter.images[0]}
                                                alt={shelter.name}
                                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                            />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                                                <HomeIcon className="w-12 h-12" />
                                            </div>
                                        )}
                                        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-4 pt-12">
                                            <h3 className="text-white font-bold text-lg truncate">{shelter.name}</h3>
                                        </div>
                                    </div>

                                    <div className="p-4 flex-1 flex flex-col">
                                        <p className="text-gray-600 text-sm mb-4 line-clamp-2 flex-1">
                                            {shelter.description || "ไม่มีรายละเอียด"}
                                        </p>

                                        <div className="flex items-center gap-4 text-sm text-gray-500 mb-4">
                                            <div className="flex items-center gap-1">
                                                <Dog className="w-4 h-4 text-orange-500" />
                                                <span>{shelter.pet_count_dog || 0}</span>
                                            </div>
                                            <div className="flex items-center gap-1">
                                                <Cat className="w-4 h-4 text-blue-500" />
                                                <span>{shelter.pet_count_cat || 0}</span>
                                            </div>
                                        </div>

                                        <div className="pt-4 border-t border-gray-100 flex items-center justify-between">
                                            <div className="flex items-center gap-1 text-xs text-gray-500">
                                                <MapPin className="w-3 h-3" />
                                                ดูแผนที่
                                            </div>
                                            <span className="text-orange-500 text-sm font-bold flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                                                ดูรายละเอียด <ExternalLink className="w-3 h-3" />
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}

function HomeIcon({ className }: { className?: string }) {
    return (
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
            <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <polyline points="9 22 9 12 15 12 15 22" />
        </svg>
    );
}
