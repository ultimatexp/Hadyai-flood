"use client";

import React, { useEffect, useState } from "react";
import { useParams, useSearchParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { getFamilyCase, checkEnrollment, addOffer } from "@/app/actions/family";
import { Loader2, ShieldCheck, ShieldAlert, ShieldQuestion, Clock, MapPin, Phone, User, Gift } from "lucide-react";
import { format } from "date-fns";
import { th } from "date-fns/locale";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter } from "next/navigation";
import CaseComments from "@/components/case/case-comments";
import VolunteerTip from "@/components/case/volunteer-tip";

export default function FamilyCasePage() {
    const router = useRouter();
    const params = useParams();
    const searchParams = useSearchParams();
    const id = params?.id as string;
    const token = searchParams.get("token");

    const [caseData, setCaseData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [offerAmount, setOfferAmount] = useState<string>("");
    const [savingOffer, setSavingOffer] = useState(false);
    const [offerSuccess, setOfferSuccess] = useState(false);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (!currentUser) {
                // Redirect to login
                const redirect = `/case/${id}/family?token=${token}`;
                router.push(`/family/login?redirect=${encodeURIComponent(redirect)}`);
            } else {
                // Check enrollment
                const enrollment = await checkEnrollment(currentUser.uid, id);
                if (!enrollment.enrolled) {
                    // Redirect to enroll
                    router.push(`/family/enroll?caseId=${id}&token=${token}`);
                } else {
                    fetchData();
                }
            }
        });
        return () => unsubscribe();
    }, [id, token, router]);

    const fetchData = async () => {
        if (!id || !token) return;
        const result = await getFamilyCase(id, token);
        if (result.success) {
            setCaseData(result.data);
            // Set existing offer amount if available
            if (result.data.case_offers && result.data.case_offers.length > 0) {
                setOfferAmount(result.data.case_offers[0].amount.toString());
            }
        } else {
            setError(result.error || "Failed to load case");
        }
        setLoading(false);
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
        );
    }

    if (error || !caseData) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
                <div className="bg-white p-6 rounded-xl shadow-lg max-w-md w-full text-center">
                    <ShieldAlert className="w-12 h-12 text-red-500 mx-auto mb-4" />
                    <h1 className="text-xl font-bold text-gray-900 mb-2">ไม่สามารถเข้าถึงข้อมูลได้</h1>
                    <p className="text-gray-600">{error || "ลิงก์ไม่ถูกต้องหรือหมดอายุ"}</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50 pb-12">
            {/* Header */}
            <header className="bg-white shadow-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 py-4">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary">
                            <User className="w-6 h-6" />
                        </div>
                        <div>
                            <h1 className="font-bold text-lg text-gray-900 leading-tight">
                                {caseData.reporter_name}
                            </h1>
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <MapPin className="w-3 h-3" />
                                <span className="truncate max-w-[200px]">{caseData.address_text || "ไม่ระบุพิกัด"}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            <main className="container mx-auto px-4 py-6 max-w-lg space-y-6">
                {/* Safety Status Card */}
                <SafetyStatusCard status={caseData.urgency_level} statusText={caseData.status} />

                {/* Rescue Status Card */}
                <RescueStatusCard
                    status={caseData.status}
                    resolutionPhotos={caseData.photos?.filter((p: any) => p.type === 'resolved') || []}
                />

                {/* Timeline */}
                <Timeline events={caseData.case_events || []} createdAt={caseData.created_at} />

                {/* Info Note */}
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-sm text-blue-800">
                    <p className="flex gap-2">
                        <ShieldQuestion className="w-5 h-5 shrink-0" />
                        <span>
                            ข้อมูลในหน้านี้เป็นข้อมูลล่าสุดที่ระบบได้รับ อาจมีความล่าช้าจากสถานการณ์จริง
                        </span>
                    </p>
                </div>

                {/* Volunteer Info */}
                {
                    caseData.rescuer && (
                        <div className="bg-white rounded-xl border shadow-sm p-5 space-y-3">
                            <h2 className="font-bold text-lg text-gray-900 flex items-center gap-2">
                                <User className="w-5 h-5 text-blue-600" />
                                อาสาที่ดูแลเคสนี้
                            </h2>
                            <div className="flex items-center gap-4">
                                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl">
                                    {caseData.rescuer.name?.[0] || "A"}
                                </div>
                                <div>
                                    <p className="font-bold text-lg">{caseData.rescuer.name || "ไม่ระบุชื่อ"}</p>
                                    {caseData.rescuer.phone_number && (
                                        <a href={`tel:${caseData.rescuer.phone_number}`} className="text-blue-600 flex items-center gap-1 hover:underline">
                                            <Phone className="w-4 h-4" />
                                            {caseData.rescuer.phone_number}
                                        </a>
                                    )}
                                </div>
                            </div>
                        </div>
                    )
                }

                {/* Chat Section */}
                <div className="space-y-3">
                    <h2 className="font-bold text-lg text-gray-900">สอบถาม/ติดต่ออาสา</h2>
                    {auth.currentUser && (
                        <CaseComments
                            caseId={id}
                            userId={auth.currentUser.uid}
                            role="member"
                        />
                    )}
                </div>

                {/* Offer Section */}
                <div className="bg-white rounded-xl border shadow-sm p-6">
                    <h2 className="font-bold text-lg text-gray-900 mb-4 flex items-center gap-2">
                        <Gift className="w-5 h-5 text-yellow-600" />
                        สินน้ำใจสำหรับอาสา
                    </h2>
                    <p className="text-sm text-gray-600 mb-4">
                        เพิ่มสินน้ำใจเพื่อแสดงความขอบคุณต่อผู้ช่วยเหลือ (จำนวนเงินจะแสดงให้อาสาเห็นบนแผนที่)
                    </p>
                    <div className="flex gap-3">
                        <div className="flex-1">
                            <input
                                type="number"
                                value={offerAmount}
                                onChange={(e) => setOfferAmount(e.target.value)}
                                placeholder="กรอกจำนวนเงิน (บาท)"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-yellow-500"
                            />
                        </div>
                        <button
                            onClick={async () => {
                                if (!offerAmount || parseFloat(offerAmount) <= 0) {
                                    alert("กรุณากรอกจำนวนเงินที่ถูกต้อง");
                                    return;
                                }
                                setSavingOffer(true);
                                setOfferSuccess(false);
                                const result = await addOffer(id, parseFloat(offerAmount), token!);
                                setSavingOffer(false);
                                if (result.success) {
                                    setOfferSuccess(true);
                                    setTimeout(() => setOfferSuccess(false), 3000);
                                } else {
                                    alert("เกิดข้อผิดพลาด: " + result.error);
                                }
                            }}
                            disabled={savingOffer}
                            className="px-6 py-2 bg-yellow-600 hover:bg-yellow-700 text-white font-bold rounded-lg transition-colors disabled:opacity-50"
                        >
                            {savingOffer ? "กำลังบันทึก..." : offerAmount && parseFloat(offerAmount) > 0 && caseData.case_offers?.length > 0 ? "อัปเดต" : "เพิ่ม"}
                        </button>
                    </div>
                    {offerSuccess && (
                        <div className="mt-3 text-sm text-green-600 font-medium">
                            ✓ บันทึกสินน้ำใจเรียบร้อยแล้ว
                        </div>
                    )}
                    {caseData.case_offers && caseData.case_offers.length > 0 && (
                        <div className="mt-3 text-sm text-gray-600">
                            สินน้ำใจปัจจุบัน: <span className="font-bold text-yellow-600">{caseData.case_offers[0].amount.toLocaleString()} บาท</span>
                        </div>
                    )}
                </div>

                {/* Volunteer Tip Section */}
                {caseData.status === 'RESOLVED' && caseData.rescuer?.promptpay_number && (
                    <VolunteerTip
                        caseId={id}
                        volunteerId={caseData.rescuer.user_id} // Assuming rescuer object has user_id, need to verify
                        volunteerName={caseData.rescuer.name}
                        promptpayNumber={caseData.rescuer.promptpay_number}
                    />
                )}
            </main >
        </div >
    );
}

function SafetyStatusCard({ status, statusText }: { status: number, statusText: string }) {
    // Map urgency level to safety status
    // 1 = Critical (Red)
    // 2 = High (Orange)
    // 3 = Medium (Yellow/Green - Safe Enough?)

    let color = "bg-gray-100 text-gray-700";
    let Icon = ShieldQuestion;
    let label = "ไม่ทราบสถานะ";
    let desc = "กำลังรอการตรวจสอบ";

    if (statusText === "RESOLVED") {
        color = "bg-green-100 text-green-700 border-green-200";
        Icon = ShieldCheck;
        label = "ปลอดภัยแล้ว";
        desc = "ได้รับการช่วยเหลือหรืออยู่ในพื้นที่ปลอดภัย";
    } else if (status === 1) {
        color = "bg-red-100 text-red-700 border-red-200";
        Icon = ShieldAlert;
        label = "ความเสี่ยงสูง";
        desc = "ต้องการความช่วยเหลือเร่งด่วน";
    } else if (status === 2) {
        color = "bg-orange-100 text-orange-700 border-orange-200";
        Icon = ShieldAlert;
        label = "ความเสี่ยงปานกลาง";
        desc = "รอการช่วยเหลือ";
    } else if (status === 3) {
        color = "bg-yellow-100 text-yellow-700 border-yellow-200";
        Icon = Clock;
        label = "ความเสี่ยงต่ำ / พอรอได้";
        desc = "อยู่ในพื้นที่ที่ยังพอปลอดภัย";
    }

    return (
        <div className={`rounded-xl border p-5 ${color}`}>
            <div className="flex items-start justify-between mb-2">
                <h2 className="font-bold text-lg">สถานะความปลอดภัย</h2>
                <Icon className="w-6 h-6" />
            </div>
            <div className="text-2xl font-bold mb-1">{label}</div>
            <p className="opacity-90">{desc}</p>
        </div>
    );
}

function RescueStatusCard({ status, resolutionPhotos }: { status: string; resolutionPhotos?: any[] }) {
    const isResolved = status === "RESOLVED";
    const isInProgress = status === "IN_PROGRESS";

    return (
        <div className="bg-white rounded-xl border shadow-sm p-5">
            <h2 className="font-bold text-lg mb-4 text-gray-900">สถานะการช่วยเหลือ</h2>

            <div className="space-y-4">
                <Step
                    active={true}
                    completed={true}
                    label="ได้รับแจ้งเหตุแล้ว"
                    time="ระบบได้รับข้อมูลแล้ว"
                />
                <Step
                    active={isInProgress || isResolved}
                    completed={isInProgress || isResolved}
                    label="กำลังดำเนินการ / ประสานงาน"
                    time={isInProgress ? "เจ้าหน้าที่กำลังดำเนินการ" : "รอการตอบรับ"}
                />
                <Step
                    active={isResolved}
                    completed={isResolved}
                    label="ช่วยเหลือสำเร็จ / ปลอดภัย"
                    time={isResolved ? "ยืนยันความปลอดภัยแล้ว" : "รอการยืนยัน"}
                    last
                />
            </div>

            {/* Resolution Photos */}
            {isResolved && resolutionPhotos && resolutionPhotos.length > 0 && (
                <div className="mt-4 pt-4 border-t border-gray-100">
                    <p className="text-sm text-gray-600 mb-2">รูปภาพหลังช่วยเหลือ:</p>
                    <div className="flex gap-2 flex-wrap">
                        {resolutionPhotos.slice(0, 4).map((photo: any, index: number) => (
                            <img
                                key={index}
                                src={photo.url}
                                alt={`Resolution ${index + 1}`}
                                className="w-20 h-20 object-cover rounded-lg border border-gray-200 cursor-pointer hover:opacity-80 transition-opacity"
                                onClick={() => window.open(photo.url, '_blank')}
                            />
                        ))}
                        {resolutionPhotos.length > 4 && (
                            <div className="w-20 h-20 bg-gray-100 rounded-lg flex items-center justify-center text-gray-600 text-sm font-medium">
                                +{resolutionPhotos.length - 4}
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}

function Step({ active, completed, label, time, last }: any) {
    return (
        <div className="flex gap-4 relative">
            {!last && (
                <div className={`absolute left-[11px] top-8 bottom-[-16px] w-0.5 ${completed ? "bg-green-500" : "bg-gray-200"}`} />
            )}
            <div className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 z-10 ${completed ? "bg-green-500 text-white" : active ? "bg-blue-500 text-white" : "bg-gray-200"
                }`}>
                {completed ? <CheckIcon /> : <div className="w-2 h-2 bg-white rounded-full" />}
            </div>
            <div>
                <div className={`font-bold ${active || completed ? "text-gray-900" : "text-gray-400"}`}>{label}</div>
                <div className="text-xs text-gray-500">{time}</div>
            </div>
        </div>
    );
}

function CheckIcon() {
    return (
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
        </svg>
    );
}

function Timeline({ events, createdAt }: { events: any[], createdAt: string }) {
    // Combine creation time with events
    const allEvents = [
        {
            id: "created",
            event_type: "SOS_CREATED",
            message: "แจ้งขอความช่วยเหลือเข้ามาในระบบ",
            created_at: createdAt
        },
        ...events
    ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    return (
        <div className="bg-white rounded-xl border shadow-sm p-5">
            <h2 className="font-bold text-lg mb-4 text-gray-900">ไทม์ไลน์เหตุการณ์</h2>
            <div className="space-y-6">
                {allEvents.map((event, index) => (
                    <div key={event.id} className="flex gap-4">
                        <div className="flex flex-col items-center">
                            <div className="text-xs font-bold text-gray-500 w-12 text-right">
                                {format(new Date(event.created_at), "HH:mm")}
                            </div>
                        </div>
                        <div className="flex-1 pb-2 border-l-2 border-gray-100 pl-4 relative">
                            <div className="absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full bg-gray-300 border-2 border-white" />
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
