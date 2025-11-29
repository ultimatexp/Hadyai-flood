"use client";

import { useState, useEffect } from "react";
import { auth } from "@/lib/firebase";
import { RecaptchaVerifier, signInWithPhoneNumber, ConfirmationResult, signInAnonymously } from "firebase/auth";
import { useRouter } from "next/navigation";
import { ThaiButton } from "@/components/ui/thai-button";
import { Phone, Lock, Loader2, AlertCircle, KeyRound } from "lucide-react";

interface PhoneLoginProps {
    onSuccess?: () => void;
    minimal?: boolean;
}

export default function PhoneLogin({ onSuccess, minimal = false }: PhoneLoginProps) {
    const [phoneNumber, setPhoneNumber] = useState("");
    const [otp, setOtp] = useState("");
    const [step, setStep] = useState<"PHONE" | "OTP" | "ADMIN">("PHONE");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [confirmationResult, setConfirmationResult] = useState<ConfirmationResult | null>(null);
    const [adminPassword, setAdminPassword] = useState("");
    const router = useRouter();

    useEffect(() => {
        if (!window.recaptchaVerifier && step === "PHONE") {
            window.recaptchaVerifier = new RecaptchaVerifier(auth, "recaptcha-container", {
                size: "invisible",
                callback: () => {
                    // reCAPTCHA solved, allow signInWithPhoneNumber.
                },
            });
        }
    }, [step]);

    const handleSendOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        // Basic validation for Thai phone number
        // Remove leading 0 and add +66
        let formattedPhone = phoneNumber.replace(/\D/g, "");
        if (formattedPhone.startsWith("0")) {
            formattedPhone = "+66" + formattedPhone.substring(1);
        } else if (!formattedPhone.startsWith("66")) {
            formattedPhone = "+66" + formattedPhone;
        } else {
            formattedPhone = "+" + formattedPhone;
        }

        try {
            const appVerifier = window.recaptchaVerifier;
            const confirmation = await signInWithPhoneNumber(auth, formattedPhone, appVerifier);
            setConfirmationResult(confirmation);
            setStep("OTP");
        } catch (err: any) {
            console.error("Error sending OTP:", err);
            setError(err.message || "เกิดข้อผิดพลาดในการส่ง OTP กรุณาลองใหม่อีกครั้ง");
            // Reset recaptcha on error
            if (window.recaptchaVerifier) {
                window.recaptchaVerifier.clear();
                window.recaptchaVerifier = undefined;
            }
        } finally {
            setLoading(false);
        }
    };

    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        if (!confirmationResult) return;

        try {
            await confirmationResult.confirm(otp);
            // User signed in successfully.
            if (onSuccess) {
                onSuccess();
            } else {
                router.push("/helper");
            }
        } catch (err: any) {
            console.error("Error verifying OTP:", err);
            setError("รหัส OTP ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง");
        } finally {
            setLoading(false);
        }
    };

    const handleAdminLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        if (adminPassword === "DietDoctor70350@") {
            try {
                await signInAnonymously(auth);
                if (onSuccess) {
                    onSuccess();
                } else {
                    router.push("/helper");
                }
            } catch (err: any) {
                console.error("Error signing in anonymously:", err);
                setError("เกิดข้อผิดพลาดในการเข้าสู่ระบบ (กรุณาเปิดใช้งาน Anonymous Auth ใน Firebase)");
            } finally {
                setLoading(false);
            }
        } else {
            setError("รหัสผ่านไม่ถูกต้อง");
            setLoading(false);
        }
    };

    const content = (
        <>
            {!minimal && (
                <div className="text-center mb-8">
                    <h2 className="text-2xl font-bold text-gray-800">
                        {step === "ADMIN" ? "เข้าสู่ระบบ Admin" : "เข้าสู่ระบบอาสา"}
                    </h2>
                    <p className="text-gray-500 text-sm mt-2">
                        {step === "ADMIN" ? "กรุณากรอกรหัสผ่านเพื่อเข้าใช้งาน" : "ยืนยันตัวตนด้วยเบอร์โทรศัพท์เพื่อเริ่มใช้งาน"}
                    </p>
                </div>
            )}

            {error && (
                <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-xl flex items-start gap-3 text-red-600 text-sm">
                    <AlertCircle className="w-5 h-5 shrink-0" />
                    <p>{error}</p>
                </div>
            )}

            {step === "PHONE" && (
                <form onSubmit={handleSendOtp} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700">เบอร์โทรศัพท์</label>
                        <div className="relative">
                            <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="tel"
                                value={phoneNumber}
                                onChange={(e) => setPhoneNumber(e.target.value)}
                                placeholder="08x-xxx-xxxx"
                                className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-800 bg-gray-900 text-white placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all text-lg"
                                required
                            />
                        </div>
                    </div>

                    <div id="recaptcha-container"></div>

                    <ThaiButton
                        type="submit"
                        disabled={loading}
                        className="w-full h-12 text-lg shadow-blue-600/20"
                    >
                        {loading ? (
                            <Loader2 className="w-6 h-6 animate-spin" />
                        ) : (
                            "ส่งรหัส OTP"
                        )}
                    </ThaiButton>

                    <button
                        type="button"
                        onClick={() => {
                            setStep("ADMIN");
                            setError("");
                        }}
                        className="w-full text-center text-gray-400 text-xs hover:text-gray-600 transition-colors"
                    >
                        Admin Login
                    </button>
                </form>
            )}

            {step === "OTP" && (
                <form onSubmit={handleVerifyOtp} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700">รหัส OTP (6 หลัก)</label>
                        <div className="relative">
                            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                value={otp}
                                onChange={(e) => setOtp(e.target.value)}
                                placeholder="xxxxxx"
                                maxLength={6}
                                className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition-all text-lg tracking-widest"
                                required
                            />
                        </div>
                    </div>

                    <ThaiButton
                        type="submit"
                        disabled={loading}
                        className="w-full h-12 text-lg shadow-blue-600/20"
                    >
                        {loading ? (
                            <Loader2 className="w-6 h-6 animate-spin" />
                        ) : (
                            "ยืนยันรหัส OTP"
                        )}
                    </ThaiButton>

                    <button
                        type="button"
                        onClick={() => {
                            setStep("PHONE");
                            setOtp("");
                            setError("");
                        }}
                        className="w-full text-center text-gray-500 text-sm hover:text-gray-700 transition-colors"
                    >
                        เปลี่ยนเบอร์โทรศัพท์
                    </button>
                </form>
            )}

            {step === "ADMIN" && (
                <form onSubmit={handleAdminLogin} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-gray-700">รหัสผ่าน Admin</label>
                        <div className="relative">
                            <KeyRound className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="password"
                                value={adminPassword}
                                onChange={(e) => setAdminPassword(e.target.value)}
                                placeholder="••••••••"
                                className="w-full pl-12 pr-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition-all text-lg"
                                required
                            />
                        </div>
                    </div>

                    <ThaiButton
                        type="submit"
                        disabled={loading}
                        className="w-full h-12 text-lg shadow-blue-600/20"
                    >
                        {loading ? (
                            <Loader2 className="w-6 h-6 animate-spin" />
                        ) : (
                            "เข้าสู่ระบบ"
                        )}
                    </ThaiButton>

                    <button
                        type="button"
                        onClick={() => {
                            setStep("PHONE");
                            setError("");
                        }}
                        className="w-full text-center text-gray-500 text-sm hover:text-gray-700 transition-colors"
                    >
                        กลับไปหน้าเข้าสู่ระบบปกติ
                    </button>
                </form>
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

// Add types for window object
declare global {
    interface Window {
        recaptchaVerifier: any;
    }
}
