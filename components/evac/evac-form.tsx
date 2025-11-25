"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import { ThaiButton } from "@/components/ui/thai-button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { FacilitiesSelector } from "./facilities-selector";
import { PhotoUploader } from "@/components/ui/photo-uploader";
import { createEvacPoint } from "@/lib/actions/evac";
import { MapPin, Info, CheckCircle2, AlertTriangle, Building2, School, Church, Hospital } from "lucide-react";
import { cn } from "@/lib/utils";
import { supabase } from "@/lib/supabase";

const MapPicker = dynamic(() => import("@/components/map/map-picker"), { ssr: false });

const TYPES = [
    { id: "school", label: "โรงเรียน", icon: School },
    { id: "temple", label: "วัด/มัสยิด", icon: Church },
    { id: "community", label: "ศูนย์ชุมชน", icon: Building2 },
    { id: "hospital", label: "โรงพยาบาล", icon: Hospital },
    { id: "other", label: "อื่นๆ", icon: MapPin },
];

const STATUSES = [
    { id: "OPEN", label: "เปิดรับคน", color: "bg-green-100 text-green-700 border-green-200" },
    { id: "LIMITED", label: "รับได้จำกัด", color: "bg-yellow-100 text-yellow-700 border-yellow-200" },
    { id: "FULL", label: "เต็มแล้ว", color: "bg-orange-100 text-orange-700 border-orange-200" },
    { id: "CLOSED", label: "ปิด", color: "bg-gray-100 text-gray-700 border-gray-200" },
];

export function EvacForm() {
    const router = useRouter();
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [files, setFiles] = useState<File[]>([]);
    const [formData, setFormData] = useState({
        lat: 0,
        lng: 0,
        title: "",
        type: "school",
        open_status: "OPEN",
        capacity: "",
        facilities: [] as string[],
        contact_phone: "",
        note: "",
        photos: [] as any[],
        address_text: "",
    });

    const handleNext = () => {
        if (step === 1 && (formData.lat === 0 || formData.lng === 0)) {
            alert("กรุณาปักหมุดตำแหน่ง");
            return;
        }
        if (step === 2 && !formData.title) {
            alert("กรุณาระบุชื่อจุดอพยพ");
            return;
        }
        setStep(step + 1);
    };

    const handleSubmit = async () => {
        setLoading(true);
        try {
            // Upload photos
            const uploadedPhotos = [];
            for (const file of files) {
                const fileExt = file.name.split('.').pop();
                const fileName = `${Math.random()}.${fileExt}`;
                const filePath = `evac-photos/${fileName}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos') // Reuse existing bucket or create new one
                    .upload(filePath, file);

                if (uploadError) {
                    console.error('Error uploading photo:', uploadError);
                    continue;
                }

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(filePath);

                uploadedPhotos.push({ url: publicUrl, type: 'image' });
            }

            const result = await createEvacPoint({
                ...formData,
                capacity: formData.capacity ? parseInt(formData.capacity) : null,
                photos: uploadedPhotos,
            });

            if (result.error) {
                alert("เกิดข้อผิดพลาด: " + result.error);
            } else {
                // Redirect to detail page with token
                router.push(`/evac/${result.data.id}?token=${result.editToken}&created=true`);
            }
        } catch (error) {
            console.error(error);
            alert("เกิดข้อผิดพลาดในการเชื่อมต่อ");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-6">
            {/* Progress Steps */}
            <div className="flex justify-between mb-8 relative">
                <div className="absolute top-1/2 left-0 right-0 h-1 bg-gray-200 -z-10 -translate-y-1/2" />
                {[1, 2, 3].map((s) => (
                    <div key={s} className={cn(
                        "w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm transition-all border-4",
                        step >= s ? "bg-primary text-white border-primary" : "bg-white text-gray-400 border-gray-200"
                    )}>
                        {s}
                    </div>
                ))}
            </div>

            {step === 1 && (
                <div className="space-y-4 animate-in fade-in slide-in-from-right-4">
                    <h2 className="text-xl font-bold flex items-center gap-2">
                        <MapPin className="text-primary" />
                        ระบุตำแหน่งจุดอพยพ
                    </h2>
                    <MapPicker
                        lat={formData.lat}
                        lng={formData.lng}
                        onLocationSelect={(lat, lng) => setFormData({ ...formData, lat, lng })}
                    />
                    <ThaiButton onClick={handleNext} className="w-full mt-4">
                        ถัดไป
                    </ThaiButton>
                </div>
            )}

            {step === 2 && (
                <div className="space-y-6 animate-in fade-in slide-in-from-right-4">
                    <h2 className="text-xl font-bold flex items-center gap-2">
                        <Info className="text-primary" />
                        ข้อมูลพื้นฐาน
                    </h2>

                    <div className="space-y-2">
                        <Label>ชื่อจุดอพยพ <span className="text-red-500">*</span></Label>
                        <Input
                            value={formData.title}
                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                            placeholder="เช่น โรงเรียนเทศบาล 1"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>ประเภทสถานที่</Label>
                        <div className="grid grid-cols-2 gap-2">
                            {TYPES.map((t) => {
                                const Icon = t.icon;
                                return (
                                    <button
                                        key={t.id}
                                        type="button"
                                        onClick={() => setFormData({ ...formData, type: t.id })}
                                        className={cn(
                                            "flex items-center gap-2 p-3 rounded-xl border text-sm font-medium transition-all",
                                            formData.type === t.id
                                                ? "border-primary bg-primary/5 text-primary shadow-sm"
                                                : "border-border bg-card text-muted-foreground hover:bg-accent"
                                        )}
                                    >
                                        <Icon className="w-4 h-4" />
                                        {t.label}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    <div className="space-y-2">
                        <Label>สถานะปัจจุบัน</Label>
                        <div className="grid grid-cols-2 gap-2">
                            {STATUSES.map((s) => (
                                <button
                                    key={s.id}
                                    type="button"
                                    onClick={() => setFormData({ ...formData, open_status: s.id })}
                                    className={cn(
                                        "p-2 rounded-xl border text-sm font-bold transition-all",
                                        formData.open_status === s.id
                                            ? s.color + " ring-2 ring-offset-1 ring-primary/20"
                                            : "bg-white text-gray-500 border-gray-200"
                                    )}
                                >
                                    {s.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="space-y-2">
                        <Label>รองรับได้อีก (คน) - โดยประมาณ</Label>
                        <Input
                            type="number"
                            value={formData.capacity}
                            onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                            placeholder="เช่น 50"
                        />
                    </div>

                    <div className="flex gap-3">
                        <ThaiButton variant="outline" onClick={() => setStep(1)} className="flex-1">
                            ย้อนกลับ
                        </ThaiButton>
                        <ThaiButton onClick={handleNext} className="flex-1">
                            ถัดไป
                        </ThaiButton>
                    </div>
                </div>
            )}

            {step === 3 && (
                <div className="space-y-6 animate-in fade-in slide-in-from-right-4">
                    <h2 className="text-xl font-bold flex items-center gap-2">
                        <CheckCircle2 className="text-primary" />
                        สิ่งอำนวยความสะดวก & ติดต่อ
                    </h2>

                    <div className="space-y-2">
                        <Label>สิ่งอำนวยความสะดวก</Label>
                        <FacilitiesSelector
                            selected={formData.facilities}
                            onChange={(facilities) => setFormData({ ...formData, facilities })}
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>เบอร์โทรติดต่อ (ถ้ามี)</Label>
                        <Input
                            type="tel"
                            value={formData.contact_phone}
                            onChange={(e) => setFormData({ ...formData, contact_phone: e.target.value })}
                            placeholder="08x-xxx-xxxx"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>รายละเอียดเพิ่มเติม / หมายเหตุ</Label>
                        <Textarea
                            value={formData.note}
                            onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                            placeholder="เช่น ทางเข้าอยู่ด้านหลัง, ต้องการบริจาคน้ำดื่มเพิ่ม"
                            rows={3}
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>รูปภาพสถานที่ (ถ้ามี)</Label>
                        <PhotoUploader
                            files={files}
                            onFilesChange={setFiles}
                        />
                    </div>

                    <div className="flex gap-3 pt-4">
                        <ThaiButton variant="outline" onClick={() => setStep(2)} className="flex-1">
                            ย้อนกลับ
                        </ThaiButton>
                        <ThaiButton onClick={handleSubmit} isLoading={loading} className="flex-[2]">
                            ยืนยันข้อมูล
                        </ThaiButton>
                    </div>
                </div>
            )}
        </div>
    );
}
