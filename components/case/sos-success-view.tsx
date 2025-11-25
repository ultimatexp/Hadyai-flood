"use client";

import { Check, Truck, Clock, Phone, BookOpen, ChevronRight, Copy, Edit, CheckCircle2 } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import Link from "next/link";
import { format } from "date-fns";
import { th } from "date-fns/locale";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
import { supabase } from "@/lib/supabase";
import { useState } from "react";
import { useRouter } from "next/navigation";

interface SOSSuccessViewProps {
    caseData: any;
    editToken?: string | null;
}

export function SOSSuccessView({ caseData, editToken }: SOSSuccessViewProps) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [currentStatus, setCurrentStatus] = useState(caseData.status);
    const [isConfirming, setIsConfirming] = useState(false);
    const [countdown, setCountdown] = useState(3);

    const steps = [
        {
            id: "NEW",
            label: "ได้รับแจ้งเหตุแล้ว",
            subLabel: "Signal Received",
            time: format(new Date(caseData.created_at), "HH:mm a"),
            icon: Check,
            active: true,
            color: "bg-green-500",
        },
        {
            id: "IN_PROGRESS",
            label: "เจ้าหน้าที่กำลังเดินทาง",
            subLabel: "Rescue Team Dispatched",
            time: currentStatus === "IN_PROGRESS" ? format(new Date(), "HH:mm a") : "-",
            icon: Truck,
            active: ["ACKNOWLEDGED", "IN_PROGRESS", "RESOLVED"].includes(currentStatus),
            color: "bg-blue-500",
        },
        {
            id: "RESOLVED",
            label: "ช่วยเหลือสำเร็จ",
            subLabel: "Mission Complete",
            time: currentStatus === "RESOLVED" ? format(new Date(), "HH:mm a") : "-",
            icon: Clock,
            active: currentStatus === "RESOLVED",
            color: "bg-gray-500", // Will be green if active
        },
    ];

    const handleCancelConfirm = () => {
        setIsConfirming(false);
        setCountdown(3);
    };

    const startConfirmation = () => {
        setIsConfirming(true);
        setCountdown(3);

        const timer = setInterval(() => {
            setCountdown((prev) => {
                if (prev <= 1) {
                    clearInterval(timer);
                    executeResolve();
                    return 0;
                }
                return prev - 1;
            });
        }, 1000);
    };

    const executeResolve = async () => {
        setLoading(true);
        setIsConfirming(false);
        try {
            const { error } = await supabase
                .from("sos_cases")
                .update({ status: "RESOLVED" })
                .eq("id", caseData.id);

            if (error) throw error;

            // Update local state immediately
            setCurrentStatus("RESOLVED");
            alert("ขอบคุณที่แจ้งสถานะ! ขอให้ปลอดภัยครับ");
        } catch (error) {
            console.error("Error updating status:", error);
            alert("เกิดข้อผิดพลาดในการอัปเดตสถานะ");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-zinc-950 text-white flex flex-col items-center justify-center p-6 relative overflow-hidden" style={{ backgroundColor: "#09090b" }}>
            {/* Success Icon */}
            <div className="w-24 h-24 bg-green-500 rounded-full flex items-center justify-center mb-6 animate-in zoom-in duration-500">
                <Check className="w-12 h-12 text-white stroke-[3]" />
            </div>

            <h1 className="text-3xl font-bold mb-2 text-center">ส่งคำขอความช่วยเหลือสำเร็จ</h1>
            <p className="text-gray-400 text-center mb-8 max-w-xs">
                เจ้าหน้าที่ได้รับข้อมูลแล้ว กรุณารอการติดต่อกลับและอยู่ในที่ปลอดภัย
            </p>

            {/* Status Card */}
            <div className="w-full max-w-sm bg-zinc-900 rounded-2xl p-6 border border-gray-800 mb-8" style={{ backgroundColor: "#18181b" }}>
                <h2 className="font-bold text-lg mb-6">สถานะการช่วยเหลือ</h2>

                <div className="space-y-0 relative">
                    {/* Vertical Line */}
                    <div className="absolute left-[19px] top-4 bottom-8 w-0.5 bg-gray-700" />

                    {steps.map((step, idx) => (
                        <div key={idx} className="relative flex gap-4 pb-8 last:pb-0">
                            <div className={`
                                w-10 h-10 rounded-full flex items-center justify-center shrink-0 z-10 border-4 border-zinc-900
                                ${step.active ? step.color : "bg-gray-700"}
                            `} style={{ borderColor: "#18181b" }}>
                                <step.icon className="w-5 h-5 text-white" />
                            </div>
                            <div className="pt-1">
                                <h3 className="font-bold text-white">{step.label}</h3>
                                <p className="text-xs text-gray-400 mt-1">{step.subLabel}</p>
                                <p className="text-xs text-gray-500 mt-0.5">{step.time}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Actions */}
            <div className="w-full max-w-sm space-y-3">
                {/* Self Resolve Button - Shows if not resolved */}
                {currentStatus !== "RESOLVED" && (
                    <div className="space-y-2">
                        {!isConfirming ? (
                            <button
                                onClick={startConfirmation}
                                disabled={loading}
                                className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-3 transition-colors shadow-lg shadow-green-900/20"
                            >
                                {loading ? (
                                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                                ) : (
                                    <CheckCircle2 className="w-5 h-5" />
                                )}
                                ได้รับความช่วยเหลือแล้ว (I'm Safe)
                            </button>
                        ) : (
                            <>
                                <div className="w-full bg-green-600 text-white font-bold py-4 rounded-xl flex flex-col items-center justify-center gap-2 animate-pulse">
                                    <div className="text-4xl font-bold">{countdown}</div>
                                    <div className="text-sm">กำลังยืนยันการอัปเดตสถานะ...</div>
                                </div>
                                <button
                                    onClick={handleCancelConfirm}
                                    className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl transition-colors"
                                >
                                    ยกเลิก (Cancel)
                                </button>
                            </>
                        )}
                    </div>
                )}

                {/* Edit Button (Only if token exists) */}
                {(caseData.edit_token || editToken) && (
                    <Link href={`/case/${caseData.id}/update?token=${caseData.edit_token || editToken}`} className="block w-full">
                        <button className="w-full bg-yellow-500 hover:bg-yellow-600 text-black font-bold py-4 rounded-xl flex items-center justify-center gap-3 transition-colors">
                            <Edit className="w-5 h-5" />
                            แก้ไขข้อมูล (Edit Data)
                        </button>
                    </Link>
                )}

                <Dialog>
                    <DialogTrigger asChild>
                        <button className="w-full bg-[#EF4444] hover:bg-red-600 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-3 transition-colors">
                            <Phone className="w-5 h-5 fill-current" />
                            โทรขอความช่วยเหลือ (Call for Help)
                        </button>
                    </DialogTrigger>
                    <DialogContent className="sm:max-w-md">
                        <DialogHeader>
                            <DialogTitle className="text-center text-xl font-bold">เบอร์โทรฉุกเฉิน</DialogTitle>
                            <DialogDescription className="text-center">
                                ศภบ.มทบ.42 (ศูนย์บรรเทาสาธารณภัย มทบ.42)
                            </DialogDescription>
                        </DialogHeader>
                        <div className="space-y-4 py-4">
                            <div className="space-y-2">
                                <h4 className="font-semibold text-red-600 flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-red-600" /> เบอร์หลัก (สายด่วน)
                                </h4>
                                <a href="tel:074232145" className="block text-2xl font-bold text-center bg-red-50 p-3 rounded-xl border border-red-100 text-red-700 hover:bg-red-100 transition-colors">
                                    074-232-145 ถึง 8
                                </a>
                            </div>

                            <div className="space-y-2">
                                <h4 className="font-semibold text-blue-600 flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-blue-600" /> เบอร์มือถือ (ติดต่อด่วน)
                                </h4>
                                <div className="grid grid-cols-2 gap-3">
                                    <a href="tel:0982233364" className="block text-lg font-bold text-center bg-blue-50 p-2 rounded-xl border border-blue-100 text-blue-700 hover:bg-blue-100 transition-colors">
                                        098-223-3364
                                    </a>
                                    <a href="tel:0615865574" className="block text-lg font-bold text-center bg-blue-50 p-2 rounded-xl border border-blue-100 text-blue-700 hover:bg-blue-100 transition-colors">
                                        061-586-5574
                                    </a>
                                </div>
                            </div>

                            <div className="space-y-2">
                                <h4 className="font-semibold text-gray-600 flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-gray-600" /> เบอร์สำรอง
                                </h4>
                                <a href="tel:074586685" className="block text-lg font-bold text-center bg-gray-50 p-2 rounded-xl border border-gray-100 text-gray-700 hover:bg-gray-100 transition-colors">
                                    074-586-685
                                </a>
                            </div>

                            <div className="flex items-center justify-center gap-2 text-sm text-muted-foreground bg-muted/50 p-2 rounded-lg">
                                <Clock className="w-4 h-4" />
                                โทรได้ตลอด 24 ชั่วโมง พร้อมเข้าช่วยเหลือทันที
                            </div>
                        </div>
                    </DialogContent>
                </Dialog>

                <button
                    onClick={() => {
                        const url = `${window.location.origin}/case/${caseData.id}`;
                        navigator.clipboard.writeText(url);
                        alert("คัดลอกลิงก์แล้ว! ส่งให้ญาติหรือคนรู้จักเพื่อติดตามสถานะได้เลย");
                    }}
                    className="w-full bg-zinc-800 hover:bg-zinc-700 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-3 transition-colors border border-zinc-700"
                >
                    <Copy className="w-5 h-5" />
                    แชร์ลิงก์ติดตามสถานะ (Share Link)
                </button>

                <Link href="/info" className="block w-full">
                    <button className="w-full bg-[#1F2937] hover:bg-gray-700 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-3 transition-colors">
                        <BookOpen className="w-5 h-5" />
                        ข้อควรรู้ (Things to know)
                    </button>
                </Link>

                <Link href="/" className="block w-full text-center text-gray-500 text-sm mt-4 hover:text-white transition-colors">
                    ← กลับหน้าหลัก (Back to Homepage)
                </Link>
            </div>
        </div>
    );
}
