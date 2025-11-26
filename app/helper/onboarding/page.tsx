"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { ThaiButton } from "@/components/ui/thai-button";
import { Loader2, User, CreditCard } from "lucide-react";
import { updateUserProfile } from "@/app/actions/auth";

export default function HelperOnboardingPage() {
    const [loading, setLoading] = useState(false);
    const [name, setName] = useState("");
    const [promptpay, setPromptpay] = useState("");
    const [userId, setUserId] = useState<string | null>(null);
    const router = useRouter();

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            if (user) {
                setUserId(user.uid);
            } else {
                router.push("/helper/login");
            }
        });
        return () => unsubscribe();
    }, [router]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!userId || !name.trim()) return;

        setLoading(true);
        try {
            const result = await updateUserProfile(userId, {
                name: name.trim(),
                promptpay_number: promptpay.trim() || undefined
            });

            if (result.success) {
                router.push("/helper");
            } else {
                alert("เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง");
            }
        } catch (error) {
            console.error(error);
            alert("เกิดข้อผิดพลาด");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
            <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-6">
                <div className="text-center mb-8">
                    <h1 className="text-2xl font-bold text-gray-900">ข้อมูลอาสาสมัคร</h1>
                    <p className="text-gray-500 mt-2">กรุณากรอกข้อมูลเพื่อเริ่มใช้งาน</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700">ชื่อ-นามสกุล (Required)</label>
                        <div className="relative">
                            <User className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                placeholder="สมชาย ใจดี"
                                className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition-all"
                                required
                            />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700">เบอร์พร้อมเพย์ (Optional)</label>
                        <div className="relative">
                            <CreditCard className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                value={promptpay}
                                onChange={(e) => setPromptpay(e.target.value)}
                                placeholder="08x-xxx-xxxx"
                                className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition-all"
                            />
                        </div>
                        <p className="text-xs text-gray-500">สำหรับรับเงินสนับสนุนค่าเดินทาง/อาหาร (ถ้ามี)</p>
                    </div>

                    <ThaiButton
                        type="submit"
                        disabled={loading}
                        className="w-full h-12 text-lg shadow-blue-600/20"
                    >
                        {loading ? (
                            <Loader2 className="w-6 h-6 animate-spin" />
                        ) : (
                            "บันทึกข้อมูล"
                        )}
                    </ThaiButton>
                </form>
            </div>
        </div>
    );
}
