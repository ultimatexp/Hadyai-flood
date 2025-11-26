"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { enrollFamilyMember } from "@/app/actions/family";
import { Loader2, UserPlus, ShieldCheck } from "lucide-react";

function FamilyEnrollContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const caseId = searchParams.get("caseId");
    const token = searchParams.get("token");

    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    const [name, setName] = useState("");
    const [relationship, setRelationship] = useState("");

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            if (!currentUser) {
                // Redirect to login if not authenticated
                const redirect = `/family/enroll?caseId=${caseId}&token=${token}`;
                router.push(`/family/login?redirect=${encodeURIComponent(redirect)}`);
            } else {
                setUser(currentUser);
                setLoading(false);
            }
        });
        return () => unsubscribe();
    }, [router, caseId, token]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!user || !caseId) return;

        setSubmitting(true);
        const result = await enrollFamilyMember(
            user.uid,
            caseId,
            name,
            relationship,
            user.phoneNumber || undefined
        );

        if (result.success) {
            router.push(`/case/${caseId}/family?token=${token}`);
        } else {
            alert("เกิดข้อผิดพลาด: " + result.error);
            setSubmitting(false);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
            <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
                <div className="bg-blue-600 p-6 text-center">
                    <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                        <UserPlus className="w-8 h-8 text-white" />
                    </div>
                    <h1 className="text-2xl font-bold text-white">ลงทะเบียนติดตามเคส</h1>
                    <p className="text-blue-100 mt-2">กรุณาระบุข้อมูลเพื่อยืนยันตัวตน</p>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">ชื่อ-นามสกุล ของคุณ</label>
                        <input
                            type="text"
                            required
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none"
                            placeholder="เช่น สมชาย ใจดี"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">ความเกี่ยวข้องกับผู้ประสบภัย</label>
                        <select
                            required
                            value={relationship}
                            onChange={(e) => setRelationship(e.target.value)}
                            className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none bg-white"
                        >
                            <option value="">-- กรุณาเลือก --</option>
                            <option value="พ่อ/แม่">พ่อ/แม่</option>
                            <option value="ลูก">ลูก</option>
                            <option value="พี่/น้อง">พี่/น้อง</option>
                            <option value="ญาติ">ญาติ</option>
                            <option value="เพื่อน">เพื่อน</option>
                            <option value="อื่นๆ">อื่นๆ</option>
                        </select>
                    </div>

                    <div className="pt-4">
                        <button
                            type="submit"
                            disabled={submitting}
                            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-xl transition-colors flex items-center justify-center gap-2"
                        >
                            {submitting ? (
                                <Loader2 className="w-5 h-5 animate-spin" />
                            ) : (
                                <ShieldCheck className="w-5 h-5" />
                            )}
                            ยืนยันและเข้าดูข้อมูล
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

export default function FamilyEnrollPage() {
    return (
        <Suspense fallback={
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
        }>
            <FamilyEnrollContent />
        </Suspense>
    );
}
