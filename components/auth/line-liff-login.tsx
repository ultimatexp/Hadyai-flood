"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { auth } from "@/lib/firebase";
import { signInWithCustomToken } from "firebase/auth";
import { ThaiButton } from "@/components/ui/thai-button";
import { Loader2, AlertCircle } from "lucide-react";

interface LineLiffLoginProps {
    minimal?: boolean;
    onSuccess?: () => void;
    /** Optional staff login using ADMIN_WEB_PASSWORD (server) + Firebase custom token */
    showStaffGate?: boolean;
}

export default function LineLiffLogin({
    minimal = false,
    onSuccess,
    showStaffGate = false,
}: LineLiffLoginProps) {
    const liffId = process.env.NEXT_PUBLIC_LINE_LIFF_ID;
    const configuredRedirectUri = process.env.NEXT_PUBLIC_LINE_LOGIN_REDIRECT_URI?.trim();
    const onSuccessRef = useRef(onSuccess);
    onSuccessRef.current = onSuccess;
    const [error, setError] = useState("");
    const [initError, setInitError] = useState("");
    const [ready, setReady] = useState(false);
    const [loading, setLoading] = useState(false);
    const [staffOpen, setStaffOpen] = useState(false);
    const [staffPassword, setStaffPassword] = useState("");

    const exchangeAndSignIn = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const liff = (await import("@line/liff")).default;
            const idToken = await liff.getIDToken();
            const res = await fetch("/api/auth/line-custom-token", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ idToken }),
            });
            const data = (await res.json()) as {
                customToken?: string;
                profile?: { name?: string | null };
                error?: string;
            };
            if (!res.ok || !data.customToken) {
                throw new Error(data.error || "เข้าสู่ระบบไม่สำเร็จ");
            }

            await signInWithCustomToken(auth, data.customToken);

            const name = data.profile?.name;
            if (name) {
                try {
                    const { updateUserProfile } = await import("@/app/actions/auth");
                    const user = auth.currentUser;
                    if (user) await updateUserProfile(user.uid, { name: String(name) });
                } catch {
                    // profile sync is optional
                }
            }

            onSuccessRef.current?.();
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : "เข้าสู่ระบบไม่สำเร็จ");
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        let cancelled = false;
        (async () => {
            if (!liffId) {
                setInitError("ตั้งค่า NEXT_PUBLIC_LINE_LIFF_ID ในระบบ");
                return;
            }
            try {
                const liff = (await import("@line/liff")).default;
                await liff.init({ liffId });
                if (cancelled) return;
                setReady(true);
                if (liff.isLoggedIn()) {
                    await exchangeAndSignIn();
                }
            } catch (e: unknown) {
                if (!cancelled) {
                    setInitError(e instanceof Error ? e.message : "LIFF init failed");
                }
            }
        })();
        return () => {
            cancelled = true;
        };
    }, [liffId, exchangeAndSignIn]);

    const handleLineClick = async () => {
        if (!liffId) return;
        setError("");
        const liff = (await import("@line/liff")).default;
        if (!liff.isLoggedIn()) {
            let redirectUri: string | undefined = undefined;
            if (configuredRedirectUri) {
                redirectUri = configuredRedirectUri;
            } else if (typeof window !== "undefined") {
                redirectUri = `${window.location.origin}${window.location.pathname}${window.location.search}`;
            }
            liff.login({ redirectUri: redirectUri ?? undefined });
            return;
        }
        await exchangeAndSignIn();
    };

    const handleStaffSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError("");
        try {
            const { createAdminConsoleCustomToken } = await import("@/app/actions/admin-auth");
            const result = await createAdminConsoleCustomToken(staffPassword);
            if (!result.ok) {
                if (result.error === "not_configured") {
                    throw new Error("ยังไม่ตั้งค่ารหัสเจ้าหน้าที่บนเซิร์ฟเวอร์");
                }
                throw new Error("รหัสไม่ถูกต้อง");
            }
            await signInWithCustomToken(auth, result.customToken);
            onSuccessRef.current?.();
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : "เข้าสู่ระบบไม่สำเร็จ");
        } finally {
            setLoading(false);
        }
    };

    const content = (
        <>
            {error && (
                <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-xl flex items-start gap-3 text-red-600 text-sm">
                    <AlertCircle className="w-5 h-5 shrink-0" />
                    <p>{error}</p>
                </div>
            )}

            {initError ? (
                <p className="text-center text-sm text-red-600">{initError}</p>
            ) : (
                <ThaiButton
                    type="button"
                    onClick={handleLineClick}
                    disabled={!ready || loading || !liffId}
                    className="w-full h-12 text-lg shadow-green-600/20 bg-[#06C755] hover:bg-[#05b34c] text-white border-0"
                >
                    {loading ? (
                        <Loader2 className="w-6 h-6 animate-spin" />
                    ) : (
                        "เข้าสู่ระบบด้วย LINE"
                    )}
                </ThaiButton>
            )}

            {!initError && (
                <p className="text-center text-xs text-gray-500 mt-4">
                    รองรับการเปิดผ่าน LIFF ใน LINE และเบราว์เซอร์ทั่วไป
                </p>
            )}

            {showStaffGate && (
                <div className="mt-6 border-t border-gray-100 pt-4">
                    <button
                        type="button"
                        onClick={() => {
                            setStaffOpen((v) => !v);
                            setError("");
                        }}
                        className="w-full text-center text-gray-400 text-xs hover:text-gray-600 transition-colors"
                    >
                        เข้าแบบเจ้าหน้าที่ (รหัสพิเศษ)
                    </button>
                    {staffOpen && (
                        <form onSubmit={handleStaffSubmit} className="mt-4 space-y-3">
                            <input
                                type="password"
                                value={staffPassword}
                                onChange={(e) => setStaffPassword(e.target.value)}
                                placeholder="รหัสเจ้าหน้าที่"
                                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none text-sm"
                                autoComplete="current-password"
                            />
                            <ThaiButton type="submit" disabled={loading} className="w-full" variant="outline">
                                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : "เข้าสู่ระบบ"}
                            </ThaiButton>
                        </form>
                    )}
                </div>
            )}
        </>
    );

    if (minimal) {
        return <div className="w-full">{content}</div>;
    }

    return (
        <div className="w-full max-w-md mx-auto p-6 bg-white rounded-2xl shadow-xl border border-gray-100">
            {content}
        </div>
    );
}
