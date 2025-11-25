"use client";

import { useState } from "react";
import { ThaiButton } from "@/components/ui/thai-button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getCaseByPhone } from "@/lib/actions/sos";
import { Loader2, Phone, Search, AlertCircle, ChevronRight, MapPin } from "lucide-react";
import Link from "next/link";
import { format } from "date-fns";
import { th } from "date-fns/locale";

export default function StatusCheckPage() {
    const [phone, setPhone] = useState("");
    const [loading, setLoading] = useState(false);
    const [cases, setCases] = useState<any[] | null>(null);
    const [error, setError] = useState("");

    const handleCheck = async () => {
        if (!phone) return;
        setLoading(true);
        setError("");
        setCases(null);

        try {
            const result = await getCaseByPhone(phone);
            if (result.error) {
                setError("เกิดข้อผิดพลาดในการค้นหา");
            } else {
                setCases(result.data || []);
            }
        } catch (err) {
            setError("เกิดข้อผิดพลาดในการเชื่อมต่อ");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-background p-4 pb-20">
            <div className="max-w-md mx-auto space-y-6">
                <div className="text-center space-y-2 pt-8">
                    <h1 className="text-2xl font-bold">ติดตามสถานะขอความช่วยเหลือ</h1>
                    <p className="text-muted-foreground">กรอกเบอร์โทรศัพท์ที่ใช้แจ้งเหตุ</p>
                </div>

                <div className="bg-white p-6 rounded-2xl shadow-sm border border-border space-y-4">
                    <div className="space-y-2">
                        <Label>เบอร์โทรศัพท์</Label>
                        <div className="relative">
                            <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                            <Input
                                type="tel"
                                value={phone}
                                onChange={(e) => setPhone(e.target.value)}
                                className="pl-9"
                                placeholder="08x-xxx-xxxx"
                            />
                        </div>
                    </div>
                    <ThaiButton
                        onClick={handleCheck}
                        isLoading={loading}
                        className="w-full"
                        disabled={!phone}
                    >
                        <Search className="mr-2 w-4 h-4" />
                        ตรวจสอบสถานะ
                    </ThaiButton>
                </div>

                {error && (
                    <div className="bg-red-50 text-red-600 p-4 rounded-xl flex items-center gap-2">
                        <AlertCircle className="w-5 h-5" />
                        {error}
                    </div>
                )}

                {cases && cases.length === 0 && (
                    <div className="text-center text-muted-foreground py-8">
                        ไม่พบข้อมูลการขอความช่วยเหลือสำหรับเบอร์นี้
                    </div>
                )}

                {cases && cases.length > 0 && (
                    <div className="space-y-4">
                        <h2 className="font-bold text-lg">รายการที่พบ ({cases.length})</h2>
                        {cases.map((c) => (
                            <Link href={`/case/${c.id}?created=true`} key={c.id}>
                                <div className="bg-white p-4 rounded-xl border border-border shadow-sm hover:shadow-md transition-shadow mb-3">
                                    <div className="flex justify-between items-start mb-2">
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                            <MapPin className="w-4 h-4" />
                                            {format(new Date(c.created_at), "d MMM HH:mm", { locale: th })}
                                        </div>
                                        <span className={`px-2 py-1 rounded-full text-xs font-bold ${c.status === "NEW" || c.status === "WAITING" ? "bg-red-100 text-red-700" :
                                                c.status === "ACKNOWLEDGED" ? "bg-blue-100 text-blue-700" :
                                                    c.status === "IN_PROGRESS" ? "bg-orange-100 text-orange-700" :
                                                        "bg-green-100 text-green-700"
                                            }`}>
                                            {c.status === "NEW" || c.status === "WAITING" ? "รอความช่วยเหลือ" :
                                                c.status === "ACKNOWLEDGED" ? "รับเรื่องแล้ว" :
                                                    c.status === "IN_PROGRESS" ? "กำลังช่วยเหลือ" : "ช่วยเหลือแล้ว"}
                                        </span>
                                    </div>
                                    <p className="font-medium line-clamp-2">{c.address_text || "ไม่มีรายละเอียดสถานที่"}</p>
                                    <div className="mt-2 flex justify-end text-primary text-sm font-bold items-center">
                                        ดูรายละเอียด <ChevronRight className="w-4 h-4" />
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
