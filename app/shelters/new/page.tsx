"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { createShelter } from "@/app/actions/shelter";
import { ThaiButton } from "@/components/ui/thai-button";
import { ArrowLeft, Upload, MapPin, Dog, Cat, Gift, Phone, FileText, Check, Loader2, X, Home } from "lucide-react";
import Link from "next/link";
import dynamic from "next/dynamic";
import { supabase } from "@/lib/supabase";

// Dynamically import MapPicker
const MapPicker = dynamic(() => import("@/components/map/map-picker"), {
    ssr: false,
    loading: () => <div className="h-[300px] bg-gray-100 animate-pulse rounded-xl" />
});

export default function NewShelterPage() {
    const router = useRouter();
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [user, setUser] = useState<any>(null);

    // Form State
    const [name, setName] = useState("");
    const [description, setDescription] = useState(""); // Latest review / description
    const [contactInfo, setContactInfo] = useState("");
    const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [petCountDog, setPetCountDog] = useState(0);
    const [petCountCat, setPetCountCat] = useState(0);
    const [neededItems, setNeededItems] = useState("");
    const [donationAddress, setDonationAddress] = useState("");
    const [images, setImages] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);

    useState(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            if (!currentUser) {
                // Redirect or show login prompt (for now just set user null)
            } else {
                setUser(currentUser);
            }
        });
        return () => unsubscribe();
    });

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

    const removeImage = (index: number) => {
        setImages(prev => prev.filter((_, i) => i !== index));
        setImagePreviews(prev => prev.filter((_, i) => i !== index));
    };

    const handleSubmit = async () => {
        if (!user) {
            alert("กรุณาเข้าสู่ระบบก่อนลงทะเบียน");
            return;
        }
        if (!location) {
            alert("กรุณาระบุตำแหน่ง");
            return;
        }

        setLoading(true);
        try {
            const imageUrls: string[] = [];

            // Upload images
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

                imageUrls.push(publicUrl);
            }

            const result = await createShelter({
                name,
                description,
                images: imageUrls,
                needed_items: neededItems,
                pet_count_dog: petCountDog,
                pet_count_cat: petCountCat,
                donation_address: donationAddress,
                lat: location.lat,
                lng: location.lng,
                contact_info: contactInfo,
                user_id: user.uid
            });

            if (result.success) {
                router.push("/shelters");
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

    const renderStep1 = () => (
        <div className="space-y-4 animate-in fade-in slide-in-from-right">
            <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                <Home className="w-6 h-6 text-orange-500" />
                ข้อมูลพื้นฐาน
            </h2>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">ชื่อศูนย์พักพิง</label>
                <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                    placeholder="เช่น บ้านพักพิงสี่ขา"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">รีวิวล่าสุด / รายละเอียด</label>
                <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    rows={4}
                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                    placeholder="เล่าเรื่องราวเกี่ยวกับศูนย์พักพิง..."
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">ช่องทางติดต่อ</label>
                <input
                    type="text"
                    value={contactInfo}
                    onChange={(e) => setContactInfo(e.target.value)}
                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                    placeholder="เบอร์โทร, Facebook Page, Line ID"
                />
            </div>
        </div>
    );

    const renderStep2 = () => (
        <div className="space-y-4 animate-in fade-in slide-in-from-right">
            <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                <MapPin className="w-6 h-6 text-orange-500" />
                ตำแหน่งที่ตั้ง
            </h2>
            <div className="bg-orange-50 p-4 rounded-xl text-sm text-orange-800 mb-4">
                ปักหมุดตำแหน่งของศูนย์พักพิงเพื่อให้ผู้คนเดินทางไปบริจาคหรือเยี่ยมชมได้ถูกต้อง
            </div>
            <MapPicker
                lat={location?.lat}
                lng={location?.lng}
                onLocationSelect={(lat, lng) => setLocation({ lat, lng })}
            />
        </div>
    );

    const renderStep3 = () => (
        <div className="space-y-4 animate-in fade-in slide-in-from-right">
            <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                <Gift className="w-6 h-6 text-orange-500" />
                ข้อมูลการดูแลและการรับบริจาค
            </h2>

            <div className="grid grid-cols-2 gap-4">
                <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-1">
                        <Dog className="w-4 h-4" /> จำนวนสุนัข
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
                        <Cat className="w-4 h-4" /> จำนวนแมว
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
                <label className="block text-sm font-medium text-gray-700 mb-1">สิ่งของที่ต้องการรับบริจาค</label>
                <textarea
                    value={neededItems}
                    onChange={(e) => setNeededItems(e.target.value)}
                    rows={3}
                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                    placeholder="เช่น อาหารเม็ด, ทรายแมว, ยารักษาโรค..."
                />
            </div>

            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">ที่อยู่สำหรับจัดส่งของบริจาค</label>
                <textarea
                    value={donationAddress}
                    onChange={(e) => setDonationAddress(e.target.value)}
                    rows={3}
                    className="w-full px-4 py-2 border rounded-xl focus:ring-2 focus:ring-orange-500 outline-none"
                    placeholder="ที่อยู่ไปรษณีย์..."
                />
            </div>
        </div>
    );

    const renderStep4 = () => (
        <div className="space-y-4 animate-in fade-in slide-in-from-right">
            <h2 className="text-xl font-bold text-gray-800 mb-4 flex items-center gap-2">
                <Upload className="w-6 h-6 text-orange-500" />
                รูปภาพ
            </h2>

            <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-orange-500 transition-colors bg-gray-50">
                <input
                    type="file"
                    accept="image/*"
                    multiple
                    onChange={handleImageSelect}
                    className="hidden"
                    id="shelter-images"
                />
                <label htmlFor="shelter-images" className="cursor-pointer flex flex-col items-center">
                    <Upload className="w-12 h-12 text-gray-400 mb-2" />
                    <span className="text-gray-600 font-medium">คลิกเพื่ออัพโหลดรูปภาพ</span>
                    <span className="text-sm text-gray-400">เลือกได้หลายรูป</span>
                </label>
            </div>

            {imagePreviews.length > 0 && (
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                    {imagePreviews.map((preview, index) => (
                        <div key={index} className="relative aspect-video rounded-lg overflow-hidden border">
                            <img src={preview} alt={`Preview ${index}`} className="w-full h-full object-cover" />
                            <button
                                onClick={() => removeImage(index)}
                                className="absolute top-1 right-1 bg-black/50 hover:bg-red-500 text-white p-1 rounded-full transition-colors"
                            >
                                <X className="w-4 h-4" />
                            </button>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );

    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header */}
            <div className="bg-white shadow-sm p-4 sticky top-0 z-50">
                <div className="max-w-2xl mx-auto flex items-center gap-4">
                    <Link href="/shelters">
                        <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                            <ArrowLeft className="w-6 h-6 text-gray-700" />
                        </button>
                    </Link>
                    <h1 className="text-xl font-bold text-gray-900">ลงทะเบียนศูนย์พักพิง</h1>
                </div>
            </div>

            <div className="max-w-2xl mx-auto p-4">
                {/* Progress Steps */}
                <div className="flex justify-between mb-8 px-4">
                    {[1, 2, 3, 4].map((s) => (
                        <div key={s} className="flex flex-col items-center gap-2">
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-colors ${step >= s ? 'bg-orange-500 text-white' : 'bg-gray-200 text-gray-500'
                                }`}>
                                {s}
                            </div>
                            <span className="text-xs text-gray-500">
                                {s === 1 ? 'ข้อมูล' : s === 2 ? 'ตำแหน่ง' : s === 3 ? 'การดูแล' : 'รูปภาพ'}
                            </span>
                        </div>
                    ))}
                </div>

                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
                    {step === 1 && renderStep1()}
                    {step === 2 && renderStep2()}
                    {step === 3 && renderStep3()}
                    {step === 4 && renderStep4()}
                </div>

                <div className="flex gap-3">
                    {step > 1 && (
                        <button
                            onClick={() => setStep(s => s - 1)}
                            className="flex-1 py-3 rounded-xl border border-gray-300 font-bold text-gray-700 hover:bg-gray-50 transition-colors"
                        >
                            ย้อนกลับ
                        </button>
                    )}

                    {step < 4 ? (
                        <button
                            onClick={() => setStep(s => s + 1)}
                            className="flex-1 py-3 rounded-xl bg-orange-500 text-white font-bold hover:bg-orange-600 transition-colors shadow-lg shadow-orange-200"
                        >
                            ถัดไป
                        </button>
                    ) : (
                        <button
                            onClick={handleSubmit}
                            disabled={loading}
                            className="flex-1 py-3 rounded-xl bg-green-600 text-white font-bold hover:bg-green-700 transition-colors shadow-lg shadow-green-200 disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                            {loading && <Loader2 className="w-5 h-5 animate-spin" />}
                            ยืนยันการลงทะเบียน
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
}
