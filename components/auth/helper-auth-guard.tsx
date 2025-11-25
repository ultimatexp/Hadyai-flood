"use client";

import { useEffect, useState } from "react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { useRouter, usePathname } from "next/navigation";
import { Loader2 } from "lucide-react";

export default function HelperAuthGuard({ children }: { children: React.ReactNode }) {
    const [loading, setLoading] = useState(true);
    const [authenticated, setAuthenticated] = useState(false);
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            if (user) {
                setAuthenticated(true);
            } else {
                setAuthenticated(false);
                // Redirect to login if not on login page
                if (pathname !== "/helper/login") {
                    router.push("/helper/login");
                }
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, [pathname, router]);

    // Allow access to login page without auth
    if (pathname === "/helper/login") {
        return <>{children}</>;
    }

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="text-center">
                    <Loader2 className="w-10 h-10 animate-spin text-blue-600 mx-auto mb-4" />
                    <p className="text-gray-500">กำลังตรวจสอบสิทธิ์...</p>
                </div>
            </div>
        );
    }

    if (!authenticated) {
        return null; // Will redirect in useEffect
    }

    return <>{children}</>;
}
