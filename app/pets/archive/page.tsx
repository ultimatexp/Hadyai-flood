"use client";

import { useState, useEffect } from "react";
import { Search, Filter, MapPin, Calendar, PawPrint, Loader2 } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import Link from "next/link";

interface Pet {
    id: string;
    pet_name: string;
    pet_type: string;
    breed: string;
    color: string;
    marks: string;
    description: string;
    image_url: string;
    images: string[];
    owner_name: string;
    contact_info: string;
    reward: string;
    lat: number | null;
    lng: number | null;
    last_seen_at: string | null;
    created_at: string;
}

export default function PetArchivePage() {
    const [pets, setPets] = useState<Pet[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [petTypeFilter, setPetTypeFilter] = useState("all");
    const [debouncedSearch, setDebouncedSearch] = useState("");

    // Debounce search
    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedSearch(searchTerm);
        }, 500);
        return () => clearTimeout(timer);
    }, [searchTerm]);

    // Fetch pets
    useEffect(() => {
        fetchPets();
    }, [debouncedSearch, petTypeFilter]);

    const fetchPets = async () => {
        setLoading(true);
        try {
            const params = new URLSearchParams();
            if (debouncedSearch) params.append('search', debouncedSearch);
            if (petTypeFilter !== 'all') params.append('pet_type', petTypeFilter);

            const response = await fetch(`/api/pet/archive?${params.toString()}`);
            const data = await response.json();

            if (data.success) {
                setPets(data.pets || []);
            }
        } catch (error) {
            console.error('Failed to fetch pets:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white py-8 px-4">
            <div className="max-w-7xl mx-auto">
                {/* Header */}
                <div className="mb-8">
                    <div className="flex items-center justify-between mb-4">
                        <div>
                            <h1 className="text-4xl font-bold text-gray-900 mb-2 flex items-center gap-3">
                                <PawPrint className="w-10 h-10 text-orange-500" />
                                คลังข้อมูลสัตว์เลี้ยงหาย
                            </h1>
                            <p className="text-gray-600">รวมรายการสัตว์เลี้ยงที่กำลังตามหา</p>
                        </div>
                        <Link href="/find-pet">
                            <ThaiButton className="bg-orange-500 hover:bg-orange-600">
                                แจ้งเบาะแสสัตว์หาย
                            </ThaiButton>
                        </Link>
                    </div>

                    {/* Search and Filters */}
                    <div className="bg-white rounded-2xl shadow-lg p-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {/* Search Bar */}
                            <div className="relative">
                                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                                <input
                                    type="text"
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                    placeholder="ค้นหาด้วยชื่อ, สายพันธุ์, สี, รายละเอียด..."
                                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none transition-all text-black"
                                />
                            </div>

                            {/* Pet Type Filter */}
                            <div className="relative">
                                <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                                <select
                                    value={petTypeFilter}
                                    onChange={(e) => setPetTypeFilter(e.target.value)}
                                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none transition-all text-black appearance-none cursor-pointer"
                                >
                                    <option value="all">ทุกประเภท</option>
                                    <option value="dog">สุนัข</option>
                                    <option value="cat">แมว</option>
                                    <option value="other">อื่นๆ</option>
                                </select>
                            </div>
                        </div>

                        {/* Results Count */}
                        <div className="mt-4 text-sm text-gray-600">
                            {loading ? (
                                <span>กำลังค้นหา...</span>
                            ) : (
                                <span>พบ {pets.length} รายการ</span>
                            )}
                        </div>
                    </div>
                </div>

                {/* Loading State */}
                {loading && (
                    <div className="flex justify-center items-center py-20">
                        <Loader2 className="w-12 h-12 animate-spin text-orange-500" />
                    </div>
                )}

                {/* Pet Cards Grid */}
                {!loading && pets.length === 0 && (
                    <div className="text-center py-20">
                        <PawPrint className="w-20 h-20 text-gray-300 mx-auto mb-4" />
                        <p className="text-xl text-gray-500">ไม่พบข้อมูลสัตว์เลี้ยงหาย</p>
                        <p className="text-sm text-gray-400 mt-2">ลองเปลี่ยนคำค้นหาหรือตัวกรอง</p>
                    </div>
                )}

                {!loading && pets.length > 0 && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {pets.map((pet) => (
                            <Link href={`/pets/status/${pet.id}`} key={pet.id}>
                                <div
                                    className="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow border-2 border-orange-100 h-full flex flex-col"
                                >
                                    {/* Pet Image */}
                                    <div className="aspect-video relative bg-gray-100">
                                        <img
                                            src={pet.image_url}
                                            alt={pet.pet_name || "Lost Pet"}
                                            className="w-full h-full object-cover"
                                        />
                                        <div className="absolute top-3 right-3 bg-red-500 text-white px-3 py-1 rounded-full text-xs font-bold shadow-lg">
                                            สัตว์หาย
                                        </div>
                                    </div>

                                    {/* Pet Details */}
                                    <div className="p-5 flex-1 flex flex-col">
                                        <h3 className="text-xl font-bold text-gray-900 mb-2">
                                            {pet.pet_name || "ไม่ระบุชื่อ"}
                                        </h3>

                                        <div className="space-y-2 mb-4">
                                            {pet.breed && (
                                                <p className="text-sm text-gray-600">
                                                    <span className="font-semibold">สายพันธุ์:</span> {pet.breed}
                                                </p>
                                            )}
                                            {pet.color && (
                                                <p className="text-sm text-gray-600">
                                                    <span className="font-semibold">สี:</span> {pet.color}
                                                </p>
                                            )}
                                        </div>

                                        {/* Last Seen Info */}
                                        {pet.last_seen_at && (
                                            <div className="flex items-center gap-2 text-xs text-gray-500 mb-3">
                                                <Calendar className="w-4 h-4" />
                                                <span>หายเมื่อ: {new Date(pet.last_seen_at).toLocaleString('th-TH')}</span>
                                            </div>
                                        )}

                                        <div className="mt-auto pt-4 border-t border-gray-200 flex justify-between items-center">
                                            <span className="text-orange-500 font-bold text-sm">ดูรายละเอียด &gt;</span>
                                            {pet.reward && (
                                                <span className="bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded-full font-bold">
                                                    💰 {pet.reward}
                                                </span>
                                            )}
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
