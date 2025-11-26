"use client";

import HelperView from "@/components/helper";
import { ThaiButton } from "@/components/ui/thai-button";
import { ChevronLeft, User } from "lucide-react";
import Link from "next/link";
import { LogoutButton } from "@/components/auth/logout-button";
import { useState, useEffect } from "react";
import { auth } from "@/lib/firebase";

export default function HelperPage() {
    const [userName, setUserName] = useState<string>("");

    useEffect(() => {
        const fetchProfile = async () => {
            if (auth.currentUser) {
                const { getUserProfile } = await import("@/app/actions/auth");
                const profile = await getUserProfile(auth.currentUser.uid);
                if (profile.success && profile.data?.name) {
                    setUserName(profile.data.name);
                }
            }
        };
        fetchProfile();
    }, []);

    return (
        <div className="min-h-screen bg-background flex flex-col">
            <header className="bg-background/80 backdrop-blur-md border-b p-4 flex items-center gap-4 z-10">
                <Link href="/">
                    <ThaiButton variant="ghost" size="sm" className="px-2">
                        <ChevronLeft className="w-6 h-6" />
                    </ThaiButton>
                </Link>
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600">
                        <User className="w-6 h-6" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold">อาสาช่วยเหลือ</h1>
                        {userName && <p className="text-xs text-gray-500">สวัสดี, {userName}</p>}
                    </div>
                </div>
                <div className="ml-auto">
                    <LogoutButton />
                </div>
            </header>

            <main className="flex-1 relative">
                <HelperView />
            </main>
        </div>
    );
}
