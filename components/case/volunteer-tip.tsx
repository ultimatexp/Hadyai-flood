"use client";

import { useState, useEffect } from "react";
import { generate } from "promptparse";
import QRCode from "qrcode";
import { ThaiButton } from "@/components/ui/thai-button";
import { Heart, QrCode, Copy, Check, CheckCircle } from "lucide-react";
import { logTip } from "@/app/actions/family";

interface VolunteerTipProps {
    caseId: string;
    volunteerId: string;
    volunteerName: string;
    promptpayNumber: string;
}

export default function VolunteerTip({ caseId, volunteerId, volunteerName, promptpayNumber }: VolunteerTipProps) {
    const [amount, setAmount] = useState<number>(50);
    const [customAmount, setCustomAmount] = useState<string>("");
    const [qrCodeUrl, setQrCodeUrl] = useState<string>("");
    const [copied, setCopied] = useState(false);
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);

    useEffect(() => {
        generateQR();
    }, [amount, promptpayNumber]);

    const generateQR = async () => {
        try {
            // promptparse expects mobile number to be 08x... or 668x...
            // It handles formatting automatically usually, but let's ensure it's clean
            const cleanNumber = promptpayNumber.replace(/[^0-9]/g, "");

            // Generate PromptPay Payload
            const payload = generate.trueMoney({ mobileNo: cleanNumber, amount });

            // Generate QR Data URL
            const url = await QRCode.toDataURL(payload, {
                margin: 1,
                color: {
                    dark: "#000000",
                    light: "#ffffff"
                }
            });
            setQrCodeUrl(url);
        } catch (error) {
            console.error("Error generating QR:", error);
        }
    };

    const handleAmountSelect = (val: number) => {
        setAmount(val);
        setCustomAmount("");
    };

    const handleCustomChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const val = e.target.value;
        setCustomAmount(val);
        const num = parseFloat(val);
        if (!isNaN(num) && num > 0) {
            setAmount(num);
        }
    };

    const copyPromptPay = () => {
        navigator.clipboard.writeText(promptpayNumber);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const handleConfirm = async () => {
        if (loading || success) return;

        if (!confirm(`ยืนยันการโอนเงินจำนวน ${amount} บาท?`)) return;

        setLoading(true);
        const result = await logTip(caseId, volunteerId, amount);
        if (result.success) {
            setSuccess(true);
        } else {
            alert("บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่");
        }
        setLoading(false);
    };

    if (success) {
        return (
            <div className="bg-green-50 rounded-xl border border-green-100 p-8 text-center space-y-4">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto text-green-600">
                    <CheckCircle className="w-8 h-8" />
                </div>
                <h2 className="font-bold text-xl text-green-800">ขอบคุณสำหรับน้ำใจ!</h2>
                <p className="text-green-700">
                    เราได้บันทึกข้อมูลการโอนเงินของคุณแล้ว<br />
                    ขอให้คุณและครอบครัวปลอดภัย
                </p>
            </div>
        );
    }

    return (
        <div className="bg-gradient-to-b from-pink-50 to-white rounded-xl border border-pink-100 shadow-sm p-6 space-y-6 text-center">
            <div className="space-y-2">
                <div className="w-12 h-12 bg-pink-100 rounded-full flex items-center justify-center mx-auto text-pink-500">
                    <Heart className="w-6 h-6 fill-current" />
                </div>
                <h2 className="font-bold text-xl text-gray-900">ส่งกำลังใจให้อาสา</h2>
                <p className="text-sm text-gray-600 leading-relaxed">
                    "อาสาสมัครทำด้วยหัวใจของจิตอาสา สินน้ำใจเล็กๆ น้อยๆ ของคุณ ช่วยให้พวกเขามีกำลังใจในการช่วยเหลือผู้อื่นต่อ"
                </p>
            </div>

            <div className="space-y-4">
                <div className="flex flex-wrap justify-center gap-2">
                    {[50, 100, 200].map((val) => (
                        <button
                            key={val}
                            onClick={() => handleAmountSelect(val)}
                            className={`px-4 py-2 rounded-full border transition-all ${amount === val && !customAmount
                                ? "bg-pink-500 text-white border-pink-600 shadow-md transform scale-105"
                                : "bg-white text-gray-600 border-gray-200 hover:border-pink-300"
                                }`}
                        >
                            {val} ฿
                        </button>
                    ))}
                </div>

                <div className="flex items-center justify-center gap-2 max-w-[200px] mx-auto">
                    <span className="text-sm text-gray-500">ระบุเอง:</span>
                    <input
                        type="number"
                        value={customAmount}
                        onChange={handleCustomChange}
                        placeholder="0.00"
                        className="w-24 px-2 py-1 text-center border rounded-md focus:outline-none focus:border-pink-500"
                    />
                    <span className="text-sm text-gray-500">฿</span>
                </div>
            </div>

            {qrCodeUrl && (
                <div className="flex flex-col items-center space-y-3 p-4 bg-white rounded-xl border shadow-inner max-w-[250px] mx-auto">
                    <img src={qrCodeUrl} alt="PromptPay QR" className="w-full h-auto rounded-lg" />
                    <div className="text-xs text-gray-400 flex items-center gap-1">
                        <QrCode className="w-3 h-3" />
                        สแกนด้วยแอปธนาคาร
                    </div>
                </div>
            )}

            <div className="space-y-4">
                <div className="pt-2 border-t border-dashed">
                    <p className="text-sm font-medium text-gray-700 mb-1">โอนให้: {volunteerName}</p>
                    <div className="flex items-center justify-center gap-2 text-gray-500 bg-gray-50 py-1 px-3 rounded-full inline-flex">
                        <span className="font-mono">{promptpayNumber}</span>
                        <button onClick={copyPromptPay} className="hover:text-pink-600 transition-colors">
                            {copied ? <Check className="w-4 h-4 text-green-500" /> : <Copy className="w-4 h-4" />}
                        </button>
                    </div>
                </div>

                <ThaiButton
                    onClick={handleConfirm}
                    disabled={loading}
                    className="w-full bg-pink-500 hover:bg-pink-600 text-white shadow-lg shadow-pink-200"
                >
                    {loading ? "กำลังบันทึก..." : "แจ้งโอนเงินเรียบร้อย"}
                </ThaiButton>
            </div>
        </div>
    );
}
