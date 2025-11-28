"use client";

import { useState } from "react";
import {
    ArrowLeft,
    Search,
    MapPin,
    Camera,
    AlertTriangle,
    X,
    Loader2,
    Filter,
    Archive,
    Map as MapIcon,
    Upload as UploadIcon,
    Phone,
    FileText,
    Check,
    AlertCircle,
    Home
} from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import { LostPetForm } from "@/components/pet/lost-pet-form";
import dynamic from "next/dynamic";
import Link from "next/link";
import Lottie from "lottie-react";
import catAnimation from "@/assets/json/Cute cat works.json";

// Dynamically import MapPicker to avoid SSR issues with Leaflet
const MapPicker = dynamic(() => import("@/components/map/map-picker"), {
    ssr: false,
    loading: () => <div className="h-[400px] w-full bg-gray-100 animate-pulse rounded-xl flex items-center justify-center text-gray-400">กำลังโหลดแผนที่...</div>
});

// Haversine formula to calculate distance in km
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const d = R * c; // Distance in km
    return d;
}

function deg2rad(deg: number) {
    return deg * (Math.PI / 180);
}

export default function FindPetPage() {
    const [mode, setMode] = useState<'found' | 'lost'>('found');

    // Found Mode State
    const [selectedImages, setSelectedImages] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [foundLocation, setFoundLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [lastSeenDate, setLastSeenDate] = useState("");

    // Lost Mode State
    const [selectedSearchImage, setSelectedSearchImage] = useState<File | null>(null);
    const [searchImagePreview, setSearchImagePreview] = useState<string | null>(null);
    const [lostLocation, setLostLocation] = useState<{ lat: number; lng: number } | null>(null);

    // Shared State
    const [contactInfo, setContactInfo] = useState("");
    const [description, setDescription] = useState("");
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [searchResults, setSearchResults] = useState<any[]>([]);
    const [searched, setSearched] = useState(false);
    const [petAnalysis, setPetAnalysis] = useState<any>(null);
    const [analyzing, setAnalyzing] = useState(false);

    const analyzeImage = async (file: File) => {
        setAnalyzing(true);
        try {
            const formData = new FormData();
            formData.append('image', file);

            const response = await fetch('/api/analyze-pet', {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();
            if (data.success) {
                setPetAnalysis(data.data);
                // Autofill description if empty
                if (!description && data.data.description) {
                    setDescription(data.data.description);
                }
            }
        } catch (error) {
            console.error('Error analyzing image:', error);
        } finally {
            setAnalyzing(false);
        }
    };

    const handleFoundImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);
        if (files.length > 0) {
            const newImages = [...selectedImages, ...files];
            setSelectedImages(newImages);

            const newPreviews: string[] = [];
            let loadedCount = 0;

            files.forEach(file => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    newPreviews.push(reader.result as string);
                    loadedCount++;
                    if (loadedCount === files.length) {
                        setImagePreviews(prev => [...prev, ...newPreviews]);
                    }
                };
                reader.readAsDataURL(file);
            });

            setError(null);
            setSuccess(false);

            // Analyze the first image
            if (files.length > 0) {
                analyzeImage(files[0]);
            }
        }
    };

    const removeFoundImage = (index: number) => {
        const newImages = [...selectedImages];
        newImages.splice(index, 1);
        setSelectedImages(newImages);

        const newPreviews = [...imagePreviews];
        newPreviews.splice(index, 1);
        setImagePreviews(newPreviews);
    };

    const handleLostImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setSelectedSearchImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setSearchImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
            setError(null);
            setSuccess(false);
            setSearched(false);
            setSearchResults([]);
        }
    };

    const handleFoundSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (selectedImages.length === 0) {
            setError("กรุณาเลือกรูปภาพอย่างน้อย 1 รูป");
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const formData = new FormData();
            selectedImages.forEach(file => {
                formData.append('images', file);
            });
            formData.append('contact_info', contactInfo);
            formData.append('description', description);
            formData.append('status', 'FOUND');
            if (foundLocation) {
                formData.append('lat', foundLocation.lat.toString());
                formData.append('lng', foundLocation.lng.toString());
            }
            if (lastSeenDate) {
                formData.append('last_seen_at', new Date(lastSeenDate).toISOString());
            }

            // Append analysis data
            if (petAnalysis) {
                Object.entries(petAnalysis).forEach(([key, value]) => {
                    if (value !== null && value !== undefined) {
                        if (typeof value === 'object') {
                            formData.append(key, JSON.stringify(value));
                        } else {
                            formData.append(key, String(value));
                        }
                    }
                });
            }

            const response = await fetch('/api/pet/found', {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();

            if (data.success) {
                setSuccess(true);
                setSelectedImages([]);
                setImagePreviews([]);
                setContactInfo("");
                setDescription("");
                setLastSeenDate("");
                setFoundLocation(null);
            } else {
                setError(data.error || "เกิดข้อผิดพลาดในการบันทึกข้อมูล");
            }
        } catch (err: any) {
            setError(err.message || "เกิดข้อผิดพลาดในการเชื่อมต่อ");
        } finally {
            setLoading(false);
        }
    };

    const handleLostSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedSearchImage) {
            setError("กรุณาเลือกรูปภาพเพื่อค้นหา");
            return;
        }

        setLoading(true);
        setError(null);
        setSearched(false);

        try {
            const formData = new FormData();
            formData.append('image', selectedSearchImage);

            const response = await fetch('/api/pet/search', {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();

            if (data.success) {
                setSearchResults(data.matches || []);
                setSearched(true);
            } else {
                setError(data.error || "เกิดข้อผิดพลาดในการค้นหา");
            }
        } catch (err: any) {
            setError(err.message || "เกิดข้อผิดพลาดในการเชื่อมต่อ");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-b from-amber-50 to-white py-8 px-4">
            <div className="max-w-3xl mx-auto">
                <div className="flex flex-col md:flex-row items-center justify-between mb-8 gap-4">
                    <div className="text-center md:text-left flex-1">
                        <h1 className="text-3xl font-bold text-gray-900 mb-2">ศูนย์ตามหาสัตว์เลี้ยง</h1>
                        <p className="text-gray-600">ช่วยพาน้องกลับบ้าน หรือประกาศตามหาเจ้าของ</p>
                    </div>
                    <div className="flex gap-3">
                        <Link href="/pets/archive">
                            <button className="p-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors flex items-center gap-2 text-gray-700 font-medium">
                                <Archive className="w-5 h-5" />
                                <span className="hidden sm:inline">คลังข้อมูล</span>
                            </button>
                        </Link>
                        <Link href="/pets/map">
                            <button className="p-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors flex items-center gap-2 text-gray-700 font-medium">
                                <MapIcon className="w-5 h-5" />
                                <span className="hidden sm:inline">แผนที่</span>
                            </button>
                        </Link>
                        <Link href="/shelters">
                            <button className="p-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors flex items-center gap-2 text-gray-700 font-medium">
                                <Home className="w-5 h-5" />
                                <span className="hidden sm:inline">ศูนย์พักพิง</span>
                            </button>
                        </Link>
                        <LostPetForm />
                    </div>
                </div>

                {/* Animation & Text */}
                <div className="flex flex-col items-center justify-center mb-6">
                    <div className="w-48 h-48">
                        <Lottie animationData={catAnimation} loop={true} />
                    </div>
                    <p className="text-lg font-medium text-gray-600 mt-2">ให้ Fondue AI ช่วยหานะ</p>
                </div>

                {/* Mode Switcher */}
                <div className="flex justify-center mb-8">
                    <div className="bg-white p-1 rounded-full shadow-sm border border-gray-200 inline-flex">
                        <button
                            onClick={() => { setMode('found'); setError(null); setSuccess(false); }}
                            className={`px-6 py-2 rounded-full text-sm font-medium transition-colors ${mode === 'found'
                                ? 'bg-green-500 text-white shadow-sm'
                                : 'text-gray-600 hover:bg-gray-50'
                                }`}
                        >
                            ฉันพบสัตว์เลี้ยง
                        </button>
                        <button
                            onClick={() => { setMode('lost'); setError(null); setSuccess(false); }}
                            className={`px-6 py-2 rounded-full text-sm font-medium transition-colors ${mode === 'lost'
                                ? 'bg-blue-500 text-white shadow-sm'
                                : 'text-gray-600 hover:bg-gray-50'
                                }`}
                        >
                            ฉันทำสัตว์เลี้ยงหาย
                        </button>
                    </div>
                </div>

                <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
                    <div className={`h-2 ${mode === 'found' ? 'bg-green-500' : 'bg-blue-500'}`} />

                    <div className="p-6 md:p-8">
                        {mode === 'found' ? (
                            /* Found Pet Form */
                            <form onSubmit={handleFoundSubmit} className="space-y-6">
                                <div className="text-center mb-6">
                                    <h2 className="text-2xl font-bold text-gray-800">ลงทะเบียนสัตว์เลี้ยงที่พบ</h2>
                                    <p className="text-gray-500">กรอกข้อมูลและอัพโหลดรูปภาพเพื่อช่วยตามหาเจ้าของ</p>
                                </div>

                                <div className="space-y-4">
                                    {/* Image Upload */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">รูปภาพสัตว์เลี้ยง (เลือกได้หลายรูป)</label>

                                        {imagePreviews.length > 0 && (
                                            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-4">
                                                {imagePreviews.map((preview, index) => (
                                                    <div key={index} className="relative aspect-square rounded-lg overflow-hidden border border-gray-200 group">
                                                        <img src={preview} alt={`Preview ${index}`} className="w-full h-full object-cover" />
                                                        <button
                                                            type="button"
                                                            onClick={() => removeFoundImage(index)}
                                                            className="absolute top-1 right-1 bg-black/50 hover:bg-red-500 text-white p-1 rounded-full transition-colors"
                                                        >
                                                            <X className="w-4 h-4" />
                                                        </button>
                                                    </div>
                                                ))}
                                            </div>
                                        )}

                                        <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:border-green-500 transition-colors bg-gray-50">
                                            <input
                                                type="file"
                                                accept="image/*"
                                                multiple
                                                onChange={handleFoundImageSelect}
                                                className="hidden"
                                                id="found-image-upload"
                                            />
                                            <label htmlFor="found-image-upload" className="cursor-pointer flex flex-col items-center">
                                                <UploadIcon className="w-12 h-12 text-gray-400 mb-2" />
                                                <span className="text-gray-600 font-medium">
                                                    คลิกเพื่อเพิ่มรูปภาพ
                                                </span>
                                                <span className="text-xs text-gray-400 mt-1">
                                                    เลือกได้หลายรูป
                                                </span>
                                            </label>
                                        </div>

                                        {/* Analysis Results */}
                                        {analyzing && (
                                            <div className="mt-4 p-4 bg-blue-50 rounded-xl flex items-center gap-3 text-blue-700 animate-pulse">
                                                <Loader2 className="w-5 h-5 animate-spin" />
                                                <span>กำลังวิเคราะห์รูปภาพด้วย AI...</span>
                                            </div>
                                        )}

                                        {petAnalysis && !analyzing && (
                                            <div className="mt-4 p-4 bg-green-50 rounded-xl border border-green-100 animate-in fade-in slide-in-from-top-2">
                                                <div className="flex items-center gap-2 mb-2 text-green-800 font-bold">
                                                    <Check className="w-4 h-4" />
                                                    AI วิเคราะห์ข้อมูลเรียบร้อย
                                                </div>
                                                <div className="grid grid-cols-2 gap-2 text-sm text-green-700">
                                                    <div>
                                                        <span className="font-semibold">ประเภท:</span> {petAnalysis.species === 'dog' ? 'สุนัข' : petAnalysis.species === 'cat' ? 'แมว' : 'อื่นๆ'}
                                                    </div>
                                                    <div>
                                                        <span className="font-semibold">สี:</span> {petAnalysis.color_main}
                                                    </div>
                                                    {petAnalysis.breed && (
                                                        <div>
                                                            <span className="font-semibold">สายพันธุ์:</span> {petAnalysis.breed}
                                                        </div>
                                                    )}
                                                    {petAnalysis.unique_marks && (
                                                        <div className="col-span-2">
                                                            <span className="font-semibold">จุดเด่น:</span> {petAnalysis.unique_marks}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        )}
                                    </div>

                                    {/* Location Picker */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            <div className="flex items-center gap-2">
                                                <MapPin className="w-4 h-4" />
                                                ตำแหน่งที่พบ
                                            </div>
                                        </label>
                                        <MapPicker
                                            lat={foundLocation?.lat}
                                            lng={foundLocation?.lng}
                                            onLocationSelect={(lat, lng) => setFoundLocation({ lat, lng })}
                                        />
                                    </div>

                                    {/* Date and Time */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            วันและเวลาที่พบ
                                        </label>
                                        <input
                                            type="datetime-local"
                                            value={lastSeenDate}
                                            onChange={(e) => setLastSeenDate(e.target.value)}
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition-all text-black"
                                        />
                                    </div>

                                    {/* Contact Info */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            <div className="flex items-center gap-2">
                                                <Phone className="w-4 h-4" />
                                                ช่องทางติดต่อกลับ
                                            </div>
                                        </label>
                                        <input
                                            type="text"
                                            value={contactInfo}
                                            onChange={(e) => setContactInfo(e.target.value)}
                                            placeholder="เบอร์โทร, Line ID, หรือ Facebook"
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition-all text-black"
                                            required
                                        />
                                    </div>

                                    {/* Description */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            <div className="flex items-center gap-2">
                                                <FileText className="w-4 h-4" />
                                                รายละเอียดเพิ่มเติม
                                            </div>
                                        </label>
                                        <textarea
                                            value={description}
                                            onChange={(e) => setDescription(e.target.value)}
                                            placeholder="ลักษณะเด่น, สถานที่ที่พบ, ปลอกคอ, ฯลฯ"
                                            rows={3}
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition-all text-black"
                                        />
                                    </div>
                                </div>

                                <ThaiButton
                                    type="submit"
                                    disabled={loading || selectedImages.length === 0}
                                    className="w-full bg-green-600 hover:bg-green-700 text-white py-3 rounded-xl font-bold text-lg shadow-lg shadow-green-200 disabled:opacity-50 disabled:shadow-none"
                                >
                                    {loading ? (
                                        <div className="flex items-center justify-center gap-2">
                                            <Loader2 className="w-5 h-5 animate-spin" />
                                            กำลังบันทึก...
                                        </div>
                                    ) : (
                                        `ลงทะเบียนสัตว์เลี้ยง (${selectedImages.length} รูป)`
                                    )}
                                </ThaiButton>
                            </form>
                        ) : (
                            /* Lost Pet Search */
                            <form onSubmit={handleLostSearch} className="space-y-6">
                                <div className="text-center mb-6">
                                    <h2 className="text-2xl font-bold text-gray-800">ค้นหาสัตว์เลี้ยงที่หายไป</h2>
                                    <p className="text-gray-500">อัพโหลดรูปสัตว์เลี้ยงของคุณ ระบบจะค้นหาจากฐานข้อมูลสัตว์ที่พบ</p>
                                </div>

                                {/* Image Upload */}
                                <div>
                                    <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:border-blue-500 transition-colors bg-gray-50">
                                        <input
                                            type="file"
                                            accept="image/*"
                                            onChange={handleLostImageSelect}
                                            className="hidden"
                                            id="lost-image-upload"
                                        />
                                        <label htmlFor="lost-image-upload" className="cursor-pointer flex flex-col items-center">
                                            {searchImagePreview ? (
                                                <img src={searchImagePreview} alt="Preview" className="h-48 object-contain rounded-lg shadow-sm mb-2" />
                                            ) : (
                                                <Search className="w-12 h-12 text-gray-400 mb-2" />
                                            )}
                                            <span className="text-gray-600 font-medium">
                                                {searchImagePreview ? 'คลิกเพื่อเปลี่ยนรูป' : 'คลิกเพื่ออัพโหลดรูปภาพที่ต้องการค้นหา'}
                                            </span>
                                        </label>
                                    </div>
                                </div>

                                {/* Location Picker for Lost Pet */}
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">
                                        <div className="flex items-center gap-2">
                                            <MapPin className="w-4 h-4" />
                                            ตำแหน่งที่หาย (เพื่อดูระยะห่าง)
                                        </div>
                                    </label>
                                    <MapPicker
                                        lat={lostLocation?.lat}
                                        lng={lostLocation?.lng}
                                        onLocationSelect={(lat, lng) => setLostLocation({ lat, lng })}
                                    />
                                </div>

                                <ThaiButton
                                    type="submit"
                                    disabled={loading || !selectedSearchImage}
                                    className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-xl font-bold text-lg shadow-lg shadow-blue-200 disabled:opacity-50 disabled:shadow-none"
                                >
                                    {loading ? (
                                        <div className="flex items-center justify-center gap-2">
                                            <Loader2 className="w-5 h-5 animate-spin" />
                                            กำลังค้นหา...
                                        </div>
                                    ) : (
                                        "ค้นหาด้วยรูปภาพ"
                                    )}
                                </ThaiButton>
                            </form>
                        )}

                        {/* Messages */}
                        {success && (
                            <div className="mt-6 bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3 text-green-800 animate-in fade-in slide-in-from-bottom-2">
                                <div className="bg-green-100 p-2 rounded-full">
                                    <Check className="w-5 h-5" />
                                </div>
                                <div>
                                    <p className="font-bold">บันทึกข้อมูลสำเร็จ!</p>
                                    <p className="text-sm">ขอบคุณที่ช่วยแจ้งเบาะแส</p>
                                </div>
                            </div>
                        )}

                        {error && (
                            <div className="mt-6 bg-red-50 border border-red-200 rounded-xl p-4 flex items-center gap-3 text-red-800 animate-in fade-in slide-in-from-bottom-2">
                                <AlertCircle className="w-5 h-5" />
                                <p>{error}</p>
                            </div>
                        )}
                    </div>
                </div>

                {/* Search Results */}
                {mode === 'lost' && searched && (
                    <div className="mt-8 animate-in fade-in slide-in-from-bottom-4">
                        <h3 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                            <Search className="w-5 h-5" />
                            ผลการค้นหา ({searchResults.length})
                        </h3>

                        {searchResults.length === 0 ? (
                            <div className="bg-white rounded-xl p-8 text-center text-gray-500 shadow-sm">
                                <p>ไม่พบสัตว์เลี้ยงที่คล้ายกันในระบบ</p>
                                <p className="text-sm mt-2">ลองใช้รูปอื่น หรือเข้ามาตรวจสอบใหม่ภายหลัง</p>
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                {searchResults.map((pet) => {
                                    // Calculate distance if both locations are available
                                    let distance = null;
                                    let isNearby = false;
                                    if (lostLocation && pet.lat && pet.lng) {
                                        distance = calculateDistance(lostLocation.lat, lostLocation.lng, pet.lat, pet.lng);
                                        isNearby = distance <= 10;
                                    }

                                    return (
                                        <Link href={`/pets/status/${pet.pet_id || pet.id}`} key={pet.id} className="block">
                                            <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-gray-100 hover:shadow-md transition-shadow relative">
                                                {/* Nearby Badge */}
                                                {isNearby && (
                                                    <div className="absolute top-2 left-2 z-10 bg-green-500 text-white text-xs px-2 py-1 rounded-full shadow-md flex items-center gap-1 animate-pulse">
                                                        <MapPin className="w-3 h-3" />
                                                        ใกล้คุณ ({distance?.toFixed(1)} กม.)
                                                    </div>
                                                )}

                                                <div className="aspect-video relative bg-gray-100">
                                                    <img src={pet.image_url} alt="Found Pet" className="w-full h-full object-cover" />
                                                    <div className="absolute top-2 right-2 bg-black/70 text-white text-xs px-2 py-1 rounded-full backdrop-blur-sm flex flex-col items-end">
                                                        <span className="font-bold">{(pet.combined_score * 100).toFixed(0)}% Match</span>
                                                        <span className="text-[10px] opacity-80">
                                                            (V:{(pet.embedding_similarity * 100).toFixed(0)}% C:{(pet.color_similarity * 100).toFixed(0)}% F:{(pet.feature_score * 100).toFixed(0)}%)
                                                        </span>
                                                    </div>
                                                </div>
                                                <div className="p-4">
                                                    <div className="flex items-start justify-between mb-2">
                                                        <span className="inline-block px-2 py-1 bg-green-100 text-green-800 text-xs font-bold rounded-md">
                                                            พบแล้ว
                                                        </span>
                                                        {distance !== null && !isNearby && (
                                                            <span className="text-xs text-gray-500">
                                                                ห่าง {distance.toFixed(1)} กม.
                                                            </span>
                                                        )}
                                                    </div>
                                                    <p className="text-gray-600 text-sm mb-3 line-clamp-2">{pet.description || "ไม่มีรายละเอียด"}</p>

                                                    {pet.last_seen_at && (
                                                        <p className="text-xs text-gray-500 mb-2">
                                                            พบเมื่อ: {new Date(pet.last_seen_at).toLocaleString('th-TH')}
                                                        </p>
                                                    )}

                                                    <div className="pt-3 border-t border-gray-100 flex justify-between items-center">
                                                        <span className="text-blue-600 text-xs font-bold">ดูรายละเอียด</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </Link>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
