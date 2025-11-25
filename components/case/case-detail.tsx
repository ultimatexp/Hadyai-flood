"use client";

import { ThaiButton } from "@/components/ui/thai-button";
import { MagnificentTag } from "@/components/ui/magnificent-tag";
import { supabase } from "@/lib/supabase";
import { MapPin, Phone, Clock, AlertTriangle, Navigation, CheckCircle2, Edit2 } from "lucide-react";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
import { PhotoUploader } from "@/components/ui/photo-uploader";
import { formatDistanceToNow } from "date-fns";
import { th } from "date-fns/locale";
import Image from "next/image";
import { useState, useEffect } from "react";
import dynamic from "next/dynamic";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import Link from "next/link";

const CaseMap = dynamic(() => import("./case-map"), {
    ssr: false,
    loading: () => (
        <div className="flex items-center justify-center h-full text-gray-500 bg-gray-100">
            กำลังโหลดแผนที่...
        </div>
    ),
});

interface CaseDetailProps {
    caseData: any;
    isOwner?: boolean;
    editToken?: string | null;
}

export default function CaseDetail({ caseData, isOwner, editToken }: CaseDetailProps) {
    const [status, setStatus] = useState(caseData.status);
    const [loading, setLoading] = useState(false);
    const [copied, setCopied] = useState(false);
    const [origin, setOrigin] = useState("");

    // New state for resolution dialog
    const [resolveDialogOpen, setResolveDialogOpen] = useState(false);
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            setIsAuthenticated(!!user);
        });
        return () => unsubscribe();
    }, []);
    const [resolvePhotos, setResolvePhotos] = useState<File[]>([]);

    useEffect(() => {
        setOrigin(window.location.origin);
    }, []);

    const copyLink = () => {
        const url = `${window.location.origin}/case/${caseData.id}/update?token=${editToken}`;
        navigator.clipboard.writeText(url);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const postToFacebook = async (newStatus: string) => {
        try {
            const statusMessage = {
                ACKNOWLEDGED: "✅ รับเรื่องแล้ว",
                IN_PROGRESS: "🚑 กำลังช่วยเหลือ",
                RESOLVED: "🎉 ช่วยเหลือสำเร็จ"
            }[newStatus] || newStatus;

            const message = `[อัปเดตสถานะ: ${statusMessage}]\n\nเคส: ${caseData.reporter_name}\nรายละเอียด: ${caseData.description || "-"}\nพิกัด: https://www.google.com/maps?q=${caseData.lat},${caseData.lng}\n\n#น้ำท่วมหาดใหญ่ #HadyaiFlood`;

            // Use current URL or fallback to origin
            const link = window.location.href;

            // Get first photo if available
            const imageUrl = caseData.photos && caseData.photos.length > 0 ? caseData.photos[0].url : null;

            await fetch('/api/facebook/post', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message, link, imageUrl })
            });
        } catch (error) {
            console.error("Failed to auto-post to Facebook:", error);
            // Don't block the UI flow if FB post fails
        }
    };

    const updateStatus = async (newStatus: string) => {
        if (newStatus === "RESOLVED") {
            setResolveDialogOpen(true);
            return;
        }

        let confirmMessage = "";
        switch (newStatus) {
            case "ACKNOWLEDGED": confirmMessage = "ยืนยันว่าคุณกำลังจะไปช่วยเหลือเคสนี้?"; break;
            case "IN_PROGRESS": confirmMessage = "ยืนยันว่าคุณเริ่มดำเนินการช่วยเหลือแล้ว?"; break;
        }

        if (confirmMessage && !confirm(confirmMessage)) return;

        setLoading(true);
        const { error } = await supabase
            .from("sos_cases")
            .update({ status: newStatus })
            .eq("id", caseData.id);

        if (error) {
            alert("เกิดข้อผิดพลาด");
        } else {
            setStatus(newStatus);
            // Auto-post to Facebook
            postToFacebook(newStatus);
            alert("อัปเดตสถานะเรียบร้อยแล้ว!");
        }
        setLoading(false);
    };

    const handleResolveConfirm = async () => {
        setLoading(true);
        try {
            // 1. Upload photos if any
            const newPhotoUrls = [];
            for (const file of resolvePhotos) {
                const fileExt = file.name.split('.').pop();
                const fileName = `resolved_${Math.random()}.${fileExt}`;
                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, file);

                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                newPhotoUrls.push({ url: publicUrl, type: 'resolved' });
            }

            // 2. Update case status and append photos
            const updatedPhotos = [...(caseData.photos || []), ...newPhotoUrls];

            const { error } = await supabase
                .from("sos_cases")
                .update({
                    status: "RESOLVED",
                    photos: updatedPhotos
                })
                .eq("id", caseData.id);

            if (error) throw error;

            setStatus("RESOLVED");
            setResolveDialogOpen(false);

            // Auto-post to Facebook
            postToFacebook("RESOLVED");

            alert("ขอบคุณมาก! การช่วยเหลือเสร็จสิ้นแล้ว");

        } catch (error) {
            console.error("Error resolving case:", error);
            alert("เกิดข้อผิดพลาดในการอัปเดตสถานะ");
        } finally {
            setLoading(false);
        }
    };


    const statusLabels: { [key: string]: string } = {
        NEW: "รอการช่วยเหลือ",
        ACKNOWLEDGED: "มีผู้รับเรื่องแล้ว",
        IN_PROGRESS: "กำลังดำเนินการ",
        RESOLVED: "ช่วยเหลือสำเร็จ",
        CLOSED: "ปิดเคสแล้ว",
    };

    const statusColors: { [key: string]: string } = {
        NEW: "bg-red-500",
        ACKNOWLEDGED: "bg-yellow-500",
        IN_PROGRESS: "bg-blue-500",
        RESOLVED: "bg-green-500",
        CLOSED: "bg-gray-500",
    };

    return (
        <div className="space-y-6 pb-32">
            <div className="relative h-[250px] w-full bg-gray-200">
                {caseData.lat && caseData.lng ? (
                    <CaseMap lat={caseData.lat} lng={caseData.lng} />
                ) : (
                    <div className="flex items-center justify-center h-full text-gray-500">
                        ไม่พบข้อมูลพิกัด
                    </div>
                )}
            </div>

            {/* Resolution Dialog */}
            <Dialog open={resolveDialogOpen} onOpenChange={setResolveDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>ยืนยันการช่วยเหลือสำเร็จ</DialogTitle>
                        <DialogDescription>
                            คุณสามารถแนบรูปภาพเพื่อยืนยันการช่วยเหลือได้ (ไม่บังคับ)
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <label className="font-medium text-sm">รูปภาพประกอบ (ถ้ามี)</label>
                            <PhotoUploader files={resolvePhotos} onFilesChange={setResolvePhotos} />
                        </div>

                        <ThaiButton
                            className="w-full bg-green-600 hover:bg-green-700"
                            onClick={handleResolveConfirm}
                            isLoading={loading}
                        >
                            <CheckCircle2 className="mr-2" /> ยืนยัน / Confirm
                        </ThaiButton>
                    </div>
                </DialogContent>
            </Dialog>

            <div className="px-4 space-y-6">
                {/* Owner Banner */}
                {isOwner && editToken && (
                    <div className="bg-green-50 border border-green-200 rounded-xl p-4 space-y-3 animate-in fade-in slide-in-from-top-4">
                        <div className="flex items-start gap-3">
                            <CheckCircle2 className="w-6 h-6 text-green-600 shrink-0 mt-0.5" />
                            <div>
                                <h3 className="font-bold text-green-800">ส่งคำขอสำเร็จ!</h3>
                                <p className="text-sm text-green-700">
                                    กรุณาบันทึกลิงก์นี้ไว้สำหรับอัปเดตสถานะหรือแจ้งเมื่อได้รับความช่วยเหลือแล้ว
                                </p>
                            </div>
                        </div>

                        <div className="flex gap-2">
                            <input
                                readOnly
                                value={`${origin}/case/${caseData.id}/update?token=${editToken}`}
                                className="flex-1 text-xs p-2 rounded border bg-white text-muted-foreground min-w-0"
                            />
                            <ThaiButton size="sm" variant="outline" onClick={copyLink} className="shrink-0">
                                {copied ? "คัดลอกแล้ว" : "คัดลอก"}
                            </ThaiButton>
                        </div>

                        <Link href={`/case/${caseData.id}/update?token=${editToken}`} className="block">
                            <ThaiButton size="sm" className="w-full bg-green-600 hover:bg-green-700">
                                อัปเดตสถานะ / แจ้งได้รับความช่วยเหลือ
                            </ThaiButton>
                        </Link>
                    </div>
                )}

                {/* Header */}
                <div className="space-y-3">
                    <div className="flex flex-col gap-2 sm:flex-row sm:justify-between sm:items-start">
                        <h1 className="text-2xl font-bold break-words leading-tight">{caseData.reporter_name}</h1>
                        <div className="flex items-center gap-2 self-start">
                            <span className={`px-3 py-1 rounded-full text-sm font-bold ${statusColors[status] || "bg-gray-100 text-gray-700"}`}>
                                {statusLabels[status] || status}
                            </span>
                            {isOwner && editToken && (
                                <Link href={`/case/${caseData.id}/update?token=${editToken}`}>
                                    <button className="p-1 rounded-full hover:bg-gray-100 text-muted-foreground transition-colors">
                                        <Edit2 className="w-4 h-4" />
                                    </button>
                                </Link>
                            )}
                        </div>
                    </div>
                    <p className="text-muted-foreground flex items-center text-sm">
                        <Clock className="w-4 h-4 mr-1 shrink-0" />
                        {formatDistanceToNow(new Date(caseData.created_at), { addSuffix: true, locale: th })}
                    </p>
                </div>

                {/* Categories */}
                <div className="flex flex-wrap gap-2">
                    {caseData.categories?.map((cat: string) => (
                        <MagnificentTag key={cat} label={cat} size="md" />
                    ))}
                </div>

                {/* Contact */}
                <div className="p-4 bg-card border rounded-xl space-y-3">
                    <h3 className="font-semibold flex items-center">
                        <Phone className="w-5 h-5 mr-2" /> เบอร์โทรศัพท์
                    </h3>
                    {caseData.contacts?.map((phone: string, idx: number) => (
                        <a key={idx} href={`tel:${phone}`} className="block text-lg text-primary hover:underline">
                            {phone}
                        </a>
                    ))}
                </div>

                {/* Note */}
                {caseData.note && (
                    <div className="space-y-2">
                        <h3 className="font-semibold">รายละเอียดเพิ่มเติม</h3>
                        <p className="p-4 bg-muted rounded-xl">{caseData.note}</p>
                    </div>
                )}

                {/* Photos */}
                {caseData.photos?.length > 0 && (
                    <div className="space-y-3">
                        <h3 className="font-semibold text-lg">รูปภาพประกอบ ({caseData.photos.length})</h3>
                        <div className="grid grid-cols-3 gap-3">
                            {caseData.photos.map((photo: any, idx: number) => (
                                <div
                                    key={idx}
                                    className="relative aspect-square rounded-lg overflow-hidden bg-muted shadow-md hover:shadow-lg transition-shadow cursor-pointer group"
                                    onClick={() => window.open(photo.url, '_blank')}
                                >
                                    <Image
                                        src={photo.url}
                                        alt={`รูปภาพที่ ${idx + 1}`}
                                        fill
                                        className="object-cover group-hover:scale-105 transition-transform duration-200"
                                    />
                                    {photo.type === 'resolved' && (
                                        <div className="absolute top-2 right-2 bg-green-600 text-white text-xs px-2 py-1 rounded-md shadow-md">
                                            ✓ หลังช่วยเหลือ
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                        <p className="text-xs text-muted-foreground text-center">คลิกที่รูปเพื่อดูขนาดเต็ม</p>
                    </div>
                )}

                {/* Actions - Only for authenticated helpers */}
                {isAuthenticated && (
                    <div className="fixed bottom-0 left-0 right-0 p-4 bg-background/80 backdrop-blur-md border-t flex gap-3 z-[100]">
                        {status === "NEW" && (
                            <ThaiButton
                                className="flex-[2] bg-green-600 hover:bg-green-700"
                                onClick={() => updateStatus("ACKNOWLEDGED")}
                                isLoading={loading}
                            >
                                <CheckCircle2 className="mr-2" /> ฉันจะช่วยเคสนี้
                            </ThaiButton>
                        )}

                        {status === "ACKNOWLEDGED" && (
                            <ThaiButton
                                className="flex-[2] bg-blue-600 hover:bg-blue-700"
                                onClick={() => updateStatus("IN_PROGRESS")}
                                isLoading={loading}
                            >
                                <Navigation className="mr-2" /> กำลังเดินทาง / เริ่มช่วยเหลือ
                            </ThaiButton>
                        )}

                        {status === "IN_PROGRESS" && (
                            <ThaiButton
                                className="flex-[2] bg-green-600 hover:bg-green-700"
                                onClick={() => updateStatus("RESOLVED")}
                                isLoading={loading}
                            >
                                <CheckCircle2 className="mr-2" /> ช่วยเหลือสำเร็จ
                            </ThaiButton>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
