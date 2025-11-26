"use client";

import PhoneLogin from "@/components/auth/phone-login";
import Link from "next/link";
import { ChevronLeft } from "lucide-react";
import { useEffect } from "react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter } from "next/navigation";

export default function HelperLoginPage() {
    const router = useRouter();

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (user) {
                const { syncUserRole, updateUserProfile } = await import("@/app/actions/auth");

                if (user.isAnonymous) {
                    // Admin Login: Auto-set name to skip onboarding
                    await updateUserProfile(user.uid, { name: "Administrator" });
                }

                // Sync role as 'volunteer' for both Admin and Volunteers
                await syncUserRole(user.uid, "volunteer");
                router.push("/helper");
            }
        });
        return () => unsubscribe();
    }, [router]);

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-4">
            <Link href="/" className="absolute top-6 left-6 text-gray-500 hover:text-gray-800 transition-colors flex items-center gap-1">
                <ChevronLeft className="w-5 h-5" />
                กลับหน้าหลัก
            </Link>

            <div className="w-full max-w-md">
                <div className="text-center mb-8">
                    <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-blue-600/20">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-8 h-8 text-white">
                            <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
                        </svg>
                    </div>
                    <h1 className="text-3xl font-bold text-gray-900">อาสาช่วยเหลือ</h1>
                    <p className="text-gray-500 mt-2">ระบบสำหรับอาสาสมัครและเจ้าหน้าที่</p>
                </div>

                <PhoneLogin minimal onSuccess={() => { }} />
            </div>
        </div>
    );
}
