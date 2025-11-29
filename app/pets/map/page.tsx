"use client";

import { useState, useEffect } from "react";
import dynamic from "next/dynamic";
import { getAllPetLocations } from "@/app/actions/map";
import { getShelters } from "@/app/actions/shelter";
import { Loader2, ArrowLeft, Filter, Map as MapIcon, Home, Plus, MapPin } from "lucide-react";
import Link from "next/link";
import { ThaiButton } from "@/components/ui/thai-button";
import { LostPetForm } from "@/components/pet/lost-pet-form";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter } from "next/navigation";

// Dynamically import Map component to avoid SSR issues
const MapWithNoSSR = dynamic(() => import("@/components/map/pet-map"), {
    ssr: false,
    loading: () => (
        <div className="w-full h-full flex items-center justify-center bg-gray-100">
            <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
        </div>
    ),
});

export default function PetMapPage() {
    const [pets, setPets] = useState<any[]>([]);
    const [shelters, setShelters] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'ALL' | 'LOST' | 'FOUND' | 'SHELTER'>('ALL');
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [isLostPetFormOpen, setIsLostPetFormOpen] = useState(false);
    const [user, setUser] = useState<any>(null);
    const router = useRouter();

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, setUser);
        return () => unsubscribe();
    }, []);

    const handleReportLostPetClick = () => {
        if (!user) {
            alert('กรุณาเข้าสู่ระบบก่อนแจ้งสัตว์หาย');
            router.push('/login');
            return;
        }
        setIsLostPetFormOpen(true);
        setIsMenuOpen(false);
    };

    useEffect(() => {
        const fetchData = async () => {
            const [petResult, shelterResult] = await Promise.all([
                getAllPetLocations(),
                getShelters()
            ]);

            if (petResult.success && petResult.data) {
                setPets(petResult.data);
            }
            if (shelterResult.success && shelterResult.data) {
                setShelters(shelterResult.data);
            }
            setLoading(false);
        };
        fetchData();
    }, []);

    const filteredPets = pets.filter(pet => {
        if (filter === 'ALL') return true;
        if (filter === 'LOST') return pet.status === 'LOST';
        if (filter === 'FOUND') return pet.status === 'FOUND' || pet.status === 'REUNITED';
        return false;
    });

    const filteredShelters = filter === 'ALL' || filter === 'SHELTER' ? shelters : [];

    return (
        <div className="relative w-full h-screen overflow-hidden">
            {/* Header / Controls */}
            <div className="absolute top-0 left-0 right-0 z-[1000] p-4 pointer-events-none">
                <div className="max-w-7xl mx-auto flex justify-between items-start">
                    <Link href="/find-pet" className="pointer-events-auto">
                        <button className="bg-white/90 backdrop-blur shadow-lg p-3 rounded-full hover:bg-gray-50 transition-all">
                            <ArrowLeft className="w-6 h-6 text-gray-700" />
                        </button>
                    </Link>

                    <div className="bg-white/90 backdrop-blur shadow-lg rounded-2xl p-2 pointer-events-auto flex gap-2 flex-wrap justify-end">
                        <button
                            onClick={() => setFilter('ALL')}
                            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all ${filter === 'ALL' ? 'bg-gray-800 text-white' : 'hover:bg-gray-100 text-gray-600'
                                }`}
                        >
                            ทั้งหมด
                        </button>
                        <button
                            onClick={() => setFilter('LOST')}
                            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all flex items-center gap-2 ${filter === 'LOST' ? 'bg-red-500 text-white' : 'hover:bg-red-50 text-red-600'
                                }`}
                        >
                            <div className="w-2 h-2 rounded-full bg-red-200" />
                            สัตว์หาย
                        </button>
                        <button
                            onClick={() => setFilter('FOUND')}
                            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all flex items-center gap-2 ${filter === 'FOUND' ? 'bg-yellow-500 text-white' : 'hover:bg-yellow-50 text-yellow-600'
                                }`}
                        >
                            <div className="w-2 h-2 rounded-full bg-yellow-200" />
                            พบเบาะแส
                        </button>
                        <button
                            onClick={() => setFilter('SHELTER')}
                            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all flex items-center gap-2 ${filter === 'SHELTER' ? 'bg-blue-500 text-white' : 'hover:bg-blue-50 text-blue-600'
                                }`}
                        >
                            <Home className="w-3 h-3" />
                            ศูนย์พักพิง
                        </button>
                    </div>
                </div>
            </div>


            {/* Floating Action Button */}
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-[1000] flex flex-col items-center gap-3 pointer-events-auto">
                {isMenuOpen && (
                    <>
                        <Link href="/shelters/new">
                            <button className="flex items-center gap-2 bg-white text-gray-800 px-4 py-2 rounded-full shadow-lg hover:bg-gray-50 transition-all">
                                <span className="font-bold text-sm">เพิ่มศูนย์พักพิง</span>
                                <div className="bg-blue-100 p-2 rounded-full text-blue-600">
                                    <Home className="w-5 h-5" />
                                </div>
                            </button>
                        </Link>
                        <button
                            onClick={handleReportLostPetClick}
                            className="flex items-center gap-2 bg-white text-gray-800 px-4 py-2 rounded-full shadow-lg hover:bg-gray-50 transition-all"
                        >
                            <span className="font-bold text-sm">แจ้งสัตว์หาย</span>
                            <div className="bg-red-100 p-2 rounded-full text-red-600">
                                <div className="w-5 h-5 rounded-full bg-red-500" />
                            </div>
                        </button>
                        <Link href="/find-pet">
                            <button className="flex items-center gap-2 bg-white text-gray-800 px-4 py-2 rounded-full shadow-lg hover:bg-gray-50 transition-all">
                                <span className="font-bold text-sm">แจ้งเบาะแส</span>
                                <div className="bg-orange-100 p-2 rounded-full text-orange-600">
                                    <MapPin className="w-5 h-5" />
                                </div>
                            </button>
                        </Link>
                    </>
                )}
                <button
                    onClick={() => setIsMenuOpen(!isMenuOpen)}
                    className={`p-4 rounded-full shadow-xl transition-all ${isMenuOpen ? 'bg-gray-800 text-white rotate-45' : 'bg-orange-500 text-white hover:bg-orange-600'
                        }`}
                >
                    <Plus className="w-8 h-8" />
                </button>
            </div>
            {/* Map */}
            <div className="w-full h-full">
                <MapWithNoSSR pets={filteredPets} shelters={filteredShelters} />
            </div>
            <LostPetForm open={isLostPetFormOpen} onOpenChange={setIsLostPetFormOpen} />
        </div>
    );
}
