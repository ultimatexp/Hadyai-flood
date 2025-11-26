"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { User, ChevronRight, Clock, LogOut } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { th } from "date-fns/locale";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { useRouter } from "next/navigation";
import { getEnrolledCases } from "@/app/actions/family";

export default function FamilyWatchlistPage() {
    const router = useRouter();
    const [watchlist, setWatchlist] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [user, setUser] = useState<any>(null);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (!currentUser) {
                router.push("/family/login");
            } else {
                setUser(currentUser);
                fetchCases(currentUser.uid);
            }
        });
        return () => unsubscribe();
    }, [router]);

    const fetchCases = async (uid: string) => {
        const result = await getEnrolledCases(uid);
        if (result.success) {
            setWatchlist(result.data || []);
        }
        setLoading(false);
    };

    const handleLogout = async () => {
        await signOut(auth);
        router.push("/family/login");
    };

    if (loading) {
        return <div className="min-h-screen flex items-center justify-center">Loading...</div>;
    }

    return (
        <div className="min-h-screen bg-gray-50 pb-12">
            <header className="bg-white shadow-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 py-4 flex justify-between items-center">
                    <h1 className="font-bold text-xl text-gray-900">เคสที่ติดตาม (My Family)</h1>
                    <button onClick={handleLogout} className="text-red-500 text-sm flex items-center gap-1">
                        <LogOut className="w-4 h-4" /> ออกจากระบบ
                    </button>
                </div>
            </header>

            <main className="container mx-auto px-4 py-6 max-w-lg">
                {watchlist.length === 0 ? (
                    <div className="text-center py-12">
                        <div className="w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-4 text-gray-400">
                            <User className="w-8 h-8" />
                        </div>
                        <h2 className="text-lg font-bold text-gray-900 mb-2">ยังไม่มีเคสที่ติดตาม</h2>
                        <p className="text-gray-500 text-sm max-w-xs mx-auto">
                            เมื่อคุณได้รับลิงก์ติดตามเคสและลงทะเบียนแล้ว รายการจะปรากฏที่นี่
                        </p>
                    </div>
                ) : (
                    <div className="space-y-3">
                        {watchlist.map((item) => (
                            <Link
                                key={item.id}
                                href={`/case/${item.id}/family?token=${item.family_token}`}
                                className="block bg-white rounded-xl border shadow-sm p-4 hover:shadow-md transition-shadow relative group"
                            >
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center text-blue-600 shrink-0">
                                            <User className="w-5 h-5" />
                                        </div>
                                        <div>
                                            <div className="font-bold text-gray-900">{item.reporter_name}</div>
                                            <div className="text-xs text-gray-500 flex items-center gap-1">
                                                <Clock className="w-3 h-3" />
                                                <span>
                                                    แจ้งเมื่อ {formatDistanceToNow(new Date(item.created_at), { addSuffix: true, locale: th })}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                    <ChevronRight className="w-5 h-5 text-gray-400" />
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </main>
        </div>
    );
}
