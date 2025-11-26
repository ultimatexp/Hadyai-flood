"use client";

import PhoneLogin from "@/components/auth/phone-login";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, Suspense } from "react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { Loader2 } from "lucide-react";

function FamilyLoginContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const redirectUrl = searchParams.get("redirect") || "/family";

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (user) {
                // Sync role as 'member'
                const { syncUserRole } = await import("@/app/actions/auth");
                await syncUserRole(user.uid, "member");
                router.push(redirectUrl);
            }
        });
        return () => unsubscribe();
    }, [router, redirectUrl]);

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
            <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
                <div className="bg-blue-600 p-6 text-center">
                    <h1 className="text-2xl font-bold text-white">เข้าสู่ระบบสำหรับญาติ</h1>
                    <p className="text-blue-100 mt-2">ติดตามสถานะคนในครอบครัว</p>
                </div>
                <div className="p-6">
                    <PhoneLogin minimal onSuccess={() => router.push(redirectUrl)} />
                </div>
            </div>
        </div>
    );
}

export default function FamilyLoginPage() {
    return (
        <Suspense fallback={
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
        }>
            <FamilyLoginContent />
        </Suspense>
    );
}
