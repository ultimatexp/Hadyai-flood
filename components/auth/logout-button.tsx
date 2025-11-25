"use client";

import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";
import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";
import { ThaiButton } from "@/components/ui/thai-button";
import { useState } from "react";

export function LogoutButton() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);

    const handleLogout = async () => {
        try {
            setLoading(true);
            await signOut(auth);
            router.push("/");
            router.refresh();
        } catch (error) {
            console.error("Logout error:", error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <ThaiButton
            variant="ghost"
            size="sm"
            className="text-red-600 hover:text-red-700 hover:bg-red-50"
            onClick={handleLogout}
            isLoading={loading}
        >
            <LogOut className="w-4 h-4 mr-2" />
            ออกจากระบบ
        </ThaiButton>
    );
}
