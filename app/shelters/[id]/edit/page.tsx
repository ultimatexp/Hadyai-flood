"use client";

import { useState, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { getShelter, updateShelter } from "@/app/actions/shelter";
import { ArrowLeft, Upload, MapPin, Dog, Cat, Gift, Loader2, X, Home, Save } from "lucide-react";
import Link from "next/link";
import dynamic from "next/dynamic";
import { supabase } from "@/lib/supabase";

// Dynamically import MapPicker
const MapPicker = dynamic(() => import("@/components/map/map-picker"), {
    ssr: false,
    loading: () => <div className="h-[300px] bg-gray-100 animate-pulse rounded-xl" />
});

export default function EditShelterPage() {
    const router = useRouter();
    const params = useParams();
    const id = params.id as string;

    const [loading, setLoading] = useState(false);
    const [fetching, setFetching] = useState(true);
    const [user, setUser] = useState<any>(null);

    // Form State
    const [name, setName] = useState("");
    const [description, setDescription] = useState("");
    const [contactInfo, setContactInfo] = useState("");
    const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [petCountDog, setPetCountDog] = useState(0);
    const [petCountCat, setPetCountCat] = useState(0);
    const [neededItems, setNeededItems] = useState("");
    const [donationAddress, setDonationAddress] = useState("");
    const [images, setImages] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [existingImages, setExistingImages] = useState<string[]>([]);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            setUser(currentUser);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        const fetchData = async () => {
            const result = await getShelter(id);
            if (result.success && result.data) {
                const data = result.data;
                setName(data.name);
                setDescription(data.description || "");
                setContactInfo(data.contact_info || "");
                setLocation({ lat: data.lat, lng: data.lng });
                setPetCountDog(data.pet_count_dog || 0);
                setPetCountCat(data.pet_count_cat || 0);
                setNeededItems(data.needed_items || "");
                setDonationAddress(data.donation_address || "");
                setExistingImages(data.images || []);
            }
            setFetching(false);
        };
        fetchData();
    }, [id]);

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);
        if (files.length > 0) {
            setImages(prev => [...prev, ...files]);

            files.forEach(file => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    setImagePreviews(prev => [...prev, reader.result as string]);
                };
                reader.readAsDataURL(file);
            });
        }
    };

    const removeNewImage = (index: number) => {
        setImages(prev => prev.filter((_, i) => i !== index));
        setImagePreviews(prev => prev.filter((_, i) => i !== index));
    };

    const removeExistingImage = (index: number) => {
        setExistingImages(prev => prev.filter((_, i) => i !== index));
    };

    const handleSubmit = async () => {
        if (!user) {
            alert("กรุณาเข้าสู่ระบบก่อนแก้ไขข้อมูล");
            return;
        }
        if (!location) {
            alert("กรุณาระบุตำแหน่ง");
            return;
        }

        setLoading(true);
        try {
            const newImageUrls: string[] = [];

            // Upload new images
            for (const file of images) {
                const fileExt = file.name.split('.').pop();
                const fileName = `shelters/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, file);

                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                newImageUrls.push(publicUrl);
            }

            // Combine existing and new images
            const finalImages = [...existingImages, ...newImageUrls];

            const result = await updateShelter(id, {
                name,
                description,
                images: finalImages,
                needed_items: neededItems,
                pet_count_dog: petCountDog,
                pet_count_cat: petCountCat,
                donation_address: donationAddress,
                lat: location.lat,
                lng: location.lng,
                contact_info: contactInfo,
            });

            if (result.success) {
                router.push(`/shelters/${id}`);
            } else {
                alert("เกิดข้อผิดพลาด: " + result.error);
            }
        } catch (error: any) {
            console.error(error);
            alert("เกิดข้อผิดพลาดในการบันทึกข้อมูล");
        } finally {
            setLoading(false);
        }
    };

    if (fetching) return <div className="min-h-screen flex items-center justify-center"><Loader2 className="w-8 h-8 animate-spin text-orange-500" /></div>;

    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header */}
            <div className="bg-white shadow-sm p-4 sticky top-0 z-50">
                <div className="max-w-2xl mx-auto flex items-center gap-4">
                    <Link href={`/shelters/${id}`}>
                        <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                            <ArrowLeft className="w-6 h-6 text-gray-700" />
                        </button>
                    </Link>
                    <h1 className="text-xl font-bold text-gray-900">แก้ไขข้อมูลศูนย์พักพิง</h1>
                </div>
            </div>

            <div className="max-w-2xl mx-auto p-4 space-y-6">
                {/* Basic Info */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                    <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                        <Home className="w-5 h-5 text-orange-500" />
                        ข้อมูลพื้นฐาน
                    </h2>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">ชื่อศูนย์พักพิง</label>
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">รายละเอียด</label>
                            <textarea
                                value={description}
                                onChange={(e) => setDescription(e.target.value)}
                                rows={4}
                                className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">ช่องทางติดต่อ</label>
                            <input
                                type="text"
                                value={contactInfo}
                                onChange={(e) => setContactInfo(e.target.value)}
                                className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                            />
                        </div>
                    </div>
                </div>

                {/* Location */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                    <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                        <MapPin className="w-5 h-5 text-orange-500" />
                        ตำแหน่งที่ตั้ง
                    </h2>
                    <MapPicker
                        lat={location?.lat}
                        lng={location?.lng}
                        onLocationSelect={(lat, lng) => setLocation({ lat, lng })}
                    />
                </div>

                {/* Stats & Needs */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                    <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                        <Gift className="w-5 h-5 text-orange-500" />
                        การดูแลและการรับบริจาค
                    </h2>
                    <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-1">
                                    <Dog className="w-4 h-4" /> สุนัข
                                </label>
                                <input
                                    type="number"
                                    value={petCountDog}
                                    onChange={(e) => setPetCountDog(parseInt(e.target.value) || 0)}
                                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-1">
                                    <Cat className="w-4 h-4" /> แมว
                                </label>
                                <input
                                    type="number"
                                    value={petCountCat}
                                    onChange={(e) => setPetCountCat(parseInt(e.target.value) || 0)}
                                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                                />
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">สิ่งของที่ต้องการ</label>
                            <textarea
                                value={neededItems}
                                onChange={(e) => setNeededItems(e.target.value)}
                                rows={3}
                                className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">ที่อยู่จัดส่ง</label>
                            <textarea
                                value={donationAddress}
                                onChange={(e) => setDonationAddress(e.target.value)}
                                rows={3}
                                className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                            />
                        </div>
                    </div>
                </div>

                {/* Images */}
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                    <h2 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                        <Upload className="w-5 h-5 text-orange-500" />
                        รูปภาพ
                    </h2>

                    <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-4">
                        {existingImages.map((img, index) => (
                            <div key={`existing-${index}`} className="relative aspect-video rounded-lg overflow-hidden border">
                                <img src={img} alt={`Existing ${index}`} className="w-full h-full object-cover" />
                                <button
                                    onClick={() => removeExistingImage(index)}
                                    className="absolute top-1 right-1 bg-black/50 hover:bg-red-500 text-white p-1 rounded-full transition-colors"
                                >
                                    <X className="w-4 h-4" />
                                </button>
                            </div>
                        ))}
                        {imagePreviews.map((preview, index) => (
                            <div key={`new-${index}`} className="relative aspect-video rounded-lg overflow-hidden border">
                                <img src={preview} alt={`New ${index}`} className="w-full h-full object-cover" />
                                <button
                                    onClick={() => removeNewImage(index)}
                                    className="absolute top-1 right-1 bg-black/50 hover:bg-red-500 text-white p-1 rounded-full transition-colors"
                                >
                                    <X className="w-4 h-4" />
                                </button>
                            </div>
                        ))}
                    </div>

                    <div className="border-2 border-dashed border-gray-300 rounded-xl p-4 text-center hover:border-orange-500 transition-colors bg-gray-50">
                        <input
                            type="file"
                            accept="image/*"
                            multiple
                            onChange={handleImageSelect}
                            className="hidden"
                            id="edit-shelter-images"
                        />
                        <label htmlFor="edit-shelter-images" className="cursor-pointer flex flex-col items-center">
                            <Upload className="w-8 h-8 text-gray-400 mb-1" />
                            <span className="text-gray-600 font-medium text-sm">เพิ่มรูปภาพ</span>
                        </label>
                    </div>
                </div>

                <button
                    onClick={handleSubmit}
                    disabled={loading}
                    className="w-full py-4 rounded-xl bg-green-600 text-white font-bold hover:bg-green-700 transition-colors shadow-lg shadow-green-200 disabled:opacity-50 flex items-center justify-center gap-2 text-lg"
                >
                    {loading ? <Loader2 className="w-6 h-6 animate-spin" /> : <Save className="w-6 h-6" />}
                    บันทึกการเปลี่ยนแปลง
                </button>
            </div>
        </div>
    );
}
