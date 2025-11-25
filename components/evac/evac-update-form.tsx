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
import { updateEvacPoint } from "@/lib/actions/evac";
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

interface EvacUpdateFormProps {
    initialData: any;
    token: string;
}

export function EvacUpdateForm({ initialData, token }: EvacUpdateFormProps) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [files, setFiles] = useState<File[]>([]);
    const [formData, setFormData] = useState({
        lat: initialData.lat,
        lng: initialData.lng,
        title: initialData.title,
        type: initialData.type,
        open_status: initialData.open_status,
        capacity: initialData.capacity?.toString() || "",
        facilities: initialData.facilities || [],
        contact_phone: initialData.contact_phone || "",
        note: initialData.note || "",
        photos: initialData.photos || [],
        address_text: initialData.address_text || "",
    });

    const handleSubmit = async () => {
        setLoading(true);
        try {
            // Upload new photos
            const uploadedPhotos = [...formData.photos];
            for (const file of files) {
                const fileExt = file.name.split('.').pop();
                const fileName = `${Math.random()}.${fileExt}`;
                const filePath = `evac-photos/${fileName}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
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

            const result = await updateEvacPoint(initialData.id, token, {
                ...formData,
                capacity: formData.capacity ? parseInt(formData.capacity) : null,
                photos: uploadedPhotos,
            });

            if (result.error) {
                alert("เกิดข้อผิดพลาด: " + result.error);
            } else {
                router.push(`/evac/${initialData.id}?token=${token}`);
                router.refresh();
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
            <div className="space-y-4 animate-in fade-in">
                <h2 className="text-xl font-bold flex items-center gap-2">
                    <Info className="text-primary" />
                    แก้ไขข้อมูลจุดอพยพ
                </h2>

                <div className="space-y-2">
                    <Label>ชื่อจุดอพยพ <span className="text-red-500">*</span></Label>
                    <Input
                        value={formData.title}
                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    />
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
                    <Label>รองรับได้อีก (คน)</Label>
                    <Input
                        type="number"
                        value={formData.capacity}
                        onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                    />
                </div>

                <div className="space-y-2">
                    <Label>สิ่งอำนวยความสะดวก</Label>
                    <FacilitiesSelector
                        selected={formData.facilities}
                        onChange={(facilities) => setFormData({ ...formData, facilities })}
                    />
                </div>

                <div className="space-y-2">
                    <Label>เบอร์โทรติดต่อ</Label>
                    <Input
                        type="tel"
                        value={formData.contact_phone}
                        onChange={(e) => setFormData({ ...formData, contact_phone: e.target.value })}
                    />
                </div>

                <div className="space-y-2">
                    <Label>รายละเอียดเพิ่มเติม</Label>
                    <Textarea
                        value={formData.note}
                        onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                        rows={3}
                    />
                </div>

                <div className="space-y-2">
                    <Label>เพิ่มรูปภาพ</Label>
                    <PhotoUploader
                        files={files}
                        onFilesChange={setFiles}
                    />
                </div>

                <ThaiButton onClick={handleSubmit} isLoading={loading} className="w-full">
                    บันทึกการเปลี่ยนแปลง
                </ThaiButton>
            </div>
        </div>
    );
}
