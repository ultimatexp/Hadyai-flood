"use client";

import React, { useState } from "react";
import { ThaiButton } from "../ui/thai-button";
import { CategoryChip } from "../ui/category-chip";
import { UrgencySelector } from "../ui/urgency-selector";
import { PhotoUploader } from "../ui/photo-uploader";
import MapPicker from "../map";
import { supabase } from "@/lib/supabase";
import { cn } from "@/lib/utils";
import {
    MapPin,
    Phone,
    User,
    Accessibility,
    Zap,
    Droplets,
    Utensils,
    Baby,
    Dog,
    HelpCircle,
    ChevronRight,
    ChevronLeft,
    CheckCircle2
} from "lucide-react";
import { useRouter } from "next/navigation";

const CATEGORIES = [
    { id: "ผู้พิการ", icon: Accessibility },
    { id: "ผู้สูงอายุ", icon: User },
    { id: "ติดเตียง", icon: User }, // Using User for now, maybe Bed if available
    { id: "Power Bank", icon: Zap },
    { id: "น้ำดื่ม", icon: Droplets },
    { id: "อาหาร", icon: Utensils },
    { id: "เด็กเล็ก", icon: Baby },
    { id: "สัตว์เลี้ยง", icon: Dog },
    { id: "อื่น ๆ", icon: HelpCircle },
];

export default function SOSWizard() {
    const router = useRouter();
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);

    const [formData, setFormData] = useState({
        lat: 0,
        lng: 0,
        address_text: "",
        reporter_name: "",
        contacts: [""] as string[],
        categories: [] as string[],
        urgency_level: 2,
        note: "",
    });
    const [photos, setPhotos] = useState<File[]>([]);

    const handleNext = () => setStep((p) => p + 1);
    const handleBack = () => setStep((p) => p - 1);

    const handleSubmit = async () => {
        setLoading(true);
        try {
            // 0. Check for duplicates
            const cleanContact = formData.contacts[0].replace(/[-\s]/g, "");
            if (cleanContact) {
                const { data: existingCases } = await supabase
                    .from('sos_cases')
                    .select('id, status')
                    .contains('contacts', [cleanContact])
                    .in('status', ['NEW', 'ACKNOWLEDGED', 'IN_PROGRESS'])
                    .limit(1);

                if (existingCases && existingCases.length > 0) {
                    alert("เบอร์โทรศัพท์นี้มีการแจ้งเหตุเข้ามาแล้วและกำลังดำเนินการอยู่\nระบบจะพาคุณไปยังหน้ารายละเอียดเคสเดิม");
                    router.push(`/case/${existingCases[0].id}`);
                    setLoading(false);
                    return;
                }
            }

            // 1. Upload photos
            const photoUrls = [];
            for (const file of photos) {
                const fileExt = file.name.split('.').pop();
                const fileName = `${Math.random()}.${fileExt}`;
                const { data, error } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, file);

                if (error) throw error;

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                photoUrls.push({ url: publicUrl, type: 'before' });
            }

            // 2. Insert case
            const { data, error } = await supabase
                .from('sos_cases')
                .insert({
                    ...formData,
                    contacts: formData.contacts
                        .filter(c => c.trim() !== "")
                        .map(c => c.replace(/[-\s]/g, "")),
                    photos: photoUrls,
                })
                .select()
                .single();

            if (error) throw error;

            // 3. Redirect to success/detail page
            router.push(`/case/${data.id}?token=${data.edit_token}&created=true`);

        } catch (error) {
            console.error("Error submitting SOS:", error);
            alert("เกิดข้อผิดพลาดในการส่งข้อมูล กรุณาลองใหม่อีกครั้ง");
        } finally {
            setLoading(false);
        }
    };

    const toggleCategory = (cat: string) => {
        setFormData(prev => {
            if (prev.categories.includes(cat)) {
                return { ...prev, categories: prev.categories.filter(c => c !== cat) };
            }
            return { ...prev, categories: [...prev.categories, cat] };
        });
    };

    const addContact = () => setFormData(prev => ({ ...prev, contacts: [...prev.contacts, ""] }));
    const updateContact = (idx: number, val: string) => {
        const newContacts = [...formData.contacts];
        newContacts[idx] = val;
        setFormData(prev => ({ ...prev, contacts: newContacts }));
    };

    return (
        <div className="max-w-lg mx-auto pb-20">
            {/* Progress Bar */}
            <div className="flex items-center justify-between mb-8 px-2">
                {[1, 2, 3].map((s) => (
                    <div key={s} className="flex items-center">
                        <div className={cn(
                            "w-10 h-10 rounded-full flex items-center justify-center font-bold text-lg transition-colors",
                            step >= s ? "bg-primary text-white" : "bg-muted text-muted-foreground"
                        )}>
                            {s}
                        </div>
                        {s < 3 && <div className={cn("w-12 h-1 mx-2 rounded-full", step > s ? "bg-primary" : "bg-muted")} />}
                    </div>
                ))}
            </div>

            {/* Step 1: Location */}
            {step === 1 && (
                <div className="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
                    <div className="text-center space-y-2">
                        <h2 className="text-2xl font-bold">ระบุตำแหน่งของคุณ</h2>
                        <p className="text-muted-foreground">ปักหมุดจุดที่ต้องการความช่วยเหลือ</p>
                    </div>

                    <MapPicker
                        lat={formData.lat || undefined}
                        lng={formData.lng || undefined}
                        onLocationSelect={(lat, lng) => setFormData(prev => ({ ...prev, lat, lng }))}
                    />

                    <div className="space-y-2">
                        <label className="font-medium">จุดสังเกตเพิ่มเติม (ถ้ามี)</label>
                        <textarea
                            className="w-full p-3 rounded-xl border-2 border-border bg-background focus:border-primary outline-none transition-colors"
                            placeholder="เช่น บ้านสีฟ้า ตรงข้ามเสาไฟฟ้า..."
                            rows={3}
                            value={formData.address_text}
                            onChange={(e) => setFormData(prev => ({ ...prev, address_text: e.target.value }))}
                        />
                    </div>

                    <ThaiButton
                        className="w-full mt-4"
                        onClick={handleNext}
                        disabled={!formData.lat || !formData.lng}
                    >
                        ถัดไป <ChevronRight className="ml-2" />
                    </ThaiButton>
                </div>
            )}

            {/* Step 2: Info */}
            {step === 2 && (
                <div className="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
                    <div className="text-center space-y-2">
                        <h2 className="text-2xl font-bold">ข้อมูลการติดต่อ</h2>
                        <p className="text-muted-foreground">เพื่อให้เจ้าหน้าที่ติดต่อกลับได้</p>
                    </div>

                    <div className="space-y-4">
                        <div className="space-y-2">
                            <label className="font-medium">ชื่อผู้แจ้ง / ผู้ประสบภัย</label>
                            <input
                                type="text"
                                className="w-full p-3 rounded-xl border-2 border-border bg-background focus:border-primary outline-none"
                                placeholder="ชื่อ-นามสกุล หรือ ชื่อเล่น"
                                value={formData.reporter_name}
                                onChange={(e) => setFormData(prev => ({ ...prev, reporter_name: e.target.value }))}
                            />
                        </div>

                        <div className="space-y-2">
                            <label className="font-medium">เบอร์โทรศัพท์</label>
                            {formData.contacts.map((contact, idx) => (
                                <div key={idx} className="flex gap-2">
                                    <input
                                        type="tel"
                                        className="w-full p-3 rounded-xl border-2 border-border bg-background focus:border-primary outline-none"
                                        placeholder="08x-xxx-xxxx"
                                        value={contact}
                                        onChange={(e) => updateContact(idx, e.target.value)}
                                    />
                                </div>
                            ))}
                            <button type="button" onClick={addContact} className="text-sm text-primary font-medium hover:underline">
                                + เพิ่มเบอร์สำรอง
                            </button>
                        </div>

                        <div className="space-y-2">
                            <label className="font-medium">ต้องการความช่วยเหลือเรื่อง</label>
                            <div className="grid grid-cols-3 gap-2">
                                {CATEGORIES.map((cat) => (
                                    <CategoryChip
                                        key={cat.id}
                                        label={cat.id}
                                        icon={cat.icon}
                                        selected={formData.categories.includes(cat.id)}
                                        onClick={() => toggleCategory(cat.id)}
                                    />
                                ))}
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="font-medium">ระดับความเร่งด่วน</label>
                            <UrgencySelector
                                value={formData.urgency_level}
                                onChange={(val) => setFormData(prev => ({ ...prev, urgency_level: val }))}
                            />
                        </div>
                    </div>

                    <div className="flex gap-3 pt-4">
                        <ThaiButton variant="outline" onClick={handleBack} className="flex-1">
                            <ChevronLeft className="mr-2" /> ย้อนกลับ
                        </ThaiButton>
                        <ThaiButton
                            className="flex-[2]"
                            onClick={handleNext}
                            disabled={!formData.reporter_name || !formData.contacts[0]}
                        >
                            ถัดไป <ChevronRight className="ml-2" />
                        </ThaiButton>
                    </div>
                </div>
            )}

            {/* Step 3: Details */}
            {step === 3 && (
                <div className="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
                    <div className="text-center space-y-2">
                        <h2 className="text-2xl font-bold">รายละเอียดเพิ่มเติม</h2>
                        <p className="text-muted-foreground">รูปภาพจะช่วยให้ประเมินสถานการณ์ได้ดีขึ้น</p>
                    </div>

                    <div className="space-y-4">
                        <div className="space-y-2">
                            <label className="font-medium">รายละเอียดเพิ่มเติม (ถ้ามี)</label>
                            <textarea
                                className="w-full p-3 rounded-xl border-2 border-border bg-background focus:border-primary outline-none"
                                placeholder="เช่น ระดับน้ำสูง 1 เมตร, มีผู้ป่วยติดเตียงต้องการออกซิเจน..."
                                rows={4}
                                value={formData.note}
                                onChange={(e) => setFormData(prev => ({ ...prev, note: e.target.value }))}
                            />
                        </div>

                        <div className="space-y-2">
                            <label className="font-medium">รูปภาพประกอบ</label>
                            <PhotoUploader files={photos} onFilesChange={setPhotos} />
                        </div>
                    </div>

                    <div className="flex gap-3 pt-4">
                        <ThaiButton variant="outline" onClick={handleBack} className="flex-1">
                            <ChevronLeft className="mr-2" /> ย้อนกลับ
                        </ThaiButton>
                        <ThaiButton
                            className="flex-[2] bg-green-600 hover:bg-green-700 shadow-green-600/20"
                            onClick={handleSubmit}
                            isLoading={loading}
                        >
                            <CheckCircle2 className="mr-2" /> ส่งคำขอความช่วยเหลือ
                        </ThaiButton>
                    </div>
                </div>
            )}
        </div>
    );
}
