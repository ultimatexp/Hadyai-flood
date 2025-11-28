"use client";

import PhoneLogin from "@/components/auth/phone-login";
import Link from "next/link";
import { ChevronLeft, Users, Heart } from "lucide-react";
import { useEffect, useState } from "react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter } from "next/navigation";

export default function LoginPage() {
    const router = useRouter();
    const [selectedRole, setSelectedRole] = useState<'member' | 'volunteer' | null>(null);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (user && selectedRole) {
                const { syncUserRole, updateUserProfile } = await import("@/app/actions/auth");

                if (user.isAnonymous) {
                    // Admin Login: Auto-set name to skip onboarding
                    await updateUserProfile(user.uid, { name: "Administrator" });
                }

                // Sync role based on selection
                await syncUserRole(user.uid, selectedRole);

                // Redirect based on role
                if (selectedRole === 'volunteer') {
                    router.push("/helper");
                } else {
                    router.push("/");
                }
            }
        });
        return () => unsubscribe();
    }, [router, selectedRole]);

    return (
        <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-blue-50 flex flex-col items-center justify-center p-4">
            <Link href="/" className="absolute top-6 left-6 text-gray-500 hover:text-gray-800 transition-colors flex items-center gap-1">
                <ChevronLeft className="w-5 h-5" />

            </Link>

            <div className="w-full max-w-md">
                {!selectedRole ? (
                    // Role Selection Screen
                    <div className="text-center">
                        <div className="mb-8">
                            <h1 className="text-4xl font-bold text-gray-900 mb-2">ยินดีต้อนรับ</h1>
                            <p className="text-gray-500">เลือกประเภทการเข้าใช้งาน</p>
                        </div>

                        <div className="space-y-4">
                            {/* Member Option */}
                            <button
                                onClick={() => setSelectedRole('member')}
                                className="w-full bg-white p-6 rounded-2xl shadow-lg hover:shadow-xl transition-all border-2 border-gray-100 hover:border-orange-300 group"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-16 h-16 bg-orange-100 rounded-xl flex items-center justify-center group-hover:bg-orange-200 transition-colors">
                                        <Users className="w-8 h-8 text-orange-600" />
                                    </div>
                                    <div className="text-left flex-1">
                                        <h3 className="text-xl font-bold text-gray-900">สมาชิกทั่วไป</h3>
                                        <p className="text-sm text-gray-500 mt-1">แจ้งสัตว์หาย / ค้นหาสัตว์</p>
                                    </div>
                                </div>
                            </button>

                            {/* Volunteer Option */}
                            <button
                                onClick={() => setSelectedRole('volunteer')}
                                className="w-full bg-white p-6 rounded-2xl shadow-lg hover:shadow-xl transition-all border-2 border-gray-100 hover:border-blue-300 group"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-16 h-16 bg-blue-100 rounded-xl flex items-center justify-center group-hover:bg-blue-200 transition-colors">
                                        <Heart className="w-8 h-8 text-blue-600" />
                                    </div>
                                    <div className="text-left flex-1">
                                        <h3 className="text-xl font-bold text-gray-900">อาสาสมัคร</h3>
                                        <p className="text-sm text-gray-500 mt-1">ช่วยเหลือและบริหารจัดการ</p>
                                    </div>
                                </div>
                            </button>
                        </div>
                    </div>
                ) : (
                    // Phone Login Screen
                    <div>
                        <button
                            onClick={() => setSelectedRole(null)}
                            className="mb-6 text-gray-500 hover:text-gray-800 transition-colors flex items-center gap-1"
                        >
                            <ChevronLeft className="w-5 h-5" />
                            เปลี่ยนประเภทผู้ใช้
                        </button>

                        <div className="text-center mb-8">
                            <div className={`w-16 h-16 ${selectedRole === 'volunteer' ? 'bg-blue-600' : 'bg-orange-500'} rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg`}>
                                {selectedRole === 'volunteer' ? (
                                    <Heart className="w-8 h-8 text-white" />
                                ) : (
                                    <Users className="w-8 h-8 text-white" />
                                )}
                            </div>
                            <h1 className="text-3xl font-bold text-gray-900">
                                {selectedRole === 'volunteer' ? 'อาสาช่วยเหลือ' : 'สมาชิกทั่วไป'}
                            </h1>
                            <p className="text-gray-500 mt-2">
                                {selectedRole === 'volunteer'
                                    ? 'ระบบสำหรับอาสาสมัครและเจ้าหน้าที่'
                                    : 'เข้าสู่ระบบด้วยเบอร์โทรศัพท์'}
                            </p>
                        </div>

                        <PhoneLogin minimal onSuccess={() => { }} />
                    </div>
                )}
            </div>
        </div>
    );
}
