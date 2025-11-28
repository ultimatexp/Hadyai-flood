"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getPetDetails, updatePetStatus } from "@/app/actions/pet";
import { Loader2, ShieldCheck, ShieldAlert, ShieldQuestion, Clock, MapPin, Phone, User, PawPrint, CheckCircle, ArrowLeft } from "lucide-react";
import { format } from "date-fns";
import { th } from "date-fns/locale";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { ThaiButton } from "@/components/ui/thai-button";
import Link from "next/link";
import PetComments from "@/components/pet/pet-comments";

export default function PetStatusPage() {
    const params = useParams();
    const id = params?.id as string;
    const router = useRouter();

    const [petData, setPetData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [currentUser, setCurrentUser] = useState<any>(null);
    const [updating, setUpdating] = useState(false);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            setCurrentUser(user);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        fetchData();
    }, [id]);

    const fetchData = async () => {
        if (!id) return;
        const result = await getPetDetails(id);
        if (result.success) {
            setPetData(result.data);
        } else {
            setError(result.error || "Failed to load pet data");
        }
        setLoading(false);
    };

    const handleConfirmFound = async () => {
        if (!confirm("ยืนยันว่าคุณพบสัตว์เลี้ยงแล้ว? สถานะจะถูกเปลี่ยนเป็น 'พบแล้ว'")) return;

        setUpdating(true);
        const result = await updatePetStatus(id, "REUNITED");
        if (result.success) {
            setPetData(result.data);
            alert("ยินดีด้วย! สถานะสัตว์เลี้ยงถูกอัปเดตเรียบร้อยแล้ว");
        } else {
            alert("เกิดข้อผิดพลาด: " + result.error);
        }
        setUpdating(false);
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
            </div>
        );
    }

    if (error || !petData) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
                <div className="bg-white p-6 rounded-xl shadow-lg max-w-md w-full text-center">
                    <ShieldAlert className="w-12 h-12 text-red-500 mx-auto mb-4" />
                    <h1 className="text-xl font-bold text-gray-900 mb-2">ไม่สามารถเข้าถึงข้อมูลได้</h1>
                    <p className="text-gray-600">{error || "ไม่พบข้อมูลสัตว์เลี้ยง"}</p>
                    <Link href="/find-pet">
                        <ThaiButton className="mt-4 bg-orange-500 hover:bg-orange-600">กลับหน้าหลัก</ThaiButton>
                    </Link>
                </div>
            </div>
        );
    }

    const isOwner = currentUser && petData.user_id === currentUser.uid;

    return (
        <div className="min-h-screen bg-gray-50 pb-12">
            {/* Header */}
            <header className="bg-white shadow-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 py-4">
                    <div className="flex items-center gap-3">
                        <Link href="/find-pet" className="mr-2">
                            <ArrowLeft className="w-6 h-6 text-gray-500" />
                        </Link>
                        <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center text-orange-600">
                            <PawPrint className="w-6 h-6" />
                        </div>
                        <div>
                            <h1 className="font-bold text-lg text-gray-900 leading-tight">
                                {petData.pet_name || "ไม่ระบุชื่อ"}
                            </h1>
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <span className="bg-orange-100 text-orange-800 px-2 py-0.5 rounded-full text-[10px] font-bold">
                                    {petData.pet_type === 'dog' ? 'สุนัข' : petData.pet_type === 'cat' ? 'แมว' : 'สัตว์เลี้ยง'}
                                </span>
                                <span>• {petData.breed || "ไม่ระบุสายพันธุ์"}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            <main className="container mx-auto px-4 py-6 max-w-lg space-y-6">
                {/* Pet Image */}
                <div className="aspect-video w-full bg-gray-200 rounded-xl overflow-hidden shadow-sm relative">
                    <img
                        src={petData.image_url}
                        alt={petData.pet_name}
                        className="w-full h-full object-cover"
                    />
                    <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-4">
                        <p className="text-white font-bold text-lg">{petData.pet_name}</p>
                        <p className="text-white/80 text-sm">{petData.color} • {petData.marks || "ไม่มีตำหนิ"}</p>
                    </div>
                </div>

                {/* Status Card */}
                <StatusCard status={petData.status} />

                {/* Owner Actions */}
                {isOwner && petData.status !== 'REUNITED' && (
                    <div className="bg-white rounded-xl border shadow-sm p-5">
                        <h2 className="font-bold text-lg mb-3 text-gray-900">สำหรับเจ้าของ</h2>
                        <p className="text-sm text-gray-600 mb-4">หากคุณพบสัตว์เลี้ยงของคุณแล้ว กรุณากดยืนยันเพื่อปิดเคส</p>
                        <button
                            onClick={handleConfirmFound}
                            disabled={updating}
                            className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-xl shadow-lg shadow-green-200 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                        >
                            {updating ? (
                                <Loader2 className="w-5 h-5 animate-spin" />
                            ) : (
                                <CheckCircle className="w-5 h-5" />
                            )}
                            ยืนยันว่าพบแล้ว (ปิดเคส)
                        </button>
                    </div>
                )}

                {/* Timeline */}
                <Timeline petData={petData} />

                {/* Info Note */}
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-sm text-blue-800">
                    <p className="flex gap-2">
                        <ShieldQuestion className="w-5 h-5 shrink-0" />
                        <span>
                            ข้อมูลในหน้านี้เป็นข้อมูลล่าสุดที่ระบบได้รับ หากมีเบาะแสเพิ่มเติม กรุณาติดต่อเจ้าของโดยตรง
                        </span>
                    </p>
                </div>

                {/* Chat Section */}
                <div className="space-y-3">
                    <h2 className="font-bold text-lg text-gray-900">สอบถาม/แจ้งเบาะแส</h2>
                    {currentUser ? (
                        <PetComments
                            petId={id}
                            userId={currentUser.uid}
                            role={isOwner ? 'owner' : 'finder'}
                        />
                    ) : (
                        <div className="bg-white p-6 rounded-xl border shadow-sm text-center">
                            <p className="text-gray-600 mb-4">กรุณาเข้าสู่ระบบเพื่อส่งข้อความถึงเจ้าของ</p>
                            <Link href="/login">
                                <ThaiButton>เข้าสู่ระบบ</ThaiButton>
                            </Link>
                        </div>
                    )}
                </div>

                {/* Contact Info */}
                <div className="bg-white rounded-xl border shadow-sm p-5 space-y-3">
                    <h2 className="font-bold text-lg text-gray-900 flex items-center gap-2">
                        <User className="w-5 h-5 text-blue-600" />
                        ข้อมูลติดต่อเจ้าของ
                    </h2>
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl">
                            {petData.owner_name?.[0] || "U"}
                        </div>
                        <div>
                            <p className="font-bold text-lg">{petData.owner_name || "ไม่ระบุชื่อ"}</p>
                            {petData.contact_info && (
                                <a href={`tel:${petData.contact_info}`} className="text-blue-600 flex items-center gap-1 hover:underline">
                                    <Phone className="w-4 h-4" />
                                    {petData.contact_info}
                                </a>
                            )}
                        </div>
                    </div>
                </div>

                {/* Description */}
                <div className="bg-white rounded-xl border shadow-sm p-5">
                    <h2 className="font-bold text-lg mb-2 text-gray-900">รายละเอียดเพิ่มเติม</h2>
                    <p className="text-gray-700 whitespace-pre-wrap">{petData.description || "ไม่มีรายละเอียด"}</p>

                    {petData.last_seen_at && (
                        <div className="mt-4 pt-4 border-t border-gray-100 text-sm text-gray-500 flex items-center gap-2">
                            <Clock className="w-4 h-4" />
                            <span>หายเมื่อ: {format(new Date(petData.last_seen_at), "d MMM yyyy HH:mm", { locale: th })}</span>
                        </div>
                    )}
                </div>

            </main>
        </div>
    );
}

function StatusCard({ status }: { status: string }) {
    let color = "bg-gray-100 text-gray-700";
    let Icon = ShieldQuestion;
    let label = "ไม่ทราบสถานะ";
    let desc = "กำลังรอการตรวจสอบ";

    if (status === "REUNITED") {
        color = "bg-green-100 text-green-700 border-green-200";
        Icon = ShieldCheck;
        label = "พบแล้ว / ปลอดภัย";
        desc = "สัตว์เลี้ยงได้กลับคืนสู่เจ้าของแล้ว";
    } else if (status === "LOST") {
        color = "bg-red-100 text-red-700 border-red-200";
        Icon = ShieldAlert;
        label = "กำลังตามหา";
        desc = "ต้องการความช่วยเหลือในการตามหา";
    } else if (status === "FOUND") {
        color = "bg-yellow-100 text-yellow-700 border-yellow-200";
        Icon = Clock;
        label = "พบเบาะแส";
        desc = "มีผู้พบเห็นและแจ้งเข้ามาในระบบ";
    }

    return (
        <div className={`rounded-xl border p-5 ${color}`}>
            <div className="flex items-start justify-between mb-2">
                <h2 className="font-bold text-lg">สถานะปัจจุบัน</h2>
                <Icon className="w-6 h-6" />
            </div>
            <div className="text-2xl font-bold mb-1">{label}</div>
            <p className="opacity-90">{desc}</p>
        </div>
    );
}

function Timeline({ petData }: { petData: any }) {
    // Construct timeline events
    const events = [
        {
            id: "created",
            message: "ประกาศตามหาสัตว์เลี้ยง",
            created_at: petData.created_at,
            type: "start"
        }
    ];

    if (petData.status === 'REUNITED') {
        events.push({
            id: "reunited",
            message: "เจ้าของยืนยันว่าพบสัตว์เลี้ยงแล้ว",
            created_at: new Date().toISOString(), // In a real app, this should be from a separate events table or updated_at
            type: "end"
        });
    }

    // Sort by date desc
    events.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    return (
        <div className="bg-white rounded-xl border shadow-sm p-5">
            <h2 className="font-bold text-lg mb-4 text-gray-900">ไทม์ไลน์เหตุการณ์</h2>
            <div className="space-y-6">
                {events.map((event) => (
                    <div key={event.id} className="flex gap-4">
                        <div className="flex flex-col items-center">
                            <div className="text-xs font-bold text-gray-500 w-12 text-right">
                                {format(new Date(event.created_at), "HH:mm")}
                            </div>
                        </div>
                        <div className="flex-1 pb-2 border-l-2 border-gray-100 pl-4 relative">
                            <div className={`absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full border-2 border-white ${event.type === 'end' ? 'bg-green-500' : 'bg-gray-300'
                                }`} />
                            <p className="text-gray-900 text-sm">{event.message}</p>
                            <p className="text-xs text-gray-400 mt-1">
                                {format(new Date(event.created_at), "d MMM yyyy", { locale: th })}
                            </p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
