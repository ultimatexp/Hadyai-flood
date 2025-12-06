"use client";

import { compressImage } from "@/lib/image-utils";
import { useState, useEffect } from "react";
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
    Home,
    ChevronLeft,
    Plus,
    Facebook
} from "lucide-react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter } from "next/navigation";
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
    const router = useRouter();
    const [mode, setMode] = useState<'found' | 'lost'>('found');
    const [user, setUser] = useState<any>(null);
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const [isLostPetFormOpen, setIsLostPetFormOpen] = useState(false);

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
        setIsDropdownOpen(false);
    };

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
    const [isAnonymousReport, setIsAnonymousReport] = useState(false);
    const [description, setDescription] = useState("");
    const [sex, setSex] = useState<'male' | 'female' | 'unknown'>('unknown');
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [searchResults, setSearchResults] = useState<any[]>([]);
    const [searched, setSearched] = useState(false);
    const [petAnalysis, setPetAnalysis] = useState<any>(null);
    const [analyzing, setAnalyzing] = useState(false);

    const analyzeImage = async (file: File) => {
        console.log("analyzeImage called");
        setAnalyzing(true);
        try {
            const formData = new FormData();
            formData.append('image', file);

            console.log("Sending request to /api/analyze-pet");
            const response = await fetch('/api/analyze-pet', {
                method: 'POST',
                body: formData,
            });
            console.log("Response received:", response.status);

            let data;
            try {
                data = await response.json();
                console.log("Data parsed:", data);
            } catch (jsonError) {
                console.error("JSON parse error:", jsonError);
                // Try to read as text to see what happened
                const text = await response.text(); // This might fail if body already read, but worth a try if json() failed immediately
                console.log("Raw response text:", text);
                throw new Error("Failed to parse server response");
            }

            if (data.success) {
                setPetAnalysis(data.data);
                console.log("✅ Analysis complete! Data saved:", data.data);
                // Autofill description if empty
                if (!description && data.data.description) {
                    setDescription(data.data.description);
                }

                // Auto-trigger search after analysis completes (ensures features are sent)
                // Auto-trigger removed as per user request
                // User will manually click search button
            }
        } catch (error: any) {
            console.error('Error analyzing image:', error);
            // Log the specific error message to see if it matches
            console.log("Error message:", error.message);
        } finally {
            setAnalyzing(false);
        }
    };



    // ... (inside component)

    const handleFoundSocialImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setAnalyzing(true);
        try {
            console.log(`Compressing social post image ${file.name}...`);
            let imageToUpload = file;
            try {
                imageToUpload = await compressImage(file);
            } catch (err) {
                console.error("Compression failed", err);
            }

            const formData = new FormData();
            formData.append('image', imageToUpload);

            const response = await fetch('/api/analyze-social-post', {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();

            if (data.success && data.data) {
                const info = data.data;
                let filledCount = 0;

                // Autofill fields
                if (info.sex) { setSex(info.sex); filledCount++; }
                if (info.description) { setDescription(info.description); filledCount++; }
                if (info.last_seen_date) { setLastSeenDate(info.last_seen_date); filledCount++; }
                if (info.contact_info && !isAnonymousReport) { setContactInfo(info.contact_info); filledCount++; }

                // Map analysis data to petAnalysis format if possible
                if (info.species || info.color || info.breed) {
                    setPetAnalysis({
                        species: info.species,
                        color_main: info.color,
                        breed: info.breed,
                        unique_marks: info.marks,
                        // Add other fields as needed based on what analyze-social-post returns vs analyze-pet
                    });
                }

                // Add the screenshot
                setSelectedImages(prev => [imageToUpload, ...prev]);
                const reader = new FileReader();
                reader.onloadend = () => {
                    setImagePreviews(prev => [reader.result as string, ...prev]);
                };
                reader.readAsDataURL(imageToUpload);

                if (filledCount > 0) {
                    alert(`ดึงข้อมูลเรียบร้อย! (พบข้อมูล ${filledCount} รายการ)\nกรุณาตรวจสอบความถูกต้องและเติมข้อมูลที่ขาดหายไป`);
                } else {
                    alert("วิเคราะห์รูปภาพแล้ว แต่ไม่พบข้อมูลที่ชัดเจน กรุณากรอกข้อมูลด้วยตนเอง");
                }
            } else {
                alert("ไม่สามารถวิเคราะห์ข้อมูลได้ หรือไม่พบข้อมูลสัตว์เลี้ยงในภาพ");
            }
        } catch (error) {
            console.error('Error analyzing social post:', error);
            alert("เกิดข้อผิดพลาดในการวิเคราะห์รูปภาพ");
        } finally {
            setAnalyzing(false);
        }
    };

    const handleFoundImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        console.log("Image selected");
        const files = Array.from(e.target.files || []);
        if (files.length > 0) {
            console.log("Processing files:", files.length);

            // Compress images
            const compressedFiles = await Promise.all(
                files.map(async (file) => {
                    try {
                        console.log(`Compressing ${file.name}...`);
                        const compressed = await compressImage(file);
                        console.log(`Compressed ${file.name}: ${(file.size / 1024 / 1024).toFixed(2)}MB -> ${(compressed.size / 1024 / 1024).toFixed(2)}MB`);
                        return compressed;
                    } catch (err) {
                        console.error("Compression failed for", file.name, err);
                        return file; // Fallback to original
                    }
                })
            );

            const newImages = [...selectedImages, ...compressedFiles];
            setSelectedImages(newImages);

            const newPreviews: string[] = [];
            let loadedCount = 0;

            compressedFiles.forEach(file => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    console.log("File read complete");
                    newPreviews.push(reader.result as string);
                    loadedCount++;
                    if (loadedCount === compressedFiles.length) {
                        setImagePreviews(prev => [...prev, ...newPreviews]);
                    }
                };
                reader.readAsDataURL(file);
            });

            setError(null);
            setSuccess(false);

            // Analyze the first image
            if (compressedFiles.length > 0) {
                console.log("Starting analysis for:", compressedFiles[0].name);
                analyzeImage(compressedFiles[0]);
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

    const handleLostImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            try {
                console.log(`Compressing search image ${file.name}...`);
                const compressed = await compressImage(file);
                console.log(`Compressed: ${(file.size / 1024 / 1024).toFixed(2)}MB -> ${(compressed.size / 1024 / 1024).toFixed(2)}MB`);
                setSelectedSearchImage(compressed);

                const reader = new FileReader();
                reader.onloadend = () => {
                    setSearchImagePreview(reader.result as string);
                };
                reader.readAsDataURL(compressed);

                // Analyze the image for search features
                analyzeImage(compressed);
            } catch (err) {
                console.error("Compression failed", err);
                setSelectedSearchImage(file);
                const reader = new FileReader();
                reader.onloadend = () => {
                    setSearchImagePreview(reader.result as string);
                };
                reader.readAsDataURL(file);

                // Analyze the original image
                analyzeImage(file);
            }

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

            // Handle anonymous report
            if (isAnonymousReport) {
                formData.append('contact_info', "ผู้แจ้งเบาะแสไม่สะดวกให้ติดต่อเป็นการส่วนตัว คุณเจ้าของสามารถลงไปตรวจสอบด้วยได้ตัวเอง");
            } else {
                formData.append('contact_info', contactInfo);
            }

            formData.append('description', description);
            formData.append('sex', sex);
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
        console.log("🔍 Search button clicked! petAnalysis state:", petAnalysis);
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
            formData.append('type', 'lost'); // Search FOUND pets for lost pet queries

            // Append analysis data if available
            if (petAnalysis) {
                console.log("Search: Using petAnalysis data:", petAnalysis);
                if (petAnalysis.species) formData.append('species', petAnalysis.species);
                if (petAnalysis.color_main) formData.append('color_main', petAnalysis.color_main);
                if (petAnalysis.color_pattern) formData.append('color_pattern', petAnalysis.color_pattern);
                if (petAnalysis.fur_length) formData.append('fur_length', petAnalysis.fur_length);
            } else {
                console.warn("Search: No petAnalysis data available");
            }

            // Add manual sex selection
            if (sex !== 'unknown') {
                formData.append('sex', sex);
            }

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
        <div className="min-h-screen bg-gradient-to-b from-purple-50 via-pink-50 to-orange-50">
            {/* Back Button */}
            <Link href="/" className="absolute top-6 left-6 text-gray-500 hover:text-gray-900 transition-colors z-10 bg-white/80 backdrop-blur-sm p-2 rounded-full shadow-sm hover:shadow-md">
                <ChevronLeft className="w-6 h-6" />
            </Link>

            <div className="container mx-auto py-8 px-4 max-w-5xl">
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
                        <div className="relative">
                            <button
                                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                                className="bg-orange-500 hover:bg-orange-600 text-white p-2 rounded-full shadow-lg hover:shadow-xl transition-all flex items-center gap-2 px-4"
                            >
                                <Plus className="w-5 h-5" />
                                <span className="font-bold">เพิ่ม</span>
                            </button>

                            {isDropdownOpen && (
                                <>
                                    <div className="fixed inset-0 z-40" onClick={() => setIsDropdownOpen(false)} />
                                    <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-xl z-50 border border-gray-100 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                                        <button
                                            onClick={handleReportLostPetClick}
                                            className="w-full px-4 py-3 hover:bg-orange-50 text-gray-700 text-sm font-medium flex items-center gap-3 transition-colors text-left"
                                        >
                                            <div className="bg-orange-100 p-2 rounded-lg text-orange-600">
                                                <Search className="w-4 h-4" />
                                            </div>
                                            <div>
                                                <div className="font-bold text-gray-900">แจ้งสัตว์หาย</div>
                                                <div className="text-xs text-gray-500">ประกาศตามหาสัตว์เลี้ยง</div>
                                            </div>
                                        </button>
                                        <div className="h-px bg-gray-100" />
                                        <Link href="/shelters/new" className="block w-full">
                                            <button className="w-full px-4 py-3 hover:bg-blue-50 text-gray-700 text-sm font-medium flex items-center gap-3 transition-colors text-left">
                                                <div className="bg-blue-100 p-2 rounded-lg text-blue-600">
                                                    <Home className="w-4 h-4" />
                                                </div>
                                                <div>
                                                    <div className="font-bold text-gray-900">ลงทะเบียนศูนย์พักพิง</div>
                                                    <div className="text-xs text-gray-500">สำหรับผู้ดูแลศูนย์</div>
                                                </div>
                                            </button>
                                        </Link>
                                    </div>
                                </>
                            )}
                        </div>
                        <LostPetForm open={isLostPetFormOpen} onOpenChange={setIsLostPetFormOpen} />
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
                            ค้นหาอย่างรวดเร็ว
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
                                    <h2 className="text-2xl font-bold text-gray-800">อัพโหลดรูปหมา แมวที่คุณเจอ</h2>
                                    <p className="text-gray-500">หมา แมวจรที่คุณเจออาจเป็นดวงใจของใครบางคน</p>
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

                                        {/* Social Import Button */}
                                        <div className="mt-4 border-t border-gray-200 pt-4">
                                            <div className="flex items-center justify-between bg-indigo-50 p-4 rounded-xl border border-indigo-100">
                                                <div>
                                                    <h3 className="font-bold text-indigo-800">นำเข้าจากโพสต์โซเชียล?</h3>
                                                    <p className="text-xs text-indigo-600">แคปหน้าจอโพสต์ Facebook/IG แล้วให้ AI ดึงข้อมูล</p>
                                                </div>
                                                <label className="cursor-pointer bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-full flex items-center gap-2 transition-colors shadow-sm">
                                                    {analyzing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Facebook className="w-4 h-4" />}
                                                    <span className="text-sm font-bold">{analyzing ? 'กำลังวิเคราะห์...' : 'รูปแคปหน้าจอ'}</span>
                                                    <input type="file" accept="image/*" className="hidden" onChange={handleFoundSocialImport} disabled={analyzing} />
                                                </label>
                                            </div>
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
                                                <div className="flex items-center gap-2 mb-3 text-green-800 font-bold">
                                                    <Check className="w-4 h-4" />
                                                    AI วิเคราะห์ข้อมูลเรียบร้อย
                                                </div>
                                                <div className="grid grid-cols-2 md:grid-cols-3 gap-2 text-sm text-green-700">
                                                    {/* Basic Info */}
                                                    <div>
                                                        <span className="font-semibold">ประเภท:</span> {petAnalysis.species === 'dog' ? 'สุนัข' : petAnalysis.species === 'cat' ? 'แมว' : 'อื่นๆ'}
                                                    </div>
                                                    <div>
                                                        <span className="font-semibold">สี:</span> {petAnalysis.color_main}{petAnalysis.color_secondary && ` / ${petAnalysis.color_secondary}`}
                                                    </div>
                                                    {petAnalysis.color_pattern && (
                                                        <div>
                                                            <span className="font-semibold">ลาย:</span> {petAnalysis.color_pattern}
                                                        </div>
                                                    )}
                                                    {petAnalysis.body_size && (
                                                        <div>
                                                            <span className="font-semibold">ขนาด:</span> {petAnalysis.body_size === 'small' ? 'เล็ก' : petAnalysis.body_size === 'medium' ? 'กลาง' : 'ใหญ่'}
                                                        </div>
                                                    )}
                                                    {petAnalysis.fur_length && (
                                                        <div>
                                                            <span className="font-semibold">ความยาวขน:</span> {petAnalysis.fur_length}
                                                        </div>
                                                    )}
                                                    {petAnalysis.eye_color && (
                                                        <div>
                                                            <span className="font-semibold">สีตา:</span> {petAnalysis.eye_color}
                                                        </div>
                                                    )}

                                                    {/* Body Features */}
                                                    {petAnalysis.ear_shape && (
                                                        <div>
                                                            <span className="font-semibold">รูปหู:</span> {petAnalysis.ear_shape}
                                                        </div>
                                                    )}
                                                    {petAnalysis.tail_type && (
                                                        <div>
                                                            <span className="font-semibold">ประเภทหาง:</span> {petAnalysis.tail_type}
                                                        </div>
                                                    )}

                                                    {/* Accessories */}
                                                    {petAnalysis.has_collar && (
                                                        <div className="col-span-2">
                                                            <span className="font-semibold">🔖 ปลอกคอ:</span> {petAnalysis.collar_color || 'มี'}{petAnalysis.collar_type && ` (${petAnalysis.collar_type})`}
                                                        </div>
                                                    )}
                                                    {petAnalysis.has_tag && (
                                                        <div>
                                                            <span className="font-semibold">✓ มีป้ายชื่อ</span>
                                                        </div>
                                                    )}
                                                    {petAnalysis.clothes && (
                                                        <div className="col-span-2">
                                                            <span className="font-semibold">👕 เสื้อผ้า:</span> {petAnalysis.clothes}
                                                        </div>
                                                    )}

                                                    {/* Unique Marks */}
                                                    {petAnalysis.special_marks && (
                                                        <div className="col-span-full">
                                                            <span className="font-semibold">⭐ จุดเด่น:</span> {petAnalysis.special_marks}
                                                        </div>
                                                    )}
                                                    {petAnalysis.white_patch_location && petAnalysis.white_patch_location.length > 0 && (
                                                        <div className="col-span-2">
                                                            <span className="font-semibold">ตำแหน่งสีขาว:</span> {petAnalysis.white_patch_location.join(', ')}
                                                        </div>
                                                    )}
                                                    {petAnalysis.injury_or_scar && (
                                                        <div className="col-span-full">
                                                            <span className="font-semibold">⚠️ รอยแผล/แผลเป็น:</span> {petAnalysis.injury_or_scar}
                                                        </div>
                                                    )}
                                                    {petAnalysis.heterochromia && (
                                                        <div>
                                                            <span className="font-semibold">👁️ ตาสองสี</span>
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
                                            className={`w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition-all text-black ${isAnonymousReport ? 'bg-gray-100 text-gray-400' : ''}`}
                                            required={!isAnonymousReport}
                                            disabled={isAnonymousReport}
                                        />
                                        <div className="mt-2 flex items-start gap-2">
                                            <input
                                                type="checkbox"
                                                id="anonymous-report"
                                                checked={isAnonymousReport}
                                                onChange={(e) => setIsAnonymousReport(e.target.checked)}
                                                className="mt-1 w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                                            />
                                            <label htmlFor="anonymous-report" className="text-sm text-gray-600 cursor-pointer select-none">
                                                ฉันเพียงต้องการแจ้งเบาะแส ไม่สะดวกทิ้งเบอร์ติดต่อส่วนตัว
                                            </label>
                                        </div>
                                    </div>

                                    {/* Sex Selection */}
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 mb-2">
                                            เพศ
                                        </label>
                                        <select
                                            value={sex}
                                            onChange={(e) => setSex(e.target.value as 'male' | 'female' | 'unknown')}
                                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition-all text-black appearance-none"
                                        >
                                            <option value="unknown">ไม่มีข้อมูล</option>
                                            <option value="male">ผู้</option>
                                            <option value="female">เมีย</option>
                                        </select>
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
                            <form onSubmit={handleLostSearch} data-search-form className="space-y-6">
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
                                    disabled={loading || !selectedSearchImage || analyzing}
                                    className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-xl font-bold text-lg shadow-lg shadow-blue-200 disabled:opacity-50 disabled:shadow-none"
                                >
                                    {analyzing || loading ? (
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
